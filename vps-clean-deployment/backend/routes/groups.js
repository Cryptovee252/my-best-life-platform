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

// Helper function to check if user is group admin
const isGroupAdmin = async (groupId, userId) => {
  try {
    const result = await pool.query(
      'SELECT role FROM group_members WHERE "groupId" = $1 AND "userId" = $2',
      [groupId, userId]
    );
    return result.rows.length > 0 && result.rows[0].role === 'admin';
  } catch (error) {
    console.error('Error checking admin status:', error);
    return false;
  }
};

// Helper function to check if user is group member
const isGroupMember = async (groupId, userId) => {
  try {
    const result = await pool.query(
      'SELECT * FROM group_members WHERE "groupId" = $1 AND "userId" = $2',
      [groupId, userId]
    );
    return result.rows.length > 0;
  } catch (error) {
    console.error('Error checking membership:', error);
    return false;
  }
};

// ===== GROUP MANAGEMENT =====

// GET /api/groups - Get all public groups
router.get('/', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT g.*, 
             COUNT(gm."userId") as memberCount,
             u.name as creatorName
      FROM groups g
      LEFT JOIN group_members gm ON g.id = gm."groupId"
      LEFT JOIN users u ON g."createdBy" = u.id
      WHERE g."isPrivate" = false
      GROUP BY g.id, u.name
      ORDER BY g."createdAt" DESC
    `);
    
    res.json(result.rows);
  } catch (error) {
    console.error('Error fetching groups:', error);
    res.status(500).json({ error: 'Failed to fetch groups' });
  }
});

// GET /api/groups/my - Get user's groups (authenticated)
router.get('/my', authenticateToken, async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT g.*, 
             gm.role as "isAdmin",
             gm."joinedAt",
             COUNT(gm2."userId") as memberCount
      FROM groups g
      INNER JOIN group_members gm ON g.id = gm."groupId"
      LEFT JOIN group_members gm2 ON g.id = gm2."groupId"
      WHERE gm."userId" = $1
      GROUP BY g.id, gm.role, gm."joinedAt"
      ORDER BY g."createdAt" DESC
    `, [req.user.userId]);
    
    res.json(result.rows);
  } catch (error) {
    console.error('Error fetching user groups:', error);
    res.status(500).json({ error: 'Failed to fetch user groups' });
  }
});

// GET /api/groups/:id - Get group by ID
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const result = await pool.query(`
      SELECT g.*, 
             COUNT(gm."userId") as memberCount,
             u.name as creatorName
      FROM groups g
      LEFT JOIN group_members gm ON g.id = gm."groupId"
      LEFT JOIN users u ON g."createdBy" = u.id
      WHERE g.id = $1
      GROUP BY g.id, u.name
    `, [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Group not found' });
    }
    
    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error fetching group:', error);
    res.status(500).json({ error: 'Failed to fetch group' });
  }
});

// POST /api/groups - Create new group (authenticated)
router.post('/', authenticateToken, async (req, res) => {
  try {
    const { name, description, isPrivate = false, maxMembers = 50, category = 'mixed' } = req.body;
    
    if (!name || !description) {
      return res.status(400).json({ error: 'Name and description are required' });
    }
    
    const groupId = cuid();
    
    // Create group
    const result = await pool.query(`
      INSERT INTO groups (id, name, description, category, "isPrivate", "maxMembers", "createdBy", "createdAt", "updatedAt")
      VALUES ($1, $2, $3, $4, $5, $6, $7, NOW(), NOW())
      RETURNING *
    `, [groupId, name, description, category, isPrivate, maxMembers, req.user.userId]);
    
    // Add creator as admin member
    await pool.query(`
      INSERT INTO group_members (id, "groupId", "userId", role, "joinedAt")
      VALUES ($1, $2, $3, $4, NOW())
    `, [cuid(), groupId, req.user.userId, 'admin']);
    
    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('Error creating group:', error);
    res.status(500).json({ error: 'Failed to create group' });
  }
});

// POST /api/groups/:id/join - Join group (authenticated)
router.post('/:id/join', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    
    // Check if group exists
    const groupResult = await pool.query(
      'SELECT * FROM groups WHERE id = $1',
      [id]
    );
    
    if (groupResult.rows.length === 0) {
      return res.status(404).json({ error: 'Group not found' });
    }
    
    const group = groupResult.rows[0];
    
    // Check if already a member
    const existingMember = await pool.query(
      'SELECT * FROM group_members WHERE "groupId" = $1 AND "userId" = $2',
      [id, req.user.userId]
    );
    
    if (existingMember.rows.length > 0) {
      return res.status(400).json({ error: 'Already a member of this group' });
    }
    
    // Check if group is full
    const memberCount = await pool.query(
      'SELECT COUNT(*) FROM group_members WHERE "groupId" = $1',
      [id]
    );
    
    if (parseInt(memberCount.rows[0].count) >= group.maxMembers) {
      return res.status(400).json({ error: 'Group is full' });
    }
    
    // Add member
    await pool.query(`
      INSERT INTO group_members (id, "groupId", "userId", role, "joinedAt")
      VALUES ($1, $2, $3, $4, NOW())
    `, [cuid(), id, req.user.userId, 'member']);
    
    res.json({ message: 'Successfully joined group' });
  } catch (error) {
    console.error('Error joining group:', error);
    res.status(500).json({ error: 'Failed to join group' });
  }
});

// POST /api/groups/:id/leave - Leave group (authenticated)
router.post('/:id/leave', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    
    // Check if user is a member
    const memberResult = await pool.query(
      'SELECT * FROM group_members WHERE "groupId" = $1 AND "userId" = $2',
      [id, req.user.userId]
    );
    
    if (memberResult.rows.length === 0) {
      return res.status(400).json({ error: 'Not a member of this group' });
    }
    
    const member = memberResult.rows[0];
    
    // Check if user is the creator (cannot leave, must delete group)
    const groupResult = await pool.query(
      'SELECT "createdBy" FROM groups WHERE id = $1',
      [id]
    );
    
    if (groupResult.rows[0].createdBy === req.user.userId) {
      return res.status(400).json({ error: 'Group creator cannot leave. Delete the group instead.' });
    }
    
    // Remove member
    await pool.query(
      'DELETE FROM group_members WHERE "groupId" = $1 AND "userId" = $2',
      [id, req.user.userId]
    );
    
    res.json({ message: 'Successfully left group' });
  } catch (error) {
    console.error('Error leaving group:', error);
    res.status(500).json({ error: 'Failed to leave group' });
  }
});

// DELETE /api/groups/:id - Delete group (admin only)
router.delete('/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    
    // Check if user is admin
    const isAdmin = await isGroupAdmin(id, req.user.userId);
    if (!isAdmin) {
      return res.status(403).json({ error: 'Admin access required' });
    }
    
    // Delete group (cascade will handle related records)
    await pool.query('DELETE FROM groups WHERE id = $1', [id]);
    
    res.json({ message: 'Group deleted successfully' });
  } catch (error) {
    console.error('Error deleting group:', error);
    res.status(500).json({ error: 'Failed to delete group' });
  }
});

// ===== GROUP STORIES =====

// GET /api/groups/:id/stories - Get group stories
router.get('/:id/stories', async (req, res) => {
  try {
    const { id } = req.params;
    
    const result = await pool.query(`
      SELECT gs.*, u.name as authorName, u.username as authorUsername,
             COUNT(gsl."userId") as likesCount,
             COUNT(gsc.id) as commentsCount
      FROM group_stories gs
      LEFT JOIN users u ON gs."userId" = u.id
      LEFT JOIN group_story_likes gsl ON gs.id = gsl."storyId"
      LEFT JOIN group_story_comments gsc ON gs.id = gsc."storyId"
      WHERE gs."groupId" = $1
      GROUP BY gs.id, u.name, u.username
      ORDER BY gs."createdAt" DESC
    `, [id]);
    
    res.json(result.rows);
  } catch (error) {
    console.error('Error fetching group stories:', error);
    res.status(500).json({ error: 'Failed to fetch group stories' });
  }
});

// POST /api/groups/:id/stories - Create group story (group member only)
router.post('/:id/stories', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const { title, content, category } = req.body;
    
    // Check if user is a group member
    const isMember = await isGroupMember(id, req.user.userId);
    if (!isMember) {
      return res.status(403).json({ error: 'Must be a group member to post stories' });
    }
    
    if (!title || !content || !category) {
      return res.status(400).json({ error: 'Title, content, and category are required' });
    }
    
    const storyId = cuid();
    const result = await pool.query(`
      INSERT INTO group_stories (id, title, description, category, "groupId", "userId", "createdAt", "updatedAt")
      VALUES ($1, $2, $3, $4, $5, $6, NOW(), NOW())
      RETURNING *
    `, [storyId, title, content, category, id, req.user.userId]);
    
    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('Error creating group story:', error);
    res.status(500).json({ error: 'Failed to create group story' });
  }
});

// ===== GROUP MESSAGES =====

// GET /api/groups/:id/messages - Get group messages
router.get('/:id/messages', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    
    // Check if user is a group member
    const isMember = await isGroupMember(id, req.user.userId);
    if (!isMember) {
      return res.status(403).json({ error: 'Must be a group member to view messages' });
    }
    
    const result = await pool.query(`
      SELECT gm.*, u.name as senderName, u.username as senderUsername, u."profilePic" as senderPic,
             COUNT(gmr.id) as reactionsCount
      FROM group_messages gm
      LEFT JOIN users u ON gm."userId" = u.id
      LEFT JOIN group_message_reactions gmr ON gm.id = gmr."messageId"
      WHERE gm."groupId" = $1
      GROUP BY gm.id, u.name, u.username, u."profilePic"
      ORDER BY gm."createdAt" ASC
    `, [id]);
    
    res.json(result.rows);
  } catch (error) {
    console.error('Error fetching group messages:', error);
    res.status(500).json({ error: 'Failed to fetch group messages' });
  }
});

// POST /api/groups/:id/messages - Send group message (group member only)
router.post('/:id/messages', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const { content } = req.body;
    
    if (!content || content.trim().length === 0) {
      return res.status(400).json({ error: 'Message content is required' });
    }
    
    // Check if user is a group member
    const isMember = await isGroupMember(id, req.user.userId);
    if (!isMember) {
      return res.status(403).json({ error: 'Must be a group member to send messages' });
    }
    
    const messageId = cuid();
    const result = await pool.query(`
      INSERT INTO group_messages (id, content, author, "groupId", "userId", "createdAt", "updatedAt")
      VALUES ($1, $2, $3, $4, $5, NOW(), NOW())
      RETURNING *
    `, [messageId, content.trim(), req.user.userId, id, req.user.userId]);
    
    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('Error sending group message:', error);
    res.status(500).json({ error: 'Failed to send message' });
  }
});

// ===== GROUP TASKS =====

// GET /api/groups/:id/tasks - Get group tasks
router.get('/:id/tasks', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    
    // Check if user is a group member
    const isMember = await isGroupMember(id, req.user.userId);
    if (!isMember) {
      return res.status(403).json({ error: 'Must be a group member to view tasks' });
    }
    
    const result = await pool.query(`
      SELECT gt.*, u.name as assigneeName, u.username as assigneeUsername
      FROM group_tasks gt
      LEFT JOIN users u ON gt."assignedTo" = u.id
      WHERE gt."groupId" = $1
      ORDER BY gt."dueDate" ASC, gt."createdAt" DESC
    `, [id]);
    
    res.json(result.rows);
  } catch (error) {
    console.error('Error fetching group tasks:', error);
    res.status(500).json({ error: 'Failed to fetch group tasks' });
  }
});

// POST /api/groups/:id/tasks - Create group task (group member only)
router.post('/:id/tasks', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const { title, description, category, points, dueDate, assigneeId } = req.body;
    
    if (!title || !description || !category) {
      return res.status(400).json({ error: 'Title, description, and category are required' });
    }
    
    // Check if user is a group member
    const isMember = await isGroupMember(id, req.user.userId);
    if (!isMember) {
      return res.status(403).json({ error: 'Must be a group member to create tasks' });
    }
    
    const taskId = cuid();
    const result = await pool.query(`
      INSERT INTO group_tasks (id, title, description, category, priority, "dueDate", "groupId", "createdBy", "assignedTo", "createdAt", "updatedAt")
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, NOW(), NOW())
      RETURNING *
    `, [taskId, title, description, category, 'medium', dueDate || null, id, req.user.userId, assigneeId || null]);
    
    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('Error creating group task:', error);
    res.status(500).json({ error: 'Failed to create group task' });
  }
});

// ===== GROUP CP (COMMITMENT POINTS) =====

// GET /api/groups/:id/cp - Get group CP summary
router.get('/:id/cp', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    
    // Check if user is a group member
    const isMember = await isGroupMember(id, req.user.userId);
    if (!isMember) {
      return res.status(403).json({ error: 'Must be a group member to view CP' });
    }
    
    const result = await pool.query(`
      SELECT 
        SUM("groupCP") as totalGroupCP,
        SUM("dailyCP") as totalDailyCP,
        SUM("weeklyCP") as totalWeeklyCP,
        SUM("monthlyCP") as totalMonthlyCP,
        COUNT(*) as activeMembers
      FROM group_members 
      WHERE "groupId" = $1 AND "isActive" = true
    `, [id]);
    
    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error fetching group CP:', error);
    res.status(500).json({ error: 'Failed to fetch group CP' });
  }
});

// ===== GROUP ADMIN CONTROLS =====

// GET /api/groups/:id/members - Get group members (admin only)
router.get('/:id/members', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    
    // Check if user is admin
    const isAdmin = await isGroupAdmin(id, req.user.userId);
    if (!isAdmin) {
      return res.status(403).json({ error: 'Admin access required' });
    }
    
    const result = await pool.query(`
      SELECT gm.*, u.name, u.username, u."profilePic", u.email
      FROM group_members gm
      JOIN users u ON gm."userId" = u.id
      WHERE gm."groupId" = $1
      ORDER BY gm.role DESC, gm."joinedAt" ASC
    `, [id]);
    
    res.json(result.rows);
  } catch (error) {
    console.error('Error fetching group members:', error);
    res.status(500).json({ error: 'Failed to fetch group members' });
  }
});

// PUT /api/groups/:id/members/:userId/role - Update member role (admin only)
router.put('/:id/members/:userId/role', authenticateToken, async (req, res) => {
  try {
    const { id, userId } = req.params;
    const { role } = req.body;
    
    if (!['admin', 'member'].includes(role)) {
      return res.status(400).json({ error: 'Invalid role. Must be admin or member' });
    }
    
    // Check if user is admin
    const isGroupAdminUser = await isGroupAdmin(id, req.user.userId);
    if (!isGroupAdminUser) {
      return res.status(403).json({ error: 'Admin access required' });
    }
    
    // Cannot change own role
    if (userId === req.user.userId) {
      return res.status(400).json({ error: 'Cannot change your own role' });
    }
    
    const result = await pool.query(`
      UPDATE group_members 
      SET role = $1, "updatedAt" = NOW()
      WHERE "groupId" = $2 AND "userId" = $3
      RETURNING *
    `, [role, id, userId]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Member not found' });
    }
    
    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error updating member role:', error);
    res.status(500).json({ error: 'Failed to update member role' });
  }
});

// DELETE /api/groups/:id/members/:userId - Remove member (admin only)
router.delete('/:id/members/:userId', authenticateToken, async (req, res) => {
  try {
    const { id, userId } = req.params;
    
    // Check if user is admin
    const isGroupAdminUser = await isGroupAdmin(id, req.user.userId);
    if (!isGroupAdminUser) {
      return res.status(403).json({ error: 'Admin access required' });
    }
    
    // Cannot remove yourself
    if (userId === req.user.userId) {
      return res.status(400).json({ error: 'Cannot remove yourself from the group' });
    }
    
    const result = await pool.query(`
      DELETE FROM group_members 
      WHERE "groupId" = $1 AND "userId" = $2
      RETURNING *
    `, [id, userId]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Member not found' });
    }
    
    res.json({ message: 'Member removed successfully' });
  } catch (error) {
    console.error('Error removing member:', error);
    res.status(500).json({ error: 'Failed to remove member' });
  }
});

module.exports = router; 