import 'package:flutter/material.dart';
import '../services/api_service.dart';

class LeaderboardScreen extends StatefulWidget {
  @override
  _LeaderboardScreenState createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _leaderboardFuture;

  @override
  void initState() {
    super.initState();
    _leaderboardFuture = _apiService.getLeaderboard();
  }

  Future<void> _refresh() async {
    setState(() {
      _leaderboardFuture = _apiService.getLeaderboard();
    });
    await _leaderboardFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Leaderboard 🏆')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder(
          future: _leaderboardFuture,
          builder: (ctx, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error loading leaderboard'));
            }
            final users = snapshot.data as List<dynamic>;
            return ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: users.length,
              itemBuilder: (ctx, i) {
                final user = users[i];
                Color? rankColor;
                if (i == 0)
                  rankColor = Colors.amber; // Gold
                else if (i == 1)
                  rankColor = Colors.grey.shade400; // Silver
                else if (i == 2)
                  rankColor = Colors.brown.shade300; // Bronze

                return Card(
                  elevation: i < 3 ? 4 : 1,
                  margin: EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: rankColor ?? Colors.blue.shade50,
                      foregroundColor: rankColor != null
                          ? Colors.white
                          : Colors.black,
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(
                      user['username'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: i == 0 ? Colors.amber.shade800 : Colors.black87,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${user['totalStreaks']}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 4),
                        Text('🔥', style: TextStyle(fontSize: 18)),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
