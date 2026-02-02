// lib/feed_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FeedPage extends StatelessWidget {
  const FeedPage({super.key});

  // Function to delete a post
  Future<void> _deletePost(BuildContext context, String postId) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post?'),
        content: const Text('Are you sure you want to remove this post?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;

    if (confirm) {
      await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Feed', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.grey[100],
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('posts').orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No posts yet."));

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              String postId = doc.id;
              String postUid = data['uid'] ?? '';
              String imageUrl = data['imageUrl'] ?? '';
              String caption = data['caption'] ?? '';
              Timestamp? timestamp = data['timestamp'];
              String timeAgo = timestamp != null 
                  ? DateFormat.yMMMd().add_jm().format(timestamp.toDate()) 
                  : 'Just now';

              // CHECK: Is this MY post?
              bool isMyPost = (currentUser != null && currentUser.uid == postUid);

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Header: User Info & Delete Button ---
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.shade100,
                        child: const Icon(Icons.person, color: Colors.blue),
                      ),
                      // FETCH REAL NAME
                      title: FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance.collection('users').doc(postUid).get(),
                        builder: (context, userSnap) {
                          if (userSnap.hasData && userSnap.data!.exists) {
                            return Text(
                              userSnap.data!['email'] ?? 'Student', // Or use 'name' if you saved it
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            );
                          }
                          return const Text('Loading...');
                        },
                      ),
                      subtitle: Text(timeAgo, style: const TextStyle(fontSize: 12)),
                      trailing: isMyPost 
                        ? IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deletePost(context, postId),
                          )
                        : null,
                    ),

                    // --- Image ---
                    if (imageUrl.isNotEmpty)
                      Image.network(
                        imageUrl,
                        height: 250,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const SizedBox(height: 200, child: Center(child: Icon(Icons.broken_image, size: 50))),
                      ),

                    // --- Caption ---
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(caption, style: const TextStyle(fontSize: 15)),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}