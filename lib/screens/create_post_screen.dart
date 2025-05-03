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

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final labelStyle = GoogleFonts.poppins(
      color: const Color(0xFF900C3F),
      fontSize: 14,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create Post',
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF900C3F),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                labelStyle: labelStyle,
                prefixIcon: const Icon(Icons.title, color: Color(0xFF900C3F)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF900C3F)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: _contentController,
                maxLines: null,
                expands: true,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Write your post...',
                  hintStyle: labelStyle.copyWith(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF900C3F)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _submitPost,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF900C3F),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.send_rounded, color: Colors.white),
              label: Text(
                'Submit',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
