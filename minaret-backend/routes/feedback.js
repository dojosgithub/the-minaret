const express = require('express');
const router = express.Router();
const feedbackController = require('../controllers/feedbackController');
const auth = require('../middleware/auth');

// Submit feedback
router.post('/', auth, feedbackController.submitFeedback);

module.exports = router; 