import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:travel/CreateTravelAdPage.dart';
import 'package:travel/views/dashboard/settings_page.dart';
import 'package:travel/views/dashboard/bookings_page.dart';
import 'package:travel/views/service_details_page.dart';
import 'package:travel/views/chat_page.dart';
import 'package:travel/views/group_chat_page.dart';
import 'package:travel/views/group_details_page.dart';
import 'package:travel/views/create_group_post_page.dart';
import 'package:language_picker/languages.dart';
import 'package:travel/utils/airports_data.dart';

Future<String?> pickAirport(
    BuildContext context,
    ValueChanged<String> onSelected,
    ) async {
  return await showAirportPicker(context, onSelected);
}



class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0;
  String _username = "";

  final Color brandColor = const Color(0xFF3E729F);

  @override
  void initState() {
    super.initState();
    _fetchUsername();
  }

  /// 🔹 Fetch username
  Future<void> _fetchUsername() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (doc.exists && mounted) {
      setState(() => _username = doc['username'] ?? "");
    }
  }

  void _showCreatePostSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                _postTypeItem(
                  context,
                  title: "Individual Post",
                  subtitle: "Create a post for a travel companion or parcel.",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CreateTravelAdPage(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _postTypeItem(
                  context,
                  title: "Group Post",
                  subtitle: "Create a group post to plan, group chat, and travel together.",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CreateGroupPostPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _postTypeItem(
    BuildContext context, {
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      // 🔹 APP BAR
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFFFFFF),
                Color(0xFFEAF2FA),
              ],
            ),
          ),
        ),
        titleSpacing: 10,
        title: Image.asset(
          "assets/images/logo2.png",
          height: 35,
        ),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_none, color: Colors.black),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),

      // 🔹 BODY
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _ExploreTab(username: _username),
          const BookingsPage(),
          const _MessagesTab(),
          const SettingsPage(),
        ],
      ),

      // 🔹 FLOATING ACTION BUTTON (STABLE)
      floatingActionButton: FloatingActionButton(
        backgroundColor: brandColor,
        elevation: 6,
        shape: const CircleBorder(),
        onPressed: () => _showCreatePostSheet(context),
        child: const Icon(Icons.add, size: 30, color: Colors.white),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // 🔹 BOTTOM BAR
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 10,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.explore_outlined, "Explore", 0),
              _navItem(Icons.bookmark_border, "Bookings", 1),
              const SizedBox(width: 56),
              _buildMessagesNavItem(),
              _navItem(Icons.person_outline, "Profile", 3),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔹 NAV ITEMS
  Widget _navItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? brandColor : Colors.grey),
          Text(label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? brandColor : Colors.grey,
              )),
        ],
      ),
    );
  }

  Widget _navItemWithBadge(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              Icon(icon, color: isSelected ? brandColor : Colors.grey),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Text("3",
                      style:
                      TextStyle(color: Colors.white, fontSize: 8)),
                ),
              ),
            ],
          ),
          Text(label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? brandColor : Colors.grey,
              )),
        ],
      ),
    );
  }

  Widget _buildMessagesNavItem() {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isSelected = _currentIndex == 2;

    if (currentUser == null) {
      return _navItem(Icons.message_outlined, "Messages", 2);
    }

    // Use StreamBuilder to listen to chats collection for real-time updates
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: currentUser.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _navItem(Icons.message_outlined, "Messages", 2);
        }

        // When chats update, recalculate unread count
        return FutureBuilder<int>(
          future: _getUnreadMessageCount(currentUser.uid),
          builder: (context, countSnapshot) {
            final count = countSnapshot.data ?? 0;

            if (count > 0) {
              return GestureDetector(
                onTap: () => setState(() => _currentIndex = 2),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      children: [
                        Icon(
                          Icons.message_outlined,
                          color: isSelected ? brandColor : Colors.grey,
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                count > 99 ? "99+" : "$count",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      "Messages",
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? brandColor : Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            } else {
              return _navItem(Icons.message_outlined, "Messages", 2);
            }
          },
        );
      },
    );
  }

  Future<int> _getUnreadMessageCount(String currentUserId) async {
    try {
      // Get all chats where current user is a participant
      final chatsSnapshot = await FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: currentUserId)
          .get();

      int totalUnread = 0;

      // For each chat, count unread messages
      for (var chatDoc in chatsSnapshot.docs) {
        final messagesSnapshot = await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatDoc.id)
            .collection('messages')
            .where('senderId', isNotEqualTo: currentUserId)
            .where('isRead', isEqualTo: false)
            .get();

        totalUnread += messagesSnapshot.docs.length;
      }

      return totalUnread;
    } catch (e) {
      return 0;
    }
  }
}


class _ExploreTab extends StatefulWidget {
  final String username;

  const _ExploreTab({required this.username});

  @override
  State<_ExploreTab> createState() => _ExploreTabState();
}



class _ExploreTabState extends State<_ExploreTab> {
  String _selectedFilter = "All";
  String? _filterFromLocation;
  String? _filterToLocation;
  DateTime? _filterFromDate;
  DateTime? _filterToDate;
  bool _showBookmarksOnly = false;
  final Timestamp _now = Timestamp.fromDate(DateTime.now());

  // Advanced filter options
  String _selectedService = "Travel Partner";
  double _minPrice = 0;
  double _maxPrice = 500;
  String _flightStatus = "Any Status";
  String _preferredCompanion = "Any";
  List<String> _userPreferredLanguages = [];
  double _minimumRating = 0; // 0 means "Any" rating
  double _parcelWeight = 50; // Max weight for Carry Parcel service

  // Available languages for selection using language_picker package
  final List<Language> _availableLanguages = Languages.defaultLanguages;



  Query get _query {
    final currentUser = FirebaseAuth.instance.currentUser;

    // 🔖 Bookmarks mode (unchanged)
    if (_showBookmarksOnly) {
      if (currentUser == null) {
        // Return an empty query if user is not logged in
        return FirebaseFirestore.instance
            .collection('travel_ads')
            .where('id', isEqualTo: '__non_existent__');
      }
      return FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('bookmarks')
          .orderBy('createdAt', descending: true);
    }

    Query q = FirebaseFirestore.instance
        .collection('travel_ads')
        .where('status', isEqualTo: 0)
        .orderBy('createdAt', descending: true);

    // Service filter - use simple filter chips by default
    if (_selectedFilter != "All" && _selectedFilter != "Group Trip") {
      q = q.where('service', isEqualTo: _selectedFilter);
    }

    // Note: Location and advanced filters are applied client-side in
    // _matchesLocationFilter() and _matchesAdvancedFilters() to avoid
    // Firestore composite index requirements.

    return q;
  }

  DateTime? _parseTravelDate(Map<String, dynamic> data) {
    try {
      // Case 1: single travelDate (string)
      if (data['travelDate'] is String &&
          (data['travelDate'] as String).isNotEmpty) {
        return _parseDDMMYYYY(data['travelDate']);
      }

      // Case 2: fromDate (string OR timestamp)
      if (data['fromDate'] is String &&
          (data['fromDate'] as String).isNotEmpty) {
        return _parseDDMMYYYY(data['fromDate']);
      }

      if (data['fromDate'] is Timestamp) {
        return (data['fromDate'] as Timestamp).toDate();
      }
    } catch (_) {}

    return null;
  }


  DateTime? _parseDDMMYYYY(String value) {
    try {
      final parts = value.split('/');
      if (parts.length != 3) return null;

      return DateTime(
        int.parse(parts[2]), // year
        int.parse(parts[1]), // month
        int.parse(parts[0]), // day
      );
    } catch (_) {
      return null;
    }
  }



  bool _isValidFutureTrip(Map<String, dynamic> data) {
    final tripDate = _parseTravelDate(data);
    if (tripDate == null) return false;

    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    // must be today or future
    if (tripDate.isBefore(todayOnly)) return false;

    // optional filter range (From / To)
    if (_filterFromDate != null && tripDate.isBefore(_filterFromDate!)) {
      return false;
    }

    if (_filterToDate != null && tripDate.isAfter(_filterToDate!)) {
      return false;
    }

    return true;
  }

  bool _matchesAdvancedFilters(Map<String, dynamic> data) {
    // Price filter
    if (data['price'] != null) {
      final price = double.tryParse(data['price'].toString()) ?? 0;
      if (price < _minPrice || price > _maxPrice) {
        return false;
      }
    }

    // Weight filter (for Carry Parcel)
    if (_selectedService == "Carry Parcel" && data['parcelWeight'] != null) {
      final weight = double.tryParse(data['parcelWeight'].toString().replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
      // Allow ads with weight less than or equal to selected weight
      if (weight > _parcelWeight) {
        return false;
      }
    }

    // Flight Status filter (maps to alreadyBooked field)
    if (_flightStatus != "Any Status" && data['alreadyBooked'] != null) {
      final isBooked = data['alreadyBooked'] == true;
      if (_flightStatus == "Booked" && !isBooked) {
        return false;
      }
      if (_flightStatus == "Flexible" && isBooked) {
        return false;
      }
    }

    // Preferred Companion filter (for Travel Partner)
    if (_selectedService == "Travel Partner" && _preferredCompanion != "Any" && data['preferredCompanion'] != null) {
      if (data['preferredCompanion'].toString() != _preferredCompanion) {
        return false;
      }
    }

    // Preferred Languages filter (for both Travel Partner and Carry Parcel)
    if (_userPreferredLanguages.isNotEmpty) {
      final adLanguages = (data['preferredLanguages'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
      // Show ads that have at least one common language OR have no language preference (empty/null)
      if (adLanguages.isNotEmpty) {
        final hasCommonLanguage = _userPreferredLanguages.any((lang) => adLanguages.contains(lang));
        if (!hasCommonLanguage) {
          return false;
        }
      }
      // If adLanguages is empty, we show the ad (user is flexible with languages)
    }

    return true;
  }

  bool _matchesLocationFilter(Map<String, dynamic> data) {
    if (_filterFromLocation?.isNotEmpty == true) {
      final from = (data['fromLocation'] as String? ?? '');
      if (from != _filterFromLocation) return false;
    }
    if (_filterToLocation?.isNotEmpty == true) {
      final to = (data['toLocation'] as String? ?? '');
      if (to != _filterToLocation) return false;
    }
    return true;
  }

  bool _matchesMinimumRating(double? userRating) {
    if (_minimumRating == 0) return true; // "Any" rating
    if (userRating == null) return false;
    return userRating >= _minimumRating;
  }

  bool get _hasActiveFilters {
    // Check if any filters are active (excluding service chip which has its own row)
    return _filterFromLocation != null ||
        _filterToLocation != null ||
        _filterFromDate != null ||
        _filterToDate != null ||
        _minPrice > 0 ||
        _maxPrice < 500 ||
        _minimumRating > 0 ||
        _flightStatus != "Any Status" ||
        _preferredCompanion != "Any" ||
        _userPreferredLanguages.isNotEmpty ||
        _parcelWeight < 50;
  }

  List<Widget> _buildActiveFilterChips() {
    List<Widget> chips = [];

    if (_filterFromLocation != null) {
      chips.add(_activeFilterChip("From: $_filterFromLocation", () {
        setState(() => _filterFromLocation = null);
      }));
    }

    if (_filterToLocation != null) {
      chips.add(_activeFilterChip("To: $_filterToLocation", () {
        setState(() => _filterToLocation = null);
      }));
    }

    if (_filterFromDate != null || _filterToDate != null) {
      String dateText = "";
      if (_filterFromDate != null && _filterToDate != null) {
        dateText = "Dates: ${DateFormat("dd/MM").format(_filterFromDate!)} - ${DateFormat("dd/MM").format(_filterToDate!)}";
      } else if (_filterFromDate != null) {
        dateText = "From: ${DateFormat("dd/MM/yyyy").format(_filterFromDate!)}";
      } else if (_filterToDate != null) {
        dateText = "To: ${DateFormat("dd/MM/yyyy").format(_filterToDate!)}";
      }
      chips.add(_activeFilterChip(dateText, () {
        setState(() {
          _filterFromDate = null;
          _filterToDate = null;
        });
      }));
    }

    if (_minPrice > 0 || _maxPrice < 500) {
      chips.add(_activeFilterChip("Price: \$${_minPrice.toInt()}-\$${_maxPrice.toInt()}", () {
        setState(() {
          _minPrice = 0;
          _maxPrice = 500;
        });
      }));
    }

    if (_minimumRating > 0) {
      chips.add(_activeFilterChip("Rating: ${_minimumRating.toStringAsFixed(1)}+", () {
        setState(() => _minimumRating = 0);
      }));
    }

    if (_flightStatus != "Any Status") {
      chips.add(_activeFilterChip("Flight: $_flightStatus", () {
        setState(() => _flightStatus = "Any Status");
      }));
    }

    if (_preferredCompanion != "Any") {
      chips.add(_activeFilterChip("Companion: $_preferredCompanion", () {
        setState(() => _preferredCompanion = "Any");
      }));
    }

    if (_userPreferredLanguages.isNotEmpty) {
      chips.add(_activeFilterChip(
        _userPreferredLanguages.length == 1
          ? "Language: ${_userPreferredLanguages[0]}"
          : "Languages: ${_userPreferredLanguages.length} selected",
        () {
          setState(() => _userPreferredLanguages = []);
        },
      ));
    }

    if (_parcelWeight < 50) {
      chips.add(_activeFilterChip("Max Weight: ${_parcelWeight.toInt()} kg", () {
        setState(() => _parcelWeight = 50);
      }));
    }

    // Clear all button if there are active filters
    if (chips.isNotEmpty) {
      chips.add(_activeFilterChip(
        "Clear All",
        () {
          setState(() {
            _selectedFilter = "All";
            _filterFromLocation = null;
            _filterToLocation = null;
            _filterFromDate = null;
            _filterToDate = null;
            _minPrice = 0;
            _maxPrice = 500;
            _minimumRating = 0;
            _flightStatus = "Any Status";
            _preferredCompanion = "Any";
            _userPreferredLanguages = [];
            _parcelWeight = 50;
          });
        },
        isClose: false,
        color: const Color(0xFF3E729F),
        textColor: Colors.white,
      ));
    }

    return chips;
  }

  Widget _activeFilterChip(
    String label,
    VoidCallback onRemove, {
    bool isClose = true,
    Color? color,
    Color? textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: textColor ?? Colors.black87,
          ),
        ),
        deleteIcon: Icon(
          isClose ? Icons.close : Icons.clear_all,
          size: 18,
          color: textColor ?? Colors.black54,
        ),
        onDeleted: onRemove,
        backgroundColor: color ?? const Color(0xFFEAF2FA),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }


  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        String? from = _filterFromLocation;
        String? to = _filterToLocation;
        DateTime? fromDate = _filterFromDate;
        DateTime? toDate = _filterToDate;

        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: StatefulBuilder(
            builder: (_, setModal) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// TITLE
                  const Text(
                    "Find Your Perfect Travel Service",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Browse trusted companions and couriers worldwide",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),

                  /// FROM LOCATION
                  _filterField(
                    "From Location",
                    from,
                        () async {
                      // Save current filter state before closing
                      _filterFromLocation = from;
                      _filterToLocation = to;
                      _filterFromDate = fromDate;
                      _filterToDate = toDate;
                      Navigator.pop(context);
                      // Pick airport with no nested sheet
                      final selected = await pickAirport(context, (_) {});
                      if (selected != null) {
                        _filterFromLocation = selected;
                      }
                      // Re-open filter sheet with updated state
                      _openFilterSheet();
                    },
                  ),


                  /// TO LOCATION
                  _filterField(
                    "To Location",
                    to,
                        () async {
                      // Save current filter state before closing
                      _filterFromLocation = from;
                      _filterToLocation = to;
                      _filterFromDate = fromDate;
                      _filterToDate = toDate;
                      Navigator.pop(context);
                      // Pick airport with no nested sheet
                      final selected = await pickAirport(context, (_) {});
                      if (selected != null) {
                        _filterToLocation = selected;
                      }
                      // Re-open filter sheet with updated state
                      _openFilterSheet();
                    },
                  ),

                  Row(
                    children: [
                      Expanded(
                        child: _dateField(
                          context,
                          "From",
                          fromDate,
                              (d) => setModal(() => fromDate = d),
                        ),
                      ),


                      const SizedBox(width: 12),

                      Expanded(
                        child: _dateField(
                          context,
                          "To",
                          toDate,
                              (d) => setModal(() => toDate = d),
                          minDate: fromDate,
                        ),
                      ),

                    ],
                  ),

                  const SizedBox(height: 20),

                  /// APPLY
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _filterFromLocation = null;
                              _filterToLocation = null;
                              _filterFromDate = null;
                              _filterToDate = null;
                            });
                            Navigator.pop(context);
                          },
                          child: const Text("Reset"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3E729F),
                          ),
                          icon: const Icon(Icons.search, color: Colors.white),
                          label: const Text(
                            "Search",
                            style: TextStyle(color: Colors.white),
                          ),
                          onPressed: () {
                            setState(() {
                              _filterFromLocation = from;
                              _filterToLocation = to;
                              _filterFromDate = fromDate;
                              _filterToDate = toDate;
                            });
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ],
                  ),

                ],
              );
            },
          ),
        );
      },
    );
  }

  void _openAdvancedFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        String selectedService = _selectedService;
        DateTime? fromDate = _filterFromDate;
        DateTime? toDate = _filterToDate;
        double minPrice = _minPrice;
        double maxPrice = _maxPrice;
        String flightStatus = _flightStatus;
        String preferredCompanion = _preferredCompanion;
        List<String> userPreferredLanguages = List.from(_userPreferredLanguages);
        double minimumRating = _minimumRating;
        double parcelWeight = _parcelWeight;

        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: StatefulBuilder(
            builder: (_, setModal) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// HEADER
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Text(
                          "Filters",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                    const SizedBox(height: 20),

                    /// SELECT SERVICE
                    const Text(
                      "Select Service",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _serviceChip(
                            "Travel Partner",
                            Icons.people,
                            selectedService == "Travel Partner",
                            () => setModal(() => selectedService = "Travel Partner"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _serviceChip(
                            "Carry Parcel",
                            Icons.inventory_2,
                            selectedService == "Carry Parcel",
                            () => setModal(() => selectedService = "Carry Parcel"),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    /// TRAVEL DATES
                    const Text(
                      "Travel Dates",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _compactDateField(
                            context,
                            "DD/MM/YYYY",
                            fromDate,
                            (d) => setModal(() => fromDate = d),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text("-"),
                        ),
                        Expanded(
                          child: _compactDateField(
                            context,
                            "12/04/2026",
                            toDate,
                            (d) => setModal(() => toDate = d),
                            minDate: fromDate,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    /// PRICE
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Price",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          "USD",
                          style: TextStyle(fontSize: 12, color: const Color(0xFF3E729F)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text("${minPrice.toInt()}"),
                        Expanded(
                          child: RangeSlider(
                            values: RangeValues(minPrice, maxPrice),
                            min: 0,
                            max: 500,
                            divisions: 50,
                            activeColor: const Color(0xFF3E729F),
                            onChanged: (values) {
                              setModal(() {
                                minPrice = values.start;
                                maxPrice = values.end;
                              });
                            },
                          ),
                        ),
                        Text("${maxPrice.toInt()}"),
                      ],
                    ),
                    const SizedBox(height: 20),

                    /// FLIGHT STATUS (Common for both services)
                    const Text(
                      "Flight Status",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _statusChip("Any Status", flightStatus, (v) => setModal(() => flightStatus = v)),
                        _statusChip("Booked", flightStatus, (v) => setModal(() => flightStatus = v)),
                        _statusChip("Flexible", flightStatus, (v) => setModal(() => flightStatus = v)),
                      ],
                    ),
                    const SizedBox(height: 20),

                    /// CONDITIONAL: Show different options based on service type
                    if (selectedService == "Travel Partner") ...[
                      /// PREFERRED COMPANION
                      const Text(
                        "Preferred Companion",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          _statusChip("Any", preferredCompanion, (v) => setModal(() => preferredCompanion = v)),
                          _statusChip("Male", preferredCompanion, (v) => setModal(() => preferredCompanion = v)),
                          _statusChip("Female", preferredCompanion, (v) => setModal(() => preferredCompanion = v)),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],

                    if (selectedService == "Carry Parcel") ...[
                      /// WEIGHT (for Carry Parcel)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Weight",
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          Text(
                            "${parcelWeight.toInt()} KG",
                            style: const TextStyle(fontSize: 12, color: Color(0xFF3E729F)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Slider(
                        value: parcelWeight,
                        min: 5,
                        max: 50,
                        divisions: 9,
                        activeColor: const Color(0xFF3E729F),
                        label: "${parcelWeight.toInt()} kg",
                        onChanged: (value) {
                          setModal(() => parcelWeight = value);
                        },
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _weightChip("5 kg", 5.0, parcelWeight, (v) => setModal(() => parcelWeight = v)),
                          _weightChip("10 kg", 10.0, parcelWeight, (v) => setModal(() => parcelWeight = v)),
                          _weightChip("15 kg", 15.0, parcelWeight, (v) => setModal(() => parcelWeight = v)),
                          _weightChip("20 kg", 20.0, parcelWeight, (v) => setModal(() => parcelWeight = v)),
                          _weightChip("25 kg", 25.0, parcelWeight, (v) => setModal(() => parcelWeight = v)),
                          _weightChip("30 kg", 30.0, parcelWeight, (v) => setModal(() => parcelWeight = v)),
                          _weightChip("35 kg", 35.0, parcelWeight, (v) => setModal(() => parcelWeight = v)),
                          _weightChip("40 kg", 40.0, parcelWeight, (v) => setModal(() => parcelWeight = v)),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],

                    /// USER PREFERRED LANGUAGES (Common for both services)
                    const Text(
                      "User Preferred Languages",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      readOnly: true,
                      controller: TextEditingController(
                        text: userPreferredLanguages.isEmpty
                          ? ''
                          : userPreferredLanguages.join(', ')
                      ),
                      decoration: InputDecoration(
                        hintText: "Select user preferred languages",
                        suffixIcon: const Icon(Icons.arrow_drop_down),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      onTap: () {
                        _openLanguageSelectionSheet(setModal, userPreferredLanguages);
                      },
                    ),
                    const SizedBox(height: 20),

                    /// MINIMUM RATINGS
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Minimum Ratings",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          minimumRating == 0 ? "Any" : minimumRating.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 14, color: Color(0xFF3E729F)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: minimumRating,
                      min: 0,
                      max: 5,
                      divisions: 10,
                      activeColor: const Color(0xFF3E729F),
                      label: minimumRating == 0 ? "Any" : minimumRating.toStringAsFixed(1),
                      onChanged: (value) {
                        setModal(() => minimumRating = value);
                      },
                    ),
                    const SizedBox(height: 20),

                    /// BUTTONS
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setModal(() {
                                selectedService = "Travel Partner";
                                fromDate = null;
                                toDate = null;
                                minPrice = 0;
                                maxPrice = 500;
                                flightStatus = "Any Status";
                                preferredCompanion = "Any";
                                userPreferredLanguages = [];
                                minimumRating = 0;
                                parcelWeight = 50;
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text("Reset All"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _selectedService = selectedService;
                                _selectedFilter = selectedService; // Sync filter chips with advanced filter service selection
                                _filterFromDate = fromDate;
                                _filterToDate = toDate;
                                _minPrice = minPrice;
                                _maxPrice = maxPrice;
                                _flightStatus = flightStatus;
                                _preferredCompanion = preferredCompanion;
                                _userPreferredLanguages = userPreferredLanguages;
                                _minimumRating = minimumRating;
                                _parcelWeight = parcelWeight;
                              });
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3E729F),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              "Apply Filters",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _openLanguageSelectionSheet(StateSetter setParentModal, List<String> currentSelection) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        Set<String> tempSelectedLanguages = Set.from(currentSelection);
        String searchQuery = '';

        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: StatefulBuilder(
            builder: (_, setModal) {
              // Filter languages based on search query
              List<Language> filteredLanguages = _availableLanguages
                  .where((lang) => lang.name.toLowerCase().contains(searchQuery.toLowerCase()))
                  .toList();

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// HEADER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        "Select Languages",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 20),

                  /// SEARCH BAR
                  TextField(
                    onChanged: (value) {
                      setModal(() => searchQuery = value);
                    },
                    decoration: InputDecoration(
                      hintText: "Search languages...",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// LANGUAGE LIST
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 400),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: filteredLanguages.length,
                      itemBuilder: (context, index) {
                        final language = filteredLanguages[index];
                        final isSelected = tempSelectedLanguages.contains(language.name);

                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (bool? value) {
                            setModal(() {
                              if (value == true) {
                                tempSelectedLanguages.add(language.name);
                              } else {
                                tempSelectedLanguages.remove(language.name);
                              }
                            });
                          },
                          title: Text(language.name),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                          activeColor: const Color(0xFF3E729F),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// CONTINUE BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3E729F),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        setParentModal(() {
                          currentSelection.clear();
                          currentSelection.addAll(tempSelectedLanguages);
                        });
                        Navigator.pop(context);
                      },
                      child: const Text(
                        "Continue",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _serviceChip(String label, IconData icon, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEAF2FA) : Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFF3E729F) : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? const Color(0xFF3E729F) : Colors.grey,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isSelected ? const Color(0xFF3E729F) : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String label, String currentValue, Function(String) onSelected) {
    final isSelected = currentValue == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: const Color(0xFFEAF2FA),
      labelStyle: TextStyle(
        fontSize: 12,
        color: isSelected ? const Color(0xFF3E729F) : Colors.grey,
      ),
      onSelected: (_) => onSelected(label),
    );
  }

  Widget _weightChip(String label, double weight, double currentWeight, Function(double) onSelected) {
    final isSelected = currentWeight == weight;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: const Color(0xFFEAF2FA),
      labelStyle: TextStyle(
        fontSize: 12,
        color: isSelected ? const Color(0xFF3E729F) : Colors.grey,
      ),
      onSelected: (_) => onSelected(weight),
    );
  }

  Widget _compactDateField(
    BuildContext context,
    String hint,
    DateTime? value,
    Function(DateTime) onPick, {
    DateTime? minDate,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final earliest = minDate != null && minDate.isAfter(today) ? minDate : today;
    return TextField(
      readOnly: true,
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: value ?? earliest,
          firstDate: earliest,
          lastDate: today.add(const Duration(days: 365)),
        );
        if (d != null) onPick(d);
      },
      decoration: InputDecoration(
        hintText: value == null ? hint : DateFormat("dd/MM/yyyy").format(value),
        suffixIcon: const Icon(Icons.calendar_today, size: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 🔍 SEARCH
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            readOnly: true,
            onTap: _openFilterSheet,
            decoration: InputDecoration(
              hintText: "Search...",
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.tune),
                onPressed: _openAdvancedFilterSheet,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

        ),

        // 🔹 ACTIVE FILTERS (if any)
        if (_hasActiveFilters) ...[
          Container(
            height: 40,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _buildActiveFilterChips(),
            ),
          ),
          const SizedBox(height: 8),
        ],

        // 🔹 FILTERS
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _filterChip("All"),
              _filterChip("Travel Partner"),
              _filterChip("Carry Parcel"),
              _filterChip("Group Trip"),

              // ⭐ BOOKMARKS CHIP
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: ChoiceChip(
                  label: const Text("Bookmarks"),
                  selected: _showBookmarksOnly,
                  selectedColor: const Color(0xFFEAF2FA),
                  avatar: Icon(
                    Icons.bookmark,
                    size: 16,
                    color: _showBookmarksOnly
                        ? const Color(0xFF3E729F)
                        : Colors.grey,
                  ),
                  onSelected: (v) {
                    setState(() {
                      _showBookmarksOnly = v;
                    });
                  },
                ),
              ),
            ],

          ),
        ),

        const SizedBox(height: 8),

        // 🔹 LIST
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
                  stream: _query.snapshots(),
            builder: (context, adsSnapshot) {
              // Show groups when filter is "All" or "Group Trip"
              final bool showGroups = (_selectedFilter == "All" || _selectedFilter == "Group Trip") && !_showBookmarksOnly;

              if (!showGroups) {
                // Original travel-ads-only logic
                return _buildAdsList(adsSnapshot);
              }

              // Merge travel ads + group posts
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('travel_groups')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, groupsSnapshot) {
                  if (!adsSnapshot.hasData && !groupsSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Build merged list of items: {type, doc}
                  final List<Map<String, dynamic>> items = [];

                  // Add travel ads (skip when "Group Trip" filter is active)
                  if (_selectedFilter != "Group Trip" && adsSnapshot.hasData) {
                    for (final doc in adsSnapshot.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      if (!_isValidFutureTrip(data)) continue;
                      if (!_matchesLocationFilter(data)) continue;
                      if (!_matchesAdvancedFilters(data)) continue;
                      final ts = data['createdAt'] as Timestamp?;
                      items.add({
                        'type': 'ad',
                        'id': doc.id,
                        'data': data,
                        'createdAt': ts,
                      });
                    }
                  }

                  // Add groups
                  if (groupsSnapshot.hasData) {
                    for (final doc in groupsSnapshot.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      // Apply location filter to groups too
                      if (_filterFromLocation?.isNotEmpty == true &&
                          data['fromLocation'] != _filterFromLocation) continue;
                      if (_filterToLocation?.isNotEmpty == true &&
                          data['toLocation'] != _filterToLocation) continue;
                      final ts = data['createdAt'] as Timestamp?;
                      items.add({
                        'type': 'group',
                        'id': doc.id,
                        'data': data,
                        'createdAt': ts,
                      });
                    }
                  }

                  // Sort by createdAt descending
                  items.sort((a, b) {
                    final aTs = a['createdAt'] as Timestamp?;
                    final bTs = b['createdAt'] as Timestamp?;
                    if (aTs == null && bTs == null) return 0;
                    if (aTs == null) return 1;
                    if (bTs == null) return -1;
                    return bTs.compareTo(aTs);
                  });

                  if (items.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            const Text("No travel ads found", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            Text("Be the first to create a travel ad!", style: TextStyle(fontSize: 14, color: Colors.grey.shade600), textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final item = items[i];
                      if (item['type'] == 'group') {
                        return _GroupCard(
                          groupId: item['id'],
                          data: item['data'],
                        );
                      }

                      final data = item['data'] as Map<String, dynamic>;
                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(data['userId'])
                            .get(),
                        builder: (context, userSnap) {
                          if (userSnap.hasData) {
                            final user = userSnap.data?.data() as Map<String, dynamic>?;
                            final rating = (user?['rating'] ?? 0).toDouble();
                            if (!_matchesMinimumRating(rating)) {
                              return const SizedBox();
                            }
                          }
                          return _TravelCard(adId: item['id'], data: data);
                        },
                      );
                    },
                  );
                },
              );
            },
                ),
        ),
      ],
    );
  }

  // ── ADS LIST (non-merged, used when filter != "All") ─────────────────────
  Widget _buildAdsList(AsyncSnapshot<QuerySnapshot> snapshot) {
    if (!snapshot.hasData) {
      return const Center(child: CircularProgressIndicator());
    }

    final docs = snapshot.data!.docs;
    if (docs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _hasActiveFilters ? Icons.filter_alt_off : Icons.inventory_2_outlined,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                _hasActiveFilters ? "No results found" : "No travel ads found",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                _hasActiveFilters
                    ? "Try adjusting your filters to see more results"
                    : "Be the first to create a travel ad!",
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: docs.length,
      itemBuilder: (_, i) {
        final doc = docs[i];

        if (_showBookmarksOnly) {
          final bookmarkData = doc.data() as Map<String, dynamic>?;
          final bookmarkType = bookmarkData?['type'] ?? 'ad';

          if (bookmarkType == 'group') {
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('travel_groups')
                  .doc(doc.id)
                  .get(),
              builder: (context, groupSnap) {
                if (!groupSnap.hasData || !groupSnap.data!.exists) {
                  return const SizedBox();
                }
                final data = groupSnap.data!.data() as Map<String, dynamic>;
                return _GroupCard(groupId: doc.id, data: data);
              },
            );
          }

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('travel_ads')
                .doc(doc.id)
                .get(),
            builder: (context, adSnap) {
              if (!adSnap.hasData || !adSnap.data!.exists) {
                return const SizedBox();
              }

              final data = adSnap.data!.data() as Map<String, dynamic>;

              if (!_isValidFutureTrip(data)) return const SizedBox();
              if (!_matchesLocationFilter(data)) return const SizedBox();
              if (!_matchesAdvancedFilters(data)) return const SizedBox();

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(data['userId'])
                    .get(),
                builder: (context, userSnap) {
                  if (userSnap.hasData) {
                    final user = userSnap.data?.data() as Map<String, dynamic>?;
                    final rating = (user?['rating'] ?? 0).toDouble();
                    if (!_matchesMinimumRating(rating)) return const SizedBox();
                  }
                  return _TravelCard(adId: doc.id, data: data);
                },
              );
            },
          );
        }

        final data = doc.data() as Map<String, dynamic>;

        if (!_isValidFutureTrip(data)) return const SizedBox();
        if (!_matchesLocationFilter(data)) return const SizedBox();
        if (!_matchesAdvancedFilters(data)) return const SizedBox();

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(data['userId'])
              .get(),
          builder: (context, userSnap) {
            if (userSnap.hasData) {
              final user = userSnap.data?.data() as Map<String, dynamic>?;
              final rating = (user?['rating'] ?? 0).toDouble();
              if (!_matchesMinimumRating(rating)) return const SizedBox();
            }
            return _TravelCard(adId: doc.id, data: data);
          },
        );
      },
    );
  }

  Widget _filterChip(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: _selectedFilter == label,
        selectedColor: const Color(0xFFEAF2FA),
        onSelected: (_) => setState(() => _selectedFilter = label),
      ),
    );
  }
}


Widget _filterField(String label, String? value, Function() onTap) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label),
      const SizedBox(height: 6),
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(Icons.location_on_outlined, color: Colors.grey.shade600),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value ?? "Enter destination city or airport",
                  style: TextStyle(
                    fontSize: 16,
                    color: value != null ? Colors.black : Colors.grey,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
    ],
  );
}

Widget _dateField(
    BuildContext context,
    String label,
    DateTime? value,
    Function(DateTime) onPick, {
    DateTime? minDate,
    }) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final earliest = minDate != null && minDate.isAfter(today) ? minDate : today;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label),
      const SizedBox(height: 6),
      TextField(
        readOnly: true,
        onTap: () async {
          final d = await showDatePicker(
            context: context,
            initialDate: value ?? earliest,
            firstDate: earliest,
            lastDate: today.add(const Duration(days: 365)),
          );

          if (d != null) onPick(d);
        },
        decoration: InputDecoration(
          hintText: value == null
              ? "DD/MM/YYYY"
              : DateFormat("dd/MM/yyyy").format(value),
          prefixIcon: const Icon(Icons.calendar_today),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    ],
  );
}




// 🔹 MESSAGES TAB
class _MessagesTab extends StatelessWidget {
  const _MessagesTab();

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Center(child: Text("Please log in to view messages"));
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              labelColor: const Color(0xFF3E729F),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF3E729F),
              tabs: const [
                Tab(text: "Direct"),
                Tab(text: "Groups"),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _DirectChatsTab(currentUser: currentUser),
                _GroupChatsTab(currentUser: currentUser),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DirectChatsTab extends StatelessWidget {
  final User currentUser;
  const _DirectChatsTab({required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: currentUser.uid)
          .orderBy('lastMessageTime', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _emptyState("No direct messages yet", "Start chatting with your connections!");
        }

        final chats = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: chats.length,
          itemBuilder: (context, index) {
            final chatDoc = chats[index];
            final chatData = chatDoc.data() as Map<String, dynamic>;
            final participants = List<String>.from(chatData['participants'] ?? []);
            final lastMessage = chatData['lastMessage'] ?? '';
            final lastMessageTime = chatData['lastMessageTime'] as Timestamp?;

            final otherUserId = participants.firstWhere(
              (id) => id != currentUser.uid,
              orElse: () => '',
            );

            if (otherUserId.isEmpty) return const SizedBox();

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) return const SizedBox();

                final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
                final otherUserName = userData?['username'] ?? 'User';

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('chats')
                      .doc(chatDoc.id)
                      .collection('messages')
                      .where('senderId', isNotEqualTo: currentUser.uid)
                      .where('isRead', isEqualTo: false)
                      .snapshots(),
                  builder: (context, unreadSnap) {
                    final unreadCount = unreadSnap.data?.docs.length ?? 0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          radius: 28,
                          backgroundColor: const Color(0xFFEAF2FA),
                          child: Text(
                            otherUserName[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF3E729F),
                            ),
                          ),
                        ),
                        title: Text(
                          otherUserName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: unreadCount > 0 ? FontWeight.w700 : FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          lastMessage.isEmpty ? 'No messages yet' : lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: unreadCount > 0 ? Colors.black87 : Colors.grey.shade600,
                            fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        trailing: SizedBox(
                          width: 70,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (lastMessageTime != null)
                                Text(
                                  _formatTime(lastMessageTime),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: unreadCount > 0 ? Colors.red : Colors.grey.shade500,
                                  ),
                                ),
                              if (unreadCount > 0) ...[
                                const SizedBox(height: 4),
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    unreadCount > 99 ? "99+" : "$unreadCount",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatPage(
                              otherUserId: otherUserId,
                              otherUserName: otherUserName,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class _GroupChatsTab extends StatelessWidget {
  final User currentUser;
  const _GroupChatsTab({required this.currentUser});

  static const List<String> _months = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('travel_groups')
          .where('participants', arrayContains: currentUser.uid)
          .orderBy('lastMessageTime', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _emptyState("No group chats yet", "Create a group post to travel together!");
        }

        final groups = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final groupDoc = groups[index];
            final groupData = groupDoc.data() as Map<String, dynamic>;
            final from = groupData['fromLocation'] ?? '';
            final to = groupData['toLocation'] ?? '';
            final month = _months[(groupData['month'] as int? ?? 0).clamp(0, 12)];
            final year = groupData['year'] ?? '';
            final lastMessage = groupData['lastMessage'] ?? '';
            final lastMessageTime = groupData['lastMessageTime'] as Timestamp?;
            final memberCount = (groupData['participants'] as List?)?.length ?? 0;

            final shortFrom = _short(from);
            final shortTo = _short(to);

            // Get last read time for current user
            final lastReadMap = groupData['lastReadTime'] as Map<String, dynamic>? ?? {};
            final lastReadTs = lastReadMap[currentUser.uid] as Timestamp?;

            return StreamBuilder<QuerySnapshot>(
              stream: (() {
                var query = FirebaseFirestore.instance
                    .collection('travel_groups')
                    .doc(groupDoc.id)
                    .collection('messages')
                    .where('senderId', isNotEqualTo: currentUser.uid);
                if (lastReadTs != null) {
                  query = query.where('createdAt', isGreaterThan: lastReadTs);
                }
                return query.snapshots();
              })(),
              builder: (context, unreadSnap) {
                final unreadCount = unreadSnap.data?.docs.length ?? 0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF2FA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.groups, color: Color(0xFF3E729F), size: 28),
                    ),
                    title: Text(
                      "$shortFrom → $shortTo",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: unreadCount > 0 ? FontWeight.w700 : FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "$month $year · $memberCount member${memberCount == 1 ? '' : 's'}",
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        ),
                        if (lastMessage.isNotEmpty)
                          Text(
                            lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: unreadCount > 0 ? Colors.black87 : Colors.grey.shade600,
                              fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                      ],
                    ),
                    trailing: SizedBox(
                      width: 70,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (lastMessageTime != null)
                            Text(
                              _formatTime(lastMessageTime),
                              style: TextStyle(
                                fontSize: 12,
                                color: unreadCount > 0 ? Colors.red : Colors.grey.shade500,
                              ),
                            ),
                          if (unreadCount > 0) ...[
                            const SizedBox(height: 4),
                            Container(
                              width: 20,
                              height: 20,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                unreadCount > 99 ? "99+" : "$unreadCount",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GroupChatPage(
                          groupId: groupDoc.id,
                          groupData: groupData,
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  static String _short(String value) {
    final idx = value.indexOf(' - ');
    if (idx == 3) return value.substring(0, 3);
    return value;
  }
}

Widget _emptyState(String title, String subtitle) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

String _formatTime(Timestamp timestamp) {
  final dateTime = timestamp.toDate();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

  if (messageDate == today) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  } else if (messageDate == today.subtract(const Duration(days: 1))) {
    return "Yesterday";
  } else if (messageDate.isAfter(today.subtract(const Duration(days: 7)))) {
    return DateFormat('EEEE').format(dateTime);
  } else {
    return DateFormat('dd/MM/yyyy').format(dateTime);
  }
}

class _TravelCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String adId;

  const _TravelCard({
    required this.data,
    required this.adId,
  });

  /// Returns the IATA code if the value is in "IATA - ..." format,
  /// otherwise returns the value as-is (backwards compat with old country data).
  static String _shortLocation(String value) {
    final idx = value.indexOf(' - ');
    if (idx == 3) return value.substring(0, 3); // e.g. "JFK"
    return value;
  }

  @override
  Widget build(BuildContext context) {
    final String from = data['fromLocation'] ?? "";
    final String to = data['toLocation'] ?? "";
    final String service = data['service'] ?? "";
    final String price = data['price'] ?? "";
    final String? userId = data['userId'] as String?;

    final parcelType =
    (data['parcelType'] as String?)?.toLowerCase();

    final companionType =
    (data['travelPartnerType'] as String?)?.toLowerCase().trim();





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



    if (userId == null) {
      return const SizedBox(); // or a fallback card
    }


    final String dateText = data['travelDate'] ??
        "${data['fromDate']} - ${data['toDate']}";

    final Timestamp? createdAt = data['createdAt'];
    final String postedOn = createdAt != null
        ? DateFormat("dd MMM yyyy").format(createdAt.toDate())
        : "";

    return FutureBuilder<DocumentSnapshot>(
      future:
      FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        final user = snapshot.data?.data() as Map<String, dynamic>?;

        final String username = user?['username'] ?? "User";
        final double rating = (user?['rating'] ?? 0).toDouble();
        final int ratingCount = user?['ratingCount'] ?? 0;

        return Card(
          margin: const EdgeInsets.only(bottom: 14),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                // 🔹 ROUTE + PRICE
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        "${_shortLocation(from)} → ${_shortLocation(to)}",
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text("USD $price",
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3E729F))),
                  ],
                ),

                const SizedBox(height: 4),
                Text("Travel on: $dateText",
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade600)),

                const Divider(height: 20),

                // 🔹 USER ROW
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 18,
                      backgroundColor: Color(0xFFEAF2FA),
                      child: Icon(Icons.person, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(username,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600)),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star,
                            size: 14, color: Colors.orange),
                        const SizedBox(width: 2),
                        Text("$rating ($ratingCount)",
                            style: const TextStyle(fontSize: 12)),
                      ],
                    )
                  ],
                ),

                const SizedBox(height: 10),

                // 🔹 TITLE / DESCRIPTION
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

                // 🔹 TAGS
                Wrap(
                  spacing: 8,
                  children: [
                    _tag(service),
                    if (data['partners'] != null &&
                        data['partners'].toString().isNotEmpty)
                      _tag("No. of Partners: upto ${data['partners']}"),
                    if (data['parcelWeight'] != null &&
                        data['parcelWeight'].toString().isNotEmpty)
                      _tag("Weight: ${data['parcelWeight']} KG"),
                  ],
                ),

                const SizedBox(height: 10),

                // 🔹 FOOTER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Posted on $postedOn",
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600)),
                    FirebaseAuth.instance.currentUser != null
                        ? StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .doc(FirebaseAuth.instance.currentUser!.uid)
                                .collection('bookmarks')
                                .doc(adId)
                                .snapshots(),
                            builder: (context, snapshot) {
                              final bookmarked = snapshot.data?.exists ?? false;

                              return GestureDetector(
                                onTap: () async {
                                  await toggleBookmark(adId);
                                },
                                child: Icon(
                                  bookmarked ? Icons.bookmark : Icons.bookmark_border,
                                  size: 20,
                                  color: bookmarked
                                      ? const Color(0xFF3E729F)
                                      : Colors.grey,
                                ),
                              );
                            },
                          )
                        : const SizedBox.shrink(),


                  ],
                )
              ],
            ),
          ),
          ),
        );
      },
    );
  }


  Future<void> toggleBookmark(String id, {String type = 'ad'}) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final uid = currentUser.uid;
    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('bookmarks')
        .doc(id);

    final snap = await ref.get();

    if (snap.exists) {
      await ref.delete();
    } else {
      await ref.set({
        'adId': id,
        'type': type,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }


  Widget _tag(String text) {
    return Chip(
      label: Text(text, style: const TextStyle(fontSize: 11)),
      backgroundColor: const Color(0xFFEAF2FA),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final String groupId;
  final Map<String, dynamic> data;

  const _GroupCard({
    required this.groupId,
    required this.data,
  });

  static String _shortLocation(String value) {
    final idx = value.indexOf(' - ');
    if (idx == 3) return value.substring(0, 3);
    return value;
  }

  static const List<String> _months = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final String from = data['fromLocation'] ?? '';
    final String to = data['toLocation'] ?? '';
    final int monthIdx = (data['month'] as int? ?? 0).clamp(0, 12);
    final month = _months[monthIdx];
    final year = data['year'] ?? '';
    final memberCount = (data['participants'] as List?)?.length ?? 0;
    final String creatorId = data['createdBy'] ?? '';
    final List<String> languages =
        (data['preferredLanguages'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    final Timestamp? createdAt = data['createdAt'];
    final String postedOn = createdAt != null
        ? DateFormat("dd MMM yyyy").format(createdAt.toDate())
        : "";

    return FutureBuilder<DocumentSnapshot>(
      future: creatorId.isNotEmpty
          ? FirebaseFirestore.instance.collection('users').doc(creatorId).get()
          : null,
      builder: (context, snapshot) {
        final user = snapshot.data?.data() as Map<String, dynamic>?;
        final String username = user?['username'] ?? "User";

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
                // Group badge strip
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
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        "$memberCount member${memberCount == 1 ? '' : 's'}",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Route + month
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              "${_shortLocation(from)} → ${_shortLocation(to)}",
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "$month $year",
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF3E729F),
                            ),
                          ),
                        ],
                      ),

                      const Divider(height: 20),

                      // Creator row
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 18,
                            backgroundColor: Color(0xFFEAF2FA),
                            child: Icon(Icons.person, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              username,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.people, size: 14, color: Color(0xFF3E729F)),
                              const SizedBox(width: 4),
                              Text(
                                "$memberCount",
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Description
                      const Text(
                        "Group Travel",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        (data['description'] as String?)?.isNotEmpty == true
                            ? data['description']
                            : "Join this group to find travel companions for $month $year",
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 10),

                      // Tags
                      Wrap(
                        spacing: 8,
                        children: [
                          Chip(
                            label: const Text("Group Trip", style: TextStyle(fontSize: 11)),
                            backgroundColor: const Color(0xFF3E729F).withValues(alpha: 0.15),
                          ),
                          ...languages.take(2).map((lang) => Chip(
                            label: Text(lang, style: const TextStyle(fontSize: 11)),
                            backgroundColor: const Color(0xFFEAF2FA),
                          )),
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
                          if (FirebaseAuth.instance.currentUser != null)
                            StreamBuilder<DocumentSnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(FirebaseAuth.instance.currentUser!.uid)
                                  .collection('bookmarks')
                                  .doc(groupId)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                final bookmarked = snapshot.data?.exists ?? false;
                                return GestureDetector(
                                  onTap: () async {
                                    final uid = FirebaseAuth.instance.currentUser!.uid;
                                    final ref = FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(uid)
                                        .collection('bookmarks')
                                        .doc(groupId);
                                    final snap = await ref.get();
                                    if (snap.exists) {
                                      await ref.delete();
                                    } else {
                                      await ref.set({
                                        'adId': groupId,
                                        'type': 'group',
                                        'createdAt': FieldValue.serverTimestamp(),
                                      });
                                    }
                                  },
                                  child: Icon(
                                    bookmarked ? Icons.bookmark : Icons.bookmark_border,
                                    size: 20,
                                    color: bookmarked
                                        ? const Color(0xFF3E729F)
                                        : Colors.grey,
                                  ),
                                );
                              },
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
      },
    );
  }
}

