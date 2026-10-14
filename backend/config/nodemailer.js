const nodemailer = require('nodemailer');

/**
 * Creates Nodemailer SMTP Transporter
 * Outgoing emails are routed through the configured Admin SMTP mailbox.
 */
const createTransporter = async () => {
  const user = process.env.SMTP_USER || process.env.EMAIL_USER;
  const pass = process.env.SMTP_PASS || process.env.EMAIL_PASS;

  if (user && pass && user.trim() !== '' && pass.trim() !== '') {
    const cleanUser = user.trim();
    const cleanPass = pass.trim();

    const host = process.env.SMTP_HOST || (cleanUser.includes('@gmail') ? 'smtp.gmail.com' : 'smtp.gmail.com');
    const port = Number(process.env.SMTP_PORT) || 465;
    const secure = port === 465;

    return nodemailer.createTransport({
      host,
      port,
      secure,
      auth: {
        user: cleanUser,
        pass: cleanPass
      },
      tls: {
        rejectUnauthorized: false
      }
    });
  }

  // Automatic Ethereal SMTP Test Account fallback if SMTP credentials are missing
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
    console.warn('Could not create Ethereal test account:', err.message);
    return null;
  }
};

const getFromEmail = (senderLabel = 'VEXA Style Hub') => {
  const adminEmail = process.env.ADMIN_EMAIL || process.env.SMTP_USER || process.env.EMAIL_USER || 'admin@vexa.com';
  return `"${senderLabel}" <${adminEmail}>`;
};

/**
 * 1. FORGOT PASSWORD: Send 6-Digit Verification Code via SMTP
 * Admin NEVER receives the user's password or new credentials.
 */
const sendResetCodeEmail = async (toEmail, code, userName = 'Valued Member') => {
  try {
    const transporter = await createTransporter();
    if (!transporter) return { success: false, fallbackCode: code };

    const formattedCode = code.split('').join(' ');
    const from = getFromEmail('VEXA Security & Accounts');

    const htmlContent = `
      <!DOCTYPE html>
      <html>
        <head>
          <meta charset="utf-8">
          <style>
            body { font-family: 'Helvetica Neue', Arial, sans-serif; background-color: #0b0b0d; color: #e5e5e5; margin: 0; padding: 0; }
            .container { max-width: 540px; margin: 40px auto; background-color: #141418; border: 1px solid #d4af37; border-radius: 16px; padding: 40px; box-shadow: 0 10px 30px rgba(0,0,0,0.5); }
            .logo { font-size: 26px; font-weight: bold; letter-spacing: 0.35em; color: #d4af37; text-align: center; margin-bottom: 25px; }
            h2 { color: #ffffff; font-size: 20px; text-align: center; margin-bottom: 10px; }
            p { font-size: 14px; line-height: 1.6; color: #a3a3a3; text-align: center; margin-bottom: 25px; }
            .code-box { background: linear-gradient(135deg, rgba(212,175,55,0.15) 0%, rgba(20,20,24,1) 100%); border: 1.5px solid #d4af37; border-radius: 12px; padding: 24px; text-align: center; margin: 25px 0; }
            .code-number { font-size: 36px; font-weight: 800; letter-spacing: 12px; color: #d4af37; font-family: monospace; }
            .security-banner { background-color: rgba(212,175,55,0.08); border-left: 3px solid #d4af37; padding: 12px 16px; border-radius: 6px; font-size: 12px; color: #c4c4c4; text-align: left; margin-top: 20px; }
            .footer { font-size: 11px; color: #666666; text-align: center; border-top: 1px solid #262626; margin-top: 35px; padding-top: 20px; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="logo">V E X A</div>
            <h2>Password Reset Verification</h2>
            <p>Hello <strong>${userName}</strong>,<br/>We received a request to reset your password. Use the verification code below to proceed:</p>
            
            <div class="code-box">
              <div class="code-number">${formattedCode}</div>
            </div>

            <p>This verification code expires in <strong>15 minutes</strong>. If you did not make this request, you can safely ignore this email.</p>

            <div class="security-banner">
              🔒 <strong>Security Guarantee:</strong> This code is confidential to your email. VEXA administrators will never ask for your password, OTP, or account credentials.
            </div>

            <div class="footer">
              &copy; ${new Date().getFullYear()} VEXA Style Hub. All rights reserved.<br/>
              Automated message sent via official VEXA SMTP Mail Gateway.
            </div>
          </div>
        </body>
      </html>
    `;

    const info = await transporter.sendMail({
      from,
      to: toEmail,
      subject: `🔑 ${code} is your VEXA password reset code`,
      html: htmlContent
    });

    console.log(`✉️ [SMTP] Password reset code sent to ${toEmail} (ID: ${info.messageId})`);
    return { success: true, messageId: info.messageId, fallbackCode: code };
  } catch (err) {
    console.error(`❌ [SMTP] Error sending reset code to ${toEmail}:`, err.message);
    return { success: false, fallbackCode: code, error: err.message };
  }
};

/**
 * 2. CREATE ACCOUNT: Send Welcome Email via SMTP
 * Admin does NOT receive or get access to user password/credentials.
 */
const sendWelcomeEmail = async (toEmail, userName = 'Valued Member') => {
  try {
    const transporter = await createTransporter();
    if (!transporter) return { success: false };

    const from = getFromEmail('VEXA Style Hub');

    const htmlContent = `
      <!DOCTYPE html>
      <html>
        <head>
          <meta charset="utf-8">
          <style>
            body { font-family: 'Helvetica Neue', Arial, sans-serif; background-color: #0b0b0d; color: #e5e5e5; margin: 0; padding: 0; }
            .container { max-width: 560px; margin: 40px auto; background-color: #141418; border: 1px solid #d4af37; border-radius: 16px; padding: 40px; box-shadow: 0 10px 30px rgba(0,0,0,0.5); }
            .logo { font-size: 28px; font-weight: bold; letter-spacing: 0.35em; color: #d4af37; text-align: center; margin-bottom: 20px; }
            h2 { color: #ffffff; font-size: 22px; text-align: center; margin-bottom: 12px; }
            p { font-size: 14px; line-height: 1.7; color: #b3b3b3; margin-bottom: 18px; }
            .highlight-card { background: rgba(212,175,55,0.06); border: 1px solid rgba(212,175,55,0.25); border-radius: 12px; padding: 20px; margin: 25px 0; }
            .highlight-item { font-size: 14px; color: #e5e5e5; margin-bottom: 10px; display: flex; align-items: center; }
            .security-banner { background-color: rgba(255,255,255,0.03); border-left: 3px solid #10b981; padding: 14px 16px; border-radius: 6px; font-size: 12px; color: #c4c4c4; margin-top: 25px; }
            .footer { font-size: 11px; color: #666666; text-align: center; border-top: 1px solid #262626; margin-top: 35px; padding-top: 20px; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="logo">V E X A</div>
            <h2>Welcome to VEXA Style Hub ✨</h2>
            <p>Hello <strong>${userName}</strong>,</p>
            <p>Your VEXA account has been successfully created. We are excited to welcome you into our bespoke fashion community, featuring hand-crafted luxury apparel and timeless style collections.</p>
            
            <div class="highlight-card">
              <div class="highlight-item">🌟 <strong>Account Email:</strong> &nbsp;${toEmail}</div>
              <div class="highlight-item">🛍️ <strong>Privileges:</strong> &nbsp;VIP Catalog Access, Fast Checkout, Live Order Tracking</div>
              <div class="highlight-item">📞 <strong>24/7 Helpline:</strong> &nbsp;Priority concierge assistance whenever you need help</div>
            </div>

            <div class="security-banner">
              🛡️ <strong>Privacy & Security Commitment:</strong><br/>
              Your account password is encrypted with cryptographic hashing. Administrators do not have access to your credentials and will never request your login details.
            </div>

            <div class="footer">
              &copy; ${new Date().getFullYear()} VEXA Style Hub. All rights reserved.<br/>
              Sent from VEXA Admin Mail System (${process.env.ADMIN_EMAIL || 'admin@vexa.com'})
            </div>
          </div>
        </body>
      </html>
    `;

    const info = await transporter.sendMail({
      from,
      to: toEmail,
      subject: `✨ Welcome to VEXA Style Hub, ${userName}!`,
      html: htmlContent
    });

    console.log(`✉️ [SMTP] Welcome email sent to ${toEmail} (ID: ${info.messageId})`);
    return { success: true, messageId: info.messageId };
  } catch (err) {
    console.error(`❌ [SMTP] Error sending welcome email to ${toEmail}:`, err.message);
    return { success: false, error: err.message };
  }
};

/**
 * 3. HELPLINE: Send Helpline Confirmation to User & Notification to Admin
 * Admin receives user's message/query ONLY — strictly NO credentials or tokens.
 */
const sendHelplineEmails = async ({
  ticketId = `TKT-${Date.now()}`,
  customerName = 'Valued Customer',
  customerEmail,
  phone = 'Not provided',
  category = 'General Support',
  message,
  associatedOrderId = ''
}) => {
  try {
    const transporter = await createTransporter();
    if (!transporter) return { success: false };

    const from = getFromEmail('VEXA VIP Concierge & Helpline');
    const adminEmail = process.env.ADMIN_EMAIL || process.env.SMTP_USER || 'tatukulaedukondalu@gmail.com';

    // A. Confirmation to Customer
    if (customerEmail) {
      const userHtml = `
        <!DOCTYPE html>
        <html>
          <head>
            <meta charset="utf-8">
            <style>
              body { font-family: 'Helvetica Neue', Arial, sans-serif; background-color: #0b0b0d; color: #e5e5e5; margin: 0; padding: 0; }
              .container { max-width: 560px; margin: 40px auto; background-color: #141418; border: 1px solid #d4af37; border-radius: 16px; padding: 40px; box-shadow: 0 10px 30px rgba(0,0,0,0.5); }
              .logo { font-size: 26px; font-weight: bold; letter-spacing: 0.35em; color: #d4af37; text-align: center; margin-bottom: 20px; }
              h2 { color: #ffffff; font-size: 20px; text-align: center; margin-bottom: 12px; }
              p { font-size: 14px; line-height: 1.6; color: #b3b3b3; margin-bottom: 16px; }
              .ticket-badge { background: #d4af37; color: #0b0b0d; font-weight: bold; font-size: 13px; padding: 6px 14px; border-radius: 20px; display: inline-block; margin-bottom: 15px; }
              .card { background-color: rgba(255,255,255,0.03); border: 1px solid #2a2a30; border-radius: 12px; padding: 20px; margin: 20px 0; font-size: 13px; color: #e5e5e5; }
              .security-note { font-size: 12px; color: #9e9e9e; border-left: 2px solid #d4af37; padding-left: 12px; margin-top: 20px; }
              .footer { font-size: 11px; color: #666666; text-align: center; border-top: 1px solid #262626; margin-top: 35px; padding-top: 20px; }
            </style>
          </head>
          <body>
            <div class="container">
              <div class="logo">V E X A</div>
              <div style="text-align: center;"><span class="ticket-badge">Ticket #${ticketId}</span></div>
              <h2>Helpline Request Received</h2>
              <p>Hello <strong>${customerName}</strong>,</p>
              <p>We have received your support request. Our customer support concierge has been notified and will assist you promptly.</p>
              
              <div class="card">
                <div><strong>Category:</strong> ${category}</div>
                ${associatedOrderId ? `<div><strong>Associated Order:</strong> ${associatedOrderId}</div>` : ''}
                <div style="margin-top: 10px;"><strong>Your Inquiry:</strong></div>
                <div style="color: #c4c4c4; font-style: italic; margin-top: 4px; line-height: 1.5;">"${message}"</div>
              </div>

              <div class="security-note">
                🛡️ <strong>Safety Reminder:</strong> Our support representatives will never ask you for your account password or payment PIN.
              </div>

              <div class="footer">
                &copy; ${new Date().getFullYear()} VEXA Style Hub Concierge.<br/>
                Sent from VEXA Admin Mail Gateway.
              </div>
            </div>
          </body>
        </html>
      `;

      await transporter.sendMail({
        from,
        to: customerEmail,
        subject: `🎫 [VEXA Helpline #${ticketId}] Request Received: ${category}`,
        html: userHtml
      });
      console.log(`✉️ [SMTP] Helpline acknowledgment sent to customer ${customerEmail}`);
    }

    // B. Notification to Admin Mailbox (Strictly contains NO user credentials)
    if (adminEmail) {
      const adminHtml = `
        <!DOCTYPE html>
        <html>
          <head>
            <meta charset="utf-8">
            <style>
              body { font-family: 'Helvetica Neue', Arial, sans-serif; background-color: #0b0b0d; color: #e5e5e5; margin: 0; padding: 0; }
              .container { max-width: 580px; margin: 30px auto; background-color: #141418; border: 1px solid #3b82f6; border-radius: 14px; padding: 30px; }
              .badge { background-color: #ef4444; color: #ffffff; font-size: 11px; font-weight: bold; padding: 4px 10px; border-radius: 12px; }
              h2 { color: #ffffff; font-size: 18px; margin-top: 10px; }
              .field { margin: 10px 0; font-size: 13px; color: #cccccc; }
              .field strong { color: #ffffff; }
              .msg-box { background-color: #1c1c22; border: 1px solid #33333d; border-radius: 8px; padding: 16px; margin: 15px 0; font-size: 14px; color: #f3f4f6; }
              .security-flag { font-size: 11px; color: #10b981; border: 1px solid #065f46; background: rgba(16,185,129,0.06); padding: 8px 12px; border-radius: 6px; }
            </style>
          </head>
          <body>
            <div class="container">
              <span class="badge">NEW HELPLINE INQUIRY</span>
              <h2>Support Ticket #${ticketId}</h2>
              <div class="field"><strong>Customer Name:</strong> ${customerName}</div>
              <div class="field"><strong>Customer Email:</strong> ${customerEmail || 'Not provided'}</div>
              <div class="field"><strong>Mobile / Phone:</strong> ${phone}</div>
              <div class="field"><strong>Category:</strong> ${category}</div>
              ${associatedOrderId ? `<div class="field"><strong>Order Reference:</strong> ${associatedOrderId}</div>` : ''}
              
              <div class="field"><strong>Inquiry Content:</strong></div>
              <div class="msg-box">${message}</div>

              <div class="security-flag">
                🔒 <strong>Privacy Assurance:</strong> No user passwords, authentication tokens, or private credentials are included or accessed.
              </div>
            </div>
          </body>
        </html>
      `;

      await transporter.sendMail({
        from,
        to: adminEmail,
        subject: `🚨 [VEXA Helpline Ticket #${ticketId}] ${category} - ${customerName}`,
        html: adminHtml
      });
      console.log(`✉️ [SMTP] Helpline ticket alert delivered to Admin (${adminEmail})`);
    }

    return { success: true };
  } catch (err) {
    console.error('❌ [SMTP] Helpline email error:', err.message);
    return { success: false, error: err.message };
  }
};

/**
 * 4. ORDER CREATED: Send Order Confirmation & Invoice via SMTP
 */
const sendOrderConfirmationEmail = async (order) => {
  try {
    const toEmail = order.userEmail;
    if (!toEmail) return { success: false };

    const transporter = await createTransporter();
    if (!transporter) return { success: false };

    const orderId = order.id || order._id || 'ORD-0000';
    const customerName = order.userName || order.customerName || 'Valued Customer';
    const from = getFromEmail('VEXA Style Hub Orders');

    const itemsRows = (order.items || []).map((item) => `
      <tr>
        <td style="padding: 10px; border-bottom: 1px solid #262626; color: #ffffff;">${item.name || item.title || 'Luxury Item'}</td>
        <td style="padding: 10px; border-bottom: 1px solid #262626; text-align: center; color: #c4c4c4;">${item.quantity || 1}</td>
        <td style="padding: 10px; border-bottom: 1px solid #262626; text-align: right; color: #d4af37; font-weight: bold;">₹${item.price || 0}</td>
      </tr>
    `).join('');

    const htmlContent = `
      <!DOCTYPE html>
      <html>
        <head>
          <meta charset="utf-8">
          <style>
            body { font-family: 'Helvetica Neue', Arial, sans-serif; background-color: #0b0b0d; color: #e5e5e5; margin: 0; padding: 0; }
            .container { max-width: 580px; margin: 40px auto; background-color: #141418; border: 1px solid #d4af37; border-radius: 16px; padding: 40px; box-shadow: 0 10px 30px rgba(0,0,0,0.5); }
            .logo { font-size: 26px; font-weight: bold; letter-spacing: 0.35em; color: #d4af37; text-align: center; margin-bottom: 20px; }
            h2 { color: #ffffff; font-size: 20px; text-align: center; margin-bottom: 8px; }
            .order-badge { background: #d4af37; color: #0b0b0d; font-weight: bold; font-size: 13px; padding: 6px 14px; border-radius: 20px; display: inline-block; margin-bottom: 20px; }
            p { font-size: 14px; line-height: 1.6; color: #b3b3b3; margin-bottom: 16px; }
            table { width: 100%; border-collapse: collapse; margin: 20px 0; font-size: 13px; }
            th { text-align: left; padding: 10px; border-bottom: 1.5px solid #d4af37; color: #d4af37; }
            .total-row { font-size: 16px; font-weight: bold; color: #ffffff; padding-top: 14px; text-align: right; }
            .info-box { background-color: rgba(255,255,255,0.03); border: 1px solid #2a2a30; border-radius: 10px; padding: 16px; margin: 20px 0; font-size: 13px; }
            .footer { font-size: 11px; color: #666666; text-align: center; border-top: 1px solid #262626; margin-top: 35px; padding-top: 20px; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="logo">V E X A</div>
            <div style="text-align: center;"><span class="order-badge">Order Confirmed</span></div>
            <h2>Thank You For Your Order!</h2>
            <p>Hello <strong>${customerName}</strong>,<br/>Your order <strong>#${orderId}</strong> has been received and is being prepared with utmost care.</p>
            
            <table>
              <thead>
                <tr>
                  <th>Item</th>
                  <th style="text-align: center;">Qty</th>
                  <th style="text-align: right;">Price</th>
                </tr>
              </thead>
              <tbody>
                ${itemsRows}
              </tbody>
            </table>

            <div class="total-row">
              Total Amount: <span style="color: #d4af37;">₹${order.totalAmount || 0}</span>
            </div>

            <div class="info-box">
              <div><strong>Payment Method:</strong> ${order.paymentMethod || 'Cash on Delivery'} (${order.paymentStatus || 'Pending'})</div>
              <div style="margin-top: 6px;"><strong>Delivery Address:</strong> ${order.shippingAddress || 'Customer shipping address'}</div>
            </div>

            <p style="text-align: center; font-size: 13px; color: #a3a3a3;">You can track your order status in real time in the VEXA app.</p>

            <div class="footer">
              &copy; ${new Date().getFullYear()} VEXA Style Hub.<br/>
              Sent via VEXA Admin Mail System (${process.env.ADMIN_EMAIL || 'admin@vexa.com'})
            </div>
          </div>
        </body>
      </html>
    `;

    const info = await transporter.sendMail({
      from,
      to: toEmail,
      subject: `🛍️ Order Confirmed #${orderId} - VEXA Style Hub`,
      html: htmlContent
    });

    console.log(`✉️ [SMTP] Order confirmation email sent to ${toEmail} (ID: ${info.messageId})`);
    return { success: true, messageId: info.messageId };
  } catch (err) {
    console.error(`❌ [SMTP] Error sending order confirmation to ${order.userEmail}:`, err.message);
    return { success: false, error: err.message };
  }
};

/**
 * 5. ORDER STATUS UPDATED: Send Tracking & Status Update via SMTP
 */
const sendOrderStatusEmail = async (order, newStatus, cancelReason = '') => {
  try {
    const toEmail = order.userEmail;
    if (!toEmail) return { success: false };

    const transporter = await createTransporter();
    if (!transporter) return { success: false };

    const orderId = order.id || order._id || 'ORD-0000';
    const customerName = order.userName || order.customerName || 'Valued Customer';
    const from = getFromEmail('VEXA Style Hub Order Updates');

    let statusColor = '#3b82f6';
    let statusIcon = '📦';
    if (newStatus.toLowerCase().includes('deliver')) {
      statusColor = '#10b981';
      statusIcon = '✅';
    } else if (newStatus.toLowerCase().includes('cancel')) {
      statusColor = '#ef4444';
      statusIcon = '❌';
    } else if (newStatus.toLowerCase().includes('ship')) {
      statusColor = '#d4af37';
      statusIcon = '🚚';
    }

    const htmlContent = `
      <!DOCTYPE html>
      <html>
        <head>
          <meta charset="utf-8">
          <style>
            body { font-family: 'Helvetica Neue', Arial, sans-serif; background-color: #0b0b0d; color: #e5e5e5; margin: 0; padding: 0; }
            .container { max-width: 560px; margin: 40px auto; background-color: #141418; border: 1px solid ${statusColor}; border-radius: 16px; padding: 40px; box-shadow: 0 10px 30px rgba(0,0,0,0.5); }
            .logo { font-size: 26px; font-weight: bold; letter-spacing: 0.35em; color: #d4af37; text-align: center; margin-bottom: 20px; }
            h2 { color: #ffffff; font-size: 20px; text-align: center; margin-bottom: 8px; }
            .status-badge { background: ${statusColor}; color: #ffffff; font-weight: bold; font-size: 13px; padding: 6px 16px; border-radius: 20px; display: inline-block; margin-bottom: 20px; }
            p { font-size: 14px; line-height: 1.6; color: #b3b3b3; margin-bottom: 16px; }
            .detail-card { background-color: rgba(255,255,255,0.03); border: 1px solid #2a2a30; border-radius: 10px; padding: 18px; margin: 20px 0; font-size: 13px; }
            .footer { font-size: 11px; color: #666666; text-align: center; border-top: 1px solid #262626; margin-top: 35px; padding-top: 20px; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="logo">V E X A</div>
            <div style="text-align: center;"><span class="status-badge">${statusIcon} ${newStatus.toUpperCase()}</span></div>
            <h2>Order Status Update</h2>
            <p>Hello <strong>${customerName}</strong>,<br/>Your order <strong>#${orderId}</strong> status has been updated to <strong>${newStatus}</strong>.</p>
            
            <div class="detail-card">
              <div><strong>Order ID:</strong> #${orderId}</div>
              <div style="margin-top: 6px;"><strong>Status:</strong> <span style="color: ${statusColor}; font-weight: bold;">${newStatus}</span></div>
              ${cancelReason ? `<div style="margin-top: 6px; color: #ef4444;"><strong>Reason:</strong> ${cancelReason}</div>` : ''}
              <div style="margin-top: 6px;"><strong>Total Amount:</strong> ₹${order.totalAmount || 0}</div>
              <div style="margin-top: 6px;"><strong>Shipping Address:</strong> ${order.shippingAddress || 'As per order'}</div>
            </div>

            <p style="text-align: center; font-size: 13px; color: #a3a3a3;">For any queries regarding this order, reach out to our 24/7 helpline in the app.</p>

            <div class="footer">
              &copy; ${new Date().getFullYear()} VEXA Style Hub.<br/>
              Dispatched from VEXA Admin Mail System (${process.env.ADMIN_EMAIL || 'admin@vexa.com'})
            </div>
          </div>
        </body>
      </html>
    `;

    const info = await transporter.sendMail({
      from,
      to: toEmail,
      subject: `${statusIcon} Order #${orderId} Status Update: ${newStatus}`,
      html: htmlContent
    });

    console.log(`✉️ [SMTP] Order status update email sent to ${toEmail} (ID: ${info.messageId})`);
    return { success: true, messageId: info.messageId };
  } catch (err) {
    console.error(`❌ [SMTP] Error sending order status update to ${order.userEmail}:`, err.message);
    return { success: false, error: err.message };
  }
};

/**
 * 6. MOBILE LOGIN OTP: Send 6-Digit Login Code via SMTP
 */
const sendLoginOtpEmail = async (toEmail, code, phone = '', userName = 'Valued Member') => {
  try {
    const transporter = await createTransporter();
    if (!transporter) return { success: false, fallbackCode: code };

    const formattedCode = code.split('').join(' ');
    const from = getFromEmail('VEXA Mobile Authentication');

    const htmlContent = `
      <!DOCTYPE html>
      <html>
        <head>
          <meta charset="utf-8">
          <style>
            body { font-family: 'Helvetica Neue', Arial, sans-serif; background-color: #0b0b0d; color: #e5e5e5; margin: 0; padding: 0; }
            .container { max-width: 540px; margin: 40px auto; background-color: #141418; border: 1px solid #d4af37; border-radius: 16px; padding: 40px; box-shadow: 0 10px 30px rgba(0,0,0,0.5); }
            .logo { font-size: 26px; font-weight: bold; letter-spacing: 0.35em; color: #d4af37; text-align: center; margin-bottom: 25px; }
            h2 { color: #ffffff; font-size: 20px; text-align: center; margin-bottom: 10px; }
            p { font-size: 14px; line-height: 1.6; color: #a3a3a3; text-align: center; margin-bottom: 25px; }
            .code-box { background: linear-gradient(135deg, rgba(212,175,55,0.15) 0%, rgba(20,20,24,1) 100%); border: 1.5px solid #d4af37; border-radius: 12px; padding: 24px; text-align: center; margin: 25px 0; }
            .code-number { font-size: 36px; font-weight: 800; letter-spacing: 12px; color: #d4af37; font-family: monospace; }
            .footer { font-size: 11px; color: #666666; text-align: center; border-top: 1px solid #262626; margin-top: 35px; padding-top: 20px; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="logo">V E X A</div>
            <h2>Mobile Login OTP</h2>
            <p>Hello <strong>${userName}</strong>,<br/>Use the 6-digit verification code below to log in to your VEXA account ${phone ? `(Mobile: ${phone})` : ''}:</p>
            
            <div class="code-box">
              <div class="code-number">${formattedCode}</div>
            </div>

            <p>This OTP is valid for <strong>10 minutes</strong>. Do not share this code with anyone.</p>

            <div class="footer">
              &copy; ${new Date().getFullYear()} VEXA Style Hub.<br/>
              Sent via VEXA Admin Mail System (${process.env.ADMIN_EMAIL || 'admin@vexa.com'})
            </div>
          </div>
        </body>
      </html>
    `;

    const info = await transporter.sendMail({
      from,
      to: toEmail,
      subject: `📲 ${code} is your VEXA Mobile Login OTP`,
      html: htmlContent
    });

    console.log(`✉️ [SMTP] Login OTP sent to ${toEmail} (ID: ${info.messageId})`);
    return { success: true, messageId: info.messageId, fallbackCode: code };
  } catch (err) {
    console.error(`❌ [SMTP] Error sending login OTP to ${toEmail}:`, err.message);
    return { success: false, fallbackCode: code, error: err.message };
  }
};

module.exports = {
  createTransporter,
  sendResetCodeEmail,
  sendWelcomeEmail,
  sendHelplineEmails,
  sendOrderConfirmationEmail,
  sendOrderStatusEmail,
  sendLoginOtpEmail
};
