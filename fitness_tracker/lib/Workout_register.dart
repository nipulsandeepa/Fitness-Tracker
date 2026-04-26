import 'package:cloud_firestore/cloud_firestore.dart';
import 'WorkoutLogin.dart';
//import 'newHome.dart';
import 'package:flutter/material.dart';
import 'Dashboard.dart';
import 'package:firebase_auth/firebase_auth.dart';


class WorkoutRegister extends StatefulWidget {
  const WorkoutRegister({super.key});

  @override
  State<WorkoutRegister> createState() => _WorkoutRegisterState();
}

class _WorkoutRegisterState extends State<WorkoutRegister> {
  TextEditingController firstnameController = TextEditingController();
  TextEditingController lastnameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController cpasswordController = TextEditingController();

  FirebaseFirestore firestore = FirebaseFirestore.instance;
  FirebaseAuth auth = FirebaseAuth.instance;

  bool _isLoading = false;

  void registerUser() async {
    // Validation
    if (firstnameController.text.isEmpty ||
        lastnameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        cpasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    if (passwordController.text.length < 6) {
      _showPasswordErrorDialog();
      return;
    }

    if (passwordController.text != cpasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords don't match")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Check if email already exists
      final methods = await auth.fetchSignInMethodsForEmail(emailController.text);
      if (methods.isNotEmpty) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User already registered! Try logging in.")),
        );
        return;
      }

      // Create user with Firebase Auth
      UserCredential userCredential = await auth.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      final user = userCredential.user!;
      
      // Save user profile to 'users' collection
      await firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': emailController.text,
        'firstName': firstnameController.text,
        'lastName': lastnameController.text,
        'displayName': '${firstnameController.text} ${lastnameController.text}',
        'createdAt': Timestamp.now(),
        'lastLogin': Timestamp.now(),
        'streak': 0,
        'totalWorkouts': 0,
        'totalMinutes': 0,
        'level': 1,
        'points': 0,
      });

      // For backward compatibility (remove if not needed)
      await firestore.collection('workoutUsers').doc(user.uid).set({
        'firstname': firstnameController.text,
        'lastname': lastnameController.text,
        'email': emailController.text,
      });

      // Initialize achievements
      await _initializeUserAchievements(user.uid);

      setState(() => _isLoading = false);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Registration successful! Welcome!"),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to Dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Dashboard()),
      );

    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      
      String errorMessage = "Registration failed. Please try again.";
      if (e.code == 'email-already-in-use') {
        errorMessage = "Email is already registered.";
      } else if (e.code == 'weak-password') {
        errorMessage = "Password is too weak.";
      } else if (e.code == 'invalid-email') {
        errorMessage = "Invalid email address.";
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
      
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _initializeUserAchievements(String userId) async {
    final achievements = [
      {
        'id': 'first_workout',
        'title': 'First Steps',
        'description': 'Complete your first workout',
        'icon': '👣',
        'target': 1,
        'unlocked': false,
      },
      {
        'id': 'workout_streak_3',
        'title': 'Consistent Trainee',
        'description': 'Maintain a 3-day workout streak',
        'icon': '🔥',
        'target': 3,
        'unlocked': false,
      },
      {
        'id': 'workout_streak_7',
        'title': 'Week Warrior',
        'description': 'Maintain a 7-day workout streak',
        'icon': '💪',
        'target': 7,
        'unlocked': false,
      },
      {
        'id': 'complete_10_workouts',
        'title': 'Dedicated',
        'description': 'Complete 10 workouts',
        'icon': '🏆',
        'target': 10,
        'unlocked': false,
      },
      {
        'id': 'complete_25_workouts',
        'title': 'Master',
        'description': 'Complete 25 workouts',
        'icon': '👑',
        'target': 25,
        'unlocked': false,
      },
      {
        'id': 'total_500_minutes',
        'title': 'Endurance King',
        'description': 'Complete 500 minutes of workouts',
        'icon': '⏱️',
        'target': 500,
        'unlocked': false,
      },
    ];

    for (final achievement in achievements) {
      await firestore
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .doc(achievement['id'] as String?)
          .set(achievement);
    }
  }

  void _showPasswordErrorDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            "Weak Password",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text("Password must be at least 6 characters long."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK", style: TextStyle(fontSize: 16)),
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
          "Create Account",
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.purple.shade800,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    Image.asset(
                      'lib/images/yoga.png',
                      height: 250,
                      width: 350,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(firstnameController, "First Name", Icons.person),
                    _buildTextField(lastnameController, "Last Name", Icons.person),
                    _buildTextField(emailController, "Email", Icons.email),
                    _buildTextField(passwordController, "Password", Icons.lock, isPassword: true),
                    _buildTextField(cpasswordController, "Confirm Password", Icons.lock, isPassword: true),
                    const SizedBox(height: 30),
                    
                    // Register Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: registerUser,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          backgroundColor: Colors.purple.shade700,
                        ),
                        child: const Text(
                          "Create Account",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Already have account
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Already have an account?", style: TextStyle(fontSize: 16)),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const WorkoutLogin()),
                            );
                          },
                          child: const Text(
                            "Sign In",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Privacy Notice
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        "By creating an account, you agree to our Terms of Service and Privacy Policy",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
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
          labelStyle: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.purple, width: 2),
          ),
          prefixIcon: Icon(icon, color: Colors.purple),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}