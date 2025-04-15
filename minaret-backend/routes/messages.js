const express = require('express');
const router = express.Router();
const Message = require('../models/Message');
const Conversation = require('../models/Conversation');
const auth = require('../middleware/auth');

// Get all conversations for the current user
router.get('/', auth, async (req, res) => {
  try {
    const conversations = await Conversation.find({
      participants: req.user.id
    })
    .populate('participants', 'username firstName lastName profileImage')
    .populate('lastMessage')
    .sort({ lastMessageAt: -1 });

    res.json(conversations);
  } catch (error) {
    console.error('Error fetching conversations:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Get messages for a specific conversation
router.get('/:conversationId', auth, async (req, res) => {
  try {
    const messages = await Message.find({
      $or: [
        { sender: req.user.id, recipient: req.params.conversationId },
        { sender: req.params.conversationId, recipient: req.user.id }
      ]
    })
    .sort({ createdAt: 1 })
    .populate('sender', 'username firstName lastName profileImage');

    res.json(messages);
  } catch (error) {
    console.error('Error fetching messages:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Send a new message
router.post('/', auth, async (req, res) => {
  try {
    const { recipient, content, media } = req.body;

    // Create new message
    const message = new Message({
      sender: req.user.id,
      recipient,
      content,
      media
    });

    await message.save();

    // Update or create conversation
    let conversation = await Conversation.findOne({
      participants: { $all: [req.user.id, recipient] }
    });

    if (!conversation) {
      conversation = new Conversation({
        participants: [req.user.id, recipient],
        lastMessage: message._id,
        lastMessageAt: message.createdAt,
        unreadCount: 1
      });
    } else {
      conversation.lastMessage = message._id;
      conversation.lastMessageAt = message.createdAt;
      conversation.unreadCount += 1;
    }

    await conversation.save();

    // Populate the message with sender details
    await message.populate('sender', 'username firstName lastName profileImage');

    res.status(201).json(message);
  } catch (error) {
    console.error('Error sending message:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Mark message as read
router.put('/:messageId/read', auth, async (req, res) => {
  try {
    const message = await Message.findById(req.params.messageId);
    
    if (!message) {
      return res.status(404).json({ message: 'Message not found' });
    }

    if (message.recipient.toString() !== req.user.id.toString()) {
      return res.status(403).json({ message: 'Not authorized' });
    }

    message.read = true;
    await message.save();

    // Update conversation unread count
    const conversation = await Conversation.findOne({
      participants: { $all: [message.sender, message.recipient] }
    });

    if (conversation) {
      conversation.unreadCount = Math.max(0, conversation.unreadCount - 1);
      await conversation.save();
    }

    res.json(message);
  } catch (error) {
    console.error('Error marking message as read:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router; 