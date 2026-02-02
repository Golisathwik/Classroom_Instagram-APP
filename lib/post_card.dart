// lib/post_card.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'comments_page.dart'; 

class PostCard extends StatefulWidget {
  final Map<String, dynamic> postData;
  final String postId;

  const PostCard({
    super.key,
    required this.postData,
    required this.postId,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late List<dynamic> likes;
  late bool isLiked;
  late int likeCount;
  late int commentCount;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser?.uid;

    // 1. Initialize Likes
    likes = widget.postData['likes'] ?? [];
    likeCount = likes.length;
    isLiked = (currentUserId != null) ? likes.contains(currentUserId) : false;

    // 2. Initialize Comments
    commentCount = widget.postData['commentCount'] ?? 0;
  }

  // --- LIKE LOGIC ---
  Future<void> _toggleLike() async {
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to like posts.')),
      );
      return;
    }

    // Optimistic UI Update (Update screen instantly)
    setState(() {
      if (isLiked) {
        likeCount -= 1;
        isLiked = false;
        likes.remove(currentUserId);
      } else {
        likeCount += 1;
        isLiked = true;
        likes.add(currentUserId);
      }
    });

    // Update Firebase in background
    DocumentReference postRef =
        FirebaseFirestore.instance.collection('posts').doc(widget.postId);

    try {
      if (isLiked) {
        await postRef.update({
          'likes': FieldValue.arrayUnion([currentUserId])
        });
      } else {
        await postRef.update({
          'likes': FieldValue.arrayRemove([currentUserId])
        });
      }
    } catch (e) {
      // If error, revert the change
      setState(() {
        if (isLiked) {
          likeCount -= 1;
          isLiked = false;
        } else {
          likeCount += 1;
          isLiked = true;
        }
      });
    }
  }

  // --- NAVIGATION TO COMMENTS ---
  void _goToComments() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommentsPage(postId: widget.postId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // FIX 1: Handle both 'caption' (new) and 'text' (old) fields
    final String caption = widget.postData['caption'] ?? widget.postData['text'] ?? '';
    
    // FIX 2: Handle missing user email
    final String userEmail = widget.postData['userEmail'] ?? 'Student';
    
    // Handle Timestamp
    final Timestamp? timestamp = widget.postData['timestamp'] as Timestamp?;
    final DateTime dateTime = timestamp?.toDate() ?? DateTime.now();

    // FIX 3: Robust Image URL check
    final String? imageUrl = widget.postData['imageUrl'];
    // Only show image if it exists AND is a valid web link (starts with http)
    final bool hasValidImage = imageUrl != null && imageUrl.isNotEmpty && imageUrl.startsWith('http');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0.0),
      elevation: 2.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- HEADER ---
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: const Icon(Icons.person, color: Colors.blue),
            ),
            title: Text(userEmail, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(timeago.format(dateTime)),
            trailing: const Icon(Icons.more_vert),
          ),

          // --- IMAGE POST ---
          if (hasValidImage)
            GestureDetector(
              onDoubleTap: _toggleLike,
              child: Image.network(
                imageUrl!,
                width: double.infinity,
                height: 300,
                fit: BoxFit.cover,
                // Loading Spinner
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 300,
                    color: Colors.grey[100],
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
                // Error Fallback (Grey Box)
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 300,
                    color: Colors.grey[200],
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image, color: Colors.grey, size: 50),
                  );
                },
              ),
            ),

          // --- BUTTONS ROW ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Colors.red : Colors.grey,
                  ),
                  onPressed: _toggleLike,
                ),
                IconButton(
                  icon: const Icon(Icons.comment_outlined, color: Colors.grey),
                  onPressed: _goToComments,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.bookmark_border, color: Colors.grey),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // --- LIKE COUNT ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              '$likeCount like${likeCount == 1 ? '' : 's'}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          
          const SizedBox(height: 8.0),

          // --- CAPTION ---
          if (caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.black),
                  children: [
                    TextSpan(
                      text: '$userEmail ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: caption),
                  ],
                ),
              ),
            ),

          // --- VIEW COMMENTS LINK ---
          if (commentCount > 0)
            GestureDetector(
              onTap: _goToComments,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  'View all $commentCount comment${commentCount == 1 ? '' : 's'}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            ),

          const SizedBox(height: 16.0),
        ],
      ),
    );
  }
}