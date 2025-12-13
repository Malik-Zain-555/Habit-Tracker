const express = require('express');
const cors = require('cors');
const admin = require('firebase-admin');

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// 🔐 Firebase Admin via ENV (Vercel-safe)
if (!admin.apps.length) {
    try {
        admin.initializeApp({
            credential: admin.credential.cert({
                projectId: process.env.FIREBASE_PROJECT_ID,
                clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
                privateKey: process.env.FIREBASE_PRIVATE_KEY
                    ?.replace(/\\n/g, '\n'),
            }),
        });
        console.log('Firebase initialized successfully');
    } catch (error) {
        console.error('Firebase init error:', error.message);
    }
}

const db = admin.firestore();

// Pass DB to request
app.use((req, res, next) => {
    req.db = db;
    next();
});

// Routes
app.use('/api/auth', require('./routes/auth'));
app.use('/api/habits', require('./routes/habits'));
app.use('/api/leaderboard', require('./routes/leaderboard'));
app.use('/api/notes', require('./routes/notes'));
app.use('/api/tasks', require('./routes/tasks'));

app.get('/', (req, res) => {
    res.send('Life Solver API (Firebase) is running');
});

// ❌ NO app.listen()
// ✅ EXPORT FOR VERCEL
module.exports = app;
