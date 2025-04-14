const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const User = require('../models/User');
const Post = require('../models/Post');
const Notification = require('../models/Notification');
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

// Delete a single recent search
router.delete('/recent-searches/:query', auth, async (req, res) => {
  try {
    const { query } = req.params;
    const user = await User.findById(req.user.id);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Remove the specific query from recent searches
    user.recentSearches = user.recentSearches.filter(search => search !== query);
    await user.save();
    console.log('Deleted recent search:', query);
    res.json({ message: 'Recent search deleted' });
  } catch (err) {
    console.error('Error deleting recent search:', err);
    res.status(500).json({ message: 'Server Error', error: err.message });
  }
});

// Get user by ID
router.get('/:userId', auth, async (req, res) => {
  try {
    const user = await User.findById(req.params.userId)
      .select('-password')
      .populate('followers', 'firstName lastName username profileImage')
      .populate('following', 'firstName lastName username profileImage');

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.json(user);
  } catch (err) {
    console.error('Error getting user:', err);
    res.status(500).json({ message: 'Server Error', error: err.message });
  }
});

// Check if current user is following another user
router.get('/is-following/:userId', auth, async (req, res) => {
  try {
    const currentUser = await User.findById(req.user.id);
    const isFollowing = currentUser.following.includes(req.params.userId);
    res.json({ isFollowing });
  } catch (err) {
    console.error('Error checking follow status:', err);
    res.status(500).json({ message: 'Server Error', error: err.message });
  }
});

// Follow a user
router.post('/follow/:userId', auth, async (req, res) => {
  try {
    const userToFollow = await User.findById(req.params.userId);
    if (!userToFollow) {
      return res.status(404).json({ message: 'User not found' });
    }

    const currentUser = await User.findById(req.user.id);
    
    // Check if already following
    if (currentUser.following.includes(req.params.userId)) {
      return res.status(400).json({ message: 'Already following this user' });
    }

    // Add to following and followers
    currentUser.following.push(req.params.userId);
    userToFollow.followers.push(req.user.id);

    await currentUser.save();
    await userToFollow.save();

    // Create notification for the followed user
    const notification = new Notification({
      type: 'follow',
      sender: req.user.id,
      recipient: req.params.userId,
      read: false
    });
    await notification.save();

    res.json({ message: 'Successfully followed user' });
  } catch (err) {
    console.error('Error following user:', err);
    res.status(500).json({ message: 'Server Error', error: err.message });
  }
});

// Unfollow a user
router.post('/unfollow/:userId', auth, async (req, res) => {
  try {
    const userToUnfollow = await User.findById(req.params.userId);
    if (!userToUnfollow) {
      return res.status(404).json({ message: 'User not found' });
    }

    const currentUser = await User.findById(req.user.id);
    
    // Check if not following
    if (!currentUser.following.includes(req.params.userId)) {
      return res.status(400).json({ message: 'Not following this user' });
    }

    // Remove from following and followers
    currentUser.following = currentUser.following.filter(
      id => id.toString() !== req.params.userId
    );
    userToUnfollow.followers = userToUnfollow.followers.filter(
      id => id.toString() !== req.user.id
    );

    await currentUser.save();
    await userToUnfollow.save();

    res.json({ message: 'Successfully unfollowed user' });
  } catch (err) {
    console.error('Error unfollowing user:', err);
    res.status(500).json({ message: 'Server Error', error: err.message });
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

module.exports = router; 