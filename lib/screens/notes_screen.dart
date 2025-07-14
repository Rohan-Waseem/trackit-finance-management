import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _showNoteDialog({String? noteId, String? initialText}) async {
    final TextEditingController _controller = TextEditingController(text: initialText ?? "");

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.white.withOpacity(0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1F1F2E).withOpacity(0.95),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            boxShadow: const [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 12,
                offset: Offset(0, 5),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                noteId == null ? "📝 Add a Note" : "✏️ Edit Note",
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _controller,
                maxLines: 5,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Write something...",
                  hintStyle: const TextStyle(color: Colors.white60),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.07),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel", style: TextStyle(color: Colors.white70)),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () async {
                      final content = _controller.text.trim();
                      final uid = FirebaseAuth.instance.currentUser!.uid;

                      if (content.isNotEmpty) {
                        if (noteId == null) {
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(uid)
                              .collection('notes')
                              .add({
                            'content': content,
                            'timestamp': Timestamp.now(),
                          });
                        } else {
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(uid)
                              .collection('notes')
                              .doc(noteId)
                              .update({'content': content});
                        }
                      }

                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                    ),
                    child: Text(noteId == null ? "Add" : "Update"),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteNote(String noteId) async {
    String uid = _auth.currentUser!.uid;
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('notes')
        .doc(noteId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    String uid = _auth.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFF12121C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("My Notes",
            style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        onPressed: () => _showNoteDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('users')
            .doc(uid)
            .collection('notes')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (_, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No notes yet.", style: TextStyle(color: Colors.white70, fontSize: 16)),
            );
          }

          final notes = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notes.length,
            itemBuilder: (_, index) {
              final note = notes[index];
              final noteId = note.id;
              final content = note['content'];

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F1F2E),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        content,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      color: const Color(0xFF2A2A3D),
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showNoteDialog(noteId: noteId, initialText: content);
                        } else if (value == 'delete') {
                          _deleteNote(noteId);
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text("✏️ Edit", style: TextStyle(color: Colors.white)),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text("🗑️ Delete", style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
