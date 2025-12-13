import 'package:flutter/material.dart';
import '../services/api_service.dart';

class Habit {
  final String id;
  final String title;
  final String description;
  final int currentStreak;
  final String? lastCompleted;
  final List<DateTime> completionDates;

  Habit({
    required this.id,
    required this.title,
    required this.description,
    required this.currentStreak,
    this.lastCompleted,
    this.completionDates = const [],
  });

  bool get isCompletedToday {
    if (lastCompleted == null) return false;
    final last = DateTime.parse(lastCompleted!).toLocal();
    final now = DateTime.now();
    return last.year == now.year &&
        last.month == now.month &&
        last.day == now.day;
  }

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'] ?? json['_id'] ?? '', // Handle both _id and id
      title: json['title'] ?? 'Untitled',
      description: json['description'] ?? '',
      currentStreak: json['currentStreak'] ?? 0,
      lastCompleted: json['lastCompleted'],
      completionDates:
          (json['completionDates'] as List<dynamic>?)
              ?.map((e) => DateTime.parse(e.toString()))
              .toList() ??
          [],
    );
  }
}

class HabitProvider with ChangeNotifier {
  List<Habit> _habits = [];
  final ApiService _apiService = ApiService();

  List<Habit> get habits => _habits;

  Future<void> fetchHabits() async {
    try {
      final data = await _apiService.getHabits();
      _habits = data.map((item) => Habit.fromJson(item)).toList();
      notifyListeners();
    } catch (e) {
      print('Fetch Habits Error: $e');
    }
  }

  // --- Global Streak Logic ---
  // Returns number of consecutive days where at least 3 habits were completed
  int get globalStreak {
    if (_habits.isEmpty) return 0;

    // 1. Flatten all completion dates
    Map<String, Set<String>> dailyCompletions = {};

    for (var habit in _habits) {
      for (var date in habit.completionDates) {
        // Normalize date YYYY-MM-DD
        final key = "${date.year}-${date.month}-${date.day}";
        if (!dailyCompletions.containsKey(key)) {
          dailyCompletions[key] = {};
        }
        dailyCompletions[key]!.add(habit.id);
      }
    }

    // 2. Filter days with >= 3 habits
    List<DateTime> validDays = [];
    dailyCompletions.forEach((dateKey, habitIds) {
      if (habitIds.length >= 3) {
        final parts = dateKey.split('-');
        validDays.add(
          DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          ),
        );
      }
    });

    // Debug Prints
    // print('Daily Completions Map: $dailyCompletions');
    // print('Valid Days (>=3): $validDays');

    if (validDays.isEmpty) return 0;

    // Sort descending (latest first)
    validDays.sort((a, b) => b.compareTo(a));

    // Remove duplicates if any (just in case)
    final uniqueDays = <DateTime>[];
    for (var d in validDays) {
      if (uniqueDays.isEmpty || !_isSameDay(uniqueDays.last, d)) {
        uniqueDays.add(d);
      }
    }

    // print('Unique Sorted Days: $uniqueDays');

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));

    // Check start point
    DateTime? currentCheck;
    if (uniqueDays.isNotEmpty && _isSameDay(uniqueDays.first, today)) {
      currentCheck = today;
    } else if (uniqueDays.isNotEmpty &&
        _isSameDay(uniqueDays.first, yesterday)) {
      currentCheck = yesterday;
    }

    if (currentCheck == null) {
      // print('Streak Broken. First unique day: ${uniqueDays.first} vs Today: $today / Yesterday: $yesterday');
      return 0;
    }

    int streak = 0;
    for (var day in uniqueDays) {
      if (_isSameDay(day, currentCheck!)) {
        streak++;
        currentCheck = currentCheck!.subtract(Duration(days: 1));
      } else {
        break;
      }
    }
    // print('Calculated Streak: $streak');
    return streak;
  }

  int get habitsCompletedToday {
    int count = 0;
    for (var h in _habits) {
      if (h.isCompletedToday) count++;
    }
    return count;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
  // ---------------------------

  Future<void> addHabit(String title, String description) async {
    try {
      await _apiService.createHabit(title, description);
      await fetchHabits();
    } catch (e) {
      rethrow; // Handle UI error showing
    }
  }

  Future<void> completeHabit(String habitId) async {
    final index = _habits.indexWhere((h) => h.id == habitId);
    if (index == -1) return;

    if (_habits[index].isCompletedToday) return;

    // Optimistic Update
    final oldHabit = _habits[index];
    final updatedDates = List<DateTime>.from(oldHabit.completionDates)
      ..add(DateTime.now());

    // Create new habit object with updated state
    final newHabit = Habit(
      id: oldHabit.id,
      title: oldHabit.title,
      description: oldHabit.description,
      currentStreak: oldHabit.currentStreak, // Not critical for global logic
      lastCompleted: DateTime.now().toIso8601String(),
      completionDates: updatedDates,
    );

    _habits[index] = newHabit;
    notifyListeners(); // Updates UI immediately

    try {
      await _apiService.completeHabit(habitId);
      // await fetchHabits(); // No need to refetch if we trust our local update
    } catch (e) {
      // Revert if API fails
      _habits[index] = oldHabit;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> failHabit(String habitId) async {
    try {
      await _apiService.failHabit(habitId);
      await fetchHabits(); // Refresh immediately
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateHabit(String id, String title, String description) async {
    try {
      await _apiService.updateHabit(id, title, description);
      await fetchHabits();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteHabit(String id) async {
    // Optimistic
    _habits.removeWhere((h) => h.id == id);
    notifyListeners();

    try {
      await _apiService.deleteHabit(id);
      await fetchHabits(); // confirm sync
    } catch (e) {
      await fetchHabits(); // revert on fail
    }
  }
}
