
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:fitness_tracker/AddWorkout.dart';
// import 'package:fitness_tracker/WorkoutLogin.dart';
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';
// import 'package:table_calendar/table_calendar.dart';
// import 'Dashboard.dart';

// class ViewWorkout extends StatefulWidget {
//   const ViewWorkout({super.key});

//   @override
//   State<ViewWorkout> createState() => _ViewWorkoutState();
// }

// class _ViewWorkoutState extends State<ViewWorkout> {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
//   CalendarFormat _calendarFormat = CalendarFormat.month;
//   DateTime _focusedDay = DateTime.now();
//   DateTime? _selectedDay;
  
//   String _filterType = "All"; // All, Completed, Pending
  
//   // Use StreamBuilder for real-time updates instead of loading once
//   // Stream<QuerySnapshot> _getWorkoutsStream() {
//   //   final user = _auth.currentUser;
//   //   if (user == null) {
//   //     return const Stream.empty();
//   //   }
    
//   //   Query query = _firestore
//   //       .collection('workouts')
//   //       .where('userId', isEqualTo: user.uid);
    
//   //   // Apply filter if needed
//   //   if (_filterType == "Completed") {
//   //     query = query.where('completed', isEqualTo: true);
//   //   } else if (_filterType == "Pending") {
//   //     query = query.where('completed', isEqualTo: false);
//   //   }
    
//   //   return query
//   //       .orderBy('startDate', descending: true)
//   //       .snapshots();
//   // }



//   Stream<QuerySnapshot> _getWorkoutsStream() {
//   final user = _auth.currentUser;
//   if (user == null) {
//     return const Stream.empty();
//   }
  
//   // Get ALL workouts for this user, sorted by startDate
//   return _firestore
//       .collection('workouts')
//       .where('userId', isEqualTo: user.uid)
//       .orderBy('startDate', descending: true)
//       .snapshots();
// }
  
//   // Group workouts by date for calendar
//   Map<DateTime, List<DocumentSnapshot>> _groupWorkoutsByDate(List<DocumentSnapshot> workouts) {
//     final Map<DateTime, List<DocumentSnapshot>> events = {};
    
//     for (final doc in workouts) {
//       final data = doc.data() as Map<String, dynamic>;
//       final startDate = (data['startDate'] as Timestamp).toDate();
//       final dateKey = DateTime(startDate.year, startDate.month, startDate.day);
      
//       events[dateKey] ??= [];
//       events[dateKey]!.add(doc);
//     }
    
//     return events;
//   }
  
//   void _deleteWorkout(String docId) async {
//     try {
//       await _firestore.collection('workouts').doc(docId).delete();
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Workout deleted successfully'),
//           backgroundColor: Colors.green,
//         ),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error deleting workout: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }
  
//   Future<void> _toggleComplete(String docId, bool currentValue) async {
//     try {
//       await _firestore.collection('workouts').doc(docId).update({
//         'completed': !currentValue,
//         'updatedAt': Timestamp.now(),
//       });
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error updating workout: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }
  
//   // Store the current workout data in state to update the popup
//   Map<String, dynamic>? _currentWorkoutData;
  
//   void _showWorkoutDetails(DocumentSnapshot doc) {
//     _currentWorkoutData = doc.data() as Map<String, dynamic>;
    
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (context) => _WorkoutDetailsModal(
//         doc: doc,
//         onStatusChanged: (bool newStatus) {
//           // Update local state immediately
//           setState(() {
//             if (_currentWorkoutData != null) {
//               _currentWorkoutData!['completed'] = newStatus;
//             }
//           });
//         },
//         onDelete: () {
//           Navigator.pop(context); // Close the modal
//           _deleteWorkout(doc.id);
//         },
//         onEdit: () {
//           Navigator.pop(context); // Close the modal
//           _navigateToEditWorkout(doc);
//         },
//       ),
//     );
//   }
  
//   void _navigateToEditWorkout(DocumentSnapshot doc) {
//     // Navigate to AddWorkout page with the workout data for editing
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => AddWorkout.editMode(
//           workoutId: doc.id,
//           workoutData: doc.data() as Map<String, dynamic>,
//         ),
//       ),
//     );
//   }
  
//   Widget _buildDetailRow(IconData icon, String title, String value) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 15),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Icon(icon, color: Colors.purple, size: 22),
//           const SizedBox(width: 15),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   style: const TextStyle(
//                     fontSize: 14,
//                     color: Colors.grey,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   value,
//                   style: const TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w500,
//                   ),
//                   maxLines: 3,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
  
//   @override
//   Widget build(BuildContext context) {
//     final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           'Workout Calendar',
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//             fontSize: 24,
//             color: Colors.white,
//           ),
//         ),
//         centerTitle: true,
//         backgroundColor: Colors.purple.shade800,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.dashboard, color: Colors.white),
//             onPressed: () {
//               Navigator.pushReplacement(
//                 context,
//                 MaterialPageRoute(builder: (context) => const Dashboard()),
//               );
//             },
//           ),
//         ],
//       ),
      
//       body: StreamBuilder<QuerySnapshot>(
//         stream: _getWorkoutsStream(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
          
//           if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           }
          
//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return Center(
//               child: SingleChildScrollView(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Image.asset(
//                       'lib/images/heart.png',
//                       height: 200,
//                       width: 200,
//                     ),
//                     const SizedBox(height: 20),
//                     const Text(
//                       'No workouts yet!',
//                       style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//                     ),
//                     const SizedBox(height: 10),
//                     const Text(
//                       'Add your first workout to get started',
//                       style: TextStyle(color: Colors.grey),
//                     ),
//                     const SizedBox(height: 20),
//                     ElevatedButton(
//                       onPressed: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(builder: (context) => const AddWorkout()),
//                         );
//                       },
//                       child: const Text('Add Workout'),
//                     ),
//                   ],
//                 ),
//               ),
//             );
//           }
          
//           final workouts = snapshot.data!.docs;
//           final events = _groupWorkoutsByDate(workouts);
          
//           return LayoutBuilder(
//             builder: (context, constraints) {
//               // Adjust layout for landscape mode
//               if (isLandscape) {
//                 return Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Calendar section - take 40% of width
//                     Expanded(
//                       flex: 4,
//                       child: SingleChildScrollView(
//                         child: Column(
//                           children: [
//                             Card(
//                               margin: const EdgeInsets.all(16),
//                               elevation: 4,
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(15),
//                               ),
//                               child: Padding(
//                                 padding: const EdgeInsets.all(12),
//                                 child: TableCalendar(
//                                   firstDay: DateTime.now().subtract(const Duration(days: 365)),
//                                   lastDay: DateTime.now().add(const Duration(days: 365)),
//                                   focusedDay: _focusedDay,
//                                   selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
//                                   calendarFormat: _calendarFormat,
//                                   eventLoader: (day) => events[DateTime(day.year, day.month, day.day)] ?? [],
//                                   onDaySelected: (selectedDay, focusedDay) {
//                                     setState(() {
//                                       _selectedDay = selectedDay;
//                                       _focusedDay = focusedDay;
//                                     });
//                                   },
//                                   onFormatChanged: (format) {
//                                     setState(() => _calendarFormat = format);
//                                   },
//                                   onPageChanged: (focusedDay) {
//                                     setState(() => _focusedDay = focusedDay);
//                                   },
//                                   calendarBuilders: CalendarBuilders(
//                                     markerBuilder: (context, date, events) {
//                                       if (events.isNotEmpty) {
//                                         return Positioned(
//                                           right: 1,
//                                           bottom: 1,
//                                           child: Container(
//                                             padding: const EdgeInsets.all(4),
//                                             decoration: BoxDecoration(
//                                               color: Colors.purple,
//                                               borderRadius: BorderRadius.circular(6),
//                                             ),
//                                             child: Text(
//                                               '${events.length}',
//                                               style: const TextStyle(
//                                                 fontSize: 10,
//                                                 color: Colors.white,
//                                                 fontWeight: FontWeight.bold,
//                                               ),
//                                             ),
//                                           ),
//                                         );
//                                       }
//                                       return null;
//                                     },
//                                   ),
//                                   calendarStyle: CalendarStyle(
//                                     selectedDecoration: BoxDecoration(
//                                       color: Colors.purple,
//                                       shape: BoxShape.circle,
//                                     ),
//                                     todayDecoration: BoxDecoration(
//                                       color: Colors.purple.withOpacity(0.3),
//                                       shape: BoxShape.circle,
//                                     ),
//                                   ),
//                                   headerStyle: const HeaderStyle(
//                                     formatButtonVisible: true,
//                                     titleCentered: true,
//                                     formatButtonDecoration: BoxDecoration(
//                                       color: Colors.purple,
//                                       borderRadius: BorderRadius.all(Radius.circular(20)),
//                                     ),
//                                     formatButtonTextStyle: TextStyle(color: Colors.white),
//                                   ),
//                                 ),
//                               ),
//                             ),
                            
//                             // Filter and Stats - compact in landscape
//                             Padding(
//                               padding: const EdgeInsets.symmetric(horizontal: 16),
//                               child: Row(
//                                 children: [
//                                   Expanded(
//                                     child: Card(
//                                       child: Padding(
//                                         padding: const EdgeInsets.all(12),
//                                         child: Column(
//                                           crossAxisAlignment: CrossAxisAlignment.start,
//                                           children: [
//                                             Text(
//                                               _selectedDay != null
//                                                   ? DateFormat('MMM dd, yyyy').format(_selectedDay!)
//                                                   : 'Select a date',
//                                               style: const TextStyle(fontWeight: FontWeight.bold),
//                                             ),
//                                             const SizedBox(height: 4),
//                                             Text(
//                                               '${events[DateTime(_selectedDay?.year ?? DateTime.now().year, _selectedDay?.month ?? DateTime.now().month, _selectedDay?.day ?? DateTime.now().day)]?.length ?? 0} workouts',
//                                               style: const TextStyle(color: Colors.grey, fontSize: 12),
//                                             ),
//                                           ],
//                                         ),
//                                       ),
//                                     ),
//                                   ),
                                  
//                                   const SizedBox(width: 10),
                                  
//                                   // Filter Dropdown
//                                   Container(
//                                     decoration: BoxDecoration(
//                                       borderRadius: BorderRadius.circular(10),
//                                       border: Border.all(color: Colors.grey.shade300),
//                                     ),
//                                     child: DropdownButtonHideUnderline(
//                                       child: DropdownButton<String>(
//                                         value: _filterType,
//                                         items: ["All", "Completed", "Pending"]
//                                             .map((value) => DropdownMenuItem(
//                                                   value: value,
//                                                   child: Padding(
//                                                     padding: const EdgeInsets.symmetric(horizontal: 12),
//                                                     child: Text(value),
//                                                   ),
//                                                 ))
//                                             .toList(),
//                                         onChanged: (value) {
//                                           setState(() => _filterType = value!);
//                                         },
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
                    
//                     // Workouts List - take 60% of width
//                     Expanded(
//                       flex: 6,
//                       child: Padding(
//                         padding: const EdgeInsets.all(16),
//                         child: ListView.builder(
//                           itemCount: workouts.length,
//                           itemBuilder: (context, index) {
//                             final doc = workouts[index];
//                             final data = doc.data() as Map<String, dynamic>;
//                             final isCompleted = data['completed'] ?? false;
                            
//                             return Card(
//                               margin: const EdgeInsets.only(bottom: 10),
//                               child: ListTile(
//                                 leading: Checkbox(
//                                   value: isCompleted,
//                                   onChanged: (value) => _toggleComplete(doc.id, isCompleted),
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(4),
//                                   ),
//                                 ),
//                                 title: Text(
//                                   data['workoutName'],
//                                   style: TextStyle(
//                                     fontSize: 16,
//                                     fontWeight: FontWeight.w600,
//                                     decoration: isCompleted ? TextDecoration.lineThrough : null,
//                                   ),
//                                 ),
//                                 subtitle: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text(
//                                       "${data['workoutType']} • ${data['duration']} min • ${data['whenToWorkout']}",
//                                       style: const TextStyle(fontSize: 14),
//                                     ),
//                                     if (data['notes'] != null && data['notes'].toString().isNotEmpty)
//                                       Text(
//                                         data['notes'].toString(),
//                                         style: const TextStyle(
//                                           fontSize: 12,
//                                           fontStyle: FontStyle.italic,
//                                           color: Colors.grey,
//                                         ),
//                                         maxLines: 1,
//                                         overflow: TextOverflow.ellipsis,
//                                       ),
//                                   ],
//                                 ),
//                                 trailing: IconButton(
//                                   icon: const Icon(Icons.info_outline, color: Colors.blue),
//                                   onPressed: () => _showWorkoutDetails(doc),
//                                 ),
//                                 onTap: () => _showWorkoutDetails(doc),
//                               ),
//                             );
//                           },
//                         ),
//                       ),
//                     ),
//                   ],
//                 );
//               }
              
//               // Portrait mode layout
//               return Column(
//                 children: [
//                   // Calendar
//                   Card(
//                     margin: const EdgeInsets.all(16),
//                     elevation: 4,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(15),
//                     ),
//                     child: Padding(
//                       padding: const EdgeInsets.all(12),
//                       child: TableCalendar(
//                         firstDay: DateTime.now().subtract(const Duration(days: 365)),
//                         lastDay: DateTime.now().add(const Duration(days: 365)),
//                         focusedDay: _focusedDay,
//                         selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
//                         calendarFormat: _calendarFormat,
//                         eventLoader: (day) => events[DateTime(day.year, day.month, day.day)] ?? [],
//                         onDaySelected: (selectedDay, focusedDay) {
//                           setState(() {
//                             _selectedDay = selectedDay;
//                             _focusedDay = focusedDay;
//                           });
//                         },
//                         onFormatChanged: (format) {
//                           setState(() => _calendarFormat = format);
//                         },
//                         onPageChanged: (focusedDay) {
//                           setState(() => _focusedDay = focusedDay);
//                         },
//                         calendarBuilders: CalendarBuilders(
//                           markerBuilder: (context, date, events) {
//                             if (events.isNotEmpty) {
//                               return Positioned(
//                                 right: 1,
//                                 bottom: 1,
//                                 child: Container(
//                                   padding: const EdgeInsets.all(4),
//                                   decoration: BoxDecoration(
//                                     color: Colors.purple,
//                                     borderRadius: BorderRadius.circular(6),
//                                   ),
//                                   child: Text(
//                                     '${events.length}',
//                                     style: const TextStyle(
//                                       fontSize: 10,
//                                       color: Colors.white,
//                                       fontWeight: FontWeight.bold,
//                                     ),
//                                   ),
//                                 ),
//                               );
//                             }
//                             return null;
//                           },
//                         ),
//                         calendarStyle: CalendarStyle(
//                           selectedDecoration: BoxDecoration(
//                             color: Colors.purple,
//                             shape: BoxShape.circle,
//                           ),
//                           todayDecoration: BoxDecoration(
//                             color: Colors.purple.withOpacity(0.3),
//                             shape: BoxShape.circle,
//                           ),
//                         ),
//                         headerStyle: const HeaderStyle(
//                           formatButtonVisible: true,
//                           titleCentered: true,
//                           formatButtonDecoration: BoxDecoration(
//                             color: Colors.purple,
//                             borderRadius: BorderRadius.all(Radius.circular(20)),
//                           ),
//                           formatButtonTextStyle: TextStyle(color: Colors.white),
//                         ),
//                       ),
//                     ),
//                   ),
                  
//                   // Filter and Stats
//                   Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 16),
//                     child: Row(
//                       children: [
//                         Expanded(
//                           child: Card(
//                             child: Padding(
//                               padding: const EdgeInsets.all(12),
//                               child: Row(
//                                 children: [
//                                   const Icon(Icons.event, color: Colors.purple),
//                                   const SizedBox(width: 10),
//                                   Expanded(
//                                     child: Column(
//                                       crossAxisAlignment: CrossAxisAlignment.start,
//                                       children: [
//                                         Text(
//                                           _selectedDay != null
//                                               ? DateFormat('MMMM dd, yyyy').format(_selectedDay!)
//                                               : 'Select a date',
//                                           style: const TextStyle(fontWeight: FontWeight.bold),
//                                         ),
//                                         Text(
//                                           '${events[DateTime(_selectedDay?.year ?? DateTime.now().year, _selectedDay?.month ?? DateTime.now().month, _selectedDay?.day ?? DateTime.now().day)]?.length ?? 0} workouts',
//                                           style: const TextStyle(color: Colors.grey, fontSize: 12),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         ),
                        
//                         const SizedBox(width: 10),
                        
//                         // Filter Dropdown
//                         Container(
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(10),
//                             border: Border.all(color: Colors.grey.shade300),
//                           ),
//                           child: DropdownButtonHideUnderline(
//                             child: DropdownButton<String>(
//                               value: _filterType,
//                               items: ["All", "Completed", "Pending"]
//                                   .map((value) => DropdownMenuItem(
//                                         value: value,
//                                         child: Padding(
//                                           padding: const EdgeInsets.symmetric(horizontal: 12),
//                                           child: Text(value),
//                                         ),
//                                       ))
//                                   .toList(),
//                               onChanged: (value) {
//                                 setState(() => _filterType = value!);
//                               },
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
                  
//                   // Workouts List - Use Expanded with SingleChildScrollView to prevent overflow
//                   Expanded(
//                     child: SingleChildScrollView(
//                       child: Padding(
//                         padding: const EdgeInsets.all(16),
//                         child: Column(
//                           children: [
//                             for (final doc in workouts)
//                               Card(
//                                 margin: const EdgeInsets.only(bottom: 10),
//                                 child: ListTile(
//                                   leading: Checkbox(
//                                     value: (doc.data() as Map<String, dynamic>)['completed'] ?? false,
//                                     onChanged: (value) => _toggleComplete(doc.id, (doc.data() as Map<String, dynamic>)['completed'] ?? false),
//                                     shape: RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.circular(4),
//                                     ),
//                                   ),
//                                   title: Text(
//                                     (doc.data() as Map<String, dynamic>)['workoutName'],
//                                     style: TextStyle(
//                                       fontSize: 16,
//                                       fontWeight: FontWeight.w600,
//                                       decoration: (doc.data() as Map<String, dynamic>)['completed'] == true ? TextDecoration.lineThrough : null,
//                                     ),
//                                   ),
//                                   subtitle: Column(
//                                     crossAxisAlignment: CrossAxisAlignment.start,
//                                     children: [
//                                       Text(
//                                         "${(doc.data() as Map<String, dynamic>)['workoutType']} • ${(doc.data() as Map<String, dynamic>)['duration']} min • ${(doc.data() as Map<String, dynamic>)['whenToWorkout']}",
//                                         style: const TextStyle(fontSize: 14),
//                                       ),
//                                       if ((doc.data() as Map<String, dynamic>)['notes'] != null && (doc.data() as Map<String, dynamic>)['notes'].toString().isNotEmpty)
//                                         Text(
//                                           (doc.data() as Map<String, dynamic>)['notes'].toString(),
//                                           style: const TextStyle(
//                                             fontSize: 12,
//                                             fontStyle: FontStyle.italic,
//                                             color: Colors.grey,
//                                           ),
//                                           maxLines: 1,
//                                           overflow: TextOverflow.ellipsis,
//                                         ),
//                                     ],
//                                   ),
//                                   trailing: IconButton(
//                                     icon: const Icon(Icons.info_outline, color: Colors.blue),
//                                     onPressed: () => _showWorkoutDetails(doc),
//                                   ),
//                                   onTap: () => _showWorkoutDetails(doc),
//                                 ),
//                               ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               );
//             },
//           );
//         },
//       ),











      
      
//       // Make FAB responsive - hide in landscape or position differently
//       floatingActionButton: LayoutBuilder(
//         builder: (context, constraints) {
//           if (isLandscape) {
//             // In landscape, use a smaller FAB in the bottom right
//             return FloatingActionButton(
//               onPressed: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) => const AddWorkout()),
//                 );
//               },
//               backgroundColor: Colors.purple,
//               child: const Icon(Icons.add),
//             );
//           }
          
//           // In portrait, use the extended FAB
//           return FloatingActionButton.extended(
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (context) => const AddWorkout()),
//               );
//             },
//             icon: const Icon(Icons.add),
//             label: const Text('Add Workout'),
//             backgroundColor: Colors.purple,
//           );
//         },
//       ),
//     );
//   }
// }

// // Separate StatefulWidget for the modal to manage its own state
// class _WorkoutDetailsModal extends StatefulWidget {
//   final DocumentSnapshot doc;
//   final Function(bool) onStatusChanged;
//   final VoidCallback onDelete;
//   final VoidCallback onEdit;

//   const _WorkoutDetailsModal({
//     required this.doc,
//     required this.onStatusChanged,
//     required this.onDelete,
//     required this.onEdit,
//   });

//   @override
//   State<_WorkoutDetailsModal> createState() => _WorkoutDetailsModalState();
// }

// class _WorkoutDetailsModalState extends State<_WorkoutDetailsModal> {
//   late Map<String, dynamic> _workoutData;
//   late bool _isCompleted;

//   @override
//   void initState() {
//     super.initState();
//     _workoutData = widget.doc.data() as Map<String, dynamic>;
//     _isCompleted = _workoutData['completed'] ?? false;
//   }

//   Future<void> _toggleComplete() async {
//     setState(() {
//       _isCompleted = !_isCompleted;
//     });
    
//     // Update Firebase
//     try {
//       await FirebaseFirestore.instance
//           .collection('workouts')
//           .doc(widget.doc.id)
//           .update({
//         'completed': _isCompleted,
//         'updatedAt': Timestamp.now(),
//       });
      
//       // Notify parent
//       widget.onStatusChanged(_isCompleted);
//     } catch (e) {
//       // Revert on error
//       setState(() {
//         _isCompleted = !_isCompleted;
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error updating workout: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final startDate = (_workoutData['startDate'] as Timestamp).toDate();
//     final endDate = (_workoutData['endDate'] as Timestamp).toDate();
    
//     return Container(
//       padding: const EdgeInsets.all(20),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Center(
//             child: Container(
//               width: 40,
//               height: 4,
//               margin: const EdgeInsets.only(bottom: 20),
//               decoration: BoxDecoration(
//                 color: Colors.grey[300],
//                 borderRadius: BorderRadius.circular(2),
//               ),
//             ),
//           ),
          
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Expanded(
//                 child: Text(
//                   _workoutData['workoutName'],
//                   style: const TextStyle(
//                     fontSize: 22,
//                     fontWeight: FontWeight.bold,
//                   ),
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ),
//               const SizedBox(width: 10),
//               Chip(
//                 label: Text(
//                   _isCompleted ? 'Completed' : 'Pending',
//                   style: const TextStyle(color: Colors.white, fontSize: 12),
//                 ),
//                 backgroundColor: _isCompleted ? Colors.green : Colors.orange,
//               ),
//             ],
//           ),
          
//           const SizedBox(height: 20),
          
//           _buildDetailRow(Icons.category, 'Type', _workoutData['workoutType']),
//           _buildDetailRow(Icons.timer, 'Duration', '${_workoutData['duration']} minutes'),
//           _buildDetailRow(Icons.access_time, 'Time', _workoutData['whenToWorkout']),
//           _buildDetailRow(Icons.calendar_today, 'Start Date', 
//             DateFormat('MMMM dd, yyyy').format(startDate)),
//           _buildDetailRow(Icons.calendar_today, 'End Date', 
//             DateFormat('MMMM dd, yyyy').format(endDate)),
          
//           if (_workoutData['notes'] != null && _workoutData['notes'].toString().isNotEmpty)
//             _buildDetailRow(Icons.notes, 'Notes', _workoutData['notes']),
          
//           const SizedBox(height: 30),
          
//           // Responsive button layout
//           LayoutBuilder(
//             builder: (context, constraints) {
//               if (constraints.maxWidth < 500) {
//                 // Stack buttons vertically on small screens
//                 return Column(
//                   children: [
//                     // Edit Button
//                     ElevatedButton.icon(
//                       onPressed: widget.onEdit,
//                       icon: const Icon(Icons.edit),
//                       label: const Text('Edit Workout'),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.blue,
//                         foregroundColor: Colors.white,
//                         padding: const EdgeInsets.symmetric(vertical: 15),
//                         minimumSize: const Size(double.infinity, 50),
//                       ),
//                     ),
//                     const SizedBox(height: 10),
                    
//                     // Toggle Complete Button
//                     ElevatedButton.icon(
//                       onPressed: _toggleComplete,
//                       icon: Icon(_isCompleted ? Icons.pending_actions : Icons.check_circle),
//                       label: Text(_isCompleted ? 'Mark as Pending' : 'Mark as Completed'),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: _isCompleted ? Colors.orange : Colors.green,
//                         foregroundColor: Colors.white,
//                         padding: const EdgeInsets.symmetric(vertical: 15),
//                         minimumSize: const Size(double.infinity, 50),
//                       ),
//                     ),
//                     const SizedBox(height: 10),
                    
//                     // Delete Button
//                     ElevatedButton.icon(
//                       onPressed: widget.onDelete,
//                       icon: const Icon(Icons.delete),
//                       label: const Text('Delete Workout'),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.red,
//                         foregroundColor: Colors.white,
//                         padding: const EdgeInsets.symmetric(vertical: 15),
//                         minimumSize: const Size(double.infinity, 50),
//                       ),
//                     ),
//                   ],
//                 );
//               } else {
//                 // Use horizontal layout on wider screens
//                 return Column(
//                   children: [
//                     // First row: Edit and Toggle buttons
//                     Row(
//                       children: [
//                         Expanded(
//                           child: ElevatedButton.icon(
//                             onPressed: widget.onEdit,
//                             icon: const Icon(Icons.edit),
//                             label: const Text('Edit'),
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.blue,
//                               foregroundColor: Colors.white,
//                               padding: const EdgeInsets.symmetric(vertical: 15),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 10),
//                         Expanded(
//                           child: ElevatedButton.icon(
//                             onPressed: _toggleComplete,
//                             icon: Icon(_isCompleted ? Icons.pending_actions : Icons.check_circle),
//                             label: Text(_isCompleted ? 'Mark Pending' : 'Mark Complete'),
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: _isCompleted ? Colors.orange : Colors.green,
//                               foregroundColor: Colors.white,
//                               padding: const EdgeInsets.symmetric(vertical: 15),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 10),
                    
//                     // Second row: Delete button (full width)
//                     ElevatedButton.icon(
//                       onPressed: widget.onDelete,
//                       icon: const Icon(Icons.delete),
//                       label: const Text('Delete Workout'),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.red,
//                         foregroundColor: Colors.white,
//                         padding: const EdgeInsets.symmetric(vertical: 15),
//                         minimumSize: const Size(double.infinity, 50),
//                       ),
//                     ),
//                   ],
//                 );
//               }
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDetailRow(IconData icon, String title, String value) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 15),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Icon(icon, color: Colors.purple, size: 22),
//           const SizedBox(width: 15),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   style: const TextStyle(
//                     fontSize: 14,
//                     color: Colors.grey,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   value,
//                   style: const TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w500,
//                   ),
//                   maxLines: 3,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }






import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitness_tracker/AddWorkout.dart';
import 'package:fitness_tracker/WorkoutLogin.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'Dashboard.dart';

class ViewWorkout extends StatefulWidget {
  const ViewWorkout({super.key});

  @override
  State<ViewWorkout> createState() => _ViewWorkoutState();
}

class _ViewWorkoutState extends State<ViewWorkout> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  String _filterType = "All"; // All, Completed, Pending
  
  // Use StreamBuilder for real-time updates instead of loading once
  Stream<QuerySnapshot> _getWorkoutsStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }
    
    // Get ALL workouts for this user, sorted by startDate
    // This query only needs the userId + startDate index which already exists
    return _firestore
        .collection('workouts')
        .where('userId', isEqualTo: user.uid)
        .orderBy('startDate', descending: true)
        .snapshots();
  }
  
  // Group workouts by date for calendar
  Map<DateTime, List<DocumentSnapshot>> _groupWorkoutsByDate(List<DocumentSnapshot> workouts) {
    final Map<DateTime, List<DocumentSnapshot>> events = {};
    
    for (final doc in workouts) {
      final data = doc.data() as Map<String, dynamic>;
      final startDate = (data['startDate'] as Timestamp).toDate();
      final dateKey = DateTime(startDate.year, startDate.month, startDate.day);
      
      events[dateKey] ??= [];
      events[dateKey]!.add(doc);
    }
    
    return events;
  }
  
  void _deleteWorkout(String docId) async {
    try {
      await _firestore.collection('workouts').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Workout deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting workout: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _toggleComplete(String docId, bool currentValue) async {
    try {
      await _firestore.collection('workouts').doc(docId).update({
        'completed': !currentValue,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating workout: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Store the current workout data in state to update the popup
  Map<String, dynamic>? _currentWorkoutData;
  
  void _showWorkoutDetails(DocumentSnapshot doc) {
    _currentWorkoutData = doc.data() as Map<String, dynamic>;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _WorkoutDetailsModal(
        doc: doc,
        onStatusChanged: (bool newStatus) {
          // Update local state immediately
          setState(() {
            if (_currentWorkoutData != null) {
              _currentWorkoutData!['completed'] = newStatus;
            }
          });
        },
        onDelete: () {
          Navigator.pop(context); // Close the modal
          _deleteWorkout(doc.id);
        },
        onEdit: () {
          Navigator.pop(context); // Close the modal
          _navigateToEditWorkout(doc);
        },
      ),
    );
  }
  
  void _navigateToEditWorkout(DocumentSnapshot doc) {
    // Navigate to AddWorkout page with the workout data for editing
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddWorkout.editMode(
          workoutId: doc.id,
          workoutData: doc.data() as Map<String, dynamic>,
        ),
      ),
    );
  }
  
  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.purple, size: 22),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Workout Calendar',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.purple.shade800,
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
      
      body: StreamBuilder<QuerySnapshot>(
        stream: _getWorkoutsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'lib/images/heart.png',
                      height: 200,
                      width: 200,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'No workouts yet!',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Add your first workout to get started',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AddWorkout()),
                        );
                      },
                      child: const Text('Add Workout'),
                    ),
                  ],
                ),
              ),
            );
          }
          
          // Get ALL workouts
          final allWorkouts = snapshot.data!.docs;
          
          // Apply filter client-side
          final filteredWorkouts = allWorkouts.where((doc) {
            if (_filterType == "All") return true;
            final data = doc.data() as Map<String, dynamic>;
            final isCompleted = data['completed'] ?? false;
            return _filterType == "Completed" ? isCompleted : !isCompleted;
          }).toList();
          
          // Use filteredWorkouts for the calendar and list
          final events = _groupWorkoutsByDate(filteredWorkouts);
          
          return LayoutBuilder(
            builder: (context, constraints) {
              // Adjust layout for landscape mode
              if (isLandscape) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Calendar section - take 40% of width
                    Expanded(
                      flex: 4,
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            Card(
                              margin: const EdgeInsets.all(16),
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: TableCalendar(
                                  firstDay: DateTime.now().subtract(const Duration(days: 365)),
                                  lastDay: DateTime.now().add(const Duration(days: 365)),
                                  focusedDay: _focusedDay,
                                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                                  calendarFormat: _calendarFormat,
                                  eventLoader: (day) => events[DateTime(day.year, day.month, day.day)] ?? [],
                                  onDaySelected: (selectedDay, focusedDay) {
                                    setState(() {
                                      _selectedDay = selectedDay;
                                      _focusedDay = focusedDay;
                                    });
                                  },
                                  onFormatChanged: (format) {
                                    setState(() => _calendarFormat = format);
                                  },
                                  onPageChanged: (focusedDay) {
                                    setState(() => _focusedDay = focusedDay);
                                  },
                                  calendarBuilders: CalendarBuilders(
                                    markerBuilder: (context, date, events) {
                                      if (events.isNotEmpty) {
                                        return Positioned(
                                          right: 1,
                                          bottom: 1,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: Colors.purple,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              '${events.length}',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        );
                                      }
                                      return null;
                                    },
                                  ),
                                  calendarStyle: CalendarStyle(
                                    selectedDecoration: const BoxDecoration(
                                      color: Colors.purple,
                                      shape: BoxShape.circle,
                                    ),
                                    todayDecoration: BoxDecoration(
                                      color: Colors.purple.withOpacity(0.3),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  headerStyle: const HeaderStyle(
                                    formatButtonVisible: true,
                                    titleCentered: true,
                                    formatButtonDecoration: BoxDecoration(
                                      color: Colors.purple,
                                      borderRadius: BorderRadius.all(Radius.circular(20)),
                                    ),
                                    formatButtonTextStyle: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                            
                            // Filter and Stats - compact in landscape
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Card(
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _selectedDay != null
                                                  ? DateFormat('MMM dd, yyyy').format(_selectedDay!)
                                                  : 'Select a date',
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${events[DateTime(_selectedDay?.year ?? DateTime.now().year, _selectedDay?.month ?? DateTime.now().month, _selectedDay?.day ?? DateTime.now().day)]?.length ?? 0} workouts',
                                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  
                                  const SizedBox(width: 10),
                                  
                                  // Filter Dropdown
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _filterType,
                                        items: ["All", "Completed", "Pending"]
                                            .map((value) => DropdownMenuItem(
                                                  value: value,
                                                  child: Padding(
                                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                                    child: Text(value),
                                                  ),
                                                ))
                                            .toList(),
                                        onChanged: (value) {
                                          setState(() => _filterType = value!);
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Workouts List - take 60% of width (use filteredWorkouts)
                    Expanded(
                      flex: 6,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: filteredWorkouts.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _filterType == "Completed" 
                                          ? Icons.check_circle_outline 
                                          : Icons.pending_outlined,
                                      size: 60,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _filterType == "Completed"
                                          ? 'No completed workouts'
                                          : 'No pending workouts',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _filterType == "Completed"
                                          ? 'Complete some workouts to see them here'
                                          : 'All workouts are completed!',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: filteredWorkouts.length,
                                itemBuilder: (context, index) {
                                  final doc = filteredWorkouts[index];
                                  final data = doc.data() as Map<String, dynamic>;
                                  final isCompleted = data['completed'] ?? false;
                                  
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    child: ListTile(
                                      leading: Checkbox(
                                        value: isCompleted,
                                        onChanged: (value) => _toggleComplete(doc.id, isCompleted),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                      title: Text(
                                        data['workoutName'],
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "${data['workoutType']} • ${data['duration']} min • ${data['whenToWorkout']}",
                                            style: const TextStyle(fontSize: 14),
                                          ),
                                          if (data['notes'] != null && data['notes'].toString().isNotEmpty)
                                            Text(
                                              data['notes'].toString(),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontStyle: FontStyle.italic,
                                                color: Colors.grey,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                        ],
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.info_outline, color: Colors.blue),
                                        onPressed: () => _showWorkoutDetails(doc),
                                      ),
                                      onTap: () => _showWorkoutDetails(doc),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                  ],
                );
              }
              
              // Portrait mode layout
              return Column(
                children: [
                  // Calendar
                  Card(
                    margin: const EdgeInsets.all(16),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: TableCalendar(
                        firstDay: DateTime.now().subtract(const Duration(days: 365)),
                        lastDay: DateTime.now().add(const Duration(days: 365)),
                        focusedDay: _focusedDay,
                        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                        calendarFormat: _calendarFormat,
                        eventLoader: (day) => events[DateTime(day.year, day.month, day.day)] ?? [],
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });
                        },
                        onFormatChanged: (format) {
                          setState(() => _calendarFormat = format);
                        },
                        onPageChanged: (focusedDay) {
                          setState(() => _focusedDay = focusedDay);
                        },
                        calendarBuilders: CalendarBuilders(
                          markerBuilder: (context, date, events) {
                            if (events.isNotEmpty) {
                              return Positioned(
                                right: 1,
                                bottom: 1,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.purple,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${events.length}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            }
                            return null;
                          },
                        ),
                        calendarStyle: CalendarStyle(
                          selectedDecoration: const BoxDecoration(
                            color: Colors.purple,
                            shape: BoxShape.circle,
                          ),
                          todayDecoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                        ),
                        headerStyle: const HeaderStyle(
                          formatButtonVisible: true,
                          titleCentered: true,
                          formatButtonDecoration: BoxDecoration(
                            color: Colors.purple,
                            borderRadius: BorderRadius.all(Radius.circular(20)),
                          ),
                          formatButtonTextStyle: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  
                  // Filter and Stats
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  const Icon(Icons.event, color: Colors.purple),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _selectedDay != null
                                              ? DateFormat('MMMM dd, yyyy').format(_selectedDay!)
                                              : 'Select a date',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          '${events[DateTime(_selectedDay?.year ?? DateTime.now().year, _selectedDay?.month ?? DateTime.now().month, _selectedDay?.day ?? DateTime.now().day)]?.length ?? 0} workouts',
                                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(width: 10),
                        
                        // Filter Dropdown
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _filterType,
                              items: ["All", "Completed", "Pending"]
                                  .map((value) => DropdownMenuItem(
                                        value: value,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                          child: Text(value),
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() => _filterType = value!);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Workouts List - Use filteredWorkouts
                  Expanded(
                    child: filteredWorkouts.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _filterType == "Completed" 
                                      ? Icons.check_circle_outline 
                                      : Icons.pending_outlined,
                                  size: 60,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _filterType == "Completed"
                                      ? 'No completed workouts'
                                      : 'No pending workouts',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _filterType == "Completed"
                                      ? 'Complete some workouts to see them here'
                                      : 'All workouts are completed!',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  for (final doc in filteredWorkouts)
                                    Card(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      child: ListTile(
                                        leading: Checkbox(
                                          value: (doc.data() as Map<String, dynamic>)['completed'] ?? false,
                                          onChanged: (value) => _toggleComplete(doc.id, (doc.data() as Map<String, dynamic>)['completed'] ?? false),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        ),
                                        title: Text(
                                          (doc.data() as Map<String, dynamic>)['workoutName'],
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            decoration: (doc.data() as Map<String, dynamic>)['completed'] == true ? TextDecoration.lineThrough : null,
                                          ),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "${(doc.data() as Map<String, dynamic>)['workoutType']} • ${(doc.data() as Map<String, dynamic>)['duration']} min • ${(doc.data() as Map<String, dynamic>)['whenToWorkout']}",
                                              style: const TextStyle(fontSize: 14),
                                            ),
                                            if ((doc.data() as Map<String, dynamic>)['notes'] != null && (doc.data() as Map<String, dynamic>)['notes'].toString().isNotEmpty)
                                              Text(
                                                (doc.data() as Map<String, dynamic>)['notes'].toString(),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontStyle: FontStyle.italic,
                                                  color: Colors.grey,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                          ],
                                        ),
                                        trailing: IconButton(
                                          icon: const Icon(Icons.info_outline, color: Colors.blue),
                                          onPressed: () => _showWorkoutDetails(doc),
                                        ),
                                        onTap: () => _showWorkoutDetails(doc),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
      
      // Make FAB responsive - hide in landscape or position differently
      floatingActionButton: LayoutBuilder(
        builder: (context, constraints) {
          if (isLandscape) {
            // In landscape, use a smaller FAB in the bottom right
            return FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddWorkout()),
                );
              },
              backgroundColor: Colors.purple,
              child: const Icon(Icons.add),
            );
          }
          
          // In portrait, use the extended FAB
          return FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddWorkout()),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Workout'),
            backgroundColor: Colors.purple,
          );
        },
      ),
    );
  }
}

// Separate StatefulWidget for the modal to manage its own state
class _WorkoutDetailsModal extends StatefulWidget {
  final DocumentSnapshot doc;
  final Function(bool) onStatusChanged;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _WorkoutDetailsModal({
    required this.doc,
    required this.onStatusChanged,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  State<_WorkoutDetailsModal> createState() => _WorkoutDetailsModalState();
}

class _WorkoutDetailsModalState extends State<_WorkoutDetailsModal> {
  late Map<String, dynamic> _workoutData;
  late bool _isCompleted;

  @override
  void initState() {
    super.initState();
    _workoutData = widget.doc.data() as Map<String, dynamic>;
    _isCompleted = _workoutData['completed'] ?? false;
  }

  Future<void> _toggleComplete() async {
    setState(() {
      _isCompleted = !_isCompleted;
    });
    
    // Update Firebase
    try {
      await FirebaseFirestore.instance
          .collection('workouts')
          .doc(widget.doc.id)
          .update({
        'completed': _isCompleted,
        'updatedAt': Timestamp.now(),
      });
      
      // Notify parent
      widget.onStatusChanged(_isCompleted);
    } catch (e) {
      // Revert on error
      setState(() {
        _isCompleted = !_isCompleted;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating workout: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final startDate = (_workoutData['startDate'] as Timestamp).toDate();
    final endDate = (_workoutData['endDate'] as Timestamp).toDate();
    
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _workoutData['workoutName'],
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              Chip(
                label: Text(
                  _isCompleted ? 'Completed' : 'Pending',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                backgroundColor: _isCompleted ? Colors.green : Colors.orange,
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          _buildDetailRow(Icons.category, 'Type', _workoutData['workoutType']),
          _buildDetailRow(Icons.timer, 'Duration', '${_workoutData['duration']} minutes'),
          _buildDetailRow(Icons.access_time, 'Time', _workoutData['whenToWorkout']),
          _buildDetailRow(Icons.calendar_today, 'Start Date', 
            DateFormat('MMMM dd, yyyy').format(startDate)),
          _buildDetailRow(Icons.calendar_today, 'End Date', 
            DateFormat('MMMM dd, yyyy').format(endDate)),
          
          if (_workoutData['notes'] != null && _workoutData['notes'].toString().isNotEmpty)
            _buildDetailRow(Icons.notes, 'Notes', _workoutData['notes']),
          
          const SizedBox(height: 30),
          
          // Responsive button layout
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 500) {
                // Stack buttons vertically on small screens
                return Column(
                  children: [
                    // Edit Button
                    ElevatedButton.icon(
                      onPressed: widget.onEdit,
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Workout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                    const SizedBox(height: 10),
                    
                    // Toggle Complete Button
                    ElevatedButton.icon(
                      onPressed: _toggleComplete,
                      icon: Icon(_isCompleted ? Icons.pending_actions : Icons.check_circle),
                      label: Text(_isCompleted ? 'Mark as Pending' : 'Mark as Completed'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isCompleted ? Colors.orange : Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                    const SizedBox(height: 10),
                    
                    // Delete Button
                    ElevatedButton.icon(
                      onPressed: widget.onDelete,
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete Workout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  ],
                );
              } else {
                // Use horizontal layout on wider screens
                return Column(
                  children: [
                    // First row: Edit and Toggle buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: widget.onEdit,
                            icon: const Icon(Icons.edit),
                            label: const Text('Edit'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _toggleComplete,
                            icon: Icon(_isCompleted ? Icons.pending_actions : Icons.check_circle),
                            label: Text(_isCompleted ? 'Mark Pending' : 'Mark Complete'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isCompleted ? Colors.orange : Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    
                    // Second row: Delete button (full width)
                    ElevatedButton.icon(
                      onPressed: widget.onDelete,
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete Workout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.purple, size: 22),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}