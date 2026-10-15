const express = require('express');
const router = express.Router();
const {
  createOrder,
  getAllOrders,
  getUserOrders,
  updateOrderStatus,
  updateOrderAddress,
  deleteOrder
} = require('../controllers/orderController');

router.post('/', createOrder);
router.get('/', getAllOrders);
router.get('/myorders', getUserOrders);
router.put('/address', updateOrderAddress);
router.put('/:id/address', updateOrderAddress);
router.put('/status', updateOrderStatus);
router.put('/:id/status', updateOrderStatus);
router.delete('/:id', deleteOrder);

module.exports = router;
