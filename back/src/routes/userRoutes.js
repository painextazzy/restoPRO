const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const authMiddleware = require('../middleware/auth'); // ✅ AJOUTEZ CETTE LIGNE

// Routes pour l'utilisateur connecté
router.get('/me', authMiddleware, userController.getCurrentUser);
router.put('/me', authMiddleware, userController.updateCurrentUser);

module.exports = router;