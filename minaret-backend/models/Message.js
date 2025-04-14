const mongoose = require('mongoose');
const Schema = mongoose.Schema;

const messageSchema = new Schema({
  sender: { type: Schema.Types.ObjectId, ref: 'User', required: true },
  recipient: { type: Schema.Types.ObjectId, ref: 'User', required: true },
  content: { type: String, required: true },
  read: { type: Boolean, default: false },
  createdAt: { type: Date, default: Date.now },
  media: [{
    type: { type: String, enum: ['image', 'video'] },
    url: String
  }]
}, { timestamps: true });

// Index for faster queries
messageSchema.index({ sender: 1, recipient: 1, createdAt: -1 });

const Message = mongoose.model('Message', messageSchema);

module.exports = Message; 