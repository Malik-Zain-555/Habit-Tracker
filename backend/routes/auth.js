const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const JWT_SECRET = 'supersecretkey_change_in_production';

// Register
router.post('/signup', async (req, res) => {
    try {
        const { username, email, password } = req.body;
        const db = req.db;

        // Validation
        if (!username || !email || !password) {
            return res.status(400).json({ error: 'All fields are required.' });
        }
        if (username.trim() === '' || email.trim() === '' || password.trim() === '') {
            return res.status(400).json({ error: 'Fields cannot be empty.' });
        }
        
        // Check if user exists (email or username)
        const emailSnapshot = await db.collection('users').where('email', '==', email).get();
        if (!emailSnapshot.empty) {
            return res.status(400).json({ error: 'Email already registered' });
        }

        const usernameSnapshot = await db.collection('users').where('username', '==', username).get();
        if (!usernameSnapshot.empty) {
            return res.status(400).json({ error: 'Username already taken' });
        }

        const hashedPassword = await bcrypt.hash(password, 10);
        const newUser = {
            username,
            email,
            password: hashedPassword,
            totalStreaks: 0,
            createdAt: new Date().toISOString()
        };

        const docRef = await db.collection('users').add(newUser);
        res.status(201).json({ message: 'User created', userId: docRef.id });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Login
router.post('/login', async (req, res) => {
    try {
        const { email, password } = req.body;
        const db = req.db;

        const snapshot = await db.collection('users').where('email', '==', email).limit(1).get();
        if (snapshot.empty) return res.status(400).json({ error: 'User not found' });

        const userDoc = snapshot.docs[0];
        const user = userDoc.data();

        const isMatch = await bcrypt.compare(password, user.password);
        if (!isMatch) return res.status(400).json({ error: 'Invalid credentials' });

        const token = jwt.sign({ userId: userDoc.id }, JWT_SECRET, { expiresIn: '1d' });
        res.json({ token, userId: userDoc.id, username: user.username, avatarUrl: user.avatarUrl });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Update Profile
router.put('/me', async (req, res) => {
    try {
        const token = req.headers.authorization?.split(' ')[1];
        if (!token) return res.status(401).json({ error: 'Unauthorized' });

        const decoded = jwt.verify(token, JWT_SECRET);
        const { username, avatarUrl } = req.body;
        const db = req.db;

        const userRef = db.collection('users').doc(decoded.userId);
        
        const updateData = {};
        if (username) updateData.username = username;
        if (avatarUrl) updateData.avatarUrl = avatarUrl; // Assuming logic to store URL

        await userRef.update(updateData);
        
        // Fetch updated user to return
        const updatedDoc = await userRef.get();
        const userData = updatedDoc.data();
        delete userData.password;

        res.json(userData);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Delete Account
router.delete('/me', async (req, res) => {
    try {
        const token = req.headers.authorization?.split(' ')[1];
        if (!token) return res.status(401).json({ error: 'Unauthorized' });

        const decoded = jwt.verify(token, JWT_SECRET);
        const db = req.db;

        // Delete user doc
        await db.collection('users').doc(decoded.userId).delete();
        
        // Optional: Delete user's habits/data if you want to be thorough
        // For now, just deleting the account is the MVP request.

        res.json({ message: 'Account deleted successfully' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});


// POST /google
router.post('/google', async (req, res) => {
  try {
    const { token } = req.body;
    if (!token) return res.status(400).json({ error: 'Token required' });

    const ticket = await client.verifyIdToken({
      idToken: token,
      audience: process.env.GOOGLE_CLIENT_ID,
    });
    const payload = ticket.getPayload();
    const { email, name, picture } = payload;

    // Check if user exists
    const usersRef = db.collection('users');
    const snapshot = await usersRef.where('email', '==', email).get();

    let userId;
    let userData;

    if (snapshot.empty) {
      // Create new user
      const newUserRef = usersRef.doc();
      userId = newUserRef.id;
      userData = {
        username: name,
        email: email,
        avatarUrl: picture,
        createdAt: new Date().toISOString(),
        streak: 0,
        totalHabitsCompleted: 0,
        provider: 'google'
      };
      await newUserRef.set(userData);
    } else {
      userId = snapshot.docs[0].id;
      userData = snapshot.docs[0].data();
    }

    const jwtToken = jwt.sign({ id: userId, email: email }, JWT_SECRET, {
      expiresIn: '7d',
    });

    res.status(200).json({
      token: jwtToken,
      user: {
        id: userId,
        username: userData.username,
        email: userData.email,
        avatarUrl: userData.avatarUrl,
        streak: userData.streak,
        totalHabitsCompleted: userData.totalHabitsCompleted,
      },
    });
  } catch (err) {
    console.error('Google Auth Error:', err);
    res.status(401).json({ error: 'Invalid Token' });
  }
});

module.exports = router;
