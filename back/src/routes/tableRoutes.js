// back/src/routes/tableRoutes.js
const express = require('express');
const router = express.Router();
const tableController = require('../controllers/tableController');

// Routes CRUD
router.get('/', tableController.getTables);
router.get('/:id', tableController.getTableById);
router.post('/', tableController.createTable);
router.put('/:id', tableController.updateTable);
router.delete('/:id', tableController.deleteTable);

// Routes de gestion de statut
router.put('/:id/status', tableController.updateTableStatus);
router.put('/:id/occuper', tableController.markTableAsOccupied);
router.put('/:id/liberer', tableController.markTableAsFree);

module.exports = router;