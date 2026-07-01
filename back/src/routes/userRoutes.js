const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');

// Routes publiques (sans token)
router.get('/users/me', authMiddleware, userController.getCurrentUser);
router.put('/users/me', authMiddleware, userController.updateCurrentUser);

module.exports = router;