const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const User = require('../models/User');
const Post = require('../models/Post');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Ensure uploads directory exists
const uploadDir = 'uploads/profiles';
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

// Configure multer for profile image uploads
const storage = multer.diskStorage({
  destination: function(req, file, cb) {
    cb(null, uploadDir);
  },
  filename: function(req, file, cb) {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, uniqueSuffix + path.extname(file.originalname));
  }
});

const upload = multer({
  storage: storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB limit
  fileFilter: (req, file, cb) => {
    const allowedTypes = ['image/jpeg', 'image/png', 'image/jpg'];
    if (allowedTypes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Invalid file type. Only JPEG, PNG and JPG are allowed.'));
    }
  }
}).single('image'); // Change to single file upload

// Get user profile
router.get('/profile', auth, async (req, res) => {
  try {
    const user = await User.findById(req.user.id)
      .select('-password')
      .populate('followers')
      .populate('following');
    
    // If no profile image is set, use the default
    if (!user.profileImage) {
      user.profileImage = '/uploads/profiles/default_profile.png';
    }
    
    res.json(user);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server Error');
  }
});

// Get user posts
router.get('/posts', auth, async (req, res) => {
  try {
    const posts = await Post.find({ author: req.user.id })
      .populate('author', 'firstName lastName username profileImage')
      .sort({ createdAt: -1 });
    res.json(posts);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server Error');
  }
});

// Get saved posts
router.get('/saved-posts', auth, async (req, res) => {
  try {
    const user = await User.findById(req.user.id).populate({
      path: 'savedPosts',
      populate: {
        path: 'author',
        select: 'firstName lastName username profileImage'
      }
    });
    res.json(user.savedPosts);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server Error');
  }
});

// Get user by id
router.get('/:id', async (req, res) => {
  try {
    const user = await User.findById(req.params.id).select('-password');
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    // If no profile image is set, use the default
    if (!user.profileImage) {
      user.profileImage = '/uploads/profiles/default_profile.png';
    }
    
    res.json(user);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server Error');
  }
});

// Upload profile image with error handling
router.post('/upload-profile-image', auth, (req, res) => {
  upload(req, res, async function(err) {
    if (err instanceof multer.MulterError) {
      return res.status(400).json({ message: `Upload error: ${err.message}` });
    } else if (err) {
      return res.status(400).json({ message: err.message });
    }

    try {
      if (!req.file) {
        return res.status(400).json({ message: 'No file uploaded' });
      }

      const imageUrl = `/uploads/profiles/${req.file.filename}`;
      
      // Update user's profile image in database
      await User.findByIdAndUpdate(req.user.id, { profileImage: imageUrl });

      res.json({ imageUrl });
    } catch (err) {
      console.error(err);
      res.status(500).json({ message: 'Server error' });
    }
  });
});

// Update profile
router.put('/profile', auth, async (req, res) => {
  try {
    const updates = req.body;
    const allowedUpdates = [
      'firstName',
      'lastName',
      'username',
      'bio',
      'phoneNumber',
      'dateOfBirth',
      'profileImage'
    ];

    // Filter out any fields that aren't in allowedUpdates
    const filteredUpdates = Object.keys(updates)
      .filter(key => allowedUpdates.includes(key))
      .reduce((obj, key) => {
        obj[key] = updates[key];
        return obj;
      }, {});

    const user = await User.findByIdAndUpdate(
      req.user.id,
      filteredUpdates,
      { new: true }
    ).select('-password');

    res.json(user);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});

// Get recent searches
router.get('/recent-searches', auth, async (req, res) => {
  try {
    console.log('Getting recent searches for user:', req.user.id);
    
    // Find user and explicitly include recentSearches
    const user = await User.findById(req.user.id);
    
    if (!user) {
      console.log('User not found');
      return res.status(404).json({ message: 'User not found' });
    }

    // Initialize recentSearches if it doesn't exist
    if (!user.recentSearches) {
      console.log('Initializing recentSearches for user');
      user.recentSearches = [];
      await user.save();
    }

    // Ensure recentSearches is an array
    const recentSearches = Array.isArray(user.recentSearches) ? user.recentSearches : [];
    console.log('User data:', {
      id: user._id,
      recentSearches: recentSearches,
      recentSearchesType: typeof user.recentSearches
    });
    
    res.json(recentSearches);
  } catch (err) {
    console.error('Error getting recent searches:', err);
    console.error('Error stack:', err.stack);
    res.status(500).json({ 
      message: 'Server Error',
      error: err.message,
      recentSearches: []
    });
  }
});

// Add recent search
router.post('/recent-searches', auth, async (req, res) => {
  try {
    const { query } = req.body;
    console.log('Adding recent search:', query, 'for user:', req.user.id);

    if (!query) {
      return res.status(400).json({ message: 'Search query is required' });
    }

    const user = await User.findById(req.user.id);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Initialize recentSearches if it doesn't exist
    if (!user.recentSearches) {
      console.log('Initializing recentSearches for user');
      user.recentSearches = [];
    }

    // Remove the query if it already exists
    user.recentSearches = user.recentSearches.filter(search => search !== query);
    
    // Add the query to the beginning
    user.recentSearches.unshift(query);
    
    // Keep only the last 10 searches
    if (user.recentSearches.length > 10) {
      user.recentSearches = user.recentSearches.slice(0, 10);
    }

    await user.save();
    console.log('Updated recent searches:', user.recentSearches);
    res.json(user.recentSearches);
  } catch (err) {
    console.error('Error adding recent search:', err);
    console.error('Error stack:', err.stack);
    res.status(500).json({ message: 'Server Error', error: err.message });
  }
});

// Clear recent searches
router.delete('/recent-searches', auth, async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    user.recentSearches = [];
    await user.save();
    console.log('Cleared recent searches for user');
    res.json({ message: 'Recent searches cleared' });
  } catch (err) {
    console.error('Error clearing recent searches:', err);
    res.status(500).json({ message: 'Server Error', error: err.message });
  }
});

module.exports = router; 