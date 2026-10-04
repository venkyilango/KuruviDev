import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'group_chat_page.dart';

class GroupDetailsPage extends StatefulWidget {
  final String groupId;
  final Map<String, dynamic> groupData;

  const GroupDetailsPage({
    super.key,
    required this.groupId,
    required this.groupData,
  });

  @override
  State<GroupDetailsPage> createState() => _GroupDetailsPageState();
}

class _GroupDetailsPageState extends State<GroupDetailsPage> {
  bool _isJoining = false;
  bool _isLeaving = false;
  bool _isDeleting = false;

  static const List<String> _months = [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  bool get _isMember {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final participants = widget.groupData['participants'] as List? ?? [];
    return participants.contains(uid);
  }

  Future<void> _joinGroup() async {
    if (_isJoining) return;
    setState(() => _isJoining = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance
          .collection('travel_groups')
          .doc(widget.groupId)
          .update({
        'participants': FieldValue.arrayUnion([uid]),
      });

      // Update local data so button changes
      (widget.groupData['participants'] as List).add(uid);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => GroupChatPage(
              groupId: widget.groupId,
              groupData: widget.groupData,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to join group")),
        );
      }
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  void _goToGroup() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GroupChatPage(
          groupId: widget.groupId,
          groupData: widget.groupData,
        ),
      ),
    );
  }

  bool get _isCreator {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return widget.groupData['createdBy'] == uid;
  }

  Future<void> _leaveGroup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Leave Group"),
        content: const Text("Are you sure you want to leave this group?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Leave", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLeaving = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance
          .collection('travel_groups')
          .doc(widget.groupId)
          .update({
        'participants': FieldValue.arrayRemove([uid]),
      });

      (widget.groupData['participants'] as List).remove(uid);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("You left the group"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to leave group")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLeaving = false);
    }
  }

  Future<void> _deleteGroup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Group"),
        content: const Text(
          "This will permanently delete the group and all its messages. This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);

    try {
      final groupRef = FirebaseFirestore.instance
          .collection('travel_groups')
          .doc(widget.groupId);

      // Delete messages subcollection
      final messages = await groupRef.collection('messages').get();
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in messages.docs) {
        batch.delete(doc.reference);
      }

      // Delete reports subcollection
      final reports = await groupRef.collection('reports').get();
      for (final doc in reports.docs) {
        batch.delete(doc.reference);
      }

      // Delete the group document
      batch.delete(groupRef);
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Group deleted"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to delete group")),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  int? _calculateAge(dynamic dob) {
    if (dob == null) return null;

    DateTime? birthDate;

    if (dob is Timestamp) {
      birthDate = dob.toDate();
    } else if (dob is String) {
      try {
        birthDate = DateTime.parse(dob);
      } catch (_) {
        try {
          final parts = dob.split('/');
          if (parts.length == 3) {
            final month = int.parse(parts[0]);
            final day = int.parse(parts[1]);
            final year = int.parse(parts[2]);
            birthDate = DateTime(year, month, day);
          }
        } catch (_) {
          return null;
        }
      }
    } else if (dob is DateTime) {
      birthDate = dob;
    }

    if (birthDate == null) return null;

    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Group Details"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTravelInformation(),
                    const SizedBox(height: 20),
                    _buildGroupDetails(),
                    const SizedBox(height: 20),
                    _buildPreferences(),
                    const SizedBox(height: 20),
                    _buildCreatorInformation(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
          _buildBottomButton(),
        ],
      ),
    );
  }

  Widget _buildTravelInformation() {
    final String from = widget.groupData['fromLocation'] ?? "";
    final String to = widget.groupData['toLocation'] ?? "";
    final int monthIdx = (widget.groupData['month'] as int? ?? 0).clamp(0, 12);
    final month = _months[monthIdx];
    final year = widget.groupData['year'] ?? '';

    return _buildSection(
      icon: Icons.flight_takeoff,
      title: "Travel Information",
      child: Column(
        children: [
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoBox(label: "From", value: from),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Icon(Icons.arrow_forward, color: Color(0xFF3E729F)),
              ),
              Expanded(
                child: _buildInfoBox(label: "To", value: to),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow("Travel Period", "$month $year"),
        ],
      ),
    );
  }

  Widget _buildGroupDetails() {
    final participants = widget.groupData['participants'] as List? ?? [];
    final memberCount = participants.length;
    final createdAt = widget.groupData['createdAt'];
    String createdDate = "";
    if (createdAt is Timestamp) {
      final dt = createdAt.toDate();
      createdDate = "${dt.day}/${dt.month}/${dt.year}";
    }

    return _buildSection(
      icon: Icons.groups,
      title: "Group Details",
      child: Column(
        children: [
          const SizedBox(height: 12),
          _buildInfoRow(
            "Members",
            "$memberCount member${memberCount == 1 ? '' : 's'}",
          ),
          if (createdDate.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildInfoRow("Created", createdDate),
          ],
        ],
      ),
    );
  }

  Widget _buildPreferences() {
    final List<String> languages =
        (widget.groupData['preferredLanguages'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    if (languages.isEmpty) return const SizedBox.shrink();

    return _buildSection(
      icon: Icons.language,
      title: "Preferences",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(
            "Preferred Languages",
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: languages.map((lang) {
              return Chip(
                label: Text(lang, style: const TextStyle(fontSize: 12)),
                backgroundColor: const Color(0xFFEAF2FA),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCreatorInformation() {
    final String creatorId = widget.groupData['createdBy'] ?? "";
    if (creatorId.isEmpty) return const SizedBox.shrink();

    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection('users').doc(creatorId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final user = snapshot.data?.data() as Map<String, dynamic>?;
        final String username = user?['username'] ?? "User";
        final String initial =
            username.isNotEmpty ? username[0].toUpperCase() : "U";

        String age = "";
        if (user?['age'] != null) {
          age = user!['age'].toString();
        }
        if (age.isEmpty) {
          final calculated =
              _calculateAge(user?['dob']) ?? _calculateAge(user?['dateOfBirth']);
          if (calculated != null) age = calculated.toString();
        }

        return _buildSection(
          icon: Icons.person_outline,
          title: "Creator Information",
          child: Column(
            children: [
              const SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFFFF1493),
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        age.isNotEmpty
                            ? "Age: $age years"
                            : "Age: Not specified",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3E729F),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _isJoining
                  ? null
                  : (_isMember ? _goToGroup : _joinGroup),
              child: _isJoining
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      _isMember ? "Take me to Group" : "Join Group",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        letterSpacing: 1,
                      ),
                    ),
            ),
          ),
          if (_isMember && !_isCreator) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: TextButton(
                onPressed: _isLeaving ? null : _leaveGroup,
                child: _isLeaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        "Leave Group",
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                        ),
                      ),
              ),
            ),
          ],
          if (_isCreator) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: TextButton(
                onPressed: _isDeleting ? null : _deleteGroup,
                child: _isDeleting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
                      )
                    : const Text(
                        "Delete Group",
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                        ),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Shared UI helpers ──────────────────────────────────────────────────

  Widget _buildSection({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF3E729F)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoBox({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ],
    );
  }
}
