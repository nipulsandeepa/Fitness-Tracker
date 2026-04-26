

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'AddWorkout.dart';
import 'ViewWorkout.dart';
import 'WorkoutLogin.dart';
import 'Achievements.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Statistics
  int _totalWorkouts = 0;
  int _completedWorkouts = 0;
  int _workoutMinutes = 0;
  int _currentStreak = 0;
  List<WeeklyData> _weeklyData = [];
  List<WorkoutTypeData> _workoutTypeData = [];
  
  // Motivational quotes
  final List<String> _motivationalQuotes = [
    "The only bad workout is the one that didn't happen.",
    "Don't stop when you're tired. Stop when you're done.",
    "Your body can stand almost anything. It's your mind you have to convince.",
    "Push harder than yesterday if you want a different tomorrow.",
    "Strength doesn't come from what you can do. It comes from overcoming the things you once thought you couldn't.",
    "The pain you feel today will be the strength you feel tomorrow.",
  ];

  String _randomQuote = "";

  @override
  void initState() {
    super.initState();
    _randomQuote = _motivationalQuotes[DateTime.now().second % _motivationalQuotes.length];
  }

  // Stream for real-time workout updates
  Stream<QuerySnapshot> _getWorkoutsStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }
    
    return _firestore
        .collection('workouts')
        .where('userId', isEqualTo: user.uid)
        .orderBy('startDate', descending: true)
        .snapshots();
  }

  // Calculate stats from workouts data
  void _calculateStats(List<QueryDocumentSnapshot> workouts) {
    _totalWorkouts = workouts.length;
    _completedWorkouts = workouts
        .where((doc) => doc['completed'] == true)
        .length;
    
    // Calculate total minutes
    _workoutMinutes = workouts.fold(0, (sum, doc) {
      return sum + (int.tryParse(doc['duration'].toString()) ?? 0);
    });

    // Prepare weekly data for chart
    _prepareWeeklyData(workouts);

    // Prepare workout type data
    _prepareWorkoutTypeData(workouts);

    // Calculate streak
    _calculateStreak(workouts);
  }

  void _calculateStreak(List<QueryDocumentSnapshot> workouts) {
    final today = DateTime.now();
    int streak = 0;
    DateTime currentDate = today;
    
    // Sort workouts by date descending
    final sortedWorkouts = workouts.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return (data['startDate'] as Timestamp).toDate();
    }).toList()
    ..sort((a, b) => b.compareTo(a));
    
    // Check for consecutive days with workouts
    while (true) {
      final hasWorkoutOnDay = sortedWorkouts.any((workoutDate) {
        return _isSameDay(workoutDate, currentDate);
      });
      
      if (!hasWorkoutOnDay) break;
      
      streak++;
      currentDate = currentDate.subtract(const Duration(days: 1));
    }
    
    _currentStreak = streak;
  }

  void _prepareWeeklyData(List<QueryDocumentSnapshot> workouts) {
    final now = DateTime.now();
    
    // Create list of last 7 days (including today) - Most recent first
    final weekData = List.generate(7, (index) {
      final date = now.subtract(Duration(days: index)); // Today - 0 to 6 days ago
      return WeeklyData(
        date: DateTime(date.year, date.month, date.day), // Normalize to start of day
        count: 0
      );
    });

    // Sort by date ascending for the chart (oldest to newest)
    weekData.sort((a, b) => a.date.compareTo(b.date));

    // Count workouts for each day
    for (final workout in workouts) {
      final startDate = (workout['startDate'] as Timestamp).toDate();
      final normalizedWorkoutDate = DateTime(startDate.year, startDate.month, startDate.day);
      
      // Find matching day in weekData using isSameDay comparison
      for (final dayData in weekData) {
        if (_isSameDay(dayData.date, normalizedWorkoutDate)) {
          dayData.count++;
          break; // Stop searching once found
        }
      }
    }

    // Debug print to check data
    print('Weekly Data (Last 7 days):');
    for (var data in weekData) {
      print('${DateFormat('EEE, MMM d').format(data.date)}: ${data.count} workouts');
    }

    _weeklyData = weekData;
  }

  // Helper function to compare dates (ignoring time)
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  void _prepareWorkoutTypeData(List<QueryDocumentSnapshot> workouts) {
    final typeCounts = <String, int>{};
    
    for (final workout in workouts) {
      final type = workout['workoutType'] ?? 'Other';
      typeCounts[type] = (typeCounts[type] ?? 0) + 1;
    }
    
    _workoutTypeData = typeCounts.entries
        .map((entry) => WorkoutTypeData(entry.key, entry.value))
        .toList();
  }

  void _logout() async {
    await _auth.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const WorkoutLogin()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 28,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.purple.shade800,
        elevation: 10,
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events, color: Colors.amber),
            onPressed: () {
              // Validate data before navigating
              if (_totalWorkouts == 0 || _workoutMinutes == 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Need workout data to show achievements'),
                    duration: Duration(seconds: 2),
                  ),
                );
                return;
              }
              
              // Pass safe values to Achievements page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Achievements(
                    totalWorkouts: _totalWorkouts,
                    completedWorkouts: _completedWorkouts,
                    workoutMinutes: _workoutMinutes,
                    currentStreak: _currentStreak,
                  ),
                ),
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
          
          if (!snapshot.hasData) {
            return const Center(child: Text('No data available'));
          }
          
          final workouts = snapshot.data!.docs;
          
          // Calculate stats from the stream data
          _calculateStats(workouts);
          
          return RefreshIndicator(
            onRefresh: () async {
              // Force a refresh by triggering a rebuild
              setState(() {});
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Card
                    _buildWelcomeCard(),
                    const SizedBox(height: 20),

                    // Quick Stats
                    _buildQuickStats(),
                    const SizedBox(height: 20),

                    // Weekly Activity Chart
                    _buildWeeklyChart(),
                    const SizedBox(height: 20),

                    // Workout Distribution
                    _workoutTypeData.isNotEmpty ? _buildWorkoutDistribution() : const SizedBox(),
                    const SizedBox(height: 20),

                    // Motivational Quote
                    _buildMotivationalQuote(),
                    const SizedBox(height: 20),

                    // Quick Actions
                    _buildQuickActions(),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeCard() {
    final user = _auth.currentUser;
    final hour = DateTime.now().hour;
    String greeting;
    
    if (hour < 12) {
      greeting = "Good Morning";
    } else if (hour < 17) greeting = "Good Afternoon";
    else greeting = "Good Evening";

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.purple.shade700,
              Colors.purple.shade900,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "$greeting, ${user?.email?.split('@').first ?? 'Fitness Warrior'}!",
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "You're on a $_currentStreak day streak! 🔥",
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 10),
            
            Row(
              children: [
                Icon(Icons.fitness_center, color: Colors.white.withOpacity(0.8)),
                const SizedBox(width: 8),
                Text(
                  "$_totalWorkouts workouts completed",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        _buildStatCard(
          icon: Icons.fitness_center,
          title: "Total Workouts",
          value: _totalWorkouts.toString(),
          color: Colors.blue,
        ),
        _buildStatCard(
          icon: Icons.check_circle,
          title: "Completed",
          value: _completedWorkouts.toString(),
          color: Colors.green,
        ),
        _buildStatCard(
          icon: Icons.timer,
          title: "Minutes",
          value: _workoutMinutes.toString(),
          color: Colors.orange,
        ),
        _buildStatCard(
          icon: Icons.local_fire_department,
          title: "Current Streak",
          value: "$_currentStreak days",
          color: Colors.red,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        padding: const EdgeInsets.all(12.0),
        height: 100,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 6),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 16,
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

 




Widget _buildWeeklyChart() {
  // Check if there's any data to show
  final hasData = _weeklyData.isNotEmpty && _weeklyData.any((day) => day.count > 0);
  
  return Card(
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15),
    ),
    margin: const EdgeInsets.symmetric(horizontal: 16),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 16), // Less padding on right
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Weekly Activity (Last 7 Days)",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 230,
            child: hasData 
                ? SfCartesianChart(
                    margin: const EdgeInsets.only(right: 8), // Margin on right
                    plotAreaBorderWidth: 0,
                    primaryXAxis: CategoryAxis(
                      labelRotation: -45, // Keep rotated labels
                      labelPlacement: LabelPlacement.onTicks,
                      majorGridLines: const MajorGridLines(width: 0),
                      axisLine: const AxisLine(width: 0),
                      labelStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    primaryYAxis: NumericAxis(
                      minimum: 0,
                      maximum: _weeklyData
                              .map((e) => e.count)
                              .reduce((a, b) => a > b ? a : b)
                              .toDouble() *
                          1.2,
                      interval: 1,
                      labelStyle: const TextStyle(fontSize: 12),
                      majorGridLines: const MajorGridLines(width: 0.5, color: Colors.grey),
                      axisLine: const AxisLine(width: 0),
                    ),
                    series: <CartesianSeries>[
                      ColumnSeries<WeeklyData, String>(
                        dataSource: _weeklyData,
                        xValueMapper: (WeeklyData data, _) =>
                            DateFormat('EEE d').format(data.date), // "Fri 16"
                        yValueMapper: (WeeklyData data, _) => data.count,
                        color: Colors.purple,
                        borderRadius: BorderRadius.circular(4),
                        width: 0.7,
                        dataLabelSettings: const DataLabelSettings(
                          isVisible: true,
                          labelAlignment: ChartDataLabelAlignment.top,
                          textStyle: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.insert_chart, size: 50, color: Colors.grey[300]),
                        const SizedBox(height: 10),
                        const Text(
                          "No workouts this week",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    ),
  );
}






  Widget _buildWorkoutDistribution() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Workout Distribution",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              child: SfCircularChart(
                series: <CircularSeries>[
                  DoughnutSeries<WorkoutTypeData, String>(
                    dataSource: _workoutTypeData,
                    xValueMapper: (WorkoutTypeData data, _) => data.type,
                    yValueMapper: (WorkoutTypeData data, _) => data.count,
                    dataLabelMapper: (WorkoutTypeData data, _) =>
                        '${data.type}: ${data.count}',
                    dataLabelSettings: const DataLabelSettings(isVisible: true),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMotivationalQuote() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber),
                SizedBox(width: 10),
                Text(
                  "Daily Motivation",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              _randomQuote,
              style: const TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddWorkout()),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text(
              "Add Workout",
            style: TextStyle(
              color:Colors.white
              ),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              backgroundColor: Colors.purple,
                    
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ViewWorkout()),
              );
            },
            icon: const Icon(Icons.list),
            label: const Text("View All", 
            style: TextStyle(
              color:Colors.white
              ),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              backgroundColor: Colors.blueGrey,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class WeeklyData {
  final DateTime date;
  int count; // Make this mutable by removing 'final'
  
  WeeklyData({required this.date, required this.count});
}

class WorkoutTypeData {
  final String type;
  final int count;
  
  WorkoutTypeData(this.type, this.count);
}