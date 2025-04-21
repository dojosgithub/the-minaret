const mongoose = require('mongoose');
const Schema = mongoose.Schema;

const conversationSchema = new Schema({
  participants: [{ 
    type: Schema.Types.ObjectId, 
    ref: 'User',
    required: true,
    validate: {
      validator: function(v) {
        return mongoose.Types.ObjectId.isValid(v);
      },
      message: props => `${props.value} is not a valid user ID!`
    }
  }],
  lastMessage: { 
    type: Schema.Types.ObjectId, 
    ref: 'Message' 
  },
  lastMessageAt: { 
    type: Date, 
    default: Date.now 
  },
  unreadCount: { 
    type: Number, 
    default: 0 
  }
}, { 
  timestamps: true 
});

// Index for faster queries
conversationSchema.index({ participants: 1, lastMessageAt: -1 });

// Ensure participants are unique and ordered consistently
conversationSchema.pre('save', function(next) {
  if (this.participants.length !== 2) {
    console.error('Invalid number of participants:', this.participants.length);
    return next(new Error('Conversation must have exactly 2 participants'));
  }
  
  // Sort participants to ensure consistent order
  this.participants.sort((a, b) => a.toString().localeCompare(b.toString()));
  
  // Check for duplicate participants
  if (this.participants[0].toString() === this.participants[1].toString()) {
    console.error('Duplicate participants:', this.participants);
    return next(new Error('Cannot create conversation with the same participant'));
  }
  
  next();
});

// Static method to find conversation between two users
conversationSchema.statics.findByParticipants = async function(userId1, userId2) {
  console.log('Searching for conversation between:', userId1, 'and', userId2);
  
  // Ensure both IDs are valid ObjectIds
  if (!mongoose.Types.ObjectId.isValid(userId1) || !mongoose.Types.ObjectId.isValid(userId2)) {
    console.error('Invalid user IDs:', userId1, userId2);
    return null;
  }

  try {
    const conversation = await this.findOne({
      participants: { 
        $size: 2,
        $all: [userId1, userId2]
      }
    }).populate('participants', 'username firstName lastName profileImage');

    console.log('Conversation search result:', conversation?._id);
    return conversation;
  } catch (error) {
    console.error('Error finding conversation:', error);
    throw error;
  }
};

const Conversation = mongoose.model('Conversation', conversationSchema);

module.exports = Conversation; 