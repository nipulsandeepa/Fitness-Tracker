import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:confetti/confetti.dart';
import 'package:intl/intl.dart';

class Achievements extends StatefulWidget {
  final int totalWorkouts;
  final int completedWorkouts;
  final int workoutMinutes;
  final int currentStreak;
  
  const Achievements({
    super.key,
    this.totalWorkouts = 0,
    this.completedWorkouts = 0,
    this.workoutMinutes = 0,
    this.currentStreak = 0,
  });

  @override
  State<Achievements> createState() => _AchievementsState();
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final Color color;
  final int target;
  final int progress;
  final bool unlocked;
  final DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.target,
    required this.progress,
    required this.unlocked,
    this.unlockedAt,
  });
}

class _AchievementsState extends State<Achievements> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfettiController _confettiController = ConfettiController();
  
  List<Achievement> _achievements = [];
  int _totalPoints = 0;
  int _unlockedCount = 0;

  // Helper method for safe division
  double safeDivide(int numerator, int denominator) {
    if (denominator == 0) return 0.0;
    final result = numerator / denominator;
    if (result.isNaN || result.isInfinite) return 0.0;
    return result;
  }

  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadAchievements() async {
    final user = _auth.currentUser;
    if (user == null) return;

    int totalWorkouts = widget.totalWorkouts;
    int completedWorkouts = widget.completedWorkouts;
    int totalMinutes = widget.workoutMinutes;
    int streak = widget.currentStreak;

    // Only fetch from Firestore if passed values are 0
    if (totalWorkouts == 0 || completedWorkouts == 0) {
      try {
        final workoutsSnapshot = await _firestore
            .collection('workouts')
            .where('userId', isEqualTo: user.uid)
            .get();

        totalWorkouts = workoutsSnapshot.docs.length;
        completedWorkouts = workoutsSnapshot.docs
            .where((doc) => doc['completed'] == true)
            .length;

        // Calculate total minutes if needed
        if (totalMinutes == 0) {
          totalMinutes = workoutsSnapshot.docs.fold(0, (sum, doc) {
            return sum + (int.tryParse(doc['duration'].toString()) ?? 0);
          });
        }
      } catch (e) {
        print('Error loading workouts: $e');
        totalWorkouts = 0;
        completedWorkouts = 0;
        totalMinutes = 0;
      }
    }

    // Only calculate streak if passed value is 0
    if (streak == 0) {
      streak = await _calculateStreak(user.uid);
    }

    // Get achievements from Firestore or create default ones
    final achievementsRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('achievements');

    Map<String, Timestamp> unlockedMap = {};
    try {
      final unlockedAchievements = await achievementsRef.get();
      unlockedMap = {
        for (var doc in unlockedAchievements.docs) 
          doc.id: doc['unlockedAt'] as Timestamp
      };
    } catch (e) {
      print('Error loading unlocked achievements: $e');
    }

    // Define achievements
    final defaultAchievements = [
      Achievement(
        id: 'first_workout',
        title: 'First Steps',
        description: 'Complete your first workout',
        icon: '👣',
        color: Colors.blue,
        target: 1,
        progress: totalWorkouts >= 1 ? 1 : 0,
        unlocked: unlockedMap.containsKey('first_workout') || totalWorkouts >= 1,
        unlockedAt: unlockedMap['first_workout']?.toDate(),
      ),
      Achievement(
        id: 'workout_streak_3',
        title: 'Consistent Trainee',
        description: 'Maintain a 3-day workout streak',
        icon: '🔥',
        color: Colors.orange,
        target: 3,
        progress: streak >= 3 ? 3 : streak,
        unlocked: unlockedMap.containsKey('workout_streak_3') || streak >= 3,
        unlockedAt: unlockedMap['workout_streak_3']?.toDate(),
      ),
      Achievement(
        id: 'workout_streak_7',
        title: 'Week Warrior',
        description: 'Maintain a 7-day workout streak',
        icon: '💪',
        color: Colors.red,
        target: 7,
        progress: streak >= 7 ? 7 : streak,
        unlocked: unlockedMap.containsKey('workout_streak_7') || streak >= 7,
        unlockedAt: unlockedMap['workout_streak_7']?.toDate(),
      ),
      Achievement(
        id: 'complete_10_workouts',
        title: 'Dedicated',
        description: 'Complete 10 workouts',
        icon: '🏆',
        color: Colors.amber,
        target: 10,
        progress: completedWorkouts >= 10 ? 10 : completedWorkouts,
        unlocked: unlockedMap.containsKey('complete_10_workouts') || completedWorkouts >= 10,
        unlockedAt: unlockedMap['complete_10_workouts']?.toDate(),
      ),
      Achievement(
        id: 'complete_25_workouts',
        title: 'Master',
        description: 'Complete 25 workouts',
        icon: '👑',
        color: Colors.purple,
        target: 25,
        progress: completedWorkouts >= 25 ? 25 : completedWorkouts,
        unlocked: unlockedMap.containsKey('complete_25_workouts') || completedWorkouts >= 25,
        unlockedAt: unlockedMap['complete_25_workouts']?.toDate(),
      ),
      Achievement(
        id: 'total_500_minutes',
        title: 'Endurance King',
        description: 'Complete 500 minutes of workouts',
        icon: '⏱️',
        color: Colors.green,
        target: 500,
        progress: totalMinutes >= 500 ? 500 : totalMinutes,
        unlocked: unlockedMap.containsKey('total_500_minutes') || totalMinutes >= 500,
        unlockedAt: unlockedMap['total_500_minutes']?.toDate(),
      ),
    ];

    // Try to get workout variety if we have data
    int workoutVariety = 0;
    int morningWorkouts = 0;
    
    if (totalWorkouts > 0) {
      try {
        final workoutsSnapshot = await _firestore
            .collection('workouts')
            .where('userId', isEqualTo: user.uid)
            .limit(50) // Limit to prevent too many reads
            .get();
        
        workoutVariety = _calculateWorkoutVariety(workoutsSnapshot.docs);
        morningWorkouts = _calculateMorningWorkouts(workoutsSnapshot.docs);
      } catch (e) {
        print('Error calculating variety: $e');
      }
    }

    defaultAchievements.addAll([
      Achievement(
        id: 'variety_expert',
        title: 'Variety Expert',
        description: 'Try 5 different workout types',
        icon: '🎯',
        color: Colors.teal,
        target: 5,
        progress: workoutVariety,
        unlocked: unlockedMap.containsKey('variety_expert') || workoutVariety >= 5,
        unlockedAt: unlockedMap['variety_expert']?.toDate(),
      ),
      Achievement(
        id: 'early_bird',
        title: 'Early Bird',
        description: 'Complete 5 morning workouts',
        icon: '🌅',
        color: Colors.deepOrange,
        target: 5,
        progress: morningWorkouts,
        unlocked: unlockedMap.containsKey('early_bird') || morningWorkouts >= 5,
        unlockedAt: unlockedMap['early_bird']?.toDate(),
      ),
    ]);

    // Check for newly unlocked achievements
    for (final achievement in defaultAchievements) {
      if (achievement.progress >= achievement.target && !achievement.unlocked) {
        _unlockAchievement(achievement.id);
      }
    }

    // Calculate points and stats
    _totalPoints = defaultAchievements
        .where((a) => a.unlocked)
        .fold(0, (sum, a) => sum + (a.target * 10));

    _unlockedCount = defaultAchievements.where((a) => a.unlocked).length;

    setState(() {
      _achievements = defaultAchievements;
    });
  }

  int _calculateWorkoutVariety(List<QueryDocumentSnapshot> workouts) {
    final types = <String>{};
    for (final workout in workouts) {
      final type = workout['workoutType'];
      if (type != null) {
        types.add(type.toString());
      }
    }
    return types.length;
  }

  int _calculateMorningWorkouts(List<QueryDocumentSnapshot> workouts) {
    return workouts
        .where((workout) => workout['whenToWorkout'] == 'Morning')
        .length;
  }

  Future<int> _calculateStreak(String userId) async {
    try {
      final today = DateTime.now();
      int streak = 0;
      DateTime currentDate = today;
      
      // Limit to checking last 30 days to prevent infinite loop
      const maxDaysToCheck = 30;
      int daysChecked = 0;
      
      while (daysChecked < maxDaysToCheck) {
        final startOfDay = DateTime(currentDate.year, currentDate.month, currentDate.day);
        final endOfDay = DateTime(currentDate.year, currentDate.month, currentDate.day, 23, 59, 59);
        
        final workoutOnDay = await _firestore
            .collection('workouts')
            .where('userId', isEqualTo: userId)
            .where('startDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
            .limit(1) // We only need to know if at least one exists
            .get();
        
        if (workoutOnDay.docs.isEmpty) break;
        
        streak++;
        currentDate = currentDate.subtract(const Duration(days: 1));
        daysChecked++;
      }
      
      return streak;
    } catch (e) {
      print('Error calculating streak: $e');
      return 0; // Return 0 instead of crashing
    }
  }

  Future<void> _unlockAchievement(String achievementId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('achievements')
          .doc(achievementId)
          .set({
            'unlockedAt': Timestamp.now(),
          });

      // Trigger confetti
      _confettiController.play();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Achievement Unlocked!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      print('Error unlocking achievement: $e');
    }
  }

  void _shareAchievement(Achievement achievement) {
    // In a real app, you would integrate with a sharing package
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Shared ${achievement.title} achievement!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Achievements',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 28,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.purple.shade800,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Stats
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          '🏆',
                          '$_unlockedCount/${_achievements.length}',
                          'Unlocked',
                        ),
                        _buildStatItem(
                          '⭐',
                          '$_totalPoints',
                          'Total Points',
                        ),
                        _buildStatItem(
                          '📈',
                          '${(safeDivide(_unlockedCount, _achievements.length) * 100).toInt()}%',
                          'Progress',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Achievement List
                if (_achievements.isNotEmpty) ...[
                  const Text(
                    'Your Achievements',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),

                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      childAspectRatio: 0.9,
                    ),
                    itemCount: _achievements.length,
                    itemBuilder: (context, index) {
                      return _buildAchievementCard(_achievements[index]);
                    },
                  ),
                ] else ...[
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Icon(Icons.emoji_events_outlined, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No achievements yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Complete workouts to unlock achievements!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // How to Earn More
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '💡 Tips to Earn More',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildTipItem('Complete workouts consistently to maintain your streak'),
                        _buildTipItem('Try different types of workouts for variety'),
                        _buildTipItem('Workout in the morning to earn Early Bird achievement'),
                        _buildTipItem('Set realistic goals and track your progress'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    return Card(
      elevation: achievement.unlocked ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      color: achievement.unlocked
          ? achievement.color.withOpacity(0.1)
          : Colors.grey.shade100,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: achievement.unlocked
            ? () => _shareAchievement(achievement)
            : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon with lock/unlock indicator
              Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    achievement.icon,
                    style: const TextStyle(fontSize: 32),
                  ),
                  if (!achievement.unlocked)
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.lock,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),

              // Title
              Text(
                achievement.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: achievement.unlocked
                      ? achievement.color
                      : Colors.grey,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 5),

              // Progress bar
              LinearProgressIndicator(
                value: achievement.target > 0 
                    ? achievement.progress / achievement.target 
                    : 0.0,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(
                  achievement.unlocked
                      ? achievement.color
                      : Colors.grey,
                ),
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
              const SizedBox(height: 5),

              // Progress text
              Text(
                '${achievement.progress}/${achievement.target}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),

              // Unlock date if unlocked
              if (achievement.unlocked && achievement.unlockedAt != null)
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(
                    DateFormat('MMM yyyy').format(achievement.unlockedAt!),
                    style: const TextStyle(
                      fontSize: 10,
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

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• '),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}