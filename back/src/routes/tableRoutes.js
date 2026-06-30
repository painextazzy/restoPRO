const express = require('express');
const router = express.Router();
const tableController = require('../controllers/tableController');

router.get('/', tableController.getTables);
router.get('/:id', tableController.getTableById);
router.post('/', tableController.createTable);
router.put('/:id', tableController.updateTable);
router.put('/:id/status', tableController.updateTableStatus);
router.delete('/:id', tableController.deleteTable);

module.exports = router;