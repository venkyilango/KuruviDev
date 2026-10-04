import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class GroupChatPage extends StatefulWidget {
  final String groupId;
  final Map<String, dynamic> groupData;

  const GroupChatPage({
    super.key,
    required this.groupId,
    required this.groupData,
  });

  @override
  State<GroupChatPage> createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  String _currentUserId = '';
  List<String> _restrictedUsers = [];
  StreamSubscription? _groupSub;

  static const List<String> _months = [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    _markAsRead();
    _groupSub = FirebaseFirestore.instance
        .collection('travel_groups')
        .doc(widget.groupId)
        .snapshots()
        .listen((snap) {
      if (mounted) {
        setState(() {
          _restrictedUsers = List<String>.from(
              snap.data()?['restrictedUsers'] ?? []);
        });
      }
    });
  }

  void _markAsRead() {
    if (_currentUserId.isEmpty) return;
    FirebaseFirestore.instance
        .collection('travel_groups')
        .doc(widget.groupId)
        .update({'lastReadTime.$_currentUserId': FieldValue.serverTimestamp()});
  }

  @override
  void dispose() {
    _groupSub?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String get _groupTitle {
    final from = _shortLocation(widget.groupData['fromLocation'] ?? '');
    final to = _shortLocation(widget.groupData['toLocation'] ?? '');
    final month = _months[widget.groupData['month'] ?? 0];
    final year = widget.groupData['year'] ?? '';
    return '$from → $to · $month $year';
  }

  static String _shortLocation(String value) {
    final idx = value.indexOf(' - ');
    if (idx == 3) return value.substring(0, 3);
    return value;
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUserId)
        .get();
    final senderName =
        (userDoc.data()?['username'] as String?) ?? 'User';

    final batch = FirebaseFirestore.instance.batch();

    final msgRef = FirebaseFirestore.instance
        .collection('travel_groups')
        .doc(widget.groupId)
        .collection('messages')
        .doc();

    batch.set(msgRef, {
      'text': text,
      'senderId': _currentUserId,
      'senderName': senderName,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final groupRef = FirebaseFirestore.instance
        .collection('travel_groups')
        .doc(widget.groupId);

    batch.update(groupRef, {
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showReportDialog(String targetUserId, String targetUserName) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Report User"),
        content: Text("Report $targetUserName from this group?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _reportUser(targetUserId, targetUserName);
            },
            child: const Text("Report",
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _reportUser(
      String reportedUserId, String reportedUserName) async {
    final reportsRef = FirebaseFirestore.instance
        .collection('travel_groups')
        .doc(widget.groupId)
        .collection('reports');

    // Prevent duplicate reports from the same reporter
    final existing = await reportsRef
        .where('reportedUserId', isEqualTo: reportedUserId)
        .where('reporterUserId', isEqualTo: _currentUserId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("You have already reported this user")),
        );
      }
      return;
    }

    await reportsRef.add({
      'reportedUserId': reportedUserId,
      'reporterUserId': _currentUserId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Count distinct reporters for the reported user
    final allReports = await reportsRef
        .where('reportedUserId', isEqualTo: reportedUserId)
        .get();

    final distinctReporters = allReports.docs
        .map((d) => d.data()['reporterUserId'] as String)
        .toSet();

    if (distinctReporters.length >= 5) {
      await FirebaseFirestore.instance
          .collection('travel_groups')
          .doc(widget.groupId)
          .update({
        'restrictedUsers': FieldValue.arrayUnion([reportedUserId]),
      });
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$reportedUserName has been reported")),
      );
    }
  }

  bool get _isCreator {
    return widget.groupData['createdBy'] == _currentUserId;
  }

  Future<void> _blockUser(String userId, String userName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Block User"),
        content: Text(
          "Block $userName? They will be removed from the group and restricted from sending messages.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Block", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('travel_groups')
          .doc(widget.groupId)
          .update({
        'restrictedUsers': FieldValue.arrayUnion([userId]),
        'participants': FieldValue.arrayRemove([userId]),
      });

      (widget.groupData['participants'] as List).remove(userId);

      if (mounted) {
        Navigator.pop(context); // close bottom sheet
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("$userName has been blocked"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to block user")),
        );
      }
    }
  }

  Future<void> _unblockUser(String userId, String userName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Unblock User"),
        content: Text("Unblock $userName? They will be able to rejoin the group."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3E729F)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Unblock", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('travel_groups')
          .doc(widget.groupId)
          .update({
        'restrictedUsers': FieldValue.arrayRemove([userId]),
      });

      if (mounted) {
        Navigator.pop(context); // close bottom sheet
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("$userName has been unblocked"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to unblock user")),
        );
      }
    }
  }

  void _showParticipants() async {
    final participants = List<String>.from(
        widget.groupData['participants'] ?? []);
    final blockedUsers = List<String>.from(_restrictedUsers);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Members (${participants.length})",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  ...participants.map((memberId) {
                    final isMe = memberId == _currentUserId;
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(memberId)
                          .get(),
                      builder: (_, snap) {
                        final name = snap.hasData
                            ? ((snap.data!.data()
                                    as Map<String, dynamic>?)?['username']
                                as String? ??
                                'User')
                            : 'Loading...';
                        final initial =
                            name.isNotEmpty ? name[0].toUpperCase() : 'U';
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFEAF2FA),
                            child: Text(initial,
                                style: const TextStyle(
                                    color: Color(0xFF3E729F),
                                    fontWeight: FontWeight.w600)),
                          ),
                          title: Text(name),
                          trailing: (_isCreator && !isMe)
                              ? IconButton(
                                  icon: const Icon(Icons.block, color: Colors.red, size: 20),
                                  tooltip: "Block user",
                                  onPressed: () => _blockUser(memberId, name),
                                )
                              : null,
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        );
                      },
                    );
                  }),
                  if (_isCreator && blockedUsers.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      "Blocked Users (${blockedUsers.length})",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...blockedUsers.map((userId) {
                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(userId)
                            .get(),
                        builder: (_, snap) {
                          final name = snap.hasData
                              ? ((snap.data!.data()
                                      as Map<String, dynamic>?)?['username']
                                  as String? ??
                                  'User')
                              : 'Loading...';
                          final initial =
                              name.isNotEmpty ? name[0].toUpperCase() : 'U';
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.red.shade50,
                              child: Text(initial,
                                  style: const TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.w600)),
                            ),
                            title: Text(
                              name,
                              style: const TextStyle(
                                color: Colors.red,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            trailing: TextButton(
                              onPressed: () => _unblockUser(userId, name),
                              child: const Text(
                                "Unblock",
                                style: TextStyle(
                                  color: Color(0xFF3E729F),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          );
                        },
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _groupTitle,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('travel_groups')
                  .doc(widget.groupId)
                  .snapshots(),
              builder: (_, snap) {
                final data =
                    snap.data?.data() as Map<String, dynamic>?;
                final participants =
                    List<String>.from(data?['participants'] ?? []);
                final count = participants.length;
                final isMember = participants.contains(_currentUserId);
                return Row(
                  children: [
                    Text(
                      "$count member${count == 1 ? '' : 's'}",
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.normal),
                    ),
                    if (isMember) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3E729F),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          "✓ Member",
                          style: TextStyle(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.people_outline),
            onPressed: _showParticipants,
            tooltip: "View members",
          ),
        ],
      ),
      body: Column(
        children: [
          // Group info banner
          Container(
            width: double.infinity,
            color: const Color(0xFFEAF2FA),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.flight, size: 14, color: Color(0xFF3E729F)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "${widget.groupData['fromLocation'] ?? ''} → ${widget.groupData['toLocation'] ?? ''}",
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF3E729F)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Messages
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('travel_groups')
                  .doc(widget.groupId)
                  .collection('messages')
                  .orderBy('createdAt', descending: false)
                  .snapshots(),
              builder: (_, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text("Be the first to say hello!",
                            style: TextStyle(color: Colors.grey.shade500)),
                      ],
                    ),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(
                        _scrollController.position.maxScrollExtent);
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final msg =
                        docs[i].data() as Map<String, dynamic>;
                    final isMe = msg['senderId'] == _currentUserId;
                    final createdAt = msg['createdAt'] as Timestamp?;
                    final time = createdAt != null
                        ? DateFormat('HH:mm').format(createdAt.toDate())
                        : '';

                    return _buildMessageBubble(
                      text: msg['text'] ?? '',
                      senderId: msg['senderId'] ?? '',
                      senderName: msg['senderName'] ?? 'User',
                      time: time,
                      isMe: isMe,
                    );
                  },
                );
              },
            ),
          ),

          // Input
          _restrictedUsers.contains(_currentUserId)
              ? Container(
                  width: double.infinity,
                  color: Colors.red.shade50,
                  padding: const EdgeInsets.all(16),
                  child: const Text(
                    "You have been restricted from sending messages in this group.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red, fontSize: 13),
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.15),
                        blurRadius: 6,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              hintText: "Type a message...",
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: const BorderSide(
                                    color: Color(0xFF3E729F)),
                              ),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _sendMessage,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: Color(0xFF3E729F),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.send,
                                color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble({
    required String text,
    required String senderId,
    required String senderName,
    required String time,
    required bool isMe,
  }) {
    final bubble = Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 2),
              child: Text(
                senderName,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3E729F)),
              ),
            ),
          Row(
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe)
                CircleAvatar(
                  radius: 14,
                  backgroundColor: const Color(0xFFEAF2FA),
                  child: Text(
                    senderName.isNotEmpty
                        ? senderName[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF3E729F),
                        fontWeight: FontWeight.w600),
                  ),
                ),
              if (!isMe) const SizedBox(width: 6),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe
                        ? const Color(0xFF3E729F)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: isMe
                          ? const Radius.circular(16)
                          : const Radius.circular(4),
                      bottomRight: isMe
                          ? const Radius.circular(4)
                          : const Radius.circular(16),
                    ),
                  ),
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 14,
                      color: isMe ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ),
              if (isMe) const SizedBox(width: 6),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(
                left: isMe ? 0 : 34,
                right: isMe ? 0 : 0,
                top: 2),
            child: Text(
              time,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            ),
          ),
        ],
      ),
    );

    if (isMe) return bubble;

    return GestureDetector(
      onLongPress: () => _showReportDialog(senderId, senderName),
      child: bubble,
    );
  }
}
