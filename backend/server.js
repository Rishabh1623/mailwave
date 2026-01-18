require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 5000;
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/newsletter';

// Email validation regex
const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

// Middleware
app.use(cors());
app.use(express.json());

// MongoDB Connection with proper error handling
mongoose.connect(MONGODB_URI)
  .then(() => {
    if (process.env.NODE_ENV !== 'test') {
      console.log('✅ MongoDB connected successfully');
    }
  })
  .catch(err => {
    console.error('❌ MongoDB connection error:', err.message);
    process.exit(1);
  });

// Newsletter Schema
const subscriberSchema = new mongoose.Schema({
  email: {
    type: String,
    required: true,
    unique: true
  },
  subscribedAt: {
    type: Date,
    default: Date.now
  }
});

const Subscriber = mongoose.model('Subscriber', subscriberSchema);

// Blog Post Schema
const postSchema = new mongoose.Schema({
  title: {
    type: String,
    required: true
  },
  content: {
    type: String,
    required: true
  },
  author: String,
  createdAt: {
    type: Date,
    default: Date.now
  }
});

const Post = mongoose.model('Post', postSchema);

// Routes
app.get('/api/health', (req, res) => {
  res.json({ status: 'OK', message: 'Backend is running' });
});

// Subscribe to newsletter
app.post('/api/subscribe', async (req, res) => {
  try {
    const { email } = req.body;
    
    // Validate email format
    if (!email || typeof email !== 'string') {
      return res.status(400).json({ error: 'Email is required' });
    }
    
    if (!EMAIL_REGEX.test(email)) {
      return res.status(400).json({ error: 'Invalid email format' });
    }
    
    const subscriber = new Subscriber({ email: email.toLowerCase().trim() });
    await subscriber.save();
    return res.status(201).json({ message: 'Subscribed successfully', email: subscriber.email });
  } catch (error) {
    console.error('Subscription error:', error.message);
    if (error.code === 11000) {
      return res.status(400).json({ error: 'Email already subscribed' });
    }
    return res.status(500).json({ error: 'Subscription failed' });
  }
});

// Get all subscribers
app.get('/api/subscribers', async (req, res) => {
  try {
    const subscribers = await Subscriber.find().sort({ subscribedAt: -1 });
    return res.json(subscribers);
  } catch (error) {
    console.error('Fetch subscribers error:', error.message);
    return res.status(500).json({ error: 'Failed to fetch subscribers' });
  }
});

// Create blog post
app.post('/api/posts', async (req, res) => {
  try {
    const { title, content, author } = req.body;
    
    // Validate required fields
    if (!title || typeof title !== 'string' || title.trim().length === 0) {
      return res.status(400).json({ error: 'Title is required' });
    }
    
    if (!content || typeof content !== 'string' || content.trim().length === 0) {
      return res.status(400).json({ error: 'Content is required' });
    }
    
    const post = new Post({
      title: title.trim(),
      content: content.trim(),
      author: author ? author.trim() : undefined
    });
    
    await post.save();
    return res.status(201).json(post);
  } catch (error) {
    console.error('Create post error:', error.message);
    return res.status(500).json({ error: 'Failed to create post' });
  }
});

// Get all posts
app.get('/api/posts', async (req, res) => {
  try {
    const posts = await Post.find().sort({ createdAt: -1 });
    return res.json(posts);
  } catch (error) {
    console.error('Fetch posts error:', error.message);
    return res.status(500).json({ error: 'Failed to fetch posts' });
  }
});

// Get single post
app.get('/api/posts/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    // Validate MongoDB ObjectId format
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({ error: 'Invalid post ID format' });
    }
    
    const post = await Post.findById(id);
    if (!post) {
      return res.status(404).json({ error: 'Post not found' });
    }
    return res.json(post);
  } catch (error) {
    console.error('Fetch post error:', error.message);
    return res.status(500).json({ error: 'Failed to fetch post' });
  }
});

// Start server
const server = app.listen(PORT, () => {
  if (process.env.NODE_ENV !== 'test') {
    console.log(`🚀 Server running on port ${PORT}`);
  }
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM signal received: closing HTTP server');
  server.close(() => {
    console.log('HTTP server closed');
    mongoose.connection.close(false, () => {
      console.log('MongoDB connection closed');
      process.exit(0);
    });
  });
});

module.exports = app;
