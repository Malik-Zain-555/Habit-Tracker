const express = require("express");
const router = express.Router();
const auth = require("../middleware/auth");

// Get all habits for user (Auto-reset streaks if missed)
router.get("/", auth, async (req, res) => {
  try {
    const db = req.db;
    const habitsSnapshot = await db
      .collection("habits")
      .where("userId", "==", req.user.userId)
      .get();

    const habits = [];
    const today = new Date();
    today.setHours(0, 0, 0, 0); // Midnight today

    const batch = db.batch(); // For efficient updates
    let needsCommit = false;

    habitsSnapshot.forEach((doc) => {
      const data = doc.data();
      const habit = { id: doc.id, ...data };

      // Logic: If lastCompleted < Yesterday (Midnight), reset streak
      if (data.lastCompleted) {
        const lastCompletedDate = new Date(data.lastCompleted);
        lastCompletedDate.setHours(0, 0, 0, 0);

        const yesterday = new Date(today);
        yesterday.setDate(yesterday.getDate() - 1);

        // If last completed was BEFORE yesterday, streak is broken
        if (lastCompletedDate < yesterday) {
          habit.currentStreak = 0;
          const ref = db.collection("habits").doc(doc.id);
          batch.update(ref, { currentStreak: 0 });
          needsCommit = true;
        }
      }

      habits.push(habit);
    });

    if (needsCommit) {
      await batch.commit();
    }

    // SYNC FIX: Ensure global streak is updated in DB whenever we fetch habits
    // This fixes the issue where Leaderboard shows stale data until a write action occurs.
    await _updateUserTotalStreaks(db, req.user.userId);

    res.json(habits);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.post("/", auth, async (req, res) => {
  try {
    const { title, description } = req.body;
    const db = req.db;

    const newHabit = {
      userId: req.user.userId,
      title,
      description,
      currentStreak: 0,
      completionDates: [],
      createdAt: new Date().toISOString(),
    };

    const docRef = await db.collection("habits").add(newHabit);
    res.status(201).json({ id: docRef.id, ...newHabit });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Update habit
router.put("/:id", auth, async (req, res) => {
  try {
    const { title, description } = req.body;
    const db = req.db;
    const habitRef = db.collection("habits").doc(req.params.id);
    const doc = await habitRef.get();

    if (!doc.exists) return res.status(404).json({ error: "Habit not found" });
    if (doc.data().userId !== req.user.userId)
      return res.status(403).json({ error: "Unauthorized" });

    await habitRef.update({ title, description });
    res.json({ _id: req.params.id, ...doc.data(), title, description });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Delete habit
router.delete("/:id", auth, async (req, res) => {
  try {
    const db = req.db;
    const habitRef = db.collection("habits").doc(req.params.id);
    const doc = await habitRef.get();

    if (!doc.exists) return res.status(404).json({ error: "Habit not found" });
    if (doc.data().userId !== req.user.userId)
      return res.status(403).json({ error: "Unauthorized" });

    await habitRef.delete();
    res.json({ message: "Habit deleted" });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Fail habit (Did not do)
router.post("/:id/fail", auth, async (req, res) => {
  try {
    const db = req.db;
    const habitRef = db.collection("habits").doc(req.params.id);
    const doc = await habitRef.get();

    if (!doc.exists) return res.status(404).json({ error: "Habit not found" });

    if (doc.data().userId !== req.user.userId)
      return res.status(403).json({ error: "Unauthorized" });

    // Reset streak to 0
    const updateData = { currentStreak: 0 };
    await habitRef.update(updateData);

    // Recalculate User Total
    await _updateUserTotalStreaks(db, req.user.userId);

    res.json({ _id: req.params.id, ...doc.data(), ...updateData });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Complete habit
router.post("/:id/complete", auth, async (req, res) => {
  try {
    const db = req.db;
    const habitRef = db.collection("habits").doc(req.params.id);
    const doc = await habitRef.get();

    if (!doc.exists) return res.status(404).json({ error: "Habit not found" });
    if (doc.data().userId !== req.user.userId)
      return res.status(403).json({ error: "Unauthorized" });

    const now = new Date();
    const today = new Date(now).setHours(0, 0, 0, 0);

    const lastCompleted = doc.data().lastCompleted
      ? new Date(doc.data().lastCompleted).setHours(0, 0, 0, 0)
      : null;

    if (lastCompleted === today) {
      return res.status(400).json({ error: "Habit already completed today" });
    }

    const newStreak = (doc.data().currentStreak || 0) + 1;

    // Add to completionHistory
    const completionDates = doc.data().completionDates || [];
    completionDates.push(now.toISOString());

    await habitRef.update({
      currentStreak: newStreak,
      lastCompleted: now.toISOString(),
      completionDates: completionDates,
    });

    // Update user total streak
    await _updateUserTotalStreaks(db, req.user.userId);

    res.json({
      _id: req.params.id,
      ...doc.data(),
      currentStreak: newStreak,
      lastCompleted: now.toISOString(),
      completionDates,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

async function _updateUserTotalStreaks(db, userId) {
  const dbUserRef = db.collection("users").doc(userId);
  const allHabits = await db
    .collection("habits")
    .where("userId", "==", userId)
    .get();

  // 1. Flatten all completion dates
  const dailyCompletions = {};
  allHabits.forEach((h) => {
    const data = h.data();
    if (data.completionDates && Array.isArray(data.completionDates)) {
      data.completionDates.forEach((dateStr) => {
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
      // Reconstruct Date object from key (for simple sorting)
      // Note: dateKey is local YYYY-M-D. new Date(Y, M-1, D)
      const parts = dateKey.split("-").map(Number);
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
  // Normalize Today/Yesterday
  const now = new Date();
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const yesterday = new Date(today);
  yesterday.setDate(yesterday.getDate() - 1);

  let currentCheck = null;
  const firstValid = validDays[0];

  // Check if streak starts today or yesterday
  if (firstValid.getTime() === today.getTime()) {
    currentCheck = today;
  } else if (firstValid.getTime() === yesterday.getTime()) {
    currentCheck = yesterday;
  } else {
    // Streak broken
    await dbUserRef.update({ totalStreaks: 0 });
    return;
  }

  let streak = 0;
  for (const day of validDays) {
    if (day.getTime() === currentCheck.getTime()) {
      streak++;
      // Move check back 1 day
      currentCheck.setDate(currentCheck.getDate() - 1);
    } else {
      // Gap found
      break;
    }
  }

  await dbUserRef.update({ totalStreaks: streak });
}

// Copied logic to be safe. No changes here.
module.exports = router;
