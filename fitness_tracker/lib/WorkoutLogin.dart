
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_tracker/workout_register.dart';
import 'package:fitness_tracker/Dashboard.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
class WorkoutLogin extends StatefulWidget {
  const WorkoutLogin({super.key});

  @override
  State<WorkoutLogin> createState() => _WorkoutLoginState();
}

class _WorkoutLoginState extends State<WorkoutLogin> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  FirebaseFirestore firestore = FirebaseFirestore.instance;

  final FirebaseAuth auth = FirebaseAuth.instance;



  // void login() async {
  //   if (emailController.text.isNotEmpty && passwordController.text.isNotEmpty) {
  //     var collection = firestore.collection('workoutUsers');
  //     var querySnapshot = await collection
  //         .where('email', isEqualTo: emailController.text)
  //         .where('password', isEqualTo: passwordController.text)
  //         .get();

  //     if (querySnapshot.docs.isNotEmpty) {
  //       Navigator.push(
  //         context,
  //         MaterialPageRoute(builder: (context) => const AddWorkout()),
  //       );
  //     } else {
  //       showErrorDialog("Invalid email or password. Please try again.");
  //     }
  //   } else {
  //     showErrorDialog("Please enter both email and password.");
  //   }
  // }








void login() async {
  if (emailController.text.isNotEmpty && passwordController.text.isNotEmpty) {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Sign in with Firebase Auth
      UserCredential userCredential = await auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      // Update last login time
      final user = userCredential.user!;
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'lastLogin': Timestamp.now(),
      });

      // Close loading dialog
      Navigator.pop(context);

      // Navigate to Dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Dashboard()),
      );

    } on FirebaseAuthException catch (e) {
      // Close loading dialog
      Navigator.pop(context);
      
      String errorMessage;
      if (e.code == 'user-not-found') {
        errorMessage = 'No account found with this email.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Incorrect password. Please try again.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Invalid email address format.';
      } else if (e.code == 'user-disabled') {
        errorMessage = 'This account has been disabled.';
      } else if (e.code == 'too-many-requests') {
        errorMessage = 'Too many attempts. Please try again later.';
      } else {
        errorMessage = 'Login failed. Please try again.';
      }
      
      showErrorDialog(errorMessage);
      
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);
      
      showErrorDialog('An unexpected error occurred. Please try again.');
      print('Login error: $e');
    }
  } else {
    showErrorDialog("Please enter both email and password.");
  }
}












  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Login Error", style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text(message, style: const TextStyle(fontSize: 16)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the pop-up
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Login Page",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.purple.shade800,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Image.asset('lib/images/home.png', height: 500, width: 500),
              const SizedBox(height: 30),
              _buildTextField(emailController, "Email", Icons.email),
              _buildTextField(passwordController, "Password", Icons.lock, isPassword: true),
              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: login,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  backgroundColor: Colors.blueGrey.shade700,
                ),
                child: const Text(
                  "Login",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),

              const SizedBox(height: 20),

              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const WorkoutRegister()),
                  );
                },
                child: const Text(
                  "Don't have an account? Register",
                  style: TextStyle(color: Colors.black54, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black54),
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          prefixIcon: Icon(icon, color: Colors.blueAccent),
        ),
      ),
    );
  }
}
