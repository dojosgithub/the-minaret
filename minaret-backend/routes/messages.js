const express = require('express');
const router = express.Router();
const Message = require('../models/Message');
const Conversation = require('../models/Conversation');
const auth = require('../middleware/auth');
const User = require('../models/User');

// Get all conversations for the current user
router.get('/', auth, async (req, res) => {
  try {
    const conversations = await Conversation.find({
      participants: req.user.id
    })
    .populate('participants', 'username firstName lastName profileImage')
    .populate({
      path: 'lastMessage',
      select: 'content sender recipient createdAt read',
      populate: {
        path: 'sender',
        select: 'username firstName lastName profileImage'
      }
    })
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
    // First get the conversation to get the participants
    const conversation = await Conversation.findById(req.params.conversationId);
    
    if (!conversation) {
      return res.status(404).json({ message: 'Conversation not found' });
    }

    // Get messages between the participants
    const messages = await Message.find({
      $or: [
        { 
          sender: conversation.participants[0],
          recipient: conversation.participants[1]
        },
        { 
          sender: conversation.participants[1],
          recipient: conversation.participants[0]
        }
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
    const { recipient, content, media, postId } = req.body;
    console.log('Received recipient:', recipient);

    // First check if this is a conversation ID
    let conversation = await Conversation.findById(recipient);
    let recipientUser;

    if (conversation) {
      console.log('Found conversation by ID:', conversation._id);
      // Get the other participant from the conversation
      recipientUser = conversation.participants.find(
        p => p.toString() !== req.user.id.toString()
      );
      console.log('Found recipient from conversation:', recipientUser);
    } else {
      // If not a conversation ID, treat as user ID
      console.log('Treating recipient as user ID');
      recipientUser = await User.findById(recipient);
    }

    if (!recipientUser) {
      console.error('Recipient not found:', recipient);
      return res.status(404).json({ message: 'Recipient not found' });
    }

    // Now find the conversation between the two users
    conversation = await Conversation.findByParticipants(req.user.id, recipientUser);
    console.log('Found conversation between users:', conversation?._id);

    try {
      // Create new message
      const message = new Message({
        sender: req.user.id,
        recipient: recipientUser,
        content,
        media,
        post: postId,
        conversation: conversation?._id
      });

      await message.save();
      console.log('Message saved successfully:', message._id);

      if (!conversation) {
        console.log('Creating new conversation');
        // Create new conversation if one doesn't exist
        conversation = new Conversation({
          participants: [req.user.id, recipientUser],
          lastMessage: message._id,
          lastMessageAt: message.createdAt,
          unreadCount: 1
        });
      } else {
        console.log('Updating existing conversation');
        // Update existing conversation
        conversation.lastMessage = message._id;
        conversation.lastMessageAt = message.createdAt;
        conversation.unreadCount += 1;
      }

      await conversation.save();
      console.log('Conversation saved successfully:', conversation._id);

      // Populate the message with sender and recipient details
      await message.populate([
        { path: 'sender', select: 'username firstName lastName profileImage' },
        { path: 'recipient', select: 'username firstName lastName profileImage' }
      ]);
      
      if (postId) {
        await message.populate('post', 'title body media');
      }

      res.status(201).json(message);
    } catch (error) {
      console.error('Error in message/conversation creation:', error);
      throw error;
    }
  } catch (error) {
    console.error('Error sending message:', error);
    res.status(500).json({ 
      message: 'Server error',
      error: error.message 
    });
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

// Send a post to a user
router.post('/send-post', auth, async (req, res) => {
  try {
    const { recipientId, postId } = req.body;
    
    // Find or create conversation
    let conversation = await Conversation.findOne({
      participants: { $all: [req.user.id, recipientId] }
    });

    if (!conversation) {
      conversation = new Conversation({
        participants: [req.user.id, recipientId],
        lastMessage: null,
        lastMessageAt: new Date(),
        unreadCount: 1
      });
      await conversation.save();
    }

    // Create the message
    const message = new Message({
      sender: req.user.id,
      recipient: recipientId,
      content: `Check out this post: ${req.body.content}`,
      post: postId,
      conversation: conversation._id
    });
    await message.save();

    // Update conversation
    conversation.lastMessage = message._id;
    conversation.lastMessageAt = message.createdAt;
    conversation.unreadCount += 1;
    await conversation.save();

    // Populate the message with sender and post details
    const populatedMessage = await Message.findById(message._id)
      .populate('sender', 'username firstName lastName profilePicture')
      .populate('post', 'title body media');

    res.json(populatedMessage);
  } catch (error) {
    console.error('Error sending post:', error);
    res.status(500).json({ error: 'Failed to send post' });
  }
});

module.exports = router; 