const mongoose = require('mongoose');

const TaskSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  taskId: {
    type: Number,
    required: true
  },
  category: {
    type: String,
    enum: ['mind', 'body', 'soul'],
    required: true
  },
  completedDate: {
    type: String,
    required: true
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

// Compound index to prevent duplicate task completions per day
TaskSchema.index({ userId: 1, taskId: 1, completedDate: 1 }, { unique: true });

module.exports = mongoose.model('Task', TaskSchema); 