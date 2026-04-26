
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ViewWorkout.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'WorkoutLogin.dart';

import 'Dashboard.dart';

class AddWorkout extends StatefulWidget {
  const AddWorkout({super.key, this.workoutId, this.workoutData});

  // Factory constructor for edit mode
  factory AddWorkout.editMode({required String workoutId, required Map<String, dynamic> workoutData}) {
    return AddWorkout._edit(workoutId: workoutId, workoutData: workoutData);
  }

  const AddWorkout._edit({this.workoutId, this.workoutData}) : super(key: const Key('edit_workout'));

  final String? workoutId;
  final Map<String, dynamic>? workoutData;

  @override
  State<AddWorkout> createState() => _AddWorkoutState();
}

class _AddWorkoutState extends State<AddWorkout> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now();
  DateTime selectedDate = DateTime.now();

  List<String> workoutTypes = ['Cardio', 'Strength', 'Flexibility', 'HIIT', 'Yoga', 'Pilates', 'CrossFit'];
  List<String> whenToWorkoutOptions = ['Morning', 'Afternoon', 'Evening', 'Night'];

  TextEditingController workoutNameController = TextEditingController();
  TextEditingController durationController = TextEditingController();
  TextEditingController notesController = TextEditingController();
  String? selectedWorkoutType;
  String? selectedWhenToWorkout;
  
  bool _isSaving = false;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _checkUserAuth();
    
    // Check if we're in edit mode
    _isEditMode = widget.workoutId != null && widget.workoutData != null;
    if (_isEditMode) {
      _loadWorkoutData();
    }
  }

  void _loadWorkoutData() {
    final data = widget.workoutData!;
    workoutNameController.text = data['workoutName'];
    durationController.text = data['duration'].toString();
    notesController.text = data['notes']?.toString() ?? '';
    selectedWorkoutType = data['workoutType'];
    selectedWhenToWorkout = data['whenToWorkout'];
    
    final startTimestamp = data['startDate'] as Timestamp;
    final endTimestamp = data['endDate'] as Timestamp;
    
    final startDateValue = startTimestamp.toDate();
    final endDateValue = endTimestamp.toDate();
    
    setState(() {
      startDate = startDateValue;
      endDate = endDateValue;
      selectedDate = startDateValue;
    });
  }

  void _checkUserAuth() {
    final user = _auth.currentUser;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAuthError();
      });
    } else {
      print('User authenticated: ${user.email} (${user.uid})');
    }
  }

  void _showAuthError() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Session Expired'),
        content: const Text('Your session has expired. Please login again.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            child: const Text('LOGIN'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    await _auth.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const WorkoutLogin()),
      (route) => false,
    );
  }

  Future<DateTime?> pickDate() async {
    return await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.purple,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
  }

  Future<void> saveWorkout() async {
    // Validate user
    final user = _auth.currentUser;
    if (user == null) {
      _showAuthError();
      return;
    }

    // Validate form
    if (workoutNameController.text.isEmpty) {
      _showErrorDialog('Please enter a workout name');
      return;
    }
    
    if (selectedWorkoutType == null) {
      _showErrorDialog('Please select a workout type');
      return;
    }
    
    if (selectedWhenToWorkout == null) {
      _showErrorDialog('Please select when you plan to workout');
      return;
    }
    
    if (durationController.text.isEmpty) {
      _showErrorDialog('Please enter duration');
      return;
    }
    
    final duration = int.tryParse(durationController.text);
    if (duration == null || duration <= 0) {
      _showErrorDialog('Please enter a valid duration in minutes');
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (_isEditMode) {
        // Update existing workout
        await _firestore.collection('workouts').doc(widget.workoutId!).update({
          'workoutName': workoutNameController.text.trim(),
          'workoutType': selectedWorkoutType,
          'duration': durationController.text,
          'whenToWorkout': selectedWhenToWorkout,
          'notes': notesController.text.trim(),
          'startDate': Timestamp.fromDate(startDate),
          'endDate': Timestamp.fromDate(endDate),
          'updatedAt': Timestamp.now(),
        });

        // Show update success
        _showUpdateSuccessDialog();
      } else {
        // Create new workout document
        final workoutRef = await _firestore.collection('workouts').add({
          'workoutName': workoutNameController.text.trim(),
          'workoutType': selectedWorkoutType,
          'duration': durationController.text,
          'whenToWorkout': selectedWhenToWorkout,
          'notes': notesController.text.trim(),
          'startDate': Timestamp.fromDate(startDate),
          'endDate': Timestamp.fromDate(endDate),
          'userId': user.uid,
          'completed': false,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });

        // Update user stats
        await _firestore.collection('users').doc(user.uid).update({
          'totalWorkouts': FieldValue.increment(1),
          'totalMinutes': FieldValue.increment(duration),
          'lastWorkout': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });

        // Check for first workout achievement
        await _checkFirstWorkoutAchievement(user.uid);

        // Show success
        _showSuccessDialog();
      }

      setState(() => _isSaving = false);

    } catch (e) {
      setState(() => _isSaving = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving workout: $e'),
          backgroundColor: Colors.red,
        ),
      );
      print('Save workout error: $e');
    }
  }

  Future<void> _checkFirstWorkoutAchievement(String userId) async {
    final workouts = await _firestore
        .collection('workouts')
        .where('userId', isEqualTo: userId)
        .get();
    
    if (workouts.docs.length == 1) { // This is the first workout
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .doc('first_workout')
          .update({
            'unlocked': true,
            'unlockedAt': Timestamp.now(),
            'progress': 1,
          });
      
      // Add points
      await _firestore.collection('users').doc(userId).update({
        'points': FieldValue.increment(100),
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Missing Information'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Success!', style: TextStyle(color: Colors.green)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 60),
            const SizedBox(height: 20),
            const Text('Workout saved successfully!'),
            const SizedBox(height: 10),
            Text(
              workoutNameController.text,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Clear form and stay on page
              _clearForm();
            },
            child: const Text('ADD ANOTHER'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to ViewWorkout
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ViewWorkout()),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            child: const Text('VIEW WORKOUTS', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showUpdateSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Updated!', style: TextStyle(color: Colors.blue)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.blue, size: 60),
            const SizedBox(height: 20),
            const Text('Workout updated successfully!'),
            const SizedBox(height: 10),
            Text(
              workoutNameController.text,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to ViewWorkout
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ViewWorkout()),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            child: const Text('VIEW WORKOUTS', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _clearForm() {
    workoutNameController.clear();
    durationController.clear();
    notesController.clear();
    setState(() {
      selectedWorkoutType = null;
      selectedWhenToWorkout = null;
      startDate = DateTime.now();
      endDate = DateTime.now();
      selectedDate = DateTime.now();
    });
  }

  List<DateTime> getWeekDays() {
    return List.generate(7, (index) =>
        selectedDate.subtract(Duration(days: selectedDate.weekday - 1 - index)));
  }

  @override
  Widget build(BuildContext context) {
    List<DateTime> weekDays = getWeekDays();
    bool isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.purple.shade800,
        title: Text(
          _isEditMode ? 'Edit Workout' : 'Add Workout',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.dashboard, color: Colors.white),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const Dashboard()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // Header Image
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.purple.shade800,
                        Colors.purple.shade600,
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isEditMode ? Icons.edit : Icons.fitness_center,
                        size: 50,
                        color: Colors.white
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _isEditMode ? 'Edit Your Workout' : 'Plan Your Workout',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        DateFormat('EEEE, MMMM d').format(DateTime.now()),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),

                // Weekday Selector
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: weekDays.asMap().entries.map((entry) {
                        final index = entry.key;
                        final day = entry.value;
                        bool isSelected = selectedDate.day == day.day;
                        bool isToday = day.day == DateTime.now().day && 
                                       day.month == DateTime.now().month && 
                                       day.year == DateTime.now().year;
                        
                        return GestureDetector(
                          onTap: () => setState(() {
                            selectedDate = day;
                            startDate = day;
                            endDate = day;
                          }),
                          child: Container(
                            width: 60,
                            margin: EdgeInsets.only(
                              right: index < weekDays.length - 1 ? 6 : 0,
                              left: index == 0 ? 0 : 6,
                            ),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.purple : 
                                     isToday ? Colors.purple.shade100 : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? Colors.purple : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  DateFormat('E').format(day).substring(0, 3),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: isSelected ? Colors.white : Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  day.day.toString(),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                // Form Card
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Workout Details Header
                          Text(
                            _isEditMode ? 'Edit Workout Details' : 'Workout Details',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // Workout Name
                          TextField(
                            controller: workoutNameController,
                            decoration: InputDecoration(
                              labelText: 'Workout Name *',
                              hintText: 'e.g., Morning Run, Leg Day',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.fitness_center, color: Colors.purple),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Workout Type
                          DropdownButtonFormField<String>(
                            value: selectedWorkoutType,
                            decoration: InputDecoration(
                              labelText: 'Workout Type *',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.category, color: Colors.purple),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            items: workoutTypes.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              setState(() => selectedWorkoutType = newValue);
                            },
                            hint: const Text('Select type'),
                          ),
                          const SizedBox(height: 20),

                          // Duration
                          TextField(
                            controller: durationController,
                            decoration: InputDecoration(
                              labelText: 'Duration (minutes) *',
                              hintText: 'e.g., 30, 45, 60',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.timer, color: Colors.purple),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 20),

                          // Time of Day
                          DropdownButtonFormField<String>(
                            value: selectedWhenToWorkout,
                            decoration: InputDecoration(
                              labelText: 'Preferred Time *',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.access_time, color: Colors.purple),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            items: whenToWorkoutOptions.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              setState(() => selectedWhenToWorkout = newValue);
                            },
                            hint: const Text('Select time'),
                          ),
                          const SizedBox(height: 20),

                          // Notes
                          TextField(
                            controller: notesController,
                            decoration: InputDecoration(
                              labelText: 'Notes (Optional)',
                              hintText: 'Any additional notes...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.notes, color: Colors.purple),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 20),

                          // Schedule
                          const Text(
                            'Schedule',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Responsive Date Pickers
                          LayoutBuilder(
                            builder: (context, constraints) {
                              if (constraints.maxWidth < 500) {
                                // Stack vertically on small screens
                                return Column(
                                  children: [
                                    _buildDatePicker(
                                      label: 'Start Date',
                                      date: startDate,
                                      onDatePicked: (date) {
                                        if (date != null) setState(() => startDate = date);
                                      },
                                    ),
                                    const SizedBox(height: 15),
                                    _buildDatePicker(
                                      label: 'End Date',
                                      date: endDate,
                                      onDatePicked: (date) {
                                        if (date != null) setState(() => endDate = date);
                                      },
                                    ),
                                  ],
                                );
                              } else {
                                // Use Row for wider screens
                                return Row(
                                  children: [
                                    Expanded(
                                      child: _buildDatePicker(
                                        label: 'Start Date',
                                        date: startDate,
                                        onDatePicked: (date) {
                                          if (date != null) setState(() => startDate = date);
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: _buildDatePicker(
                                        label: 'End Date',
                                        date: endDate,
                                        onDatePicked: (date) {
                                          if (date != null) setState(() => endDate = date);
                                        },
                                      ),
                                    ),
                                  ],
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 30),

                          // Action Buttons
                          Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _isSaving ? null : saveWorkout,
                                  icon: _isSaving
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : Icon(_isEditMode ? Icons.save_as : Icons.save),
                                  label: Text(
                                    _isSaving ? 'Saving...' : (_isEditMode ? 'UPDATE WORKOUT' : 'SAVE WORKOUT'),
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isEditMode ? Colors.blue : Colors.purple,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 15),
                              
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => const ViewWorkout()),
                                        );
                                      },
                                      icon: const Icon(Icons.list),
                                      label: const Text('VIEW ALL'),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        side: const BorderSide(color: Colors.purple),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _logout,
                                      icon: const Icon(Icons.logout),
                                      label: const Text('LOGOUT'),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        side: const BorderSide(color: Colors.red),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime date,
    required Function(DateTime?) onDatePicked,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 5),
        InkWell(
          onTap: () async {
            final pickedDate = await pickDate();
            if (pickedDate != null) {
              onDatePicked(pickedDate);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade50,
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.purple, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    DateFormat('MMM dd, yyyy').format(date),
                    style: const TextStyle(fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.arrow_drop_down, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    workoutNameController.dispose();
    durationController.dispose();
    notesController.dispose();
    super.dispose();
  }
}