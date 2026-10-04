import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatPage extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;

  const ChatPage({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _chatId;
  bool _isBlocked = false;
  bool _isBlockedByOther = false;

  // Pagination variables
  static const int _messagesPerPage = 50;
  DocumentSnapshot? _lastDocument;
  bool _hasMoreMessages = true;
  bool _isLoadingMore = false;
  final List<DocumentSnapshot> _messages = [];

  @override
  void initState() {
    super.initState();
    _initializeChat();
    _checkBlockStatus();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  // Listen for scroll to top to load more messages
  void _scrollListener() {
    if (_scrollController.position.pixels <= 100 &&
        !_isLoadingMore &&
        _hasMoreMessages) {
      _loadMoreMessages();
    }
  }

  Future<void> _initializeChat() async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final participants = [currentUserId, widget.otherUserId]..sort();
    final chatId = participants.join('_');

    setState(() {
      _chatId = chatId;
    });

    // Create chat document if it doesn't exist
    final chatDoc = await FirebaseFirestore.instance.collection('chats').doc(chatId).get();
    if (!chatDoc.exists) {
      await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
        'participants': participants,
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    _markMessagesAsRead(chatId, currentUserId);
  }

  Future<void> _markMessagesAsRead(String chatId, String currentUserId) async {
    final unread = await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('senderId', isNotEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .get();

    if (unread.docs.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> _checkBlockStatus() async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    // Check if current user blocked the other user
    final blockedByMe = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('blocked_users')
        .doc(widget.otherUserId)
        .get();

    // Check if other user blocked current user
    final blockedByOther = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.otherUserId)
        .collection('blocked_users')
        .doc(currentUserId)
        .get();

    setState(() {
      _isBlocked = blockedByMe.exists;
      _isBlockedByOther = blockedByOther.exists;
    });
  }

  // Load older messages (pagination)
  Future<void> _loadMoreMessages() async {
    if (_chatId == null || _isLoadingMore || !_hasMoreMessages) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      Query query = FirebaseFirestore.instance
          .collection('chats')
          .doc(_chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(_messagesPerPage);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        setState(() {
          _hasMoreMessages = false;
          _isLoadingMore = false;
        });
        return;
      }

      setState(() {
        _messages.addAll(snapshot.docs);
        _lastDocument = snapshot.docs.last;
        _hasMoreMessages = snapshot.docs.length == _messagesPerPage;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading messages: $e")),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _chatId == null) return;
    if (_isBlocked || _isBlockedByOther) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cannot send messages when blocked")),
      );
      return;
    }

    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final message = _messageController.text.trim();

    _messageController.clear();

    // Add message to subcollection
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(_chatId)
        .collection('messages')
        .add({
      'senderId': currentUserId,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    // Update last message in chat document
    await FirebaseFirestore.instance.collection('chats').doc(_chatId).update({
      'lastMessage': message,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    // Scroll to bottom after sending
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _toggleBlockUser() async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final blockRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('blocked_users')
        .doc(widget.otherUserId);

    if (_isBlocked) {
      // Unblock
      await blockRef.delete();
      setState(() => _isBlocked = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${widget.otherUserName} unblocked")),
        );
      }
    } else {
      // Block
      await blockRef.set({
        'blockedAt': FieldValue.serverTimestamp(),
      });
      setState(() => _isBlocked = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${widget.otherUserName} blocked")),
        );
      }
    }
  }

  void _showBlockDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_isBlocked ? "Unblock User" : "Block User"),
        content: Text(
          _isBlocked
              ? "Are you sure you want to unblock ${widget.otherUserName}?"
              : "Are you sure you want to block ${widget.otherUserName}? You won't be able to send or receive messages from this user.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _toggleBlockUser();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(_isBlocked ? "Unblock" : "Block"),
          ),
        ],
      ),
    );
  }

  Future<void> _showReviewDialog() async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    // Check if user has already reviewed this person
    final existingReviewQuery = await FirebaseFirestore.instance
        .collection('reviews')
        .where('reviewerId', isEqualTo: currentUserId)
        .where('reviewedUserId', isEqualTo: widget.otherUserId)
        .limit(1)
        .get();

    double currentRating = 0;
    String currentComment = '';
    String? existingReviewId;

    if (existingReviewQuery.docs.isNotEmpty) {
      final reviewData = existingReviewQuery.docs.first.data();
      currentRating = (reviewData['rating'] ?? 0).toDouble();
      currentComment = reviewData['comment'] ?? '';
      existingReviewId = existingReviewQuery.docs.first.id;
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        double selectedRating = currentRating;
        final commentController = TextEditingController(text: currentComment);

        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          existingReviewId != null
                              ? "Update Review"
                              : "Rate ${widget.otherUserName}",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // User Info
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: const Color(0xFFEAF2FA),
                          child: Text(
                            widget.otherUserName[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF3E729F),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.otherUserName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Text(
                                "How was your experience?",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // Star Rating
                    const Text(
                      "Rating",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return GestureDetector(
                            onTap: () {
                              setModalState(() {
                                selectedRating = (index + 1).toDouble();
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Icon(
                                index < selectedRating
                                    ? Icons.star
                                    : Icons.star_border,
                                size: 48,
                                color: index < selectedRating
                                    ? Colors.amber
                                    : Colors.grey,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Comment
                    const Text(
                      "Review (Optional)",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: commentController,
                      maxLines: 4,
                      maxLength: 500,
                      decoration: InputDecoration(
                        hintText: "Share your experience with ${widget.otherUserName}...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF3E729F),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: selectedRating > 0
                            ? () {
                                Navigator.pop(context);
                                _submitReview(
                                  selectedRating,
                                  commentController.text.trim(),
                                  existingReviewId,
                                );
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3E729F),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          disabledBackgroundColor: Colors.grey.shade300,
                        ),
                        child: Text(
                          existingReviewId != null
                              ? "Update Review"
                              : "Submit Review",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    // Delete button if updating existing review
                    if (existingReviewId != null) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _showDeleteReviewConfirmation(existingReviewId!);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Delete Review",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _submitReview(double rating, String comment, String? existingReviewId) async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser!.uid;
      final reviewData = {
        'reviewerId': currentUserId,
        'reviewedUserId': widget.otherUserId,
        'rating': rating,
        'comment': comment,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (existingReviewId != null) {
        // Update existing review
        await FirebaseFirestore.instance
            .collection('reviews')
            .doc(existingReviewId)
            .update(reviewData);
      } else {
        // Create new review
        reviewData['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance
            .collection('reviews')
            .add(reviewData);
      }

      // Recalculate and update the user's average rating
      await _updateUserRating(widget.otherUserId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              existingReviewId != null
                  ? "Review updated successfully!"
                  : "Review submitted successfully!",
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error submitting review: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateUserRating(String userId) async {
    try {
      // Get all reviews for this user
      final reviewsSnapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .where('reviewedUserId', isEqualTo: userId)
          .get();

      if (reviewsSnapshot.docs.isEmpty) {
        // No reviews, set rating to 0
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
          'rating': 0,
          'ratingCount': 0,
        });
        return;
      }

      // Calculate average rating
      double totalRating = 0;
      for (var doc in reviewsSnapshot.docs) {
        final data = doc.data();
        totalRating += (data['rating'] ?? 0).toDouble();
      }

      final averageRating = totalRating / reviewsSnapshot.docs.length;
      final ratingCount = reviewsSnapshot.docs.length;

      // Update user's rating
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
        'rating': double.parse(averageRating.toStringAsFixed(1)),
        'ratingCount': ratingCount,
      });
    } catch (e) {
      // Silently fail - rating update is not critical
      debugPrint("Error updating user rating: $e");
    }
  }

  void _showDeleteReviewConfirmation(String reviewId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Review"),
        content: const Text(
          "Are you sure you want to delete your review? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteReview(reviewId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteReview(String reviewId) async {
    try {
      await FirebaseFirestore.instance
          .collection('reviews')
          .doc(reviewId)
          .delete();

      // Recalculate and update the user's average rating
      await _updateUserRating(widget.otherUserId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Review deleted successfully"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error deleting review: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.otherUserName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            if (_isBlocked)
              const Text(
                "Blocked",
                style: TextStyle(fontSize: 12, color: Colors.red),
              ),
            if (_isBlockedByOther)
              const Text(
                "You are blocked",
                style: TextStyle(fontSize: 12, color: Colors.red),
              ),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        actions: [
          // Review/Rating button
          IconButton(
            icon: const Icon(Icons.star_outline),
            tooltip: "Rate User",
            onPressed: _showReviewDialog,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'block') {
                _showBlockDialog();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'block',
                child: Row(
                  children: [
                    Icon(
                      _isBlocked ? Icons.block : Icons.block_outlined,
                      size: 20,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 12),
                    Text(_isBlocked ? "Unblock User" : "Block User"),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: _chatId == null
                ? const Center(child: CircularProgressIndicator())
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('chats')
                        .doc(_chatId)
                        .collection('messages')
                        .orderBy('timestamp', descending: true)
                        .limit(_messagesPerPage)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting && _messages.isEmpty) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "No messages yet",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Start the conversation!",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // Use stream data for real-time updates
                      final recentMessages = snapshot.data!.docs;
                      final currentUserId = FirebaseAuth.instance.currentUser!.uid;

                      // Combine recent messages with loaded older messages
                      final allMessages = <DocumentSnapshot>[];
                      final recentIds = recentMessages.map((doc) => doc.id).toSet();

                      // Add recent messages first
                      allMessages.addAll(recentMessages);

                      // Add older messages that aren't in recent
                      for (var msg in _messages) {
                        if (!recentIds.contains(msg.id)) {
                          allMessages.add(msg);
                        }
                      }

                      // Scroll to bottom on initial load and new messages
                      if (_messages.isEmpty) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (_scrollController.hasClients) {
                            _scrollController.jumpTo(
                              _scrollController.position.maxScrollExtent,
                            );
                          }
                        });
                      }

                      return Column(
                        children: [
                          // Load more indicator
                          if (_isLoadingMore)
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(),
                            ),
                          if (!_hasMoreMessages && allMessages.length > _messagesPerPage)
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                "No more messages",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ),

                          // Messages list (reversed to show oldest at top, newest at bottom)
                          Expanded(
                            child: ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(12),
                              reverse: true, // Show newest at bottom
                              itemCount: allMessages.length,
                              itemBuilder: (context, index) {
                                final messageDoc = allMessages[index];
                                final messageData = messageDoc.data() as Map<String, dynamic>;
                                final senderId = messageData['senderId'] ?? '';
                                final message = messageData['message'] ?? '';
                                final timestamp = messageData['timestamp'] as Timestamp?;
                                final isMe = senderId == currentUserId;

                                return _buildMessageBubble(
                                  message: message,
                                  isMe: isMe,
                                  timestamp: timestamp,
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),

          // Message input
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    enabled: !_isBlocked && !_isBlockedByOther,
                    decoration: InputDecoration(
                      hintText: _isBlocked
                          ? "You blocked this user"
                          : _isBlockedByOther
                              ? "You are blocked"
                              : "Type a message...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: Color(0xFF3E729F)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFF3E729F),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: (_isBlocked || _isBlockedByOther) ? null : _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble({
    required String message,
    required bool isMe,
    required Timestamp? timestamp,
  }) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF3E729F) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 14,
              ),
            ),
            if (timestamp != null) ...[
              const SizedBox(height: 4),
              Text(
                _formatTimestamp(timestamp),
                style: TextStyle(
                  color: isMe ? Colors.white70 : Colors.grey.shade600,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      // Today - show time
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return "$hour:$minute";
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      // Yesterday
      return "Yesterday";
    } else {
      // Older - show date
      return "${dateTime.day}/${dateTime.month}/${dateTime.year}";
    }
  }
}
