require('dotenv').config();
const mongoose = require('mongoose');
const fs = require('fs');
const path = require('path');

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/newsletter';

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

async function seedDatabase() {
  try {
    // Connect to MongoDB
    await mongoose.connect(MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    // Clear existing posts
    await Post.deleteMany({});
    console.log('🗑️  Cleared existing posts');

    // Read sample data
    const sampleData = JSON.parse(
      fs.readFileSync(path.join(__dirname, '../data/sample_posts.json'), 'utf-8')
    );

    // Insert sample posts
    const posts = await Post.insertMany(sampleData);
    console.log(`✅ Inserted ${posts.length} sample posts`);

    // Display inserted posts
    console.log('\n📝 Sample Posts:');
    posts.forEach((post, index) => {
      console.log(`${index + 1}. ${post.title} by ${post.author}`);
    });

    console.log('\n🎉 Database seeded successfully!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error seeding database:', error);
    process.exit(1);
  }
}

seedDatabase();
