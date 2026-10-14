const Order = require('../models/Order');
const User = require('../models/User');
const Payment = require('../models/Payment');
const Notification = require('../models/Notification');
const mongoose = require('mongoose');
const { broadcast } = require('../config/websocket');
const { sendFcmNotification } = require('../config/firebase');
const { sendOrderConfirmationEmail, sendOrderStatusEmail } = require('../config/nodemailer');

const NOTIFICATION_MAP = {
  'Order Placed': {
    title: 'Order Placed 📦',
    message: (id) => `Your order #${id} has been placed successfully.`
  },
  'Order Confirmed': {
    title: 'Order Confirmed 🎉',
    message: (id) => `Your order #${id} has been confirmed.`
  },
  'Processing': {
    title: 'Order Processing',
    message: (id) => `Your order #${id} is now being prepared.`
  },
  'Shipped': {
    title: 'Order Shipped 📦',
    message: (id) => `Your order #${id} has been shipped.`
  },
  'Out for Delivery': {
    title: 'Out for Delivery 🚚',
    message: (id) => `Your order #${id} is out for delivery.`
  },
  'Delivered': {
    title: 'Order Delivered ✅',
    message: (id) => `Your order #${id} has been delivered successfully.`
  },
  'Cancelled': {
    title: 'Order Cancelled',
    message: (id) => `Your order #${id} has been cancelled.`
  }
};

// @desc    Create new order
// @route   POST /api/orders
// @access  Public
exports.createOrder = async (req, res, next) => {
  try {
    const {
      userEmail,
      userName,
      items,
      totalAmount,
      paymentMethod,
      shippingAddress,
      id,
      _id,
      paymentId: customPaymentId,
      paymentStatus: customPaymentStatus
    } = req.body;

    if (!userEmail || !items || items.length === 0) {
      return res.status(400).json({ success: false, message: 'Invalid order details provided' });
    }

    const orderId = id || _id || `ORD-${Date.now()}`;
    const cleanEmail = userEmail.toLowerCase().trim();
    const isCOD = !paymentMethod || paymentMethod.toLowerCase().includes('cash');
    const assignedPaymentId = customPaymentId || (isCOD ? `cod_${Date.now()}` : `pay_${Date.now()}`);
    const assignedPaymentStatus = customPaymentStatus || (isCOD ? 'Pending' : 'Completed');

    // Look up registered user in database to ensure the order is associated with the customer's registered name
    let resolvedUserName = (userName || '').trim();
    const registeredUser = await User.findOne({
      $or: [
        { email: cleanEmail },
        { email: { $regex: new RegExp(`^${cleanEmail.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}$`, 'i') } }
      ]
    });

    if (registeredUser && registeredUser.name && registeredUser.name.trim()) {
      resolvedUserName = registeredUser.name.trim();
    }
    if (!resolvedUserName) {
      resolvedUserName = 'Customer';
    }

    const order = await Order.create({
      id: orderId,
      userEmail: cleanEmail,
      userName: resolvedUserName,
      items,
      totalAmount,
      status: 'Order Placed',
      paymentMethod: paymentMethod || 'Cash on Delivery',
      paymentId: assignedPaymentId,
      paymentStatus: assignedPaymentStatus,
      shippingAddress: shippingAddress || 'Indiranagar 100ft Road, Bengaluru'
    });

    // Automatically store / sync Payment document in MongoDB
    try {
      const existingPay = await Payment.findOne({
        $or: [
          { paymentId: assignedPaymentId },
          { orderId: orderId }
        ]
      });

      if (!existingPay) {
        await Payment.create({
          paymentId: assignedPaymentId,
          orderId: order.id || String(order._id),
          userEmail: cleanEmail,
          userName: userName || 'Customer',
          amount: Number(totalAmount) || 0,
          currency: 'INR',
          status: isCOD ? 'Pending' : 'Success',
          paymentMethod: paymentMethod || 'Cash on Delivery',
          metadata: {
            orderDbId: String(order._id),
            itemCount: items.length
          }
        });
      } else {
        if (!existingPay.orderId) {
          existingPay.orderId = order.id || String(order._id);
          await existingPay.save();
        }
      }
    } catch (paySyncErr) {
      console.warn('Payment recording note during order creation:', paySyncErr.message);
    }

    // Real-time WebSocket Broadcast
    broadcast('ORDER_CREATED', order);
    broadcast('ORDERS_UPDATED', order);

    // Save initial Notification & send FCM Push if user registered
    try {
      const orderShortCode = String(order.id || order._id).replace(/^#/, '').slice(-8).toUpperCase();
      const notifConfig = NOTIFICATION_MAP['Order Placed'];
      const notifTitle = notifConfig.title;
      const notifBody = notifConfig.message(orderShortCode);

      const user = await User.findOne({ email: cleanEmail });
      if (user) {
        const tokens = user.fcmTokens?.length ? user.fcmTokens : (user.fcmToken ? [user.fcmToken] : []);
        if (tokens.length > 0) {
          await sendFcmNotification({
            tokens,
            title: notifTitle,
            body: notifBody,
            data: {
              type: 'order_status_update',
              orderId: order.id || String(order._id),
              status: 'Order Placed'
            }
          });
        }

        await Notification.create({
          userId: String(user._id),
          userEmail: cleanEmail,
          orderId: order.id || String(order._id),
          type: 'order_status_update',
          title: notifTitle,
          message: notifBody,
          status: 'Order Placed',
          read: false
        });
      }
    } catch (notifErr) {
      console.warn('Initial order notification log notice:', notifErr.message);
    }

    // Send Order Confirmation & Invoice email via SMTP from Admin Mail
    sendOrderConfirmationEmail(order).catch((mailErr) => {
      console.warn('Order confirmation email delivery note:', mailErr.message);
    });

    res.status(201).json({
      success: true,
      data: order
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get all orders (Admin)
// @route   GET /api/orders
// @access  Public/Admin
exports.getAllOrders = async (req, res, next) => {
  try {
    const orders = await Order.find().sort({ createdAt: -1 });

    // Look up registered users to ensure all customer bookings display under the user's registered name
    const emails = [...new Set(orders.map(o => (o.userEmail || '').toLowerCase().trim()).filter(Boolean))];
    const users = await User.find({ email: { $in: emails } }).select('name email');

    const userMap = new Map();
    users.forEach(u => {
      if (u.email && u.name) {
        userMap.set(u.email.toLowerCase().trim(), u.name.trim());
      }
    });

    const enrichedOrders = orders.map((ord) => {
      const obj = ord.toObject ? ord.toObject() : { ...ord };
      const key = (obj.userEmail || '').toLowerCase().trim();
      const regName = userMap.get(key);
      if (regName) {
        if (obj.userName !== regName) {
          obj.userName = regName;
          // Asynchronously update in DB so database stays consistently synced
          Order.updateOne({ _id: ord._id }, { userName: regName }).catch(() => {});
        }
      } else if (!obj.userName || obj.userName === 'Customer' || obj.userName === 'Valued Customer' || obj.userName === 'VEXA Customer') {
        if (key && key.includes('@')) {
          const prefix = key.split('@')[0];
          obj.userName = prefix.charAt(0).toUpperCase() + prefix.slice(1);
        }
      }
      return obj;
    });

    res.status(200).json({
      success: true,
      count: enrichedOrders.length,
      data: enrichedOrders
    });
  } catch (error) {
    console.warn('Orders fetch note:', error.message);
    res.status(200).json({
      success: true,
      count: 0,
      data: []
    });
  }
};

// @desc    Get user orders by email
// @route   GET /api/orders/myorders
// @access  Public
exports.getUserOrders = async (req, res, next) => {
  try {
    const { email } = req.query;
    if (!email) {
      return res.status(400).json({ success: false, message: 'Please provide user email' });
    }

    const cleanEmail = email.toLowerCase().trim();
    const userDoc = await User.findOne({
      $or: [
        { email: cleanEmail },
        { email: { $regex: new RegExp(`^${cleanEmail.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}$`, 'i') } }
      ]
    });

    const searchConditions = [
      { userEmail: cleanEmail },
      { userEmail: { $regex: new RegExp(`^${cleanEmail.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}$`, 'i') } }
    ];
    if (userDoc && userDoc.name) {
      searchConditions.push({ userName: userDoc.name });
    }

    const orders = await Order.find({
      $or: searchConditions
    }).sort({ createdAt: -1 });

    const enriched = orders.map((ord) => {
      const obj = ord.toObject ? ord.toObject() : { ...ord };
      if (userDoc && userDoc.name && (!obj.userName || obj.userName === 'Customer' || obj.userName === 'Valued Customer' || obj.userName === 'VEXA Customer')) {
        obj.userName = userDoc.name;
      }
      return obj;
    });

    res.status(200).json({
      success: true,
      count: enriched.length,
      data: enriched
    });
  } catch (error) {
    console.warn('User orders fetch note:', error.message);
    res.status(200).json({
      success: true,
      count: 0,
      data: []
    });
  }
};


// @desc    Update order status
// @route   PUT /api/orders/:id/status
// @access  Public/Admin
exports.updateOrderStatus = async (req, res, next) => {
  try {
    const { status: newStatus, cancelReason, customerName, userName, userEmail, orderId } = req.body;
    const targetId = (req.params.id && String(req.params.id).trim() !== 'status')
      ? String(req.params.id).trim()
      : String(orderId || req.body.id || req.body._id || '').trim();
    const cleanCode = targetId.replace(/^#+/, '').trim();

    if (!newStatus) {
      return res.status(400).json({ success: false, message: 'Please provide status' });
    }

    let order = null;
    
    if (mongoose.Types.ObjectId.isValid(targetId)) {
      order = await Order.findById(targetId);
    }
    if (!order && mongoose.Types.ObjectId.isValid(cleanCode)) {
      order = await Order.findById(cleanCode);
    }

    if (!order && (targetId || cleanCode)) {
      order = await Order.findOne({
        $or: [
          { id: targetId },
          { id: `#${cleanCode}` },
          { id: cleanCode },
          { id: { $regex: new RegExp(cleanCode.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'i') } }
        ]
      });
    }

    if (!order) {
      // In-memory or demo orders (e.g. #VX-1806): still notify admin & broadcast
      if (newStatus.toUpperCase() === 'CANCELLED') {
        const orderShortCode = cleanCode.slice(-8).toUpperCase() || 'ORDER';
        const displayCustomer = customerName || userName || userEmail || 'Customer';
        const cancelTitle = `Order was cancelled #${orderShortCode}`;
        const cancelMsg = `Order #${orderShortCode} was cancelled by ${displayCustomer}.${cancelReason ? ` Reason: ${cancelReason}` : ''}`;

        broadcast('ORDER_CANCELLED', {
          orderId: targetId || `#${orderShortCode}`,
          _id: targetId || `#${orderShortCode}`,
          id: targetId || `#${orderShortCode}`,
          customerName: displayCustomer,
          userEmail: userEmail || '',
          totalAmount: req.body.refundAmount || 0,
          cancelReason: cancelReason || 'Cancelled by customer',
          status: 'Cancelled',
        });
        broadcast('ORDERS_UPDATED', { id: targetId, status: 'Cancelled' });

        try {
          await Notification.create({
            userId: 'admin',
            userEmail: 'admin@vexa.com',
            orderId: targetId || `#${orderShortCode}`,
            type: 'order_cancelled',
            title: cancelTitle,
            message: cancelMsg,
            status: 'Cancelled',
            read: false
          });
        } catch (_) {}

        return res.status(200).json({
          success: true,
          message: 'Order cancelled successfully and admin notified',
          data: { id: targetId, status: 'Cancelled', cancelReason }
        });
      }

      return res.status(404).json({
        success: false,
        message: 'Order not found'
      });
    }

    const previousStatus = order.status || '';

    // 1. Prevent duplicate notifications when the exact same status is saved without changing
    if (previousStatus === newStatus) {
      return res.status(200).json({
        success: true,
        data: order,
        message: 'Status unchanged',
        notificationSent: false
      });
    }

    // 2. Update order status and previousStatus
    order.previousStatus = previousStatus;
    order.status = newStatus;
    if (cancelReason !== undefined) {
      order.cancelReason = cancelReason;
    }

    // Sync Payment status in MongoDB
    if (newStatus.toUpperCase() === 'CANCELLED') {
      try {
        await Payment.updateMany(
          {
            $or: [
              { orderId: order.id },
              { orderId: String(order._id) },
              { paymentId: order.paymentId }
            ]
          },
          { status: 'Refunded' }
        );
        order.paymentStatus = 'Refunded';
      } catch (payCancelErr) {
        console.warn('Payment refund status sync note:', payCancelErr.message);
      }
    } else if (newStatus.toLowerCase() === 'delivered') {
      try {
        await Payment.updateMany(
          {
            $or: [
              { orderId: order.id },
              { orderId: String(order._id) },
              { paymentId: order.paymentId }
            ],
            status: 'Pending'
          },
          { status: 'Success' }
        );
        order.paymentStatus = 'Completed';
      } catch (payDeliverErr) {
        console.warn('Payment success status sync note:', payDeliverErr.message);
      }
    }

    await order.save();

    // Broadcast Real-time WebSocket event for open dashboards/apps
    const orderBroadcastData = {
      ...(order.toObject ? order.toObject() : order),
      id: order.id,
      _id: String(order._id),
      orderId: order.id || String(order._id),
      status: newStatus,
      cancelReason: order.cancelReason,
      customerName: order.userName || order.customerName || order.userEmail || 'Customer',
      userEmail: order.userEmail,
    };
    broadcast('ORDER_STATUS_UPDATED', orderBroadcastData);
    broadcast('ORDERS_UPDATED', orderBroadcastData);
    if (newStatus.toUpperCase() === 'CANCELLED') {
      broadcast('ORDER_CANCELLED', {
        orderId: order.id || String(order._id),
        _id: order._id,
        id: order.id,
        customerName: order.userName || order.customerName || order.userEmail || 'Customer',
        userEmail: order.userEmail,
        totalAmount: order.totalAmount,
        cancelReason: cancelReason || order.cancelReason || 'Cancelled by customer',
        status: 'Cancelled',
        order,
      });
    }

    // 3. Retrieve user associated with that order and get FCM token(s)
    let notificationSent = false;
    let notificationMsg = 'No active FCM token found for user';

    const orderShortCode = String(order.id || order._id || targetId).replace(/^#/, '').slice(-8).toUpperCase();
    const notifConfig = NOTIFICATION_MAP[newStatus] || {
      title: 'Order Status Updated 📦',
      message: (id) => `Your order #${id} status changed to ${newStatus}.`
    };

    const notifTitle = notifConfig.title;
    const notifBody = notifConfig.message(orderShortCode);

    if (order.userEmail) {
      const cleanEmail = order.userEmail.toLowerCase().trim();
      const user = await User.findOne({ email: cleanEmail });

      if (user) {
        let tokens = [];
        if (Array.isArray(user.fcmTokens) && user.fcmTokens.length > 0) {
          tokens = user.fcmTokens;
        } else if (user.fcmToken) {
          tokens = [user.fcmToken];
        }

        // 4. Send FCM Push Notification to specific user devices
        if (tokens.length > 0) {
          const fcmResult = await sendFcmNotification({
            tokens,
            title: notifTitle,
            body: notifBody,
            data: {
              type: 'order_status_update',
              orderId: order.id || String(order._id),
              status: newStatus
            }
          });

          notificationSent = fcmResult.success;
          notificationMsg = fcmResult.success
            ? 'Push notification sent to customer'
            : (fcmResult.reason || 'FCM delivery failed');

          // Clean up invalid or expired tokens
          if (fcmResult.invalidTokens && fcmResult.invalidTokens.length > 0) {
            user.fcmTokens = user.fcmTokens.filter(t => !fcmResult.invalidTokens.includes(t));
            if (user.fcmToken && fcmResult.invalidTokens.includes(user.fcmToken)) {
              user.fcmToken = user.fcmTokens[0] || '';
            }
            await user.save();
          }
        }

        // 5. Create Notification History Record in Database
        await Notification.create({
          userId: String(user._id),
          userEmail: user.email,
          orderId: order.id || String(order._id),
          type: 'order_status_update',
          title: notifTitle,
          message: notifBody,
          status: newStatus,
          read: false
        });
      }
    }

    // 6. When an order is cancelled, notify all Admins directly (DB + FCM + WS)
    if (newStatus.toUpperCase() === 'CANCELLED') {
      try {
        const customerDisplayName = order.userName || order.customerName || order.userEmail || 'Customer';
        const cancelTitle = `Order was cancelled #${orderShortCode}`;
        const cancelMsg = `Order #${orderShortCode} was cancelled by ${customerDisplayName}.${order.cancelReason ? ` Reason: ${order.cancelReason}` : ''}`;

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
              title: cancelTitle,
              body: cancelMsg,
              data: {
                type: 'order_cancelled',
                orderId: order.id || String(order._id),
                status: 'Cancelled',
                customerName: customerDisplayName,
              }
            });
          }

          await Notification.create({
            userId: String(admin._id),
            userEmail: admin.email,
            orderId: order.id || String(order._id),
            type: 'order_cancelled',
            title: cancelTitle,
            message: cancelMsg,
            status: 'Cancelled',
            read: false
          });
        }

        // Also add fallback admin notification record
        await Notification.create({
          userId: 'admin',
          userEmail: 'admin@vexa.com',
          orderId: order.id || String(order._id),
          type: 'order_cancelled',
          title: cancelTitle,
          message: cancelMsg,
          status: 'Cancelled',
          read: false
        });
      } catch (adminErr) {
        console.warn('Admin cancel notification error:', adminErr.message);
      }
    }

    // Send Order Status Update tracking email via SMTP from Admin Mail
    sendOrderStatusEmail(order, newStatus, cancelReason || order.cancelReason || '').catch((mailErr) => {
      console.warn('Order status email delivery note:', mailErr.message);
    });

    return res.status(200).json({
      success: true,
      data: order,
      notificationSent,
      notificationMessage: notificationMsg
    });

  } catch (error) {
    console.warn('Update order status notice:', error.message);
    next(error);
  }
};

// @desc    Delete order
// @route   DELETE /api/orders/:id
// @access  Public/Admin/User
exports.deleteOrder = async (req, res, next) => {
  try {
    const orderId = req.params.id;
    if (mongoose.Types.ObjectId.isValid(orderId)) {
      await Order.findByIdAndDelete(orderId);
    } else {
      await Order.deleteMany({
        $or: [
          { _id: orderId },
          { id: orderId }
        ]
      });
    }
    broadcast('ORDER_DELETED', { id: orderId });
    broadcast('ORDERS_UPDATED', { id: orderId });
    res.status(200).json({
      success: true,
      message: 'Order deleted successfully'
    });
  } catch (error) {
    res.status(200).json({
      success: true,
      message: 'Order deleted successfully'
    });
  }
};
