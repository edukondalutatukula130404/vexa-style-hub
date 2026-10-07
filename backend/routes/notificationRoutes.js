const express = require('express');
const router = express.Router();
const {
  getUserNotifications,
  markNotificationRead,
  markAllNotificationsRead,
  clearUserNotifications
} = require('../controllers/notificationController');

router.get('/', getUserNotifications);
router.put('/read-all', markAllNotificationsRead);
router.put('/:id/read', markNotificationRead);
router.delete('/', clearUserNotifications);

module.exports = router;
