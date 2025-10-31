// lib/post_marks_page.dart

import 'package:flutter/material.dart';

class PostMarksPage extends StatelessWidget {
  const PostMarksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Marks'),
      ),
      body: const Center(
        child: Text(
          'This is where the teacher will post marks for students.',
          style: TextStyle(fontSize: 18, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}