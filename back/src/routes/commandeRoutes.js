// back/src/routes/commandeRoutes.js
const express = require('express');
const router = express.Router();
const commandeController = require('../controllers/commandeController');

// ==========================================
// ROUTES DES COMMANDES
// ==========================================

// Récupérer la commande en cours pour une table
router.get('/table/:tableId/encours', commandeController.getCurrentOrderForTable);

// Soumettre une commande (paiement)
router.post('/', commandeController.submitOrder);

// Récupérer une commande avec ses items
router.get('/:id', commandeController.getOrderWithItems);

// Sauvegarder le panier (sans payer)
router.post('/sauvegarder', commandeController.saveCart);

// Supprimer la commande en cours d'une table
router.delete('/table/:tableId', commandeController.deleteCurrentOrderForTable);

// Statistiques du dashboard
router.get('/dashboard/stats', commandeController.getDashboardStats);

module.exports = router;