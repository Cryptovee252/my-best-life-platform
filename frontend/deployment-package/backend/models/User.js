const mongoose = require('mongoose');

const UserSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    trim: true,
    minlength: 2,
    maxlength: 50
  },
  username: {
    type: String,
    unique: true,
    required: true,
    trim: true,
    minlength: 3,
    maxlength: 30,
    match: /^[a-zA-Z0-9_]+$/
  },
  email: {
    type: String,
    unique: true,
    required: true,
    trim: true,
    lowercase: true,
    match: /^[^\s@]+@[^\s@]+\.[^\s@]+$/
  },
  password: {
    type: String,
    required: true,
    minlength: 6
  },
  profilePic: {
    type: String,
    default: ''
  },
  dailyCP: {
    type: Number,
    default: 0,
    min: 0
  },
  lifetimeCP: {
    type: Number,
    default: 0,
    min: 0
  },
  daysActive: {
    type: Number,
    default: 1,
    min: 1
  },
  cpByCategory: {
    mind: { type: Number, default: 0, min: 0 },
    body: { type: Number, default: 0, min: 0 },
    soul: { type: Number, default: 0, min: 0 }
  },
  startDate: {
    type: String,
    default: () => new Date().toISOString().slice(0, 10)
  },
  lastActiveDate: {
    type: String,
    default: () => new Date().toISOString().slice(0, 10)
  },
  isOnline: {
    type: Boolean,
    default: false
  },
  lastSeen: {
    type: Date,
    default: Date.now
  },
  createdAt: {
    type: Date,
    default: Date.now
  },
  updatedAt: {
    type: Date,
    default: Date.now
  }
});

// Update the updatedAt field before saving
UserSchema.pre('save', function(next) {
  this.updatedAt = new Date();
  next();
});

// Virtual for full profile URL
UserSchema.virtual('profilePicUrl').get(function() {
  if (this.profilePic && this.profilePic.startsWith('http')) {
    return this.profilePic;
  }
  return this.profilePic || '';
});

// Method to get public profile (without sensitive data)
UserSchema.methods.getPublicProfile = function() {
  const userObject = this.toObject();
  delete userObject.password;
  delete userObject.__v;
  return userObject;
};

module.exports = mongoose.model('User', UserSchema);
