// screens/create_post_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  Future<void> _submitPost() async {
    await Supabase.instance.client.from('posts').insert({
      'title': _titleController.text,
      'content': _contentController.text,
      'user_id': Supabase.instance.client.auth.currentUser!.id,
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = GoogleFonts.poppins(
      color: const Color(0xFF900C3F),
      fontSize: 14,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Create Post', style: GoogleFonts.poppins(fontSize: 18)),
        backgroundColor: const Color(0xFF900C3F),
        leading: const Icon(Icons.edit_note, color: Colors.white),
      ),
      body: Container(
        color: const Color(0xFF900C3F).withOpacity(0.1),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                labelStyle: textStyle,
                prefixIcon: const Icon(
                  Icons.text_fields,
                  color: Color(0xFF900C3F),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFF900C3F)),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFF900C3F)),
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              decoration: InputDecoration(
                labelText: 'Content',
                labelStyle: textStyle,
                prefixIcon: const Icon(Icons.notes, color: Color(0xFF900C3F)),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFF900C3F)),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFF900C3F)),
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _submitPost,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF900C3F),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12.0),
              ),
              icon: const Icon(Icons.send_rounded, color: Colors.white),
              label: Text('Submit', style: GoogleFonts.poppins(fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }
}
