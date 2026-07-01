const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');

// Routes publiques (sans token)
router.get('/me', authMiddleware, userController.getCurrentUser);
router.put('/me', authMiddleware, userController.updateCurrentUser);

module.exports = router;