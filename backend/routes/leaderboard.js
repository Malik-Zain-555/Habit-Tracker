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

// --- ADMIN: Force Update All Users ---
router.post('/fix-all-streaks', async (req, res) => {
    try {
        const db = req.db;
        const usersSnapshot = await db.collection('users').get();
        let updatedCount = 0;

        const promises = [];

        usersSnapshot.forEach(doc => {
            // Process in parallel-ish (be careful with limits, but for this scale it's fine)
            promises.push(_updateUserTotalStreaks(db, doc.id).then(() => {
                updatedCount++;
            }));
        });

        await Promise.all(promises);

        res.json({ message: `Successfully synced streaks for ${updatedCount} users.` });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// --- Helper Logic (Duplicated from habits.js to avoid breaking exports) ---
async function _updateUserTotalStreaks(db, userId) {
    const dbUserRef = db.collection('users').doc(userId);
    const allHabits = await db.collection('habits').where('userId', '==', userId).get();
        
    // 1. Flatten all completion dates
    const dailyCompletions = {};
    allHabits.forEach(h => {
        const data = h.data();
        if (data.completionDates && Array.isArray(data.completionDates)) {
             data.completionDates.forEach(dateStr => {
                 const d = new Date(dateStr);
                 // Format YYYY-MM-DD
                 const key = `${d.getFullYear()}-${d.getMonth() + 1}-${d.getDate()}`;
                 if (!dailyCompletions[key]) dailyCompletions[key] = new Set();
                 dailyCompletions[key].add(h.id);
             });
        }
    });

    // 2. Filter days with >= 3 habits
    const validDays = [];
    for (const [dateKey, habitSet] of Object.entries(dailyCompletions)) {
        if (habitSet.size >= 3) {
            const parts = dateKey.split('-').map(Number);
            validDays.push(new Date(parts[0], parts[1] - 1, parts[2]));
        }
    }

    if (validDays.length === 0) {
        await dbUserRef.update({ totalStreaks: 0 });
        return;
    }

    // 3. Sort Descending
    validDays.sort((a, b) => b - a);

    // 4. Count Consecutive
    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const yesterday = new Date(today);
    yesterday.setDate(yesterday.getDate() - 1);

    let currentCheck = null;
    const firstValid = validDays[0];
    
    if (firstValid.getTime() === today.getTime()) {
        currentCheck = today;
    } else if (firstValid.getTime() === yesterday.getTime()) {
        currentCheck = yesterday;
    } else {
        await dbUserRef.update({ totalStreaks: 0 });
        return;
    }

    let streak = 0;
    for (const day of validDays) {
        if (day.getTime() === currentCheck.getTime()) {
            streak++;
            currentCheck.setDate(currentCheck.getDate() - 1);
        } else {
            break;
        }
    }

    await dbUserRef.update({ totalStreaks: streak });
}

module.exports = router;
