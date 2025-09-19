const express = require('express');
const jwt = require('jsonwebtoken');
const { Pool } = require('pg');
const cuid = require('cuid');

const router = express.Router();

// Create a direct PostgreSQL connection
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
});

// Middleware to verify JWT token
const authenticateToken = async (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'Access token required' });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'your-secret-key');
    req.user = decoded;
    next();
  } catch (error) {
    return res.status(403).json({ error: 'Invalid token' });
  }
};

// Get all stories (public)
router.get('/', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT s.*, u."name" as author_name, u."profilePic" as author_avatar
      FROM stories s
      JOIN users u ON s."userId" = u.id
      ORDER BY s."createdAt" DESC
    `);
    
    res.json({
      success: true,
      stories: result.rows
    });
  } catch (error) {
    console.error('Error fetching stories:', error);
    res.status(500).json({ 
      error: 'Failed to fetch stories',
      message: error.message 
    });
  }
});

// Get stories by user
router.get('/user/:userId', authenticateToken, async (req, res) => {
  try {
    const { userId } = req.params;
    
    // Check if user is requesting their own stories or if it's a public request
    if (req.user.userId !== userId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    const result = await pool.query(
      'SELECT * FROM stories WHERE "userId" = $1 ORDER BY "createdAt" DESC',
      [userId]
    );
    
    res.json({
      success: true,
      stories: result.rows
    });
  } catch (error) {
    console.error('Error fetching user stories:', error);
    res.status(500).json({ 
      error: 'Failed to fetch user stories',
      message: error.message 
    });
  }
});

// Create a new story
router.post('/', authenticateToken, async (req, res) => {
  try {
    const { title, description, category, caption, imageUrl } = req.body;
    const userId = req.user.userId;

    // Get user info for the story
    const userResult = await pool.query(
      'SELECT "name", "profilePic", "dailyCP" FROM users WHERE id = $1',
      [userId]
    );

    if (userResult.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    const user = userResult.rows[0];
    const now = new Date();

    const storyId = cuid();
    const newStory = await pool.query(
      `INSERT INTO stories (
        "id", "title", "author", "avatarUrl", "cp", "date", "time", 
        "imageUrl", "description", "caption", "category", "userId", 
        "createdAt", "updatedAt"
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)
      RETURNING *`,
      [
        storyId,
        title,
        user.name,
        user.profilePic || '',
        user.dailyCP,
        now.toISOString().slice(0, 10),
        now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
        imageUrl || '',
        description,
        caption || '',
        category || 'mind',
        userId,
        now,
        now
      ]
    );

    res.status(201).json({
      success: true,
      message: 'Story created successfully',
      story: newStory.rows[0]
    });
  } catch (error) {
    console.error('Error creating story:', error);
    res.status(500).json({ 
      error: 'Failed to create story',
      message: error.message 
    });
  }
});

// Update a story
router.put('/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const { title, description, category, caption, imageUrl } = req.body;
    const userId = req.user.userId;

    // Check if story exists and belongs to user
    const existingStory = await pool.query(
      'SELECT * FROM stories WHERE id = $1 AND "userId" = $2',
      [id, userId]
    );

    if (existingStory.rows.length === 0) {
      return res.status(404).json({ error: 'Story not found or access denied' });
    }

    const updatedStory = await pool.query(
      `UPDATE stories SET 
        "title" = $1, "description" = $2, "category" = $3, 
        "caption" = $4, "imageUrl" = $5, "updatedAt" = $6
      WHERE id = $7 AND "userId" = $8
      RETURNING *`,
      [title, description, category, caption, imageUrl, new Date(), id, userId]
    );

    res.json({
      success: true,
      message: 'Story updated successfully',
      story: updatedStory.rows[0]
    });
  } catch (error) {
    console.error('Error updating story:', error);
    res.status(500).json({ 
      error: 'Failed to update story',
      message: error.message 
    });
  }
});

// Delete a story
router.delete('/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.userId;

    // Check if story exists and belongs to user
    const existingStory = await pool.query(
      'SELECT * FROM stories WHERE id = $1 AND "userId" = $2',
      [id, userId]
    );

    if (existingStory.rows.length === 0) {
      return res.status(404).json({ error: 'Story not found or access denied' });
    }

    await pool.query(
      'DELETE FROM stories WHERE id = $1 AND "userId" = $2',
      [id, userId]
    );

    res.json({
      success: true,
      message: 'Story deleted successfully'
    });
  } catch (error) {
    console.error('Error deleting story:', error);
    res.status(500).json({ 
      error: 'Failed to delete story',
      message: error.message 
    });
  }
});

// Toggle like on a story
router.post('/:id/like', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.userId;

    // Get current like status
    const storyResult = await pool.query(
      'SELECT "liked" FROM stories WHERE id = $1',
      [id]
    );

    if (storyResult.rows.length === 0) {
      return res.status(404).json({ error: 'Story not found' });
    }

    const currentLiked = storyResult.rows[0].liked;
    const newLiked = !currentLiked;

    await pool.query(
      'UPDATE stories SET "liked" = $1 WHERE id = $2',
      [newLiked, id]
    );

    res.json({
      success: true,
      message: `Story ${newLiked ? 'liked' : 'unliked'} successfully`,
      liked: newLiked
    });
  } catch (error) {
    console.error('Error toggling story like:', error);
    res.status(500).json({ 
      error: 'Failed to toggle story like',
      message: error.message 
    });
  }
});

// Get comments for a story
router.get('/:id/comments', async (req, res) => {
  try {
    const { id } = req.params;
    
    const result = await pool.query(`
      SELECT c.*, u."name" as author_name, u."profilePic" as author_avatar
      FROM comments c
      JOIN users u ON c."userId" = u.id
      WHERE c."storyId" = $1
      ORDER BY c."createdAt" ASC
    `, [id]);
    
    res.json({
      success: true,
      comments: result.rows
    });
  } catch (error) {
    console.error('Error fetching comments:', error);
    res.status(500).json({ 
      error: 'Failed to fetch comments',
      message: error.message 
    });
  }
});

// Add comment to a story
router.post('/:id/comments', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const { content } = req.body;
    const userId = req.user.userId;

    if (!content || !content.trim()) {
      return res.status(400).json({ error: 'Comment content is required' });
    }

    // Get user info
    const userResult = await pool.query(
      'SELECT "name", "profilePic" FROM users WHERE id = $1',
      [userId]
    );

    if (userResult.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    const user = userResult.rows[0];
    const commentId = cuid();

    // Create comment
    const newComment = await pool.query(
      `INSERT INTO comments (
        "id", "content", "author", "avatarUrl", "storyId", "userId", 
        "createdAt", "updatedAt"
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
      RETURNING *`,
      [
        commentId,
        content.trim(),
        user.name,
        user.profilePic || '',
        id,
        userId,
        new Date(),
        new Date()
      ]
    );

    // Update story comment count
    await pool.query(
      'UPDATE stories SET "commentsCount" = "commentsCount" + 1 WHERE id = $1',
      [id]
    );

    res.status(201).json({
      success: true,
      message: 'Comment added successfully',
      comment: newComment.rows[0]
    });
  } catch (error) {
    console.error('Error adding comment:', error);
    res.status(500).json({ 
      error: 'Failed to add comment',
      message: error.message 
    });
  }
});

// Delete comment
router.delete('/:storyId/comments/:commentId', authenticateToken, async (req, res) => {
  try {
    const { storyId, commentId } = req.params;
    const userId = req.user.userId;

    // Check if comment exists and belongs to user
    const commentResult = await pool.query(
      'SELECT * FROM comments WHERE id = $1 AND "storyId" = $2 AND "userId" = $3',
      [commentId, storyId, userId]
    );

    if (commentResult.rows.length === 0) {
      return res.status(404).json({ error: 'Comment not found or access denied' });
    }

    // Delete comment
    await pool.query(
      'DELETE FROM comments WHERE id = $1',
      [commentId]
    );

    // Update story comment count
    await pool.query(
      'UPDATE stories SET "commentsCount" = "commentsCount" - 1 WHERE id = $1',
      [storyId]
    );

    res.json({
      success: true,
      message: 'Comment deleted successfully'
    });
  } catch (error) {
    console.error('Error deleting comment:', error);
    res.status(500).json({ 
      error: 'Failed to delete comment',
      message: error.message 
    });
  }
});

module.exports = router;
