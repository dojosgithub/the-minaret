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

const upload = multer({
  storage: storage,
  fileFilter: (req, file, cb) => {
    if (file.mimetype.startsWith('image/') || file.mimetype.startsWith('video/')) {
      cb(null, true);
    } else {
      cb(new Error('Invalid file type'));
    }
  }
});

// Create a post with media
router.post('/', auth, upload.array('media', 4), async (req, res) => {
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
    
    res.json(post);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server error');
  }
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