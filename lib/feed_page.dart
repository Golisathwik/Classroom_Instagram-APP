// lib/feed_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart'; 
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FeedPage extends StatelessWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Feed', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1.0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.grey[100],
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
            return const Center(child: Text("No posts yet."));
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 100), 
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              return PostCard(doc: snapshot.data!.docs[index]);
            },
          );
        },
      ),
    );
  }
}

// --- MAIN POST WIDGET ---
class PostCard extends StatefulWidget {
  final QueryDocumentSnapshot doc;

  const PostCard({super.key, required this.doc});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  bool isExpanded = false; 

  // --- 1. TOGGLE LIKE ---
  Future<void> _toggleLike() async {
    if (currentUser == null) return;
    DocumentReference postRef = FirebaseFirestore.instance.collection('posts').doc(widget.doc.id);
    List likes = widget.doc['likes'] ?? [];

    if (likes.contains(currentUser!.uid)) {
      await postRef.update({'likes': FieldValue.arrayRemove([currentUser!.uid])});
    } else {
      await postRef.update({'likes': FieldValue.arrayUnion([currentUser!.uid])});
    }
  }

  // --- 2. SHOW LIKERS LIST (New Feature) ---
  void _showLikersList(List likes) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(child: Text("Likes", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: likes.length,
                  itemBuilder: (context, index) {
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(likes[index]).get(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox();
                        var data = snapshot.data!.data() as Map<String, dynamic>?;
                        String name = data?['email']?.split('@')[0] ?? 'Unknown';
                        
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey[200],
                            child: Text(name[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- 3. SHOW COMMENTS ---
  void _showCommentsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => CommentsSheet(postId: widget.doc.id),
    );
  }

  // --- 4. DELETE POST ---
  Future<void> _deletePost() async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;

    if (confirm) {
      await FirebaseFirestore.instance.collection('posts').doc(widget.doc.id).delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> data = widget.doc.data() as Map<String, dynamic>;
    String postUid = data['uid'] ?? '';
    String imageUrl = data['imageUrl'] ?? '';
    String caption = data['caption'] ?? '';
    List likes = data['likes'] ?? [];
    Timestamp? timestamp = data['timestamp'];

    bool isLiked = currentUser != null && likes.contains(currentUser!.uid);
    bool isMyPost = currentUser != null && currentUser!.uid == postUid;

    String timeAgo = timestamp != null 
        ? DateFormat('MMM d, h:mm a').format(timestamp.toDate()) 
        : 'Just now';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
      elevation: 1,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade50,
              child: const Icon(Icons.person, color: Colors.blue),
            ),
            title: FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(postUid).get(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.exists) {
                   var userData = snapshot.data!.data() as Map<String, dynamic>;
                   return Text(userData['email']?.split('@')[0] ?? 'Student', style: const TextStyle(fontWeight: FontWeight.bold));
                }
                return const Text('Loading...');
              },
            ),
            subtitle: Text(timeAgo, style: const TextStyle(fontSize: 12)),
            trailing: isMyPost
                ? IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: _deletePost)
                : null,
          ),

          // IMAGE
          if (imageUrl.isNotEmpty)
            GestureDetector(
              onDoubleTap: _toggleLike,
              child: Image.network(imageUrl, fit: BoxFit.fitWidth, width: double.infinity),
            ),

          // BUTTONS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
            child: Row(
              children: [
                InkWell(
                  onTap: _toggleLike,
                  child: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Colors.red : Colors.black,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                InkWell(
                  onTap: _showCommentsModal,
                  child: const Icon(Icons.chat_bubble_outline, size: 26),
                ),
              ],
            ),
          ),

          // --- INSTAGRAM STYLE "LIKED BY" ---
          if (likes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: FutureBuilder<DocumentSnapshot>(
                // Fetch name of the LAST person who liked (most recent)
                future: FirebaseFirestore.instance.collection('users').doc(likes.last).get(),
                builder: (context, snapshot) {
                  String likerName = "Someone";
                  if (snapshot.hasData && snapshot.data!.exists) {
                    var userData = snapshot.data!.data() as Map<String, dynamic>;
                    likerName = userData['email']?.split('@')[0] ?? 'Someone';
                  }

                  return RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.black, fontSize: 14),
                      children: [
                        const TextSpan(text: "Liked by "),
                        TextSpan(
                          text: likerName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (likes.length > 1) ...[
                          const TextSpan(text: " and "),
                          TextSpan(
                            text: "others",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            // THIS MAKES "others" CLICKABLE
                            recognizer: TapGestureRecognizer()..onTap = () => _showLikersList(likes),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),

          // CAPTION
          if (caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 16),
              child: _buildCaption(caption),
            ),
        ],
      ),
    );
  }

  Widget _buildCaption(String text) {
    const int truncateLength = 60;
    if (text.length <= truncateLength || isExpanded) {
      return Text(text, style: const TextStyle(fontSize: 15));
    } else {
      return RichText(
        text: TextSpan(
          text: text.substring(0, truncateLength),
          style: const TextStyle(color: Colors.black, fontSize: 15),
          children: [
            const TextSpan(text: '... '),
            TextSpan(
              text: 'more',
              style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
              recognizer: TapGestureRecognizer()..onTap = () {
                setState(() => isExpanded = true);
              },
            ),
          ],
        ),
      );
    }
  }
}

// --- COMMENTS SHEET ---
class CommentsSheet extends StatefulWidget {
  final String postId;
  const CommentsSheet({super.key, required this.postId});

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final TextEditingController _commentController = TextEditingController();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty || currentUser == null) return;

    String commentText = _commentController.text.trim();
    _commentController.clear();

    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).get();
    String userName = (userDoc.data() as Map<String, dynamic>)['email']?.split('@')[0] ?? 'Anonymous';

    await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .add({
          'text': commentText,
          'uid': currentUser!.uid,
          'userName': userName,
          'timestamp': FieldValue.serverTimestamp(),
        });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(height: 5, width: 40, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 10),
          const Text("Comments", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Divider(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .doc(widget.postId)
                  .collection('comments')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No comments yet."));
                }
                return ListView(
                  children: snapshot.data!.docs.map((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.grey[200],
                        child: Text(data['userName'][0].toUpperCase(), style: const TextStyle(fontSize: 12)),
                      ),
                      title: Text(data['userName'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text(data['text']),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: "Add a comment...",
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: _postComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}