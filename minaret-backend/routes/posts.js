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

// Search posts and users
router.get('/search', auth, async (req, res) => {
  try {
    const { query, sortBy, datePosted, postedBy } = req.query;
    
    // Build the search query for posts
    let postQuery = {};
    
    // Add text search for posts
    if (query) {
      postQuery.$or = [
        { title: { $regex: query, $options: 'i' } },
        { body: { $regex: query, $options: 'i' } }
      ];
    }

    // Add date filter for posts
    if (datePosted) {
      const now = new Date();
      switch (datePosted) {
        case 'Last 24 Hours':
          postQuery.createdAt = { $gte: new Date(now.getTime() - 24 * 60 * 60 * 1000) };
          break;
        case 'This Week':
          postQuery.createdAt = { $gte: new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000) };
          break;
        case 'This Month':
          postQuery.createdAt = { $gte: new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000) };
          break;
        case '2024':
          postQuery.createdAt = { $gte: new Date('2024-01-01') };
          break;
      }
    }

    // Add posted by filter for posts
    if (postedBy) {
      switch (postedBy) {
        case 'Me':
          postQuery.author = req.user.id;
          break;
        case 'Followings':
          const user = await User.findById(req.user.id);
          postQuery.author = { $in: user.following };
          break;
      }
    }

    // Build sort options for posts
    let sortOptions = { createdAt: -1 }; // Default sort by newest
    if (sortBy) {
      switch (sortBy) {
        case 'Most Relevant':
          break;
        case 'Recent':
          sortOptions = { createdAt: -1 };
          break;
        case 'Date':
          sortOptions = { createdAt: -1 };
          break;
      }
    }

    // Build the search query for users
    let userQuery = {};
    if (query) {
      userQuery.$or = [
        { username: { $regex: query, $options: 'i' } },
        { firstName: { $regex: query, $options: 'i' } },
        { lastName: { $regex: query, $options: 'i' } }
      ];
    }

    // Execute both searches in parallel
    const [posts, users] = await Promise.all([
      Post.find(postQuery)
        .sort(sortOptions)
        .populate('author', 'firstName lastName username profileImage')
        .lean(),
      User.find(userQuery)
        .select('firstName lastName username profileImage')
        .lean()
    ]);

    res.json({ posts, users });
  } catch (err) {
    console.error('Search error:', err);
    res.status(500).json({ message: 'Server error during search' });
  }
});

// Get posts by user ID
router.get('/user/:userId', auth, async (req, res) => {
  try {
    const posts = await Post.find({ author: req.params.userId })
      .sort({ createdAt: -1 })
      .populate('author', 'firstName lastName username profileImage')
      .populate('likes', 'firstName lastName username profileImage');

    res.json(posts);
  } catch (err) {
    console.error('Error getting user posts:', err);
    res.status(500).json({ message: 'Server Error', error: err.message });
  }
});

// Add a comment to a post
router.post('/:postId/comments', auth, async (req, res) => {
  try {
    const post = await Post.findById(req.params.postId);
    if (!post) {
      return res.status(404).json({ message: 'Post not found' });
    }

    const newComment = {
      author: req.user.id,
      text: req.body.text
    };

    post.comments.unshift(newComment);
    await post.save();

    // Populate the new comment with author details
    const populatedPost = await Post.findById(post._id)
      .populate('comments.author', 'username firstName lastName profileImage')
      .populate('comments.replies.author', 'username firstName lastName profileImage');

    res.json(populatedPost.comments[0]);
  } catch (err) {
    console.error('Error adding comment:', err);
    res.status(500).json({ message: 'Server error' });
  }
});

// Add a reply to a comment
router.post('/:postId/comments/:commentId/replies', auth, async (req, res) => {
  try {
    const post = await Post.findById(req.params.postId);
    if (!post) {
      return res.status(404).json({ message: 'Post not found' });
    }

    const comment = post.comments.id(req.params.commentId);
    if (!comment) {
      return res.status(404).json({ message: 'Comment not found' });
    }

    const newReply = {
      author: req.user.id,
      text: req.body.text
    };

    comment.replies.unshift(newReply);
    await post.save();

    const populatedPost = await Post.findById(post._id)
      .populate('comments.replies.author', 'username firstName lastName profileImage');

    res.json(comment.replies[0]);
  } catch (err) {
    console.error('Error adding reply:', err);
    res.status(500).json({ message: 'Server error' });
  }
});

// Get comments for a post
router.get('/:postId/comments', auth, async (req, res) => {
  try {
    const post = await Post.findById(req.params.postId)
      .populate('comments.author', 'username firstName lastName profileImage')
      .populate('comments.replies.author', 'username firstName lastName profileImage')
      .select('comments');

    if (!post) {
      return res.status(404).json({ message: 'Post not found' });
    }

    res.json(post.comments);
  } catch (err) {
    console.error('Error getting comments:', err);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router; 