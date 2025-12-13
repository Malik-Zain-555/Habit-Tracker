import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';

class AddHabitScreen extends StatefulWidget {
  @override
  _AddHabitScreenState createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  Future<void> _submit() async {
    if (_titleController.text.isEmpty) return;
    await Provider.of<HabitProvider>(
      context,
      listen: false,
    ).addHabit(_titleController.text, _descController.text);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Habit')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Start a New Habit",
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              "Building consistency starts with one small step.",
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 32),

            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Habit Title',
                hintText: 'e.g. Morning Jog, Read Books',
                prefixIcon: Icon(Icons.star_outline),
              ),
            ),
            SizedBox(height: 16),

            TextFormField(
              controller: _descController,
              decoration: InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Why do you want to build this habit?',
                prefixIcon: Icon(Icons.notes),
              ),
              maxLines: 2,
            ),
            SizedBox(height: 32),

            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('Create Habit', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
