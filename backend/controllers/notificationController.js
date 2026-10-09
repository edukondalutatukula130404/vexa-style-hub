const Notification = require('../models/Notification');
const User = require('../models/User');
const { broadcast } = require('../config/websocket');
const { sendFcmNotification } = require('../config/firebase');

// @desc    Get user notifications by email
// @route   GET /api/notifications
// @access  Public
exports.getUserNotifications = async (req, res, next) => {
  try {
    const { email } = req.query;
    if (!email) {
      return res.status(400).json({ success: false, message: 'Please provide user email' });
    }

    const cleanEmail = email.toLowerCase().trim();
    const notifications = await Notification.find({
      $or: [
        { userEmail: cleanEmail },
        { userEmail: { $regex: new RegExp(`^${cleanEmail.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}$`, 'i') } }
      ]
    }).sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      count: notifications.length,
      data: notifications
    });
  } catch (error) {
    console.warn('Notifications fetch note:', error.message);
    res.status(200).json({
      success: true,
      count: 0,
      data: []
    });
  }
};

// @desc    Mark notification as read
// @route   PUT /api/notifications/:id/read
// @access  Public
exports.markNotificationRead = async (req, res, next) => {
  try {
    const notification = await Notification.findByIdAndUpdate(
      req.params.id,
      { read: true },
      { new: true }
    );
    res.status(200).json({
      success: true,
      data: notification
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Mark all notifications as read for a user
// @route   PUT /api/notifications/read-all
// @access  Public
exports.markAllNotificationsRead = async (req, res, next) => {
  try {
    const { email } = req.body;
    if (email) {
      const cleanEmail = email.toLowerCase().trim();
      await Notification.updateMany({ userEmail: cleanEmail }, { read: true });
    }
    res.status(200).json({
      success: true,
      message: 'All notifications marked as read'
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Clear user notifications
// @route   DELETE /api/notifications
// @access  Public
exports.clearUserNotifications = async (req, res, next) => {
  try {
    const { email } = req.query;
    if (email) {
      const cleanEmail = email.toLowerCase().trim();
      await Notification.deleteMany({ userEmail: cleanEmail });
    }
    res.status(200).json({
      success: true,
      message: 'Notifications cleared successfully'
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Receive support message or ticket from user and notify admin
// @route   POST /api/notifications/support
// @access  Public
exports.sendSupportMessage = async (req, res, next) => {
  try {
    const {
      userName,
      customerName,
      userEmail,
      orderId,
      category,
      text,
      message,
      query,
      phone,
      ticketId
    } = req.body;

    const sender = customerName || userName || userEmail || 'Customer';
    const msgText = text || message || query || 'Customer sent a support message';
    const cleanOrder = orderId ? String(orderId).replace(/^#+/, '').trim() : '';
    const orderRef = cleanOrder ? ` (Ref: #${cleanOrder.slice(-8).toUpperCase()})` : '';
    const catLabel = category ? ` [${category}]` : '';

    const notifTitle = ticketId ? `🎫 Support Ticket: ${sender}${catLabel}` : `💬 Support: ${sender}${catLabel}`;
    const notifBody = `"${msgText}"${orderRef}`;

    // 1. Broadcast live WebSocket message to open Admin dashboards
    broadcast('SUPPORT_MESSAGE', {
      ticketId: ticketId || '',
      userName: sender,
      customerName: sender,
      userEmail: userEmail || '',
      orderId: orderId || '',
      category: category || 'Customer Support',
      text: msgText,
      message: msgText,
      query: msgText,
      phone: phone || '',
      timestamp: Date.now()
    });

    if (ticketId) {
      broadcast('SUPPORT_TICKET_CREATED', {
        ticketId,
        category: category || 'General',
        query: msgText,
        userName: sender,
        customerName: sender,
        orderId: orderId || '',
        phone: phone || '',
        createdAt: new Date().toISOString()
      });
    }

    // 2. Create Notification document in MongoDB for Admin
    try {
      await Notification.create({
        userId: 'admin',
        userEmail: 'admin@vexa.com',
        orderId: orderId || ticketId || 'SUPPORT',
        type: 'support_message',
        title: notifTitle,
        message: notifBody,
        status: 'Open',
        read: false
      });
    } catch (dbErr) {
      console.warn('DB notification insert note:', dbErr.message);
    }

    // 3. Send Push Notification to all Admin FCM tokens if available
    try {
      const adminUsers = await User.find({
        $or: [{ role: 'admin' }, { email: { $regex: /admin/i } }]
      });

      for (const admin of adminUsers) {
        const adminTokens = Array.isArray(admin.fcmTokens) && admin.fcmTokens.length > 0
          ? admin.fcmTokens
          : (admin.fcmToken ? [admin.fcmToken] : []);

        if (adminTokens.length > 0) {
          await sendFcmNotification({
            tokens: adminTokens,
            title: notifTitle,
            body: notifBody,
            data: {
              type: 'support_message',
              orderId: orderId || '',
              ticketId: ticketId || '',
              customerName: sender
            }
          });
        }
      }
    } catch (e) {
      console.warn('Admin push notification note:', e.message);
    }

    res.status(200).json({
      success: true,
      message: 'Support message forwarded to admin successfully'
    });
  } catch (error) {
    console.error('sendSupportMessage error:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

