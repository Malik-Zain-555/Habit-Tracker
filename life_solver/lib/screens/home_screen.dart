import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';
import '../providers/auth_provider.dart';
import 'add_habit_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Refresh habits on load
    Provider.of<HabitProvider>(context, listen: false).fetchHabits();
    // Removed unused auth variable

    return Scaffold(
      backgroundColor: Colors.grey[50], // Light clean background
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              // Header
              Consumer<AuthProvider>(
                builder: (ctx, auth, _) => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, ${auth.username ?? "User"}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Your Daily Goals',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => ProfileScreen()),
                      ),
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.grey[200],
                        backgroundImage:
                            auth.avatarUrl != null && auth.avatarUrl!.isNotEmpty
                            ? NetworkImage(auth.avatarUrl!)
                            : null,
                        child:
                            (auth.avatarUrl == null || auth.avatarUrl!.isEmpty)
                            ? Icon(Icons.person, color: Colors.grey[600])
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Statistics Card (Premium Look)
              Consumer<HabitProvider>(
                builder: (ctx, habitProvider, _) {
                  return _buildStatisticsCard(habitProvider);
                },
              ),
              SizedBox(height: 24),

              // Habits Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Habits',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(
                      context,
                    ).push(MaterialPageRoute(builder: (_) => AddHabitScreen())),
                    icon: Icon(
                      Icons.add_circle,
                      color: Colors.deepPurple,
                      size: 30,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),

              Consumer<HabitProvider>(
                builder: (ctx, habitProvider, _) {
                  if (habitProvider.habits.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          'No habits yet.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: habitProvider.habits.length,
                    separatorBuilder: (_, __) => SizedBox(height: 12),
                    itemBuilder: (ctx, i) {
                      final habit = habitProvider.habits[i];
                      return _buildHabitCard(context, habit);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsCard(HabitProvider habitProvider) {
    final habits = habitProvider.habits;
    final streak = habitProvider.globalStreak;
    final todayCount = habitProvider.habitsCompletedToday;

    // simple logic to map completionDates to days of week
    // 0 = mon, 6 = sun
    List<int> dailyCounts = List.filled(7, 0);

    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final mondayStart = DateTime(monday.year, monday.month, monday.day);

    for (var habit in habits) {
      for (var date in habit.completionDates) {
        final d = DateTime(date.year, date.month, date.day);
        final diff = d.difference(mondayStart).inDays;
        if (diff >= 0 && diff < 7) {
          dailyCounts[diff]++;
        }
      }
    }

    // Normalize to 3
    int maxVal = dailyCounts.reduce((curr, next) => curr > next ? curr : next);
    if (maxVal < 3) maxVal = 3;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF1E1E1E), // Dark card
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with Global Streak
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Global Spark',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        color: Colors.orange,
                        size: 28,
                      ),
                      SizedBox(width: 8),
                      Text(
                        '$streak Days',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Daily progress circle
              Column(
                children: [
                  Text(
                    'Today',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  SizedBox(height: 4),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: todayCount >= 3
                          ? Colors.green.withOpacity(0.2)
                          : Colors.white10,
                      borderRadius: BorderRadius.circular(20),
                      border: todayCount >= 3
                          ? Border.all(color: Colors.green)
                          : null,
                    ),
                    child: Text(
                      '$todayCount / 3',
                      style: TextStyle(
                        color: todayCount >= 3 ? Colors.green : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 20),
          // Bar Chart
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildBar(
                dailyCounts[0],
                maxVal,
                'Mon',
                DateTime.now().weekday == 1,
              ),
              _buildBar(
                dailyCounts[1],
                maxVal,
                'Tue',
                DateTime.now().weekday == 2,
              ),
              _buildBar(
                dailyCounts[2],
                maxVal,
                'Wed',
                DateTime.now().weekday == 3,
              ),
              _buildBar(
                dailyCounts[3],
                maxVal,
                'Thu',
                DateTime.now().weekday == 4,
              ),
              _buildBar(
                dailyCounts[4],
                maxVal,
                'Fri',
                DateTime.now().weekday == 5,
              ),
              _buildBar(
                dailyCounts[5],
                maxVal,
                'Sat',
                DateTime.now().weekday == 6,
              ),
              _buildBar(
                dailyCounts[6],
                maxVal,
                'Sun',
                DateTime.now().weekday == 7,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBar(int count, int max, String label, bool isToday) {
    // Height calculation
    double height = (count / max) * 60; // Max height 60
    if (height < 4) height = 4; // Min height visibility

    return Column(
      children: [
        Container(
          width: 8,
          height: height,
          decoration: BoxDecoration(
            // Green if >= 3, else white/grey
            color: count >= 3 ? Color(0xFFD0FD3E) : Colors.white24,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        SizedBox(height: 8),
        Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 10)),
      ],
    );
  }

  Widget _buildHabitCard(BuildContext context, Habit habit) {
    final bool isDone = habit.isCompletedToday;

    return Dismissible(
      key: ValueKey(habit.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.delete, color: Colors.red),
      ),
      confirmDismiss: (_) async {
        return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Delete?'),
            content: Text('Delete "${habit.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('Yes'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        Provider.of<HabitProvider>(
          context,
          listen: false,
        ).deleteHabit(habit.id);
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDone ? Colors.green.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon Placeholder instead of per-habit streak
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isDone
                    ? Colors.green.shade100
                    : Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isDone ? Icons.check_circle : Icons.fitness_center,
                color: isDone ? Colors.green : Colors.deepPurple,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                      color: isDone ? Colors.grey : Colors.black,
                    ),
                  ),
                  if (habit.description.isNotEmpty)
                    Text(
                      habit.description,
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            // Actions
            if (!isDone)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Delete Button (was Fail streak)
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: Colors.red[300],
                      size: 24,
                    ),
                    onPressed: () =>
                        _confirmAction(context, 'Delete Habit?', () {
                          Provider.of<HabitProvider>(
                            context,
                            listen: false,
                          ).deleteHabit(habit.id);
                        }),
                  ),
                  InkWell(
                    onTap: () => _confirmAction(context, 'Mark done?', () {
                      Provider.of<HabitProvider>(
                        context,
                        listen: false,
                      ).completeHabit(habit.id);
                    }),
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black, // Premium dark button
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check, color: Colors.white, size: 20),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.grey, size: 18),
                    onPressed: () => _showEditDialog(context, habit),
                  ),
                ],
              )
            else
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Text(
                  'Completed',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _confirmAction(
    BuildContext context,
    String title,
    Function onConfirmed,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              onConfirmed();
              Navigator.of(ctx).pop();
            },
            child: Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, Habit habit) {
    final titleController = TextEditingController(text: habit.title);
    final descController = TextEditingController(text: habit.description);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Habit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: descController,
              decoration: InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                Provider.of<HabitProvider>(context, listen: false).updateHabit(
                  habit.id,
                  titleController.text,
                  descController.text,
                );
              }
              Navigator.pop(ctx);
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }
}
