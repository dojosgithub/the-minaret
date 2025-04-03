const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const Post = require('../models/Post');
const multer = require('multer');
const path = require('path');
const User = require('../models/User');

// Configure multer for media uploads
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, 'uploads/')
  },
  filename: function (req, file, cb) {
    cb(null, Date.now() + path.extname(file.originalname))
  }
});

const fileFilter = (req, file, cb) => {
  // Accept images and videos
  if (file.mimetype.startsWith('image/') || file.mimetype.startsWith('video/')) {
    cb(null, true);
  } else {
    // Reject file
    cb(null, false);
    cb(new Error('Only images and videos are allowed'));
  }
};

const upload = multer({
  storage: storage,
  fileFilter: fileFilter,
  limits: {
    fileSize: 10 * 1024 * 1024 // 10MB limit
  }
}).array('media', 4);

// Create a post with media
router.post('/', auth, (req, res) => {
  upload(req, res, async function(err) {
    if (err instanceof multer.MulterError) {
      // A Multer error occurred when uploading
      console.error('Multer error:', err);
      return res.status(400).json({ message: `Upload error: ${err.message}` });
    } else if (err) {
      // An unknown error occurred
      console.error('Unknown error:', err);
      return res.status(400).json({ message: err.message });
    }

    try {
      const { type, title, body, links } = req.body;
      
      const media = req.files ? req.files.map(file => ({
        type: file.mimetype.startsWith('image/') ? 'image' : 'video',
        url: `${req.protocol}://${req.get('host')}/uploads/${file.filename}`
      })) : [];

      const parsedLinks = links ? JSON.parse(links) : [];

      const newPost = new Post({
        author: req.user.id,
        type,
        title,
        body,
        media,
        links: parsedLinks,
      });

      const post = await newPost.save();
      await post.populate('author', 'username profileImage');
      
      res.status(201).json(post);
    } catch (err) {
      console.error('Post creation error:', err);
      res.status(500).json({ message: 'Error creating post' });
    }
  });
});

// Get all posts
router.get('/', auth, async (req, res) => {
  try {
    // Get posts from all users except the current user
    const posts = await Post.find({ author: { $ne: req.user.id } })
      .sort({ createdAt: -1 })
      .populate('author', 'firstName lastName username profileImage');
    res.json(posts);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server error');
  }
});

// Get posts by type
router.get('/type/:type', async (req, res) => {
  try {
    const posts = await Post.find({ type: req.params.type })
      .sort({ createdAt: -1 })
      .populate('author', 'username profileImage');
    res.json(posts);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server error');
  }
});

// Save post
router.post('/:id/save', auth, async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    const post = await Post.findById(req.params.id);

    if (!post) {
      return res.status(404).json({ message: 'Post not found' });
    }

    // Check if post is already saved
    if (user.savedPosts.includes(post._id)) {
      return res.status(400).json({ message: 'Post already saved' });
    }

    // Add post to saved posts
    user.savedPosts.push(post._id);
    await user.save();

    res.json({ message: 'Post saved successfully' });
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server error');
  }
});

// Unsave post
router.delete('/:id/save', auth, async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    const post = await Post.findById(req.params.id);

    if (!post) {
      return res.status(404).json({ message: 'Post not found' });
    }

    // Remove post from saved posts
    user.savedPosts = user.savedPosts.filter(
      (postId) => postId.toString() !== post._id.toString()
    );
    await user.save();

    res.json({ message: 'Post unsaved successfully' });
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server error');
  }
});

// Check if post is saved
router.get('/:id/save', auth, async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    const isSaved = user.savedPosts.includes(req.params.id);
    res.json({ isSaved });
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server error');
  }
});

// Search posts
router.get('/search', auth, async (req, res) => {
  try {
    const { query, sortBy, datePosted, postedBy } = req.query;
    
    // Build the search query
    let searchQuery = {};
    
    // Add text search
    if (query) {
      searchQuery.$or = [
        { title: { $regex: query, $options: 'i' } },
        { body: { $regex: query, $options: 'i' } }
      ];
    }

    // Add date filter
    if (datePosted) {
      const now = new Date();
      switch (datePosted) {
        case 'Last 24 Hours':
          searchQuery.createdAt = { $gte: new Date(now.getTime() - 24 * 60 * 60 * 1000) };
          break;
        case 'This Week':
          searchQuery.createdAt = { $gte: new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000) };
          break;
        case 'This Month':
          searchQuery.createdAt = { $gte: new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000) };
          break;
        case '2024':
          searchQuery.createdAt = { $gte: new Date('2024-01-01') };
          break;
      }
    }

    // Add posted by filter
    if (postedBy) {
      switch (postedBy) {
        case 'Me':
          searchQuery.author = req.user.id;
          break;
        case 'Followings':
          const user = await User.findById(req.user.id);
          searchQuery.author = { $in: user.following };
          break;
        // 'Anyone' doesn't need any additional filter
      }
    }

    // Build sort options
    let sortOptions = { createdAt: -1 }; // Default sort by newest
    if (sortBy) {
      switch (sortBy) {
        case 'Most Relevant':
          // For text search, MongoDB's text score is already considered
          break;
        case 'Recent':
          sortOptions = { createdAt: -1 };
          break;
        case 'Date':
          sortOptions = { createdAt: -1 };
          break;
      }
    }

    // Execute the search
    const posts = await Post.find(searchQuery)
      .sort(sortOptions)
      .populate('author', 'firstName lastName username profileImage')
      .lean();

    res.json(posts);
  } catch (err) {
    console.error('Search error:', err);
    res.status(500).json({ message: 'Server error during search' });
  }
});

module.exports = router; 