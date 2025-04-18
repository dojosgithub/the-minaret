const Feedback = require('../models/Feedback');

exports.submitFeedback = async (req, res) => {
  try {
    const { name, email, feedback } = req.body;

    // Validate required fields
    if (!name || !email || !feedback) {
      return res.status(400).json({
        success: false,
        message: 'All fields are required'
      });
    }

    // Validate email format
    const emailRegex = /^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid email format'
      });
    }

    // Create new feedback
    const newFeedback = new Feedback({
      name,
      email,
      feedback
    });

    // Save feedback to database
    await newFeedback.save();

    res.status(201).json({
      success: true,
      message: 'Feedback submitted successfully',
      data: newFeedback
    });
  } catch (error) {
    console.error('Error submitting feedback:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to submit feedback',
      error: error.message
    });
  }
}; 