const nodemailer = require('nodemailer');

/**
 * Creates Nodemailer Transporter
 * Uses configured SMTP credentials if provided in backend/.env,
 * or automatically creates a live Ethereal Test Account for instant email delivery & inbox preview.
 */
const createTransporter = async () => {
  const user = process.env.SMTP_USER;
  const pass = process.env.SMTP_PASS;

  if (user && pass && user.trim() !== '' && pass.trim() !== '') {
    const host = process.env.SMTP_HOST || 'smtp.gmail.com';
    const port = Number(process.env.SMTP_PORT) || 587;

    return nodemailer.createTransport({
      host,
      port,
      secure: port === 465,
      auth: { user, pass },
      tls: { rejectUnauthorized: false }
    });
  }

  // Automatic Ethereal SMTP Test Account fallback
  try {
    const account = await nodemailer.createTestAccount();
    return nodemailer.createTransport({
      host: account.smtp.host,
      port: account.smtp.port,
      secure: account.smtp.secure,
      auth: {
        user: account.user,
        pass: account.pass
      },
      tls: { rejectUnauthorized: false }
    });
  } catch (err) {
    console.warn("Could not create Ethereal test account:", err.message);
    return null;
  }
};

/**
 * Send 6-Digit Verification Code via Nodemailer
 * @param {string} toEmail - Recipient email address
 * @param {string} code - 6-digit verification code
 * @param {string} userName - Name of user
 */
const sendResetCodeEmail = async (toEmail, code, userName = 'Valued Member') => {
  const fromEmail = process.env.FROM_EMAIL || '"VEXA Luxury Wear" <noreply@vexa.com>';
  const transporter = await createTransporter();

  const formattedCode = code.split('').join(' ');

  const htmlContent = `
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="utf-8">
        <style>
          body { font-family: 'Helvetica Neue', Arial, sans-serif; background-color: #0d0d0d; color: #e5e5e5; margin: 0; padding: 0; }
          .container { max-width: 540px; margin: 40px auto; background-color: #141414; border: 1px solid #d4af37; border-radius: 16px; padding: 40px; }
          .logo { font-size: 26px; font-weight: bold; letter-spacing: 0.35em; color: #d4af37; text-align: center; margin-bottom: 25px; }
          h2 { color: #ffffff; font-size: 20px; text-align: center; margin-bottom: 10px; }
          p { font-size: 14px; line-height: 1.6; color: #a3a3a3; text-align: center; margin-bottom: 25px; }
          .code-box { background: linear-gradient(135deg, rgba(212,175,55,0.15) 0%, rgba(20,20,20,1) 100%); border: 1.5px solid #d4af37; border-radius: 12px; padding: 24px; text-align: center; margin: 30px 0; }
          .code-number { font-size: 36px; font-weight: 800; letter-spacing: 12px; color: #d4af37; font-family: monospace; }
          .footer { font-size: 11px; color: #666666; text-align: center; border-top: 1px solid #262626; margin-top: 35px; padding-top: 20px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="logo">V E X A</div>
          <h2>Verification Code</h2>
          <p>Hello ${userName}, use the 6-digit verification code below to reset your VEXA account password:</p>
          
          <div class="code-box">
            <div class="code-number">${formattedCode}</div>
          </div>

          <p>This verification code is valid for <strong>15 minutes</strong>. Do not share this code with anyone.</p>

          <div class="footer">
            &copy; ${new Date().getFullYear()} VEXA Luxury Wear Hub. All rights reserved.<br/>
            Need help? Contact support at support@vexa.com
          </div>
        </div>
      </body>
    </html>
  `;

  if (transporter) {
    try {
      const info = await transporter.sendMail({
        from: fromEmail,
        to: toEmail,
        subject: `🔑 ${code} is your VEXA password reset code`,
        html: htmlContent
      });

      const previewUrl = nodemailer.getTestMessageUrl(info);

      console.log(`✉️ 6-Digit reset code (${code}) sent via Nodemailer to ${toEmail} (Message ID: ${info.messageId})`);
      if (previewUrl) {
        console.log(`📬 [LIVE EMAIL INBOX PREVIEW]: ${previewUrl}`);
      }

      return {
        success: true,
        messageId: info.messageId,
        previewUrl: previewUrl || undefined,
        fallbackCode: code
      };
    } catch (err) {
      console.error(`❌ Nodemailer Error sending code to ${toEmail}:`, err.message);
      console.log(`🔑 [LOCAL VERIFICATION CODE FALLBACK]: ${code}`);
      return { success: false, fallbackCode: code, error: err.message };
    }
  } else {
    console.log(`ℹ️ [NODEMAILER NOTICE]: SMTP transport unavailable`);
    console.log(`🔑 [6-DIGIT VERIFICATION CODE GENERATED]: ${code}`);
    return { success: true, isLocalFallback: true, fallbackCode: code };
  }
};

/**
 * Send Password Reset Link Email using Nodemailer
 */
const sendResetPasswordEmail = async (toEmail, resetUrl, userName = 'Valued Member') => {
  const fromEmail = process.env.FROM_EMAIL || '"VEXA Luxury Wear" <noreply@vexa.com>';
  const transporter = await createTransporter();

  const htmlContent = `
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="utf-8">
        <style>
          body { font-family: 'Helvetica Neue', Arial, sans-serif; background-color: #0d0d0d; color: #e5e5e5; margin: 0; padding: 0; }
          .container { max-width: 580px; margin: 40px auto; background-color: #141414; border: 1px solid #d4af37; border-radius: 12px; padding: 40px; }
          .logo { font-size: 26px; font-weight: bold; letter-spacing: 0.35em; color: #d4af37; text-align: center; margin-bottom: 30px; }
          h2 { color: #ffffff; font-size: 20px; margin-bottom: 15px; }
          p { font-size: 14px; line-height: 1.6; color: #a3a3a3; margin-bottom: 25px; }
          .btn-container { text-align: center; margin: 35px 0; }
          .btn { background-color: #d4af37; color: #0d0d0d; font-weight: bold; font-size: 13px; letter-spacing: 0.15em; text-transform: uppercase; text-decoration: none; padding: 14px 32px; border-radius: 4px; display: inline-block; box-shadow: 0 4px 14px rgba(212, 175, 55, 0.4); }
          .footer { font-size: 11px; color: #666666; text-align: center; border-top: 1px solid #262626; margin-top: 40px; padding-top: 20px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="logo">V E X A</div>
          <h2>Password Reset Request</h2>
          <p>Hello ${userName},</p>
          <p>We received a request to reset the password for your VEXA account. Click the golden button below to create your new secure password:</p>
          
          <div class="btn-container">
            <a href="${resetUrl}" class="btn" target="_blank">Reset My Password</a>
          </div>

          <p>This password reset link is valid for <strong>1 hour</strong>.</p>

          <div class="footer">
            &copy; ${new Date().getFullYear()} VEXA Luxury Wear Hub. All rights reserved.<br/>
            Need help? Contact support at support@vexa.com
          </div>
        </div>
      </body>
    </html>
  `;

  if (transporter) {
    try {
      const info = await transporter.sendMail({
        from: fromEmail,
        to: toEmail,
        subject: '🔐 VEXA Account Password Reset Request',
        html: htmlContent
      });
      const previewUrl = nodemailer.getTestMessageUrl(info);
      return { success: true, messageId: info.messageId, previewUrl: previewUrl || undefined };
    } catch (err) {
      console.error(`❌ Nodemailer Error sending email to ${toEmail}:`, err.message);
      return { success: false, fallbackUrl: resetUrl, error: err.message };
    }
  } else {
    return { success: true, isLocalFallback: true, fallbackUrl: resetUrl };
  }
};

module.exports = { sendResetCodeEmail, sendResetPasswordEmail };
