import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:travel/views/chat_page.dart';

class ServiceDetailsPage extends StatefulWidget {
  final String adId;
  final Map<String, dynamic> data;

  const ServiceDetailsPage({
    super.key,
    required this.adId,
    required this.data,
  });

  @override
  State<ServiceDetailsPage> createState() => _ServiceDetailsPageState();
}

class _ServiceDetailsPageState extends State<ServiceDetailsPage> {
  bool _isOwner = false;
  String _adOwnerName = "";

  @override
  void initState() {
    super.initState();
    _checkOwnership();
  }

  Future<void> _checkOwnership() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final adOwnerId = widget.data['userId'] as String?;

    // Fetch the ad owner's username for direct chat
    if (adOwnerId != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(adOwnerId)
          .get();
      final name = (doc.data()?['username'] as String?) ?? "Traveler";
      if (mounted) setState(() => _adOwnerName = name);
    }

    if (mounted) {
      setState(() {
        _isOwner = currentUserId == adOwnerId;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Service Details"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTravelInformation(),
              const SizedBox(height: 20),
              _buildAdDetails(),
              const SizedBox(height: 20),
              _buildPreferencesAndPricing(),
              const SizedBox(height: 20),
              _buildTravelerInformation(),
              const SizedBox(height: 20),
              _buildTravelerReviews(),
              const SizedBox(height: 20),
              _buildConnectionSection(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTravelInformation() {
    final String from = widget.data['fromLocation'] ?? "";
    final String to = widget.data['toLocation'] ?? "";
    final String travelDate = widget.data['travelDate'] ?? "";
    final String fromDate = widget.data['fromDate'] ?? "";
    final String toDate = widget.data['toDate'] ?? "";
    final String flightNumber = widget.data['flightNumber'] ?? "";
    final String airline = widget.data['airline'] ?? "";

    return _buildSection(
      icon: Icons.flight_takeoff,
      title: "Travel Information",
      child: Column(
        children: [
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoBox(
                  label: "From",
                  value: from,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Icon(Icons.arrow_forward, color: Color(0xFF3E729F)),
              ),
              Expanded(
                child: _buildInfoBox(
                  label: "To",
                  value: to,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            "Travel Date",
            travelDate.isNotEmpty ? travelDate : "$fromDate - $toDate",
          ),
          if (flightNumber.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildInfoRow("Ticket Number", flightNumber),
          ],
          if (airline.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildInfoRow("Airline", airline),
          ],
        ],
      ),
    );
  }

  Widget _buildAdDetails() {
    final String service = widget.data['service'] ?? "";
    final String parcelType = widget.data['parcelType'] ?? "";
    final String travelPartnerType = widget.data['travelPartnerType'] ?? "";
    final String remarks = (widget.data['remarks'] as String? ?? "").trim();

    String adType;
    String fallbackDescription;

    if (service == "Travel Partner") {
      if (travelPartnerType.toLowerCase().contains("look")) {
        adType = "Looking for Travel Companion";
        fallbackDescription = "I am looking for a friendly travel companion to join me on this journey. Would love to share experiences and make the trip more enjoyable.";
      } else {
        adType = "Offering to be a Travel Companion";
        fallbackDescription = "I am available to accompany fellow travelers on this route. Happy to help and make your journey comfortable.";
      }
    } else {
      if (parcelType.toLowerCase() == "carry") {
        adType = "Reliable Courier Service Available";
        fallbackDescription = "Traveling soon and willing to carry your parcels securely to the destination. I ensure safe handling and timely delivery.";
      } else {
        adType = "Looking for Parcel Receiver";
        fallbackDescription = "Need a trusted person to receive a parcel at the destination. Details will be shared upon mutual agreement.";
      }
    }

    final displayText = remarks.isNotEmpty ? remarks : fallbackDescription;

    return _buildSection(
      icon: Icons.article_outlined,
      title: "Ad Details",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            adType,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            displayText,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesAndPricing() {
    final String service = widget.data['service'] ?? "";
    final String preferredCompanion = widget.data['preferredCompanion'] ?? "Any";
    final String partners = widget.data['partners'] ?? "";
    final String price = widget.data['price'] ?? "";
    final String parcelWeight = widget.data['parcelWeight'] ?? "";
    final List<String> languages = (widget.data['preferredLanguages'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .toList() ?? [];

    // For Parcel Service, show parcel specifications separately
    if (service == "Carry Parcel") {
      return Column(
        children: [
          // Parcel Specifications Section
          if (parcelWeight.isNotEmpty) ...[
            _buildSection(
              icon: Icons.inventory_2_outlined,
              title: "Parcel Specifications",
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  _buildPreferenceItem(
                    "Maximum Weight",
                    "$parcelWeight KG",
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          // Preferences Section (Languages)
          if (languages.isNotEmpty) ...[
            _buildSection(
              icon: Icons.language,
              title: "Communication",
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Text(
                    "Preferred Languages",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: languages.map((lang) {
                      return Chip(
                        label: Text(
                          lang,
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: const Color(0xFFEAF2FA),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          // Pricing Section
          _buildSection(
            icon: Icons.payments_outlined,
            title: "Pricing",
            child: Column(
              children: [
                const SizedBox(height: 12),
                _buildPriceItem("Price per parcel", "USD $price"),
              ],
            ),
          ),
        ],
      );
    }

    // For Travel Partner, show preferences & pricing together
    return _buildSection(
      icon: Icons.payments_outlined,
      title: "Preferences & Pricing",
      child: Column(
        children: [
          const SizedBox(height: 12),
          if (preferredCompanion != "Any") ...[
            _buildPreferenceItem(
              "Preferred Companion",
              preferredCompanion,
            ),
            const SizedBox(height: 12),
          ],
          if (partners.isNotEmpty) ...[
            _buildPreferenceItem(
              "Number of Partners",
              partners,
            ),
            const SizedBox(height: 12),
          ],
          if (languages.isNotEmpty) ...[
            const Divider(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Preferred Languages",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: languages.map((lang) {
                return Chip(
                  label: Text(
                    lang,
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: const Color(0xFFEAF2FA),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],
          _buildPriceItem("Price ", "USD $price"),
        ],
      ),
    );
  }

  // Helper function to calculate age from date of birth
  int? _calculateAge(dynamic dob) {
    if (dob == null) return null;

    DateTime? birthDate;

    // Handle different date formats
    if (dob is Timestamp) {
      birthDate = dob.toDate();
    } else if (dob is String) {
      try {
        // Try parsing standard ISO format first (yyyy-mm-dd)
        birthDate = DateTime.parse(dob);
      } catch (e) {
        // If that fails, try parsing custom format (d/m/yyyy or m/d/yyyy)
        try {
          final parts = dob.split('/');
          if (parts.length == 3) {
            final month = int.parse(parts[0]);
            final day = int.parse(parts[1]);
            final year = int.parse(parts[2]);
            birthDate = DateTime(year, month, day);
          }
        } catch (e) {
          return null;
        }
      }
    } else if (dob is DateTime) {
      birthDate = dob;
    }

    if (birthDate == null) return null;

    final now = DateTime.now();
    int age = now.year - birthDate.year;

    // Adjust if birthday hasn't occurred yet this year
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }

    return age;
  }

  Widget _buildTravelerInformation() {
    final String userId = widget.data['userId'] ?? "";

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final user = snapshot.data?.data() as Map<String, dynamic>?;
        final String username = user?['username'] ?? "User";

        // Get age from user profile, calculate from DOB, or use stored age
        String age = "";

        // First, try to get age directly from user profile
        if (user?['age'] != null) {
          final userAge = user!['age'].toString();
          if (userAge.isNotEmpty) {
            age = userAge;
          }
        }

        // Second, try to calculate from dob or dateOfBirth if age is still empty
        if (age.isEmpty) {
          // Try 'dob' field first (used in your Firebase)
          var calculatedAge = _calculateAge(user?['dob']);

          // If not found, try 'dateOfBirth' as fallback
          if (calculatedAge == null) {
            calculatedAge = _calculateAge(user?['dateOfBirth']);
          }

          if (calculatedAge != null) {
            age = calculatedAge.toString();
          }
        }

        // Finally, fall back to travelerAge from ad data if still empty
        if (age.isEmpty) {
          age = widget.data['travelerAge'] ?? "";
        }

        // Get first letter of username for avatar
        final String initial = username.isNotEmpty ? username[0].toUpperCase() : "U";

        return _buildSection(
          icon: Icons.person_outline,
          title: "Traveler Information",
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
                        age.isNotEmpty ? "Age: $age years" : "Age: Not specified",
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

  Widget _buildTravelerReviews() {
    final String userId = widget.data['userId'] ?? "";

    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        FirebaseFirestore.instance.collection('users').doc(userId).get(),
        FirebaseFirestore.instance
            .collection('reviews')
            .where('reviewedUserId', isEqualTo: userId)
            .orderBy('updatedAt', descending: true)
            .limit(5)
            .get(),
      ]),
      builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final userDoc = snapshot.data![0] as DocumentSnapshot;
        final reviewsSnapshot = snapshot.data![1] as QuerySnapshot;

        final user = userDoc.data() as Map<String, dynamic>?;
        final double rating = (user?['rating'] ?? 0).toDouble();
        final int ratingCount = user?['ratingCount'] ?? 0;

        return _buildSection(
          icon: Icons.star_outline,
          title: "Traveler Reviews ($ratingCount)",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              if (ratingCount > 0) ...[
                // Overall rating
                Row(
                  children: [
                    ...List.generate(5, (index) {
                      return Icon(
                        index < rating.floor() ? Icons.star : Icons.star_border,
                        size: 20,
                        color: Colors.amber,
                      );
                    }),
                    const SizedBox(width: 8),
                    Text(
                      rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      " ($ratingCount ${ratingCount == 1 ? 'review' : 'reviews'})",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Individual reviews
                if (reviewsSnapshot.docs.isNotEmpty) ...[
                  ...reviewsSnapshot.docs.map((reviewDoc) {
                    final reviewData = reviewDoc.data() as Map<String, dynamic>;
                    final reviewRating = (reviewData['rating'] ?? 0).toDouble();
                    final comment = reviewData['comment'] ?? '';
                    final reviewerId = reviewData['reviewerId'] ?? '';
                    final updatedAt = reviewData['updatedAt'] as Timestamp?;

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(reviewerId)
                          .get(),
                      builder: (context, reviewerSnapshot) {
                        String reviewerName = "Anonymous";
                        if (reviewerSnapshot.hasData) {
                          final reviewerData = reviewerSnapshot.data?.data() as Map<String, dynamic>?;
                          reviewerName = reviewerData?['username'] ?? "Anonymous";
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Reviewer info and rating
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      reviewerName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  Row(
                                    children: List.generate(5, (index) {
                                      return Icon(
                                        index < reviewRating.floor()
                                            ? Icons.star
                                            : Icons.star_border,
                                        size: 14,
                                        color: Colors.amber,
                                      );
                                    }),
                                  ),
                                ],
                              ),
                              if (comment.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  comment,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade700,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                              if (updatedAt != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  _formatReviewDate(updatedAt),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    );
                  }),
                ],
              ] else ...[
                Text(
                  "No reviews yet",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  String _formatReviewDate(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return "Today";
    } else if (difference.inDays == 1) {
      return "Yesterday";
    } else if (difference.inDays < 7) {
      return "${difference.inDays} days ago";
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return "$weeks ${weeks == 1 ? 'week' : 'weeks'} ago";
    } else {
      return DateFormat('MMM d, yyyy').format(dateTime);
    }
  }

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
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
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
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildPreferenceItem(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade700,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF2FA),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF3E729F),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceItem(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade700,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF3E729F),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionSection() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const SizedBox();

    if (_isOwner) {
      return Column(
        children: [
          _buildConnectionRequests(),
          const SizedBox(height: 20),
          _buildOwnerBookingRequests(),
        ],
      );
    } else {
      return Column(
        children: [
          _buildContactButton(),
          const SizedBox(height: 12),
          _buildBookingButton(),
        ],
      );
    }
  }

  Widget _buildConnectionRequests() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('connection_requests')
          .where('adId', isEqualTo: widget.adId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allRequests = snapshot.data?.docs ?? [];
        // Filter out cancelled
        final requests = allRequests
            .where((doc) =>
                (doc.data() as Map<String, dynamic>)['status'] != 'cancelled')
            .toList();
        final pendingCount = requests
            .where((doc) =>
                (doc.data() as Map<String, dynamic>)['status'] == 'pending')
            .length;

        return _buildSection(
          icon: Icons.people_outline,
          title: pendingCount > 0
              ? "Connection Requests ($pendingCount pending)"
              : "Connection Requests",
          child: requests.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    "No connection requests yet",
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                )
              : Column(
                  children: [
                    const SizedBox(height: 12),
                    ...requests.map((doc) {
                      final requestData = doc.data() as Map<String, dynamic>;
                      return _buildConnectionRequestCard(doc.id, requestData);
                    }),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildConnectionRequestCard(String requestId, Map<String, dynamic> requestData) {
    final requesterId = requestData['requesterId'] ?? "";
    final status = requestData['status'] as String? ?? 'pending';
    final message = requestData['message'] ?? "";
    final createdAt = requestData['createdAt'] as Timestamp?;
    final timeAgo = createdAt != null
        ? _getTimeAgo(createdAt.toDate())
        : "";

    Color statusColor;
    String statusText;
    IconData statusIcon;
    switch (status) {
      case 'accepted':
        statusText = "Connected";
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusText = "Rejected";
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusText = "Pending";
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(requesterId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>?;
        final username = userData?['username'] ?? "User";
        final age = userData?['age']?.toString() ?? "";
        final initial = username.isNotEmpty ? username[0].toUpperCase() : "U";

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: status == 'accepted'
                          ? Colors.green
                          : const Color(0xFF3E729F),
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            username,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          if (age.isNotEmpty)
                            Text(
                              "Age: $age years",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(statusIcon, size: 12, color: statusColor),
                              const SizedBox(width: 4),
                              Text(statusText,
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: statusColor)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(
                      timeAgo,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                if (message.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      message,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                if (status == 'pending')
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _handleConnectionRequest(requestId, 'rejected'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text("Reject"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _handleConnectionRequest(requestId, 'accepted'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3E729F),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text("Accept"),
                        ),
                      ),
                    ],
                  ),
                if (status == 'accepted')
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatPage(
                              otherUserId: requesterId,
                              otherUserName: username,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat_bubble_outline, size: 16),
                      label: Text("Chat"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                if (status == 'rejected')
                  const Center(
                    child: Text(
                      "This connection was rejected",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContactButton() {
    final adOwnerId = widget.data['userId'] as String?;
    if (adOwnerId == null) return const SizedBox();

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatPage(
                otherUserId: adOwnerId,
                otherUserName: _adOwnerName.isNotEmpty ? _adOwnerName : "Traveler",
              ),
            ),
          );
        },
        icon: const Icon(Icons.chat_bubble_outline),
        label: const Text("Chat"),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3E729F),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BOOKING — non-owner button
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildBookingButton() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('booking_requests')
          .where('adId', isEqualTo: widget.adId)
          .where('requesterId', isEqualTo: currentUserId)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          // No booking yet
          return SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _sendBookingRequest(currentUserId),
              icon: const Icon(Icons.bookmark_add_outlined),
              label: const Text("Book Service"),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF3E729F),
                side: const BorderSide(color: Color(0xFF3E729F), width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          );
        }

        final bookingId = docs.first.id;
        final status =
            (docs.first.data() as Map<String, dynamic>)['status'] as String? ??
                'pending';

        if (status == 'cancelled') {
          return SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _sendBookingRequest(currentUserId),
              icon: const Icon(Icons.bookmark_add_outlined),
              label: const Text("Book Again"),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF3E729F),
                side: const BorderSide(color: Color(0xFF3E729F), width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          );
        }

        Color statusColor;
        IconData statusIcon;
        String statusLabel;

        switch (status) {
          case 'accepted':
            statusColor = Colors.green;
            statusIcon = Icons.check_circle_outline;
            statusLabel = "Booking Confirmed";
            break;
          case 'rejected':
            statusColor = Colors.red;
            statusIcon = Icons.cancel_outlined;
            statusLabel = "Booking Declined";
            break;
          default:
            statusColor = Colors.orange;
            statusIcon = Icons.hourglass_top_rounded;
            statusLabel = "Booking Requested";
        }

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: statusColor.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
              if (status == 'pending' || status == 'accepted')
                TextButton(
                  onPressed: () => _confirmCancelBooking(bookingId),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: const Size(0, 0),
                  ),
                  child: const Text("Cancel",
                      style: TextStyle(fontSize: 13)),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sendBookingRequest(String currentUserId) async {
    final adOwnerId = widget.data['userId'] as String?;
    if (adOwnerId == null) return;
    try {
      await FirebaseFirestore.instance.collection('booking_requests').add({
        'adId': widget.adId,
        'adOwnerId': adOwnerId,
        'requesterId': currentUserId,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Booking request sent!"),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _confirmCancelBooking(String bookingId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Cancel Booking"),
        content:
            const Text("Are you sure you want to cancel this booking request?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("No")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _cancelBookingRequest(bookingId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Yes, Cancel"),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelBookingRequest(String bookingId) async {
    try {
      await FirebaseFirestore.instance
          .collection('booking_requests')
          .doc(bookingId)
          .update({'status': 'cancelled'});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Booking cancelled")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BOOKING — owner incoming requests
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildOwnerBookingRequests() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('booking_requests')
          .where('adId', isEqualTo: widget.adId)
          .snapshots(),
      builder: (context, snapshot) {
        final allRequests = snapshot.data?.docs ?? [];
        // Filter out cancelled
        final requests = allRequests
            .where((doc) =>
                (doc.data() as Map<String, dynamic>)['status'] != 'cancelled')
            .toList();
        final pendingCount = requests
            .where((doc) =>
                (doc.data() as Map<String, dynamic>)['status'] == 'pending')
            .length;

        return _buildSection(
          icon: Icons.bookmark_outlined,
          title: pendingCount > 0
              ? "Booking Requests ($pendingCount pending)"
              : "Booking Requests",
          child: requests.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    "No booking requests yet",
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                )
              : Column(
                  children: [
                    const SizedBox(height: 12),
                    ...requests.map((doc) {
                      final d = doc.data() as Map<String, dynamic>;
                      return _buildBookingRequestCard(doc.id, d);
                    }),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildBookingRequestCard(
      String bookingId, Map<String, dynamic> data) {
    final requesterId = data['requesterId'] as String? ?? '';
    final status = data['status'] as String? ?? 'pending';
    final createdAt = data['createdAt'] as Timestamp?;
    final timeAgo =
        createdAt != null ? _getTimeAgo(createdAt.toDate()) : '';

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

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(requesterId)
          .get(),
      builder: (context, snap) {
        final userData =
            snap.hasData ? snap.data!.data() as Map<String, dynamic>? : null;
        final username = userData?['username'] as String? ?? 'User';
        final initial =
            username.isNotEmpty ? username[0].toUpperCase() : 'U';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: status == 'accepted'
                          ? Colors.green
                          : const Color(0xFF3E729F),
                      child: Text(initial,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(username,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14)),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(statusIcon, size: 12, color: statusColor),
                              const SizedBox(width: 4),
                              Text(statusText,
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: statusColor)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(timeAgo,
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500)),
                  ],
                ),
                const SizedBox(height: 12),
                if (status == 'pending')
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              _respondBooking(bookingId, requesterId, 'rejected'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text("Decline"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () =>
                              _respondBooking(bookingId, requesterId, 'accepted'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3E729F),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text("Accept"),
                        ),
                      ),
                    ],
                  ),
                if (status == 'accepted')
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              _respondBooking(bookingId, requesterId, 'cancelled'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text("Cancel"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final ownerDoc = await FirebaseFirestore.instance
                                .collection('users')
                                .doc(requesterId)
                                .get();
                            final requesterName =
                                ownerDoc.data()?['username'] ?? 'User';
                            if (mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatPage(
                                    otherUserId: requesterId,
                                    otherUserName: requesterName,
                                  ),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.chat_bubble_outline, size: 16),
                          label: Text("Chat"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                if (status == 'rejected')
                  const Center(
                    child: Text(
                      "This booking was declined",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _respondBooking(
      String bookingId, String requesterId, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('booking_requests')
          .doc(bookingId)
          .update({'status': status});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(status == 'accepted'
              ? "Booking accepted!"
              : status == 'cancelled'
                  ? "Booking cancelled"
                  : "Booking declined"),
          backgroundColor: status == 'accepted'
              ? Colors.green
              : status == 'cancelled'
                  ? Colors.red
                  : Colors.orange,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleConnectionRequest(String requestId, String status) async {
    try {
      // Get the connection request data
      final requestDoc = await FirebaseFirestore.instance
          .collection('connection_requests')
          .doc(requestId)
          .get();

      final requestData = requestDoc.data();
      final requesterId = requestData?['requesterId'];
      final adOwnerId = requestData?['adOwnerId'];

      // Update the request status
      await FirebaseFirestore.instance
          .collection('connection_requests')
          .doc(requestId)
          .update({'status': status});

      // If accepted, add both users to each other's connectedUsers list
      if (status == 'accepted' && requesterId != null && adOwnerId != null) {
        // Add requester to ad owner's connected users
        await FirebaseFirestore.instance
            .collection('users')
            .doc(adOwnerId)
            .update({
          'connectedUsers': FieldValue.arrayUnion([requesterId])
        });

        // Add ad owner to requester's connected users
        await FirebaseFirestore.instance
            .collection('users')
            .doc(requesterId)
            .update({
          'connectedUsers': FieldValue.arrayUnion([adOwnerId])
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'accepted'
                  ? "Connection request accepted! You're now connected."
                  : "Connection request rejected",
            ),
            backgroundColor: status == 'accepted' ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return "${difference.inDays}d ago";
    } else if (difference.inHours > 0) {
      return "${difference.inHours}h ago";
    } else if (difference.inMinutes > 0) {
      return "${difference.inMinutes}m ago";
    } else {
      return "Just now";
    }
  }
}
