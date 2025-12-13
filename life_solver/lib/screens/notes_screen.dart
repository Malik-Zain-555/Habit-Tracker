import 'package:flutter/material.dart';
import '../services/api_service.dart';

class NotesScreen extends StatefulWidget {
  @override
  _NotesScreenState createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _notes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotes();
  }

  Future<void> _fetchNotes() async {
    try {
      final notes = await _api.getNotes();
      setState(() {
        _notes = notes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Handle error
    }
  }

  Future<void> _addNote() async {
    final _titleController = TextEditingController();
    final _contentController = TextEditingController();

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
              "Create Note",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Title',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _contentController,
              decoration: InputDecoration(
                hintText: 'Write something...',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              maxLines: 5,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                if (_titleController.text.isEmpty) return;
                Navigator.pop(ctx);
                try {
                  await _api.createNote(
                    _titleController.text,
                    _contentController.text,
                  );
                  _fetchNotes();
                } catch (e) {
                  // Error handled
                }
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text('Save Note'),
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
      appBar: AppBar(title: Text('Notes')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _notes.isEmpty
          ? Center(child: Text("No notes yet"))
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: _notes.length,
              itemBuilder: (ctx, i) {
                final note = _notes[i];
                return Card(
                  margin: EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(
                      note['title'],
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      note['content'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.grey),
                      onPressed: () async {
                        await _api.deleteNote(note['id']);
                        _fetchNotes();
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNote,
        child: Icon(Icons.add),
        backgroundColor: Colors.deepPurple,
      ),
    );
  }
}
