const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const Post = require('../models/Post');
const multer = require('multer');
const path = require('path');

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
router.get('/', async (req, res) => {
  try {
    const posts = await Post.find()
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

module.exports = router; 