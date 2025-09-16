const express = require('express');
const jwt = require('jsonwebtoken');
const { PrismaClient } = require('@prisma/client');

const router = express.Router();
const prisma = new PrismaClient();

// Middleware to verify JWT token
const authenticateToken = (req, res, next) => {
  const token = req.headers.authorization?.replace('Bearer ', '');
  
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

// Get all tasks for a user
router.get('/', authenticateToken, async (req, res) => {
  try {
    const tasks = await prisma.task.findMany({
      where: { userId: req.user.userId },
      orderBy: [
        { completed: 'asc' },
        { dueDate: 'asc' },
        { createdAt: 'desc' }
      ]
    });

    res.json({ tasks });
  } catch (error) {
    console.error('Get tasks error:', error);
    res.status(500).json({ 
      error: 'Failed to get tasks',
      message: error.message 
    });
  }
});

// Get task by ID
router.get('/:id', authenticateToken, async (req, res) => {
  try {
    const task = await prisma.task.findFirst({
      where: {
        id: req.params.id,
        userId: req.user.userId
      }
    });

    if (!task) {
      return res.status(404).json({ error: 'Task not found' });
    }

    res.json({ task });
  } catch (error) {
    console.error('Get task error:', error);
    res.status(500).json({ 
      error: 'Failed to get task',
      message: error.message 
    });
  }
});

// Create new task
router.post('/', authenticateToken, async (req, res) => {
  try {
    const { title, description, category, dueDate, priority, estimatedTime } = req.body;

    if (!title || !category) {
      return res.status(400).json({ 
        error: 'Title and category are required' 
      });
    }

    const task = await prisma.task.create({
      data: {
        title,
        description: description || '',
        category,
        dueDate: dueDate ? new Date(dueDate) : null,
        priority: priority || 'medium',
        estimatedTime: estimatedTime || 0,
        completed: false,
        userId: req.user.userId
      }
    });

    res.status(201).json({
      message: 'Task created successfully',
      task
    });
  } catch (error) {
    console.error('Create task error:', error);
    res.status(500).json({ 
      error: 'Failed to create task',
      message: error.message 
    });
  }
});

// Update task
router.put('/:id', authenticateToken, async (req, res) => {
  try {
    const { title, description, category, dueDate, priority, estimatedTime, completed } = req.body;

    // Check if task exists and belongs to user
    const existingTask = await prisma.task.findFirst({
      where: {
        id: req.params.id,
        userId: req.user.userId
      }
    });

    if (!existingTask) {
      return res.status(404).json({ error: 'Task not found' });
    }

    const updateData = {};
    if (title !== undefined) updateData.title = title;
    if (description !== undefined) updateData.description = description;
    if (category !== undefined) updateData.category = category;
    if (dueDate !== undefined) updateData.dueDate = dueDate ? new Date(dueDate) : null;
    if (priority !== undefined) updateData.priority = priority;
    if (estimatedTime !== undefined) updateData.estimatedTime = estimatedTime;
    if (completed !== undefined) updateData.completed = completed;

    const updatedTask = await prisma.task.update({
      where: { id: req.params.id },
      data: updateData
    });

    res.json({
      message: 'Task updated successfully',
      task: updatedTask
    });
  } catch (error) {
    console.error('Update task error:', error);
    res.status(500).json({ 
      error: 'Failed to update task',
      message: error.message 
    });
  }
});

// Delete task
router.delete('/:id', authenticateToken, async (req, res) => {
  try {
    // Check if task exists and belongs to user
    const existingTask = await prisma.task.findFirst({
      where: {
        id: req.params.id,
        userId: req.user.userId
      }
    });

    if (!existingTask) {
      return res.status(404).json({ error: 'Task not found' });
    }

    await prisma.task.delete({
      where: { id: req.params.id }
    });

    res.json({ message: 'Task deleted successfully' });
  } catch (error) {
    console.error('Delete task error:', error);
    res.status(500).json({ 
      error: 'Failed to delete task',
      message: error.message 
    });
  }
});

// Mark task as completed
router.patch('/:id/complete', authenticateToken, async (req, res) => {
  try {
    const { completed } = req.body;

    if (typeof completed !== 'boolean') {
      return res.status(400).json({ error: 'Completed status must be boolean' });
    }

    // Check if task exists and belongs to user
    const existingTask = await prisma.task.findFirst({
      where: {
        id: req.params.id,
        userId: req.user.userId
      }
    });

    if (!existingTask) {
      return res.status(404).json({ error: 'Task not found' });
    }

    const updatedTask = await prisma.task.update({
      where: { id: req.params.id },
      data: { completed }
    });

    res.json({
      message: `Task ${completed ? 'completed' : 'uncompleted'} successfully`,
      task: updatedTask
    });
  } catch (error) {
    console.error('Complete task error:', error);
    res.status(500).json({ 
      error: 'Failed to update task completion',
      message: error.message 
    });
  }
});

// Get tasks by category
router.get('/category/:category', authenticateToken, async (req, res) => {
  try {
    const tasks = await prisma.task.findMany({
      where: {
        userId: req.user.userId,
        category: req.params.category
      },
      orderBy: [
        { completed: 'asc' },
        { dueDate: 'asc' },
        { createdAt: 'desc' }
      ]
    });

    res.json({ tasks });
  } catch (error) {
    console.error('Get tasks by category error:', error);
    res.status(500).json({ 
      error: 'Failed to get tasks by category',
      message: error.message 
    });
  }
});

// Get task statistics
router.get('/stats/overview', authenticateToken, async (req, res) => {
  try {
    const totalTasks = await prisma.task.count({
      where: { userId: req.user.userId }
    });

    const completedTasks = await prisma.task.count({
      where: {
        userId: req.user.userId,
        completed: true
      }
    });

    const pendingTasks = await prisma.task.count({
      where: {
        userId: req.user.userId,
        completed: false
      }
    });

    const overdueTasks = await prisma.task.count({
      where: {
        userId: req.user.userId,
        completed: false,
        dueDate: {
          lt: new Date()
        }
      }
    });

    const categoryStats = await prisma.task.groupBy({
      by: ['category'],
      where: { userId: req.user.userId },
      _count: {
        category: true
      }
    });

    res.json({
      totalTasks,
      completedTasks,
      pendingTasks,
      overdueTasks,
      completionRate: totalTasks > 0 ? Math.round((completedTasks / totalTasks) * 100) : 0,
      categoryStats: categoryStats.map(stat => ({
        category: stat.category,
        count: stat._count.category
      }))
    });
  } catch (error) {
    console.error('Get task stats error:', error);
    res.status(500).json({ 
      error: 'Failed to get task statistics',
      message: error.message 
    });
  }
});

module.exports = router; 