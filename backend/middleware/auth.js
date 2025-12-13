const jwt = require('jsonwebtoken');

const JWT_SECRET = 'supersecretkey_change_in_production';

module.exports = (req, res, next) => {
    try {
        const token = req.headers.authorization?.split(' ')[1];
        if (!token) return res.status(401).json({ error: 'Unauthorized' });

        const decoded = jwt.verify(token, JWT_SECRET);
        // Standardize: req.user contains constraints, req.userId is direct
        req.user = decoded; 
        req.userId = decoded.userId; // Convenience alias
        next();
    } catch (err) {
        res.status(401).json({ error: 'Invalid token' });
    }
};
