import 'dart:async';
 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'
    hide EmailAuthProvider, PhoneAuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
 
import 'firebase_options.dart';
import 'guest_book_message.dart';
 
class ApplicationState extends ChangeNotifier {
  ApplicationState() {
    init();
  }
 
  bool _loggedIn = false;
  bool get loggedIn => _loggedIn;
 
  bool _emailVerified = false;
  bool get emailVerified => _emailVerified;
 
  StreamSubscription<QuerySnapshot>? _guestBookSubscription;
  List<GuestBookMessage> _guestBookMessages = [];
  List<GuestBookMessage> get guestBookMessages => _guestBookMessages;
 
  // Total number of people going, summed across every user's document.
  int _attendees = 0;
  int get attendees => _attendees;
 
  // How many people the signed-in user is bringing (including themselves).
  int _myGuests = 0;
  StreamSubscription<DocumentSnapshot>? _myGuestsSubscription;
  int get myGuests => _myGuests;
  set myGuests(int n) {
    FirebaseFirestore.instance
        .collection('attendees')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .set(<String, dynamic>{'guests': n});
  }
 
  Future<void> init() async {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
 
    FirebaseUIAuth.configureProviders([
      EmailAuthProvider(),
    ]);
 
    // Sum every user's guest count to get the total going.
    FirebaseFirestore.instance
        .collection('attendees')
        .snapshots()
        .listen((snapshot) {
      _attendees = snapshot.docs.fold(
          0, (sum, doc) => sum + ((doc.data()['guests'] as int?) ?? 0));
      notifyListeners();
    });
 
    FirebaseAuth.instance.userChanges().listen((user) {
      if (user != null) {
        _loggedIn = true;
        _emailVerified = user.emailVerified;
        _guestBookSubscription = FirebaseFirestore.instance
            .collection('guestbook')
            .orderBy('timestamp', descending: true)
            .snapshots()
            .listen((snapshot) {
          _guestBookMessages = [];
          for (final document in snapshot.docs) {
            _guestBookMessages.add(
              GuestBookMessage(
                name: document.data()['name'] as String,
                message: document.data()['text'] as String,
              ),
            );
          }
          notifyListeners();
        });
        // Watch this user's own document; no document means 0 guests.
        _myGuestsSubscription = FirebaseFirestore.instance
            .collection('attendees')
            .doc(user.uid)
            .snapshots()
            .listen((snapshot) {
          _myGuests = (snapshot.data()?['guests'] as int?) ?? 0;
          notifyListeners();
        });
      } else {
        _loggedIn = false;
        _emailVerified = false;
        _guestBookMessages = [];
        _myGuests = 0;
        _guestBookSubscription?.cancel();
        _myGuestsSubscription?.cancel();
      }
      notifyListeners();
    });
  }
 
  Future<DocumentReference> addMessageToGuestBook(String message) {
    if (!_loggedIn) {
      throw Exception('Must be logged in');
    }
 
    return FirebaseFirestore.instance
        .collection('guestbook')
        .add(<String, dynamic>{
      'text': message,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'name': FirebaseAuth.instance.currentUser!.displayName,
      'userId': FirebaseAuth.instance.currentUser!.uid,
    });
  }
}
 