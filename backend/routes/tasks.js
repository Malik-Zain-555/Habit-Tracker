const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');

router.use(auth);

// GET tasks
router.get('/', async (req, res) => {
    try {
        const snapshot = await req.db.collection('tasks')
            .where('userId', '==', req.userId)
            .get();
        
        const tasks = [];
        snapshot.forEach(doc => tasks.push({ id: doc.id, ...doc.data() }));
        
        // Sort in memory to avoid Firestore Index requirement
        tasks.sort((a, b) => b.createdAt.localeCompare(a.createdAt));
        
        res.json(tasks);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// POST task
router.post('/', async (req, res) => {
    try {
        const { title, dueTime } = req.body;
        if (!title) return res.status(400).json({ error: 'Title required' });

        const newTask = {
            userId: req.userId,
            title,
            done: false,
            dueTime: dueTime || null,
            createdAt: new Date().toISOString()
        };

        const docRef = await req.db.collection('tasks').add(newTask);
        res.status(201).json({ id: docRef.id, ...newTask });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// PATCH toggle task
router.patch('/:id', async (req, res) => {
    try {
        const { done } = req.body;
        await req.db.collection('tasks').doc(req.params.id).update({ done });
        res.json({ message: 'Task updated' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// DELETE task
router.delete('/:id', async (req, res) => {
    try {
        await req.db.collection('tasks').doc(req.params.id).delete();
        res.json({ message: 'Task deleted' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

module.exports = router;
