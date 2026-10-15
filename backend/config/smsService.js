/**
 * Fast2SMS Gateway Service
 * Delivers real cellular SMS messages to Indian (+91) phone numbers.
 */

const sendMobileOtpSms = async (phone, otpCode) => {
  const apiKey = process.env.FAST2SMS_API_KEY;

  // Extract clean 10-digit Indian phone number
  const cleanNumber = phone.toString().replace(/\D/g, '').slice(-10);

  if (!cleanNumber || cleanNumber.length !== 10) {
    console.warn(`⚠️ [SMS] Invalid 10-digit phone number: ${phone}`);
    return { success: false, message: 'Invalid 10-digit phone number' };
  }

  if (!apiKey || apiKey.trim() === '' || apiKey.trim() === 'YOUR_FAST2SMS_API_KEY_HERE') {
    console.warn(`⚠️ [SMS GATEWAY] FAST2SMS_API_KEY is not set in backend/.env!`);
    console.warn(`📲 [SIMULATED SMS to +91 ${cleanNumber}]: OTP code is ${otpCode}`);
    return {
      success: false,
      isConfigured: false,
      message: 'FAST2SMS_API_KEY not configured in backend/.env'
    };
  }

  try {
    // 1. Try Fast2SMS Dedicated OTP Route
    const response = await fetch('https://www.fast2sms.com/dev/bulkV2', {
      method: 'POST',
      headers: {
        'authorization': apiKey.trim(),
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        variables_values: otpCode.toString(),
        route: 'otp',
        numbers: cleanNumber
      })
    });

    const data = await response.json();

    if (data.return === true || data.status_code === 200) {
      console.log(`📲 [REAL SMS DELIVERED VIA FAST2SMS to +91 ${cleanNumber}]: ${otpCode} (ReqID: ${data.request_id || 'OK'})`);
      return { success: true, isConfigured: true, data };
    }

    // 2. If OTP route returned an issue, try Quick SMS Route ('q')
    console.warn(`⚠️ [FAST2SMS OTP Route note for ${cleanNumber}]: ${data.message || JSON.stringify(data)}. Trying Quick SMS fallback...`);

    const fallbackResponse = await fetch('https://www.fast2sms.com/dev/bulkV2', {
      method: 'POST',
      headers: {
        'authorization': apiKey.trim(),
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        route: 'q',
        message: `Your VEXA verification code is ${otpCode}. Valid for 10 minutes.`,
        language: 'english',
        flash: 0,
        numbers: cleanNumber
      })
    });

    const fallbackData = await fallbackResponse.json();
    if (fallbackData.return === true || fallbackData.status_code === 200) {
      console.log(`📲 [REAL SMS DELIVERED VIA FAST2SMS (Quick) to +91 ${cleanNumber}]: ${otpCode}`);
      return { success: true, isConfigured: true, data: fallbackData };
    }

    console.warn(`❌ [FAST2SMS Delivery Failed for ${cleanNumber}]:`, fallbackData.message || fallbackData);
    return { success: false, isConfigured: true, message: fallbackData.message || data.message };
  } catch (error) {
    console.error(`❌ [SMS Connection Error to ${cleanNumber}]:`, error.message);
    return { success: false, error: error.message };
  }
};

module.exports = {
  sendMobileOtpSms
};
