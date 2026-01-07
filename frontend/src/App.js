import React, { useState, useEffect } from 'react';
import axios from 'axios';
import './App.css';

const API_URL = process.env.REACT_APP_API_URL || 'http://localhost:5000/api';

function App() {
  const [posts, setPosts] = useState([]);
  const [email, setEmail] = useState('');
  const [message, setMessage] = useState('');
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    fetchPosts();
  }, []);

  const fetchPosts = async () => {
    try {
      const response = await axios.get(`${API_URL}/posts`);
      setPosts(response.data);
    } catch (error) {
      console.error('Error fetching posts:', error);
    }
  };

  const handleSubscribe = async (e) => {
    e.preventDefault();
    setLoading(true);
    setMessage('');

    try {
      await axios.post(`${API_URL}/subscribe`, { email });
      setMessage('✅ Successfully subscribed!');
      setEmail('');
    } catch (error) {
      setMessage(error.response?.data?.error || '❌ Subscription failed');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="App">
      <header className="header">
        <h1>📰 MailWave</h1>
        <p>Stay updated with our latest posts</p>
      </header>

      <main className="main">
        <section className="subscribe-section">
          <h2>Subscribe to Our Newsletter</h2>
          <form onSubmit={handleSubscribe} className="subscribe-form">
            <input
              type="email"
              placeholder="Enter your email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
              disabled={loading}
            />
            <button type="submit" disabled={loading}>
              {loading ? 'Subscribing...' : 'Subscribe'}
            </button>
          </form>
          {message && <p className="message">{message}</p>}
        </section>

        <section className="posts-section">
          <h2>Latest Posts</h2>
          {posts.length === 0 ? (
            <p className="no-posts">No posts yet. Check back soon!</p>
          ) : (
            <div className="posts-grid">
              {posts.map((post) => (
                <article key={post._id} className="post-card">
                  <h3>{post.title}</h3>
                  <p className="post-content">{post.content}</p>
                  <div className="post-meta">
                    {post.author && <span>By {post.author}</span>}
                    <span>{new Date(post.createdAt).toLocaleDateString()}</span>
                  </div>
                </article>
              ))}
            </div>
          )}
        </section>
      </main>

      <footer className="footer">
        <p>Three-Tier DevOps Application | Frontend + Backend + MongoDB</p>
      </footer>
    </div>
  );
}

export default App;
