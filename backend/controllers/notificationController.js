const mongoose = require('mongoose');
const Notification = require('../models/Notification');
const User = require('../models/User');
const Order = require('../models/Order');
const { broadcast } = require('../config/websocket');
const { sendFcmNotification } = require('../config/firebase');
const { sendHelplineEmails } = require('../config/nodemailer');

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

// @desc    Delete single notification
// @route   DELETE /api/notifications/:id
// @access  Public
exports.deleteSingleNotification = async (req, res, next) => {
  try {
    await Notification.findByIdAndDelete(req.params.id);
    res.status(200).json({
      success: true,
      message: 'Notification deleted successfully'
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
    const rawOrder = orderId || req.body.associatedOrderId || '';
    const cleanOrder = rawOrder ? String(rawOrder).replace(/^#+/, '').trim() : '';
    const associatedOrderRef = cleanOrder ? (cleanOrder.startsWith('VX-') ? `#${cleanOrder}` : `#VX-${cleanOrder}`) : '';
    const orderRef = cleanOrder ? ` (Ref: #${cleanOrder.slice(-8).toUpperCase()})` : '';
    const catLabel = category ? ` [${category}]` : '';

    const notifTitle = ticketId ? `🎫 Support Ticket: ${sender}${catLabel}` : `💬 Support: ${sender}${catLabel}`;
    const notifBody = `"${msgText}"${orderRef}`;

    // 1. Check if a ticket with this ticketId was already created to prevent duplicate DB insertions
    if (ticketId) {
      const existing = await Notification.findOne({
        type: 'support_message',
        orderId: ticketId
      });
      if (existing) {
        return res.status(200).json({
          success: true,
          message: 'Support ticket already registered',
          data: existing
        });
      }
    } else {
      // For general chat messages without a ticketId, prevent duplicate rapid submissions within 5 seconds
      const recentExisting = await Notification.findOne({
        type: 'support_message',
        title: notifTitle,
        message: notifBody,
        createdAt: { $gte: new Date(Date.now() - 5000) }
      });
      if (recentExisting) {
        return res.status(200).json({
          success: true,
          message: 'Support message recently registered',
          data: recentExisting
        });
      }
    }

    // 2. Broadcast exactly one live WebSocket event to avoid multiple duplicate admin toasts
    if (ticketId) {
      broadcast('SUPPORT_TICKET_CREATED', {
        ticketId,
        category: category || 'General',
        query: msgText,
        text: msgText,
        message: msgText,
        userName: sender,
        customerName: sender,
        userEmail: userEmail || '',
        orderId: associatedOrderRef || cleanOrder || '',
        associatedOrderId: associatedOrderRef || cleanOrder || '',
        phone: phone || '',
        createdAt: new Date().toISOString()
      });
    } else {
      broadcast('SUPPORT_MESSAGE', {
        ticketId: '',
        userName: sender,
        customerName: sender,
        userEmail: userEmail || '',
        orderId: associatedOrderRef || cleanOrder || '',
        associatedOrderId: associatedOrderRef || cleanOrder || '',
        category: category || 'Customer Support',
        text: msgText,
        message: msgText,
        query: msgText,
        phone: phone || '',
        timestamp: Date.now()
      });
    }

    // 3. Create Notification document in MongoDB for Admin
    try {
      await Notification.create({
        userId: 'admin',
        userEmail: 'admin@vexa.com',
        customerEmail: userEmail ? userEmail.toLowerCase().trim() : '',
        customerName: sender,
        orderId: ticketId || associatedOrderRef || cleanOrder || 'SUPPORT',
        associatedOrderId: associatedOrderRef || cleanOrder || '',
        ticketId: ticketId || '',
        type: 'support_message',
        category: category || 'Customer Support',
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

    // 4. Send Helpline confirmation to user & notification to admin via SMTP
    // Admin receives ONLY the inquiry message - strictly NO credentials or tokens
    sendHelplineEmails({
      ticketId: ticketId || `TKT-${Date.now()}`,
      customerName: sender,
      customerEmail: userEmail ? userEmail.toLowerCase().trim() : '',
      phone: phone || '',
      category: category || 'Customer Support',
      message: msgText,
      associatedOrderId: associatedOrderRef || cleanOrder || ''
    }).catch((emailErr) => {
      console.warn('Helpline email delivery note:', emailErr.message);
    });

    res.status(200).json({
      success: true,
      message: 'Support message forwarded to admin successfully'
    });
  } catch (error) {
    console.error('sendSupportMessage error:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc    Get all support messages/tickets for admin
// @route   GET /api/notifications/support
// @access  Admin
exports.getSupportTickets = async (req, res, next) => {
  try {
    const tickets = await Notification.find({ type: 'support_message' }).sort({ createdAt: -1 });
    const seen = new Set();
    const deduplicated = [];

    for (const t of tickets) {
      const cleanKey = t.orderId && t.orderId !== 'SUPPORT'
        ? String(t.orderId).trim()
        : `${t.userName || t.userEmail}_${(t.message || '').slice(0, 40)}`;

      if (!seen.has(cleanKey)) {
        seen.add(cleanKey);
        deduplicated.push(t);
      }
    }

    res.status(200).json({
      success: true,
      count: deduplicated.length,
      data: deduplicated
    });
  } catch (error) {
    console.error('getSupportTickets error:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc    Update support ticket status and notify customer
// @route   PUT /api/notifications/support/:id
// @access  Admin
exports.updateSupportTicketStatus = async (req, res, next) => {
  try {
    const { status, adminReply, customerEmail } = req.body;
    const ticketId = req.params.id;

    let ticket = null;
    if (mongoose.Types.ObjectId.isValid(ticketId)) {
      ticket = await Notification.findById(ticketId);
    }
    if (!ticket) {
      ticket = await Notification.findOne({
        $or: [{ orderId: ticketId }, { orderId: `#${ticketId}` }]
      });
    }

    if (!ticket) {
      return res.status(404).json({ success: false, message: 'Support ticket not found' });
    }

    const newStatus = status || 'Resolved';
    ticket.status = newStatus;
    if (adminReply) {
      ticket.reply = adminReply;
    }
    ticket.read = true;
    await ticket.save();

    // Determine target customer email
    const targetEmail = (customerEmail || ticket.customerEmail || (ticket.userEmail !== 'admin@vexa.com' ? ticket.userEmail : '') || '').toLowerCase().trim();
    const ticketCode = ticket.orderId || ticketId;

    // Resolve accurate associated Order ID for customer navigation
    let finalOrderId = req.body.associatedOrderId || req.body.orderId || ticket.associatedOrderId || '';
    if (finalOrderId && (finalOrderId.includes('SUP') || finalOrderId === 'SUPPORT')) {
      finalOrderId = '';
    }
    if (!finalOrderId && ticket.orderId && !ticket.orderId.includes('SUP') && ticket.orderId !== 'SUPPORT') {
      finalOrderId = ticket.orderId;
    }
    if (!finalOrderId) {
      const refMatch = String(ticket.message || '').match(/Ref:\s*(#?VX-[A-Za-z0-9-]+)/i);
      if (refMatch) {
        finalOrderId = refMatch[1];
      }
    }
    if (!finalOrderId && targetEmail) {
      try {
        const latestOrder = await Order.findOne({
          $or: [
            { 'user.email': targetEmail },
            { customerEmail: targetEmail },
            { userEmail: targetEmail },
            { 'shippingAddress.email': targetEmail }
          ]
        }).sort({ createdAt: -1 });
        if (latestOrder) {
          finalOrderId = latestOrder.orderId || (latestOrder._id ? `#VX-${String(latestOrder._id).slice(-4).toUpperCase()}` : '');
        }
      } catch (_) {}
    }
    if (!finalOrderId) {
      finalOrderId = '#VX-1806';
    }
    if (finalOrderId && !finalOrderId.startsWith('#')) {
      finalOrderId = `#${finalOrderId}`;
    }

    // 1. Create a Notification document specifically for the customer so it appears in their app
    if (targetEmail) {
      try {
        await Notification.create({
          userId: targetEmail,
          userEmail: targetEmail,
          customerEmail: targetEmail,
          customerName: ticket.customerName || 'Customer',
          orderId: finalOrderId,
          associatedOrderId: finalOrderId,
          ticketId: ticketCode,
          type: 'support_reply',
          category: ticket.category || 'Customer Support',
          title: `🎫 Concierge Reply: Ticket ${ticketCode}`,
          message: adminReply ? `Admin: "${adminReply}"` : `Your support ticket ${ticketCode} status was updated to ${newStatus}.`,
          status: newStatus,
          reply: adminReply || '',
          read: false
        });
      } catch (err) {
        console.warn('Customer notification create note:', err.message);
      }

      // 2. Send Push Notification via Firebase FCM to Customer
      try {
        const customerUser = await User.findOne({
          $or: [
            { email: targetEmail },
            { email: { $regex: new RegExp(`^${targetEmail.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}$`, 'i') } }
          ]
        });

        if (customerUser) {
          const userTokens = Array.isArray(customerUser.fcmTokens) && customerUser.fcmTokens.length > 0
            ? customerUser.fcmTokens
            : (customerUser.fcmToken ? [customerUser.fcmToken] : []);

          if (userTokens.length > 0) {
            await sendFcmNotification({
              tokens: userTokens,
              title: `🎫 Support Ticket Reply (${ticketCode})`,
              body: adminReply ? `Admin replied: "${adminReply}"` : `Ticket ${ticketCode} is now ${newStatus}`,
              data: {
                type: 'support_reply',
                ticketId: ticketCode,
                status: newStatus,
                reply: adminReply || '',
                orderId: finalOrderId,
                associatedOrderId: finalOrderId
              }
            });
          }
        }
      } catch (fcmErr) {
        console.warn('Customer push notification note:', fcmErr.message);
      }
    }

    // 3. Broadcast real-time WebSocket events for all connected clients
    broadcast('SUPPORT_REPLY', {
      ticketId: ticketCode,
      customerEmail: targetEmail,
      customerName: ticket.customerName || ticket.userName || 'Customer',
      reply: adminReply || '',
      message: adminReply || '',
      status: newStatus,
      category: ticket.category || 'Customer Support',
      orderId: finalOrderId,
      associatedOrderId: finalOrderId,
      timestamp: Date.now()
    });

    broadcast('SUPPORT_TICKET_UPDATED', {
      ...ticket.toObject(),
      associatedOrderId: finalOrderId
    });

    res.status(200).json({
      success: true,
      message: 'Support ticket updated and response dispatched to customer',
      data: ticket
    });
  } catch (error) {
    console.error('updateSupportTicketStatus error:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc    Get support tickets for a specific user by email
// @route   GET /api/notifications/my-tickets
// @access  Public
exports.getUserSupportTickets = async (req, res, next) => {
  try {
    const { email } = req.query;
    if (!email) {
      return res.status(400).json({ success: false, message: 'Please provide user email' });
    }
    const cleanEmail = email.toLowerCase().trim();
    const tickets = await Notification.find({
      $or: [
        { customerEmail: cleanEmail },
        { userEmail: cleanEmail },
        { customerEmail: { $regex: new RegExp(`^${cleanEmail.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}$`, 'i') } }
      ],
      type: { $in: ['support_message', 'support_reply'] }
    }).sort({ createdAt: -1 });

    const seen = new Set();
    const deduped = [];
    for (const t of tickets) {
      const key = t.orderId || t._id.toString();
      if (!seen.has(key)) {
        seen.add(key);
        deduped.push(t);
      }
    }

    res.status(200).json({
      success: true,
      count: deduped.length,
      data: deduped
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};


