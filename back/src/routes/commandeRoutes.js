const express = require('express');
const router = express.Router();
const commandeController = require('../controllers/commandeController');

// Routes
router.get('/table/:tableId/encours', commandeController.getCurrentOrderForTable);
router.post('/', commandeController.submitOrder);
router.put('/:id/payer', commandeController.markOrderAsPaid);
router.get('/:id', commandeController.getOrderWithItems);
router.post('/sauvegarder', commandeController.saveCart);
router.delete('/table/:tableId', commandeController.deleteCurrentOrderForTable);
router.get('/dashboard/stats', commandeController.getDashboardStats);

module.exports = router;