const Notification = require('../models/Notification');

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
