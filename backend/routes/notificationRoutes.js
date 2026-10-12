const express = require('express');
const router = express.Router();
const {
  getUserNotifications,
  markNotificationRead,
  markAllNotificationsRead,
  clearUserNotifications,
  sendSupportMessage,
  getSupportTickets,
  updateSupportTicketStatus,
  getUserSupportTickets
} = require('../controllers/notificationController');

router.get('/', getUserNotifications);
router.get('/my-tickets', getUserSupportTickets);
router.get('/support', getSupportTickets);
router.post('/support', sendSupportMessage);
router.put('/support/:id', updateSupportTicketStatus);
router.put('/read-all', markAllNotificationsRead);
router.put('/:id/read', markNotificationRead);
router.delete('/', clearUserNotifications);

module.exports = router;
