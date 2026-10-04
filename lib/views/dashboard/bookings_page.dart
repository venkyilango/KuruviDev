import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:travel/views/service_details_page.dart';
import 'package:travel/views/chat_page.dart';
import 'package:travel/views/group_details_page.dart';

class BookingsPage extends StatefulWidget {
  const BookingsPage({super.key});

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Tab Bar with notification badge
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(25),
              ),
              child: StreamBuilder<QuerySnapshot>(
                stream: uid != null
                    ? FirebaseFirestore.instance
                        .collection('booking_requests')
                        .where('adOwnerId', isEqualTo: uid)
                        .where('status', isEqualTo: 'pending')
                        .snapshots()
                    : null,
                builder: (context, snapshot) {
                  final pendingCount = snapshot.hasData ? snapshot.data!.docs.length : 0;

                  return TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          spreadRadius: 1,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: const Color(0xFF3E729F),
                    unselectedLabelColor: Colors.grey,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                    tabs: [
                      const Tab(
                        height: 40,
                        text: "My Bookings",
                      ),
                      Tab(
                        height: 40,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text("My Posts"),
                            if (pendingCount > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$pendingCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Tab Bar View
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  _MyBookingsTab(),
                  _MyPostsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// My Bookings Tab - Shows connection requests sent by the current user
class _MyBookingsTab extends StatelessWidget {
  const _MyBookingsTab();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Center(child: Text("Please login to view your bookings"));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('booking_requests')
          .where('requesterId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_border,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    "No Bookings Yet",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Book a service from a travel ad and it will appear here",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final requests = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final requestDoc = requests[index];
            final requestData = requestDoc.data() as Map<String, dynamic>;
            final adId = requestData['adId'] ?? "";

            return _BookingCard(
              requestId: requestDoc.id,
              requestData: requestData,
              adId: adId,
            );
          },
        );
      },
    );
  }
}

// Booking Card - Shows connection request details with ad information
class _BookingCard extends StatelessWidget {
  final String requestId;
  final Map<String, dynamic> requestData;
  final String adId;

  const _BookingCard({
    required this.requestId,
    required this.requestData,
    required this.adId,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('travel_ads').doc(adId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final adData = snapshot.data!.data() as Map<String, dynamic>?;

        // Handle deleted ad
        if (adData == null) {
          return _buildDeletedAdCard(context);
        }

        // Check if user is connected with ad owner
        final adOwnerId = adData['userId'] ?? "";

        final String from = adData['fromLocation'] ?? "";
        final String to = adData['toLocation'] ?? "";
        final String service = adData['service'] ?? "";
        final String price = adData['price'] ?? "";
        final String dateText = adData['travelDate'] ?? "${adData['fromDate']} - ${adData['toDate']}";

        final String status = requestData['status'] ?? 'pending';
        final Timestamp? createdAt = requestData['createdAt'];
        final String sentOn = createdAt != null
            ? DateFormat("dd MMM yyyy").format(createdAt.toDate())
            : "";

        // Status badge
        Color statusColor;
        String statusText;
        IconData statusIcon;

        switch (status) {
          case 'accepted':
            statusText = "Accepted";
            statusColor = Colors.green;
            statusIcon = Icons.check_circle;
            break;
          case 'rejected':
            statusText = "Declined";
            statusColor = Colors.red;
            statusIcon = Icons.cancel;
            break;
          default:
            statusText = "Pending";
            statusColor = Colors.orange;
            statusIcon = Icons.pending;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ServiceDetailsPage(
                    adId: adId,
                    data: adData,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Route + Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          "$from → $to",
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: statusColor),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 14, color: statusColor),
                            const SizedBox(width: 4),
                            Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),
                  Text(
                    "Travel on: $dateText",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),

                  const Divider(height: 20),

                  // Service Type + Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            service == "Travel Partner" ? Icons.people : Icons.inventory_2,
                            size: 16,
                            color: const Color(0xFF3E729F),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            service,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        "USD $price",
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3E729F),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Message sent (if any)
                  if (requestData['message'] != null && requestData['message'].toString().isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.message, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              requestData['message'],
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Sent on $sentOn",
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                      if (status == 'pending')
                        TextButton(
                          onPressed: () => _showCancelDialog(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: const Size(0, 0),
                          ),
                          child: const Text(
                            "Cancel Booking",
                            style: TextStyle(fontSize: 11, color: Colors.red),
                          ),
                        ),
                      if (status == 'accepted')
                        ElevatedButton.icon(
                          onPressed: () async {
                            // Fetch ad owner's username
                            final ownerDoc = await FirebaseFirestore.instance
                                .collection('users')
                                .doc(adOwnerId)
                                .get();
                            final ownerName = ownerDoc.data()?['username'] ?? 'User';

                            if (context.mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatPage(
                                    otherUserId: adOwnerId,
                                    otherUserName: ownerName,
                                  ),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.chat_bubble_outline, size: 14),
                          label: const Text(
                            "Chat",
                            style: TextStyle(fontSize: 11),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3E729F),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            minimumSize: const Size(0, 0),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDeletedAdCard(BuildContext context) {
    final String status = requestData['status'] ?? 'pending';
    final Timestamp? createdAt = requestData['createdAt'];
    final String sentOn = createdAt != null
        ? DateFormat("dd MMM yyyy").format(createdAt.toDate())
        : "";

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      color: Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Travel Ad Deleted",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "This travel ad is no longer available",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "The traveler may have removed their post. Your connection request ($status) is still stored.",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Sent on $sentOn",
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                TextButton.icon(
                  onPressed: () => _deleteConnectionRequest(context),
                  icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                  label: const Text(
                    "Remove",
                    style: TextStyle(fontSize: 11, color: Colors.red),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: const Size(0, 0),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteConnectionRequest(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('booking_requests')
          .doc(requestId)
          .delete();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Connection request removed")),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error removing request: $e")),
        );
      }
    }
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cancel Request"),
        content: const Text("Are you sure you want to cancel this connection request?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('booking_requests')
                    .doc(requestId)
                    .delete();

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Connection request cancelled")),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error cancelling request: $e")),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Yes, Cancel"),
          ),
        ],
      ),
    );
  }
}

// My Posts Tab - Shows all posts created by the current user
class _MyPostsTab extends StatelessWidget {
  const _MyPostsTab();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Center(child: Text("Please login to view your posts"));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('travel_ads')
          .where('userId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, adsSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('travel_groups')
              .where('createdBy', isEqualTo: uid)
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, groupsSnapshot) {
            if (adsSnapshot.connectionState == ConnectionState.waiting &&
                groupsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final adDocs = adsSnapshot.data?.docs ?? [];
            final groupDocs = groupsSnapshot.data?.docs ?? [];

            if (adDocs.isEmpty && groupDocs.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_circle_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        "No Posts Yet",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Create your first travel ad to get started!",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            // Merge ads and groups into a single list sorted by createdAt
            final List<Map<String, dynamic>> items = [];
            for (final doc in adDocs) {
              final data = doc.data() as Map<String, dynamic>;
              items.add({'type': 'ad', 'id': doc.id, 'data': data, 'createdAt': data['createdAt'] as Timestamp?});
            }
            for (final doc in groupDocs) {
              final data = doc.data() as Map<String, dynamic>;
              items.add({'type': 'group', 'id': doc.id, 'data': data, 'createdAt': data['createdAt'] as Timestamp?});
            }
            items.sort((a, b) {
              final aTs = a['createdAt'] as Timestamp?;
              final bTs = b['createdAt'] as Timestamp?;
              if (aTs == null && bTs == null) return 0;
              if (aTs == null) return 1;
              if (bTs == null) return -1;
              return bTs.compareTo(aTs);
            });

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                if (item['type'] == 'group') {
                  return _MyGroupPostCard(
                    groupId: item['id'],
                    data: item['data'],
                  );
                }
                return _PostCard(
                  adId: item['id'],
                  data: item['data'],
                );
              },
            );
          },
        );
      },
    );
  }
}

class _PostCard extends StatelessWidget {
  final String adId;
  final Map<String, dynamic> data;

  const _PostCard({
    required this.adId,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final String from = data['fromLocation'] ?? "";
    final String to = data['toLocation'] ?? "";
    final String service = data['service'] ?? "";
    final String price = data['price'] ?? "";

    final parcelType = (data['parcelType'] as String?)?.toLowerCase();
    final companionType = (data['travelPartnerType'] as String?)?.toLowerCase().trim();

    String _parcelLabel(String? type) {
      switch (type) {
        case "carry":
          return "📦 Carry Parcel";
        case "receive":
          return "📥 Receive Parcel";
        default:
          return "📦 Parcel Service";
      }
    }

    String _companionLabel(String? type) {
      if (type == null) return "🤝 Travel Companion";
      if (type.contains("offer")) return "🤝 Be a Companion";
      if (type.contains("look")) return "🔍 Looking for a Companion";
      return "🤝 Travel Companion";
    }

    final String dateText = data['travelDate'] ?? "${data['fromDate']} - ${data['toDate']}";

    final Timestamp? createdAt = data['createdAt'];
    final String postedOn = createdAt != null
        ? DateFormat("dd MMM yyyy").format(createdAt.toDate())
        : "";

    // Status badge
    final int status = data['status'] ?? 0;
    String statusText = "";
    Color statusColor = Colors.green;

    switch (status) {
      case 0:
        statusText = "Active";
        statusColor = Colors.green;
        break;
      case 1:
        statusText = "Completed";
        statusColor = Colors.blue;
        break;
      case 2:
        statusText = "Cancelled";
        statusColor = Colors.red;
        break;
      default:
        statusText = "Active";
        statusColor = Colors.green;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ServiceDetailsPage(
                adId: adId,
                data: data,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Route + Price + Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    "$from → $to",
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "USD $price",
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3E729F),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    "Travel on: $dateText",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ),
                Row(
                  children: [
                    // Pending requests notification badge
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('booking_requests')
                          .where('adId', isEqualTo: adId)
                          .where('status', isEqualTo: 'pending')
                          .snapshots(),
                      builder: (context, snapshot) {
                        final pendingCount = snapshot.hasData ? snapshot.data!.docs.length : 0;

                        if (pendingCount > 0) {
                          return Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.orange),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.notifications_active, size: 12, color: Colors.orange.shade700),
                                const SizedBox(width: 4),
                                Text(
                                  '$pendingCount pending',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange.shade700,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const Divider(height: 20),

            // Title / Description
            Text(
              service == "Travel Partner"
                  ? _companionLabel(companionType)
                  : _parcelLabel(parcelType),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 4),
            Text(
              service == "Travel Partner"
                  ? (companionType == "be_companion"
                      ? "Available to accompany fellow travelers"
                      : "Searching for someone to travel with")
                  : (parcelType == "carry"
                      ? "Willing to carry parcels securely"
                      : "Need a trusted person to receive a parcel"),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),

            const SizedBox(height: 10),

            // Tags
            Wrap(
              spacing: 8,
              children: [
                _tag(service),
                if (data['partners'] != null && data['partners'].toString().isNotEmpty)
                  _tag("No. of Partners: upto ${data['partners']}"),
                if (data['parcelWeight'] != null && data['parcelWeight'].toString().isNotEmpty)
                  _tag("Weight: ${data['parcelWeight']} KG"),
              ],
            ),

            const SizedBox(height: 10),

            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Posted on $postedOn",
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                Row(
                  children: [
                    // IconButton(
                    //   icon: const Icon(Icons.edit, size: 20),
                    //   color: const Color(0xFF3E729F),
                    //   onPressed: () {
                    //     // TODO: Implement edit functionality
                    //     ScaffoldMessenger.of(context).showSnackBar(
                    //       const SnackBar(content: Text("Edit functionality coming soon")),
                    //     );
                    //   },
                    // ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      color: Colors.red,
                      onPressed: () {
                        // TODO: Implement delete functionality
                        _showDeleteDialog(context);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Post"),
        content: const Text("Are you sure you want to delete this travel ad?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              try {
                // Delete associated booking requests
                final bookingRequests = await FirebaseFirestore.instance
                    .collection('booking_requests')
                    .where('adId', isEqualTo: adId)
                    .get();
                final batch = FirebaseFirestore.instance.batch();
                for (final doc in bookingRequests.docs) {
                  batch.delete(doc.reference);
                }
                // Delete the ad itself
                batch.delete(FirebaseFirestore.instance
                    .collection('travel_ads')
                    .doc(adId));
                await batch.commit();

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Post deleted successfully"),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Error deleting post: $e"),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  Widget _tag(String text) {
    return Chip(
      label: Text(text, style: const TextStyle(fontSize: 11)),
      backgroundColor: const Color(0xFFEAF2FA),
    );
  }
}

class _MyGroupPostCard extends StatelessWidget {
  final String groupId;
  final Map<String, dynamic> data;

  const _MyGroupPostCard({required this.groupId, required this.data});

  static const List<String> _months = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String _shortLocation(String value) {
    final idx = value.indexOf(' - ');
    if (idx == 3) return value.substring(0, 3);
    return value;
  }

  @override
  Widget build(BuildContext context) {
    final String from = data['fromLocation'] ?? '';
    final String to = data['toLocation'] ?? '';
    final int monthIdx = (data['month'] as int? ?? 0).clamp(0, 12);
    final month = _months[monthIdx];
    final year = data['year'] ?? '';
    final memberCount = (data['participants'] as List?)?.length ?? 0;
    final description = data['description'] as String? ?? '';
    final Timestamp? createdAt = data['createdAt'];
    final String postedOn = createdAt != null
        ? DateFormat("dd MMM yyyy").format(createdAt.toDate())
        : "";

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GroupDetailsPage(
                groupId: groupId,
                groupData: data,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: const BoxDecoration(
                color: Color(0xFF3E729F),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.groups, size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                  const Text(
                    "Group Trip",
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Text(
                    "$memberCount member${memberCount == 1 ? '' : 's'}",
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          "${_shortLocation(from)} → ${_shortLocation(to)}",
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "$month $year",
                        style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF3E729F)),
                      ),
                    ],
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Posted on $postedOn",
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          "Active",
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.green),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
