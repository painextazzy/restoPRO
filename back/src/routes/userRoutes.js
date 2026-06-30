const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');

// Routes publiques (sans token)
router.get('/me', userController.getCurrentUser);
router.put('/me', userController.updateCurrentUser); // plus de middleware upload

module.exports = router;