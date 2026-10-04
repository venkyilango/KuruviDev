// import 'package:flutter/material.dart';
// import 'package:country_picker/country_picker.dart';
//
// class CreateTravelAdPage extends StatefulWidget {
//   const CreateTravelAdPage({super.key});
//
//   @override
//   State<CreateTravelAdPage> createState() => _CreateTravelAdPageState();
// }
//
// class _CreateTravelAdPageState extends State<CreateTravelAdPage> {
//   String _selectedService = "Travel Partner";
//   String _travelPartnerType = "Looking";
//   String _parcelType = "Receive";
//   bool _alreadyBooked = false;
//
//   final TextEditingController _fromLocationController =
//   TextEditingController();
//   final TextEditingController _toLocationController =
//   TextEditingController();
//
//   final TextEditingController _singleDateController =
//   TextEditingController();
//   final TextEditingController _fromDateController =
//   TextEditingController();
//   final TextEditingController _toDateController =
//   TextEditingController();
//
//   final List<String> _companionOptions = ["Any", "Male", "Female"];
//   String _selectedCompanion = "Any";
//
//   void _resetDates() {
//     _singleDateController.clear();
//     _fromDateController.clear();
//     _toDateController.clear();
//   }
//
//   Future<void> _pickDate(TextEditingController controller) async {
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now(),
//       firstDate: DateTime.now(),
//       lastDate: DateTime.now().add(const Duration(days: 365)),
//     );
//
//     if (picked != null) {
//       setState(() {
//         controller.text =
//         "${picked.day}/${picked.month}/${picked.year}";
//       });
//     }
//   }
//
//   // ✅ CORRECT COUNTRY PICKER
//   void _openCountryPicker(TextEditingController controller) {
//     showCountryPicker(
//       context: context,
//       showPhoneCode: false,
//       onSelect: (Country country) {
//         controller.text =
//         "${country.flagEmoji} ${country.name}";
//       },
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.black,
//         elevation: 0,
//         title: const Text(
//           "Create Your Travel Ad",
//           style: TextStyle(fontWeight: FontWeight.w600),
//         ),
//       ),
//
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//
//             const Text(
//               "Share your travel plans to find the perfect travel partner or reliable cargo for your journey.",
//             ),
//
//             const SizedBox(height: 24),
//
//             const Text("Select Service *"),
//             const SizedBox(height: 8),
//
//             Row(
//               children: [
//                 _ServiceCard(
//                   icon: Icons.people_outline,
//                   label: "Travel Partner",
//                   isSelected: _selectedService == "Travel Partner",
//                   onTap: () {
//                     setState(() {
//                       _selectedService = "Travel Partner";
//                       _alreadyBooked = false;
//                       _resetDates();
//                     });
//                   },
//                 ),
//                 const SizedBox(width: 12),
//                 _ServiceCard(
//                   icon: Icons.inventory_2_outlined,
//                   label: "Carry Parcel",
//                   isSelected: _selectedService == "Carry Parcel",
//                   onTap: () {
//                     setState(() {
//                       _selectedService = "Carry Parcel";
//                       _alreadyBooked = false;
//                       _resetDates();
//                     });
//                   },
//                 ),
//               ],
//             ),
//
//             const SizedBox(height: 20),
//
//             if (_selectedService == "Travel Partner") ...[
//               const Text("What are you looking for?"),
//               _radioTile(
//                 "I'm looking for a companion",
//                 "Looking",
//                 _travelPartnerType,
//                     (v) => setState(() => _travelPartnerType = v),
//               ),
//               _radioTile(
//                 "I will be a companion",
//                 "Offering",
//                 _travelPartnerType,
//                     (v) => setState(() => _travelPartnerType = v),
//               ),
//             ],
//
//             if (_selectedService == "Carry Parcel") ...[
//               const Text("Parcel Preference"),
//               _radioTile(
//                 "I want to receive a parcel",
//                 "Receive",
//                 _parcelType,
//                     (v) => setState(() => _parcelType = v),
//               ),
//               _radioTile(
//                 "I can carry a parcel",
//                 "Carry",
//                 _parcelType,
//                     (v) => setState(() => _parcelType = v),
//               ),
//             ],
//
//             const SizedBox(height: 20),
//
//             Row(
//               children: [
//                 Switch(
//                   value: _alreadyBooked,
//                   activeColor: const Color(0xFF3E729F),
//                   onChanged: (v) {
//                     setState(() {
//                       _alreadyBooked = v;
//                       _resetDates();
//                     });
//                   },
//                 ),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: Text(
//                     _selectedService == "Travel Partner"
//                         ? "Already booked your flight?"
//                         : "Already booked your travel?",
//                     style: const TextStyle(fontWeight: FontWeight.w600),
//                   ),
//                 ),
//               ],
//             ),
//
//             if (_alreadyBooked &&
//                 _selectedService == "Travel Partner") ...[
//               _buildTextField("Flight Number", "Enter flight number"),
//               _buildTextField("Airline Name", "Enter airline name"),
//             ],
//
//             const SizedBox(height: 12),
//
//             _buildLocationField(
//               label: "Travel From *",
//               controller: _fromLocationController,
//               onTap: () => _openCountryPicker(_fromLocationController),
//             ),
//
//             _buildLocationField(
//               label: "Travel To *",
//               controller: _toLocationController,
//               onTap: () => _openCountryPicker(_toLocationController),
//             ),
//
//             const SizedBox(height: 16),
//
//             if (_alreadyBooked) ...[
//               _buildDateField(
//                 "Travel Date *",
//                 _singleDateController,
//                     () => _pickDate(_singleDateController),
//               ),
//             ] else ...[
//               Row(
//                 children: [
//                   Expanded(
//                     child: _buildDateField(
//                       "From Date *",
//                       _fromDateController,
//                           () => _pickDate(_fromDateController),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: _buildDateField(
//                       "To Date *",
//                       _toDateController,
//                           () => _pickDate(_toDateController),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//
//             if (_selectedService == "Travel Partner" &&
//                 _travelPartnerType == "Looking") ...[
//               const SizedBox(height: 16),
//               const Text("Preferred travel companion"),
//               const SizedBox(height: 8),
//
//               Row(
//                 children: _companionOptions.map((option) {
//                   return Expanded(
//                     child: Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 4),
//                       child: GestureDetector(
//                         onTap: () =>
//                             setState(() => _selectedCompanion = option),
//                         child: _ChoiceChip(
//                           label: option,
//                           selected: _selectedCompanion == option,
//                         ),
//                       ),
//                     ),
//                   );
//                 }).toList(),
//               ),
//
//               const SizedBox(height: 16),
//               _buildTextField("No. of partners", "Enter number of partners"),
//
//               Row(
//                 children: [
//                   Expanded(
//                     child: _buildTextField(
//                         "Traveler Name *", "Enter traveler name"),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: _buildTextField(
//                         "Traveler Age *", "Enter traveler age"),
//                   ),
//                 ],
//               ),
//             ],
//
//             _buildTextField("Pricing *", "Enter pricing"),
//
//             const SizedBox(height: 30),
//
//             SizedBox(
//               width: double.infinity,
//               height: 48,
//               child: ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFF3E729F),
//                 ),
//                 onPressed: () {},
//                 child: const Text(
//                   "Continue",
//                   style: TextStyle(color: Colors.white),
//                 ),
//               ),
//             ),
//
//             const SizedBox(height: 40),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _radioTile(
//       String title, String value, String group, Function(String) onChanged) {
//     return RadioListTile<String>(
//       title: Text(title),
//       value: value,
//       groupValue: group,
//       onChanged: (v) => onChanged(v!),
//       activeColor: const Color(0xFF3E729F),
//       contentPadding: EdgeInsets.zero,
//     );
//   }
//
//   static Widget _buildTextField(String label, String hint) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(label),
//         const SizedBox(height: 6),
//         TextField(
//           decoration: InputDecoration(
//             hintText: hint,
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(8),
//             ),
//           ),
//         ),
//         const SizedBox(height: 12),
//       ],
//     );
//   }
// }
//
// // 🔹 Location field
// Widget _buildLocationField({
//   required String label,
//   required TextEditingController controller,
//   required VoidCallback onTap,
// }) {
//   return Column(
//     crossAxisAlignment: CrossAxisAlignment.start,
//     children: [
//       Text(label),
//       const SizedBox(height: 6),
//       TextField(
//         controller: controller,
//         readOnly: true,
//         onTap: onTap,
//         decoration: InputDecoration(
//           hintText: "Select country",
//           suffixIcon: const Icon(Icons.search),
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(8),
//           ),
//         ),
//       ),
//       const SizedBox(height: 12),
//     ],
//   );
// }
//
// // 🔹 Date field
// Widget _buildDateField(
//     String label, TextEditingController controller, VoidCallback onTap) {
//   return Column(
//     crossAxisAlignment: CrossAxisAlignment.start,
//     children: [
//       Text(label),
//       const SizedBox(height: 6),
//       TextField(
//         controller: controller,
//         readOnly: true,
//         onTap: onTap,
//         decoration: InputDecoration(
//           hintText: "Select date",
//           suffixIcon: const Icon(Icons.calendar_today),
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(8),
//           ),
//         ),
//       ),
//       const SizedBox(height: 12),
//     ],
//   );
// }
//
// // 🔹 Service card
// class _ServiceCard extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final bool isSelected;
//   final VoidCallback onTap;
//
//   const _ServiceCard({
//     required this.icon,
//     required this.label,
//     required this.isSelected,
//     required this.onTap,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Expanded(
//       child: GestureDetector(
//         onTap: onTap,
//         child: Container(
//           padding: const EdgeInsets.all(14),
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(10),
//             border: Border.all(
//               color: isSelected
//                   ? const Color(0xFF3E729F)
//                   : Colors.grey.shade300,
//             ),
//             color: isSelected
//                 ? const Color(0xFFEAF2FA)
//                 : Colors.white,
//           ),
//           child: Column(
//             children: [
//               Icon(
//                 icon,
//                 color: isSelected
//                     ? const Color(0xFF3E729F)
//                     : Colors.grey,
//               ),
//               const SizedBox(height: 6),
//               Text(label),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// // 🔹 Choice chip
// class _ChoiceChip extends StatelessWidget {
//   final String label;
//   final bool selected;
//
//   const _ChoiceChip({required this.label, required this.selected});
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: 40,
//       alignment: Alignment.center,
//       decoration: BoxDecoration(
//         color: selected ? const Color(0xFFEAF2FA) : Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(
//           color: selected
//               ? const Color(0xFF3E729F)
//               : Colors.grey.shade300,
//         ),
//       ),
//       child: Text(label),
//     );
//   }
// }



import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:language_picker/languages.dart';
import 'package:travel/utils/airports_data.dart';

class CreateTravelAdPage extends StatefulWidget {
  const CreateTravelAdPage({super.key});

  @override
  State<CreateTravelAdPage> createState() => _CreateTravelAdPageState();
}

class _CreateTravelAdPageState extends State<CreateTravelAdPage> {
  // 🔹 FORM KEY
  final _formKey = GlobalKey<FormState>();

  // 🔹 STATE
  String _selectedService = "Travel Partner";
  String _travelPartnerType = "Looking";
  String _parcelType = "Receive";
  bool _alreadyBooked = false;
  bool _isSubmitting = false;

  // 🔹 CONTROLLERS (existing + required for validation/storage)
  final _fromLocationController = TextEditingController();
  final _toLocationController = TextEditingController();

  final _singleDateController = TextEditingController();
  final _fromDateController = TextEditingController();
  final _toDateController = TextEditingController();
  final _parcelWeightController = TextEditingController();

  final _flightNumberController = TextEditingController();
  final _airlineController = TextEditingController();
  final _partnersController = TextEditingController();
  final _travelerNameController = TextEditingController();
  final _travelerAgeController = TextEditingController();
  final _priceController = TextEditingController();
  final _remarksController = TextEditingController();

  final List<String> _companionOptions = ["Any", "Male", "Female"];
  String _selectedCompanion = "Any";

  String _defaultRemarks() {
    if (_selectedService == "Travel Partner") {
      return _travelPartnerType == "Looking"
          ? "I am looking for a companion for travel or activities. Please reach out with your location and plans so we can discuss details."
          : "I am happy to provide companionship for travel or errands. Share your route and schedule, and we can discuss arrangements.";
    } else {
      return _parcelType == "Receive"
          ? "I am looking to receive a parcel. If someone is traveling from my desired city, let's connect to discuss locations and details."
          : "I can carry parcels for others while travelling. Let's discuss the arrangements and service charges.";
    }
  }

  void _refreshDefaultRemarks() {
    _remarksController.text = _defaultRemarks();
  }

  // Language selection
  final List<Language> _availableLanguages = Languages.defaultLanguages;
  List<String> _selectedLanguages = [];

  @override
  void initState() {
    super.initState();
    _remarksController.text = _defaultRemarks();
  }

  DateTime _parseDate(String value) {
    final parts = value.split('/');
    return DateTime(
      int.parse(parts[2]),
      int.parse(parts[1]),
      int.parse(parts[0]),
    );
  }


  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }



  // 🔹 HELPERS
  void _resetDates() {
    _singleDateController.clear();
    _fromDateController.clear();
    _toDateController.clear();
  }

  Future<void> _pickDate(TextEditingController controller, {DateTime? minDate}) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final earliest = minDate != null && minDate.isAfter(today) ? minDate : today;
    final picked = await showDatePicker(
      context: context,
      initialDate: earliest,
      firstDate: earliest,
      lastDate: today.add(const Duration(days: 365)),
    );

    if (picked != null) {
      controller.text =
      "${picked.day}/${picked.month}/${picked.year}";
    }
  }

  Future<void> _openAirportPicker(TextEditingController controller) async {
    final other = controller == _fromLocationController
        ? _toLocationController.text.trim()
        : _fromLocationController.text.trim();
    await showAirportPicker(context, (value) {
      setState(() => controller.text = value);
    }, excludeAirport: other.isNotEmpty ? other : null);
  }

  void _openLanguageSelectionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        Set<String> tempSelectedLanguages = Set.from(_selectedLanguages);
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
                        setState(() {
                          _selectedLanguages.clear();
                          _selectedLanguages.addAll(tempSelectedLanguages);
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

  // 🔹 SUBMIT (VALIDATION + FIRESTORE)
  Future<void> _submitForm() async {
    if (_isSubmitting) return;
    _isSubmitting = true;
    setState(() {});

    if (!_formKey.currentState!.validate()) {
      _isSubmitting = false;
      setState(() {});
      return;
    }

    try {
    final today = DateTime.now();
    final now = DateTime(today.year, today.month, today.day);

    if (_alreadyBooked) {
      final travelDate = _parseDate(_singleDateController.text);

      if (travelDate.isBefore(now)) {
        _showError("Travel date cannot be earlier than today");
        return;
      }
    } else {
      final fromDate = _parseDate(_fromDateController.text);
      final toDate = _parseDate(_toDateController.text);

      if (fromDate.isBefore(now)) {
        _showError("From Date cannot be earlier than today");
        return;
      }

      if (toDate.isBefore(now)) {
        _showError("To Date cannot be earlier than today");
        return;
      }

      if (fromDate.isAfter(toDate)) {
        _showError("From Date cannot be after To Date");
        return;
      }
    }

    // ❌ FROM & TO LOCATION SHOULD NOT BE SAME
    if (_fromLocationController.text.trim() ==
        _toLocationController.text.trim()) {
      _showError("Travel From and Travel To cannot be the same");
      return;
    }


    // 🔹 DATE RANGE VALIDATION
    if (!_alreadyBooked) {
      final fromDate = _parseDate(_fromDateController.text);
      final toDate = _parseDate(_toDateController.text);

      if (fromDate.isAfter(toDate)) {
        _showError("From Date cannot be after To Date");
        return;
      }
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;

    // ── MAX 3 ACTIVE INDIVIDUAL POSTS ──────────────────────────────────────
    final activeAds = await FirebaseFirestore.instance
        .collection('travel_ads')
        .where('userId', isEqualTo: uid)
        .where('status', isEqualTo: 0)
        .get();

    if (activeAds.docs.length >= 3) {
      _showError(
          "You can have at most 3 active posts. Please delete an existing post before creating a new one.");
      return;
    }
    // ───────────────────────────────────────────────────────────────────────

    final payload = {
      "userId": uid,
      "service": _selectedService,
      "travelPartnerType": _travelPartnerType,
      "parcelType": _parcelType,
      "fromLocation": _fromLocationController.text,
      "toLocation": _toLocationController.text,
      "alreadyBooked": _alreadyBooked,
      "status" : 0,
      "travelDate": _alreadyBooked ? _singleDateController.text : null,
      "fromDate": !_alreadyBooked ? _fromDateController.text : null,
      "toDate": !_alreadyBooked ? _toDateController.text : null,
      "flightNumber":
      _alreadyBooked && _selectedService == "Travel Partner"
          ? _flightNumberController.text
          : null,
      "airline":
      _alreadyBooked && _selectedService == "Travel Partner"
          ? _airlineController.text
          : null,
      "preferredCompanion": _selectedCompanion,
      "parcelWeight": _selectedService == "Carry Parcel"
          ? _parcelWeightController.text
          : null,

      "partners": _partnersController.text,
      "travelerName": _travelerNameController.text,
      "travelerAge": _travelerAgeController.text,
      "price": _priceController.text,
      "preferredLanguages": _selectedLanguages,
      "remarks": _remarksController.text.trim(),
      "createdAt": FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection("travel_ads")
        .add(payload);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Ad created successfully")),
    );

    Navigator.pop(context);
    } catch (e) {
      if (mounted) _showError("Something went wrong. Please try again.");
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // 🔹 UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          "Create Your Travel Ad",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// ---------- YOUR ORIGINAL UI (UNCHANGED) ----------

              const Text(
                "Share your travel plans to find the perfect travel partner or reliable cargo for your journey.",
              ),

              const SizedBox(height: 24),

              const Text("Select Service *"),
              const SizedBox(height: 8),

              Row(
                children: [
                  _ServiceCard(
                    icon: Icons.people_outline,
                    label: "Travel Partner",
                    isSelected: _selectedService == "Travel Partner",
                    onTap: () {
                      setState(() {
                        _selectedService = "Travel Partner";
                        _alreadyBooked = false;
                        _resetDates();
                      });
                      _refreshDefaultRemarks();
                    },
                  ),
                  const SizedBox(width: 12),
                  _ServiceCard(
                    icon: Icons.inventory_2_outlined,
                    label: "Carry Parcel",
                    isSelected: _selectedService == "Carry Parcel",
                    onTap: () {
                      setState(() {
                        _selectedService = "Carry Parcel";
                        _alreadyBooked = false;
                        _resetDates();
                      });
                      _refreshDefaultRemarks();
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),

              if (_selectedService == "Travel Partner") ...[
                const Text("What are you looking for?"),
                _radioTile(
                  "I'm looking for a companion",
                  "Looking",
                  _travelPartnerType,
                      (v) { setState(() => _travelPartnerType = v); _refreshDefaultRemarks(); },
                ),
                _radioTile(
                  "I will be a companion",
                  "Offering",
                  _travelPartnerType,
                      (v) { setState(() => _travelPartnerType = v); _refreshDefaultRemarks(); },
                ),
              ],

              if (_selectedService == "Carry Parcel") ...[
                const Text("Parcel Preference"),
                _radioTile(
                  "I want to receive a parcel",
                  "Receive",
                  _parcelType,
                      (v) { setState(() => _parcelType = v); _refreshDefaultRemarks(); },
                ),
                _radioTile(
                  "I can carry a parcel",
                  "Carry",
                  _parcelType,
                      (v) { setState(() => _parcelType = v); _refreshDefaultRemarks(); },
                ),
              ],

              const SizedBox(height: 20),

              Row(
                children: [
                  Switch(
                    value: _alreadyBooked,
                    activeColor: const Color(0xFF3E729F),
                    onChanged: (v) {
                      setState(() {
                        _alreadyBooked = v;
                        _resetDates();
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedService == "Travel Partner"
                          ? "Already booked your flight?"
                          : "Already booked your travel?",
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),

              if (_alreadyBooked && _selectedService == "Travel Partner") ...[
                _buildTextField(
                  "Flight Number",
                  "Enter flight number",
                  controller: _flightNumberController,
                  maxLength: 8,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                  ],
                  validator: (v) =>
                  v == null || v.isEmpty ? "Required" : null,
                ),
                _buildTextField(
                  "Airline Name",
                  "Enter airline name",
                  controller: _airlineController,
                  maxLength: 15,
                  validator: (v) =>
                  v == null || v.isEmpty ? "Required" : null,
                ),
              ],

              _buildLocationField(
                label: "Travel From *",
                controller: _fromLocationController,
                onTap: () =>
                    _openAirportPicker(_fromLocationController),
                validator: (v) =>
                v == null || v.isEmpty ? "Required" : null,
              ),

              _buildLocationField(
                label: "Travel To *",
                controller: _toLocationController,
                onTap: () =>
                    _openAirportPicker(_toLocationController),
                validator: (v) =>
                v == null || v.isEmpty ? "Required" : null,
              ),

              if (_alreadyBooked)
                _buildDateField(
                  "Travel Date *",
                  _singleDateController,
                      () => _pickDate(_singleDateController),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: _buildDateField(
                        "From Date *",
                        _fromDateController,
                            () => _pickDate(_fromDateController),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDateField(
                        "To Date *",
                        _toDateController,
                            () {
                          DateTime? fromDate;
                          if (_fromDateController.text.isNotEmpty) {
                            final parts = _fromDateController.text.split('/');
                            if (parts.length == 3) {
                              fromDate = DateTime(
                                int.parse(parts[2]),
                                int.parse(parts[1]),
                                int.parse(parts[0]),
                              );
                            }
                          }
                          _pickDate(_toDateController, minDate: fromDate);
                        },
                      ),
                    ),
                  ],
                ),

              SizedBox(height: 15,),
              if (_selectedService == "Travel Partner" &&
                  _travelPartnerType == "Looking") ...[
                const Text("Preferred travel companion"),
                const SizedBox(height: 15),
                Row(
                  children: _companionOptions.map((option) {
                    return Expanded(
                      child: Padding(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 4),
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedCompanion = option),
                          child: _ChoiceChip(
                            label: option,
                            selected: _selectedCompanion == option,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                SizedBox(height: 20,),
                _buildTextField(
                  "No. of partners",
                  "Enter number of partners",
                  controller: _partnersController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                ),
                SizedBox(height: 15,),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        "Traveler Name *",
                        "Enter traveler name",
                        controller: _travelerNameController,
                        maxLength: 15,
                        validator: (v) =>
                        v == null || v.isEmpty ? "Required" : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        "Traveler Age *",
                        "Enter traveler age",
                        controller: _travelerAgeController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (v) =>
                        v == null || v.isEmpty ? "Required" : null,
                      ),
                    ),
                  ],
                ),
              ],


              if (_selectedService == "Carry Parcel") ...[
                const SizedBox(height: 10),
                _buildTextField(
                  "Parcel Weight *",
                  "Max 99 kg",
                  controller: _parcelWeightController,
                  keyboardType: TextInputType.number,
                  maxLength: 2,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: (v) {
                    if (v == null || v.isEmpty) return "Required";
                    final val = int.tryParse(v);
                    if (val == null || val < 1 || val > 99) return "Enter 1-99 kg";
                    return null;
                  },
                ),
              ],


              SizedBox(height: 15,),

              /// LANGUAGE SELECTION
              const Text("Preferred Languages"),
              const SizedBox(height: 6),
              TextFormField(
                readOnly: true,
                controller: TextEditingController(
                  text: _selectedLanguages.isEmpty
                      ? ''
                      : _selectedLanguages.join(', ')
                ),
                decoration: InputDecoration(
                  hintText: "Select preferred languages",
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onTap: _openLanguageSelectionSheet,
              ),
              const SizedBox(height: 12),

              /// REMARKS
              const Text("Remarks"),
              const SizedBox(height: 6),
              TextFormField(
                controller: _remarksController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: "Add a note for others…",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 12),

              _buildTextField(
                "Pricing (USD) *",
                "Enter amount in USD",
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return "Required";
                  }
                  if (double.tryParse(v) == null) {
                    return "Enter a valid amount";
                  }
                  if (double.parse(v) < 0) {
                    return "Amount cannot be negative";
                  }
                  if (double.parse(v) > 500) {
                    return "Maximum price is \$500";
                  }
                  return null;
                },
              ),



              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3E729F),
                  ),
                  onPressed: _isSubmitting ? null : _submitForm,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text(
                          "Submit",
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _radioTile(
      String title, String value, String group, Function(String) onChanged) {
    return RadioListTile<String>(
      title: Text(title),
      value: value,
      groupValue: group,
      onChanged: (v) => onChanged(v!),
      activeColor: const Color(0xFF3E729F),
      contentPadding: EdgeInsets.zero,
    );
  }


  static Widget _buildTextField(
      String label,
      String hint, {
        TextEditingController? controller,
        String? Function(String?)? validator,
        TextInputType keyboardType = TextInputType.text,
        List<TextInputFormatter>? inputFormatters,
        int? maxLength,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLength: maxLength,
          decoration: InputDecoration(
            hintText: hint,
            counterText: maxLength != null ? null : "",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

}



/// 🔹 Location field
Widget _buildLocationField({
  required String label,
  required TextEditingController controller,
  required VoidCallback onTap,
  String? Function(String?)? validator,

}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label),
      const SizedBox(height: 6),
      TextFormField(
        controller: controller,
        readOnly: true,
        validator: validator,
        onTap: onTap,
        decoration: InputDecoration(
          hintText: "Select airport",
          suffixIcon: const Icon(Icons.flight),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      const SizedBox(height: 12),
    ],
  );
}

/// 🔹 Date field
Widget _buildDateField(
    String label, TextEditingController controller, VoidCallback onTap) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label),
      const SizedBox(height: 6),
      TextFormField(
        controller: controller,
        readOnly: true,
        validator: (v) =>
        v == null || v.isEmpty ? "Required" : null,
        onTap: onTap,
        decoration: InputDecoration(
          hintText: "Select date",
          suffixIcon: const Icon(Icons.calendar_today),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      const SizedBox(height: 12),
    ],
  );
}




/// 🔹 Service card
class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF3E729F)
                  : Colors.grey.shade300,
            ),
            color: isSelected
                ? const Color(0xFFEAF2FA)
                : Colors.white,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? const Color(0xFF3E729F)
                    : Colors.grey,
              ),
              const SizedBox(height: 6),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}

/// 🔹 Choice chip
class _ChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;

  const _ChoiceChip({required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFEAF2FA) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected
              ? const Color(0xFF3E729F)
              : Colors.grey.shade300,
        ),
      ),
      child: Text(label),
    );
  }
}
