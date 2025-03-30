const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const Post = require('../models/Post');

// Create a post
router.post('/', auth, async (req, res) => {
  try {
    const { type, title, body, media, links } = req.body;
    
    const newPost = new Post({
      author: req.user.id,
      type,
      title,
      body,
      media,
      links,
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