import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ip_country_lookup/ip_country_lookup.dart';
import 'package:ip_country_lookup/models/ip_country_data_model.dart';

/// Result of Google authentication
enum GoogleAuthStatus { newUser, existingUser }

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  IpCountryData? countryData;
  String? usersPublicIpAddress;
  /* -------------------------------------------------------------------------- */
  /*                               COMMON HELPERS                               */
  /* -------------------------------------------------------------------------- */

  bool _isAbove18(String dob) {
    final parts = dob.split('/');
    final birthDate = DateTime(
      int.parse(parts[2]),
      int.parse(parts[1]),
      int.parse(parts[0]),
    );

    final today = DateTime.now();
    int age = today.year - birthDate.year;

    if (today.month < birthDate.month ||
        (today.month == birthDate.month &&
            today.day < birthDate.day)) {
      age--;
    }

    return age >= 18;
  }

  Future<bool> isUsernameAlreadyTaken(String username) async {
    final query = await _firestore
        .collection('users')
        .where('username', isEqualTo: username.trim())
        .limit(1)
        .get();

    return query.docs.isNotEmpty;
  }

  /* -------------------------------------------------------------------------- */
  /*                          🔐 AUTH EVENT LOGGER                               */
  /* -------------------------------------------------------------------------- */

  Future<void> _logAuthEvent({
    required String uid,
    required String email,
    required String event, // login | logout
    required String provider,
    required String deviceType,
  }) async {
    countryData = await IpCountryLookup().getIpLocationData();
    await _firestore.collection('auth_logs').add({
      'uid': uid,
      'email': email,
      'event': event,
      'provider': provider,
      'deviceType': deviceType,
      'timestamp': FieldValue.serverTimestamp(),
      'ip':countryData!.ip.toString()
    });
  }

  /* -------------------------------------------------------------------------- */
  /*                               EMAIL SIGNUP                                 */
  /* -------------------------------------------------------------------------- */

  Future<void> createUser({
    required String email,
    required String password,
    required String username,
    required String contact,
    required String dob,
    required String deviceType,
    double? latitude,
    double? longitude,
  }) async {
    if (!_isAbove18(dob)) {
      throw 'You must be at least 18 years old to register';
    }

    if (await isUsernameAlreadyTaken(username)) {
      throw 'Username already taken';
    }

    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final uid = cred.user!.uid;

    await _firestore.collection('users').doc(uid).set({
      'uid': uid,
      'email': email.trim(),
      'username': username.trim(),
      'contact': contact.trim(),
      'dob': dob,
      'ageVerified': true,
      'provider': 'email',
      'deviceType': deviceType,

      // 📍 Location
      'location': latitude != null && longitude != null
          ? {
        'lat': latitude,
        'lng': longitude,
      }
          : null,

      // ⭐ RATINGS (NEW)
      'rating': 0.0,
      'ratingCount': 0,
      'totalTrips': 0,

      // 🧩 META
      'profileCompleted': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /* -------------------------------------------------------------------------- */
  /*                                EMAIL LOGIN                                 */
  /* -------------------------------------------------------------------------- */

  Future<void> loginWithEmail({
    required String email,
    required String password,
    required String deviceType,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = cred.user!;

    await _logAuthEvent(
      uid: user.uid,
      email: user.email ?? email,
      event: 'login',
      provider: 'email',
      deviceType: deviceType,
    );
  }

  /* -------------------------------------------------------------------------- */
  /*                              GOOGLE SIGN-IN                                */
  /* -------------------------------------------------------------------------- */

  Future<GoogleAuthStatus> signInWithGoogle({
    required String deviceType,
  }) async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn(
      serverClientId: '252418943052-flgu143l4ll0ai8evm73m08t5lhkt173.apps.googleusercontent.com',
    ).signIn();

    if (googleUser == null) {
      throw 'Google sign-in cancelled';
    }

    final googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final UserCredential userCredential =
    await _auth.signInWithCredential(credential);

    final user = userCredential.user!;
    final uid = user.uid;

    await _logAuthEvent(
      uid: uid,
      email: user.email ?? '',
      event: 'login',
      provider: 'google',
      deviceType: deviceType,
    );

    final doc =
    await _firestore.collection('users').doc(uid).get();

    return doc.exists
        ? GoogleAuthStatus.existingUser
        : GoogleAuthStatus.newUser;
  }

  /* -------------------------------------------------------------------------- */
  /*                       COMPLETE GOOGLE PROFILE                               */
  /* -------------------------------------------------------------------------- */

  Future<void> completeGoogleSignup({
    required String username,
    required String dob,
    String? phone,
    required String deviceType,
    double? latitude,
    double? longitude,
  }) async {
    if (!_isAbove18(dob)) {
      throw 'You must be at least 18 years old to register';
    }

    if (await isUsernameAlreadyTaken(username)) {
      throw 'Username already taken';
    }

    final user = _auth.currentUser!;
    final uid = user.uid;

    await _firestore.collection('users').doc(uid).set({
      'uid': uid,
      'email': user.email,
      'username': username.trim(),
      'contact': phone?.trim() ?? '',
      'dob': dob,
      'ageVerified': true,
      'provider': 'google',
      'deviceType': deviceType,

      // 📍 Location
      'location': latitude != null && longitude != null
          ? {
        'lat': latitude,
        'lng': longitude,
      }
          : null,

      // ⭐ RATINGS (NEW)
      'rating': 0.0,
      'ratingCount': 0,
      'totalTrips': 0,

      // 🧩 META
      'profileCompleted': true,
      'createdAt': FieldValue.serverTimestamp(),
    });

  }

  /* -------------------------------------------------------------------------- */
  /*                                   LOGOUT                                   */
  /* -------------------------------------------------------------------------- */

  Future<void> logout({
    required String deviceType,
  }) async {
    final user = _auth.currentUser;

    if (user != null) {
      await _logAuthEvent(
        uid: user.uid,
        email: user.email ?? '',
        event: 'logout',
        provider: user.providerData.isNotEmpty
            ? user.providerData.first.providerId
            : 'unknown',
        deviceType: deviceType,
      );
    }

    await GoogleSignIn(
      serverClientId: '252418943052-flgu143l4ll0ai8evm73m08t5lhkt173.apps.googleusercontent.com',
    ).signOut();
    await _auth.signOut();
  }
}
