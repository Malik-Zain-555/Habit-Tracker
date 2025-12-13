class User {
  final String id;
  final String username;
  final int totalStreaks;

  User({required this.id, required this.username, required this.totalStreaks});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'],
      username: json['username'],
      totalStreaks: json['totalStreaks'],
    );
  }
}
