const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  firstName: {
    type: String,
    required: true,
  },
  lastName: {
    type: String,
    required: true,
  },
  username: {
    type: String,
    required: true,
    unique: true,
  },
  password: {
    type: String,
    required: true,
  },
  phoneNumber: {
    type: String,
    required: true,
    unique: true,
  },
  userType: {
    type: String,
    required: true,
    enum: ['Muslim', 'Non-Muslim', 'Scholar', 'Reporter']
  },
  profileImage: {
    type: String,
    default: 'default-profile.png',
  },
  bio: {
    type: String,
    default: '',
  },
  followers: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
  }],
  following: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
  }],
  createdAt: {
    type: Date,
    default: Date.now,
  },
  dateOfBirth: {
    type: Date,
    default: Date.now,
  },
});

module.exports = mongoose.model('User', userSchema); 