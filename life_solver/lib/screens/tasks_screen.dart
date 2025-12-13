import 'package:flutter/material.dart';
import '../services/api_service.dart';

class TasksScreen extends StatefulWidget {
  @override
  _TasksScreenState createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    try {
      final tasks = await _api.getTasks();
      setState(() {
        _tasks = tasks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addTask() async {
    final _titleController = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Add New Task",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _titleController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'What needs to be done?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                if (_titleController.text.isEmpty) return;
                Navigator.pop(ctx);
                await _api.createTask(_titleController.text);
                _fetchTasks();
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('Add Task'),
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Tasks')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _tasks.isEmpty
          ? Center(child: Text("No tasks yet"))
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: _tasks.length,
              itemBuilder: (ctx, i) {
                final task = _tasks[i];
                return Card(
                  margin: EdgeInsets.only(bottom: 12),
                  child: CheckboxListTile(
                    title: Text(
                      task['title'],
                      style: TextStyle(
                        decoration: task['done']
                            ? TextDecoration.lineThrough
                            : null,
                        color: task['done'] ? Colors.grey : Colors.black,
                      ),
                    ),
                    value: task['done'],
                    onChanged: (val) async {
                      // Optimistic update
                      setState(() {
                        task['done'] = val;
                      });
                      await _api.toggleTask(task['id'], val!);
                    },
                    secondary: IconButton(
                      icon: Icon(Icons.delete, color: Colors.grey),
                      onPressed: () async {
                        await _api.deleteTask(task['id']);
                        _fetchTasks();
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTask,
        child: Icon(Icons.add),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
