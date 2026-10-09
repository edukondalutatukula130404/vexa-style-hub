const express = require('express');
const router = express.Router();
const {
  getUserNotifications,
  markNotificationRead,
  markAllNotificationsRead,
  clearUserNotifications,
  sendSupportMessage
} = require('../controllers/notificationController');

router.get('/', getUserNotifications);
router.post('/support', sendSupportMessage);
router.put('/read-all', markAllNotificationsRead);
router.put('/:id/read', markNotificationRead);
router.delete('/', clearUserNotifications);

module.exports = router;
