import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:language_picker/languages.dart';
import 'package:travel/utils/airports_data.dart';
import 'package:travel/views/group_chat_page.dart';

class CreateGroupPostPage extends StatefulWidget {
  const CreateGroupPostPage({super.key});

  @override
  State<CreateGroupPostPage> createState() => _CreateGroupPostPageState();
}

class _CreateGroupPostPageState extends State<CreateGroupPostPage> {
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final _descriptionController = TextEditingController();

  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  List<String> _selectedLanguages = [];

  bool _isLoading = false;

  final List<Language> _availableLanguages = Languages.defaultLanguages;

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _openAirportPicker(TextEditingController controller) async {
    final other = controller == _fromController
        ? _toController.text.trim()
        : _fromController.text.trim();
    await showAirportPicker(context, (value) {
      setState(() => controller.text = value);
    }, excludeAirport: other.isNotEmpty ? other : null);
  }

  void _openLanguageSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        Set<String> temp = Set.from(_selectedLanguages);
        String query = '';
        return Padding(
          padding: EdgeInsets.only(
            left: 16, right: 16, top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: StatefulBuilder(builder: (_, setModal) {
            final filtered = _availableLanguages
                .where((l) => l.name.toLowerCase().contains(query.toLowerCase()))
                .toList();
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Select Languages",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (v) => setModal(() => query = v),
                  decoration: InputDecoration(
                    hintText: "Search languages...",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final lang = filtered[i];
                      return CheckboxListTile(
                        value: temp.contains(lang.name),
                        onChanged: (v) => setModal(() {
                          v == true
                              ? temp.add(lang.name)
                              : temp.remove(lang.name);
                        }),
                        title: Text(lang.name),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        activeColor: const Color(0xFF3E729F),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3E729F),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      setState(() => _selectedLanguages = temp.toList());
                      Navigator.pop(context);
                    },
                    child: const Text("Done",
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
              ],
            );
          }),
        );
      },
    );
  }

  Future<void> _submit() async {
    if (_isLoading) return;

    if (_fromController.text.isEmpty || _toController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select From and To airports")),
      );
      return;
    }

    if (_fromController.text.trim() == _toController.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Travel From and Travel To cannot be the same airport"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final now = DateTime.now();
    if (_selectedYear < now.year ||
        (_selectedYear == now.year && _selectedMonth < now.month)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Travel month cannot be in the past"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser!;
      final from = _fromController.text;
      final to = _toController.text;

      // ── MAX 1 ACTIVE GROUP POST PER USER ──────────────────────────────────
      QuerySnapshot myGroups;
      try {
        myGroups = await FirebaseFirestore.instance
            .collection('travel_groups')
            .where('createdBy', isEqualTo: currentUser.uid)
            .get(const GetOptions(source: Source.server));
      } catch (_) {
        myGroups = await FirebaseFirestore.instance
            .collection('travel_groups')
            .where('createdBy', isEqualTo: currentUser.uid)
            .get();
      }

      if (myGroups.docs.isNotEmpty) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                "You already have an active group post. Delete it before creating a new one."),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      // ─────────────────────────────────────────────────────────────────────

      // Create new group
      final groupRef = await FirebaseFirestore.instance
          .collection('travel_groups')
          .add({
        'fromLocation': from,
        'toLocation': to,
        'month': _selectedMonth,
        'year': _selectedYear,
        'description': _descriptionController.text.trim(),
        'preferredLanguages': _selectedLanguages,
        'createdBy': currentUser.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'participants': [currentUser.uid],
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      final newGroup = await groupRef.get();
      final groupData = newGroup.data()!;

      if (!mounted) return;
      setState(() => _isLoading = false);

      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GroupChatPage(
            groupId: groupRef.id,
            groupData: groupData,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final years = [now.year, now.year + 1];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Create Group Post"),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Share your travel plans to find group companions.",
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // ── FROM ──
            _label("Travel From *"),
            const SizedBox(height: 6),
            _locationField(_fromController, "Enter departure city or airport",
                () => _openAirportPicker(_fromController)),
            const SizedBox(height: 16),

            // ── TO ──
            _label("Travel To *"),
            const SizedBox(height: 6),
            _locationField(_toController, "Enter destination city or airport",
                () => _openAirportPicker(_toController)),
            const SizedBox(height: 20),

            // ── MONTH PICKER ──
            _label("Travel Month *"),
            const SizedBox(height: 10),

            // Year toggle
            Row(
              children: years.map((y) {
                final selected = _selectedYear == y;
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedYear = y;
                    if (y == now.year && _selectedMonth < now.month) {
                      _selectedMonth = now.month;
                    }
                  }),
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF3E729F)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "$y",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : Colors.grey.shade700,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),

            // Month grid
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 2.2,
              children: List.generate(12, (i) {
                final month = i + 1;
                // Disable past months in current year
                final isPast = _selectedYear == now.year && month < now.month;
                final selected = _selectedMonth == month;
                return GestureDetector(
                  onTap: isPast ? null : () => setState(() => _selectedMonth = month),
                  child: Container(
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF3E729F)
                          : isPast
                              ? Colors.grey.shade100
                              : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFF3E729F)
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _months[i],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: selected
                              ? Colors.white
                              : isPast
                                  ? Colors.grey.shade400
                                  : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),

            // ── LANGUAGES ──
            _label("User Preferred Languages"),
            const SizedBox(height: 6),
            TextField(
              readOnly: true,
              controller: TextEditingController(
                text: _selectedLanguages.isEmpty
                    ? ''
                    : _selectedLanguages.join(', '),
              ),
              onTap: _openLanguageSheet,
              decoration: InputDecoration(
                hintText: "Select user preferred languages",
                suffixIcon: const Icon(Icons.arrow_drop_down),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 20),

            // ── DESCRIPTION ──
            _label("Description"),
            const SizedBox(height: 6),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              maxLength: 200,
              decoration: InputDecoration(
                hintText: "Describe your travel plans, preferences, etc.",
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 24),

            // ── CONTINUE ──
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3E729F),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        "Continue",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    );
  }

  Widget _locationField(
      TextEditingController controller, String hint, VoidCallback onTap) {
    return TextField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.location_on_outlined),
        suffixIcon: const Icon(Icons.flight),
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }
}
