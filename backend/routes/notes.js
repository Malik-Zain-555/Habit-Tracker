const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');

const JWT_SECRET = 'supersecretkey_change_in_production'; // In prod, use .env

// Middleware to authenticate
const authenticate = (req, res, next) => {
    const token = req.headers.authorization?.split(' ')[1];
    if (!token) return res.status(401).json({ error: 'Unauthorized' });
    try {
        const decoded = jwt.verify(token, JWT_SECRET);
        req.userId = decoded.userId;
        next();
    } catch (err) {
        res.status(401).json({ error: 'Invalid token' });
    }
};

router.use(authenticate);

// GET all notes
router.get('/', async (req, res) => {
    try {
        const notesSnapshot = await req.db.collection('notes')
            .where('userId', '==', req.userId)
            .orderBy('createdAt', 'desc')
            .get();
        
        const notes = [];
        notesSnapshot.forEach(doc => notes.push({ id: doc.id, ...doc.data() }));
        res.json(notes);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// POST create note
router.post('/', async (req, res) => {
    try {
        const { title, content } = req.body;
        if (!title) return res.status(400).json({ error: 'Title required' });

        const newNote = {
            userId: req.userId,
            title,
            content: content || '',
            createdAt: new Date().toISOString()
        };

        const docRef = await req.db.collection('notes').add(newNote);
        res.status(201).json({ id: docRef.id, ...newNote });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// DELETE note
router.delete('/:id', async (req, res) => {
    try {
        await req.db.collection('notes').doc(req.params.id).delete();
        res.json({ message: 'Note deleted' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

module.exports = router;
