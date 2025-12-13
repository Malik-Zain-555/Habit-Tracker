const express = require('express');
const router = express.Router();

// Get top users
router.get('/', async (req, res) => {
    try {
        const db = req.db;
        const snapshot = await db.collection('users')
            .orderBy('totalStreaks', 'desc')
            .limit(10)
            .get();
        
        const users = [];
        snapshot.forEach(doc => {
            const data = doc.data();
            users.push({
                _id: doc.id,
                username: data.username,
                totalStreaks: data.totalStreaks
            });
        });
        res.json(users);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

module.exports = router;
