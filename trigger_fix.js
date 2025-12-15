const https = require('https');

// URL from your screenshot
const url = 'https://habit-tracker-amber-nine.vercel.app/api/leaderboard/fix-all-streaks';

console.log(`Triggering Leaderboard Fix at: ${url}...`);

const req = https.request(url, { method: 'POST' }, (res) => {
    let data = '';

    res.on('data', (chunk) => {
        data += chunk;
    });

    res.on('end', () => {
        console.log(`\nStatus Code: ${res.statusCode}`);
        console.log('Response:', data);
        if (res.statusCode === 200) {
            console.log('\n✅ SUCCESS! All streaks have been synchronized.');
        } else {
            console.log('\n❌ FAILED. Check the logs above.');
        }
    });
});

req.on('error', (e) => {
    console.error(`\n❌ Error: ${e.message}`);
});

req.end();
