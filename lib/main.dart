// Session 7 translation table
// MoMo Wallet        -> My Week
// Txn, txn.dart      -> Course, models/course.dart
// transactions       -> courses
// TxnRepository      -> CourseRepository
// WalletState        -> WeekState
// balance            -> weekMinutes (total of the week)
// WalletScreen       -> WeekScreen
// TxnForm            -> CourseScreen

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'screens/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: kIsWeb ? webFirebaseOptions : null);
  runApp(const MyWeekApp());
}

class MyWeekApp extends StatelessWidget {
  const MyWeekApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Week',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.teal),
      home: const AuthGate(),
    );
  }
}
