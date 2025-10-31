// lib/feed_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'post_card.dart'; // Our beautiful widget
import 'create_post_page.dart'; // <-- Import this page

class FeedPage extends StatelessWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Classroom Feed'),
        backgroundColor: Colors.white,
        elevation: 1.0,
        
        // --- THIS IS THE NEW PART ---
        actions: [
          IconButton(
            icon: const Icon(Icons.add_a_photo_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreatePostPage()),
              );
            },
          ),
        ],
        // --- END OF NEW PART ---
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No posts yet.'));
          }

          return ListView(
  children: snapshot.data!.docs.map((doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    // Pass the document's ID (postId) to the PostCard
    return PostCard(
      postData: data,
      postId: doc.id, // <-- THIS IS THE NEW LINE
    );
  }).toList(),
);
        },
      ),
    );
  }
}