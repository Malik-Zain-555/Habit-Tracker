import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
// import 'login_screen.dart'; // Removed unused import

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  final _usernameController = TextEditingController();
  final _avatarUrlController = TextEditingController();
  final ApiService _api = ApiService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Profile')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Consumer<AuthProvider>(
                builder: (ctx, auth, _) => CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.deepPurple.shade50,
                  backgroundImage:
                      auth.avatarUrl != null && auth.avatarUrl!.isNotEmpty
                      ? NetworkImage(auth.avatarUrl!)
                      : null,
                  child: (auth.avatarUrl == null || auth.avatarUrl!.isEmpty)
                      ? Icon(Icons.person, size: 60, color: Colors.deepPurple)
                      : null,
                ),
              ),
              SizedBox(height: 16),
              Text(
                Provider.of<AuthProvider>(context).username ?? 'User',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 24),

              if (_isEditing)
                Column(
                  children: [
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(labelText: 'Username'),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: _avatarUrlController,
                      decoration: InputDecoration(
                        labelText: 'Avatar URL (Optional)',
                      ),
                    ),
                    SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            setState(() => _isEditing = false);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                          ),
                          child: Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            try {
                              await Provider.of<AuthProvider>(
                                context,
                                listen: false,
                              ).updateProfile(
                                username: _usernameController.text,
                                avatarUrl: _avatarUrlController.text,
                              );
                              setState(() => _isEditing = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Profile Updated!')),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          },
                          child: Text('Save'),
                        ),
                      ],
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: _buildIconBox(Icons.edit, Colors.blue),
                      title: Text('Edit Profile'),
                      trailing: Icon(Icons.chevron_right),
                      onTap: () {
                        final auth = Provider.of<AuthProvider>(
                          context,
                          listen: false,
                        );
                        setState(() {
                          _isEditing = true;
                          _usernameController.text = auth.username ?? '';
                          _avatarUrlController.text = auth.avatarUrl ?? '';
                        });
                      },
                    ),
                    SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: _buildIconBox(Icons.delete_forever, Colors.red),
                      title: Text('Delete Account'),
                      trailing: Icon(Icons.chevron_right),
                      onTap: () => _confirmDelete(),
                    ),
                    SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: _buildIconBox(Icons.logout, Colors.orange),
                      title: Text('Logout'),
                      trailing: Icon(Icons.chevron_right),
                      onTap: () async {
                        Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst); // Clear stack
                        await Provider.of<AuthProvider>(
                          context,
                          listen: false,
                        ).logout();
                        // AuthWrapper will handle showing LoginScreen
                      },
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconBox(IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Account?'),
        content: Text('This action cannot be undone. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _api.deleteAccount();
                Navigator.of(context).popUntil((route) => route.isFirst);
                await Provider.of<AuthProvider>(
                  context,
                  listen: false,
                ).logout();
              } catch (e) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Failed: $e')));
              }
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
