import 'package:fitness_tracker/AddWorkout.dart';
import 'package:fitness_tracker/Dashboard.dart';
import 'package:fitness_tracker/WorkoutLogin.dart';
import 'package:fitness_tracker/Workout_register.dart';
import 'package:fitness_tracker/Achievements.dart';
//import 'package:fitness_tracker/ViewWorkout.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';





void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyCwpBcjNPKhXt9iyfuzdkhKsaVHIztUCX0",
      projectId: "exampractise02",
      messagingSenderId: "862435494699",
      appId: "1:862435494699:web:3d595a7ba2f7f3727b536e"
    )
  );
  
  // Check auth state on startup
  final auth = FirebaseAuth.instance;
  print('Initial auth state: ${auth.currentUser?.uid}');
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Workout Tracker Pro',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        fontFamily: 'Roboto',
      ),
      // Use this approach instead
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        print('AuthWrapper - Connection state: ${snapshot.connectionState}');
        print('AuthWrapper - Has data: ${snapshot.hasData}');
        print('AuthWrapper - User: ${snapshot.data?.email}');
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        if (snapshot.hasData && snapshot.data != null) {
          return const Dashboard();
        }
        
        return const WorkoutLogin();
      },
    );
  }
}
