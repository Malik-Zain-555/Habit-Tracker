const express = require('express');
const cors = require('cors');
const admin = require('firebase-admin');

// Initialize Firebase Admin
try {
    const serviceAccount = require('./serviceAccountKey.json');
    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
    });
    console.log("Firebase initialized successfully");
} catch (error) {
    console.error("Error initializing Firebase. Did you add serviceAccountKey.json?", error.message);
}

const db = admin.firestore();
const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(express.json());

// Pass DB to request
app.use((req, res, next) => {
    req.db = db;
    next();
});

// Routes
const authRoutes = require('./routes/auth');
const habitRoutes = require('./routes/habits');
const leaderboardRoutes = require('./routes/leaderboard');
const notesRoutes = require('./routes/notes');
const tasksRoutes = require('./routes/tasks');

app.use('/api/auth', authRoutes);
app.use('/api/habits', habitRoutes);
app.use('/api/leaderboard', leaderboardRoutes);
app.use('/api/notes', notesRoutes);
app.use('/api/tasks', tasksRoutes);

app.get('/', (req, res) => {
    res.send('Life Solver API (Firebase) is running');
});

app.listen(PORT, '0.0.0.0', () => {
    console.log(`Server is running on port ${PORT}`);
});
