import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_splitter/helper/color.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class Activity extends StatefulWidget {
  const Activity({super.key});

  @override
  State<Activity> createState() => _ActivityState();
}

class _ActivityState extends State<Activity> {
  List<String> userGroupIds = [];
  bool _isLoadingUserGroups = true;

  @override
  void initState() {
    super.initState();
    fetchUserGroups();
  }

  Future<void> fetchUserGroups() async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (userDoc.exists && userDoc.data() != null) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        List<dynamic> groups = data['groupIds'] ?? [];
        setState(() {
          userGroupIds = groups.map((g) => g.toString()).toList();
          _isLoadingUserGroups = false;
        });
      } else {
        setState(() {
          _isLoadingUserGroups = false;
        });
      }
    } catch (e) {
      print("Error fetching user groups: $e");
      setState(() {
        _isLoadingUserGroups = false;
      });
    }
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'groupCreated':
        return Icons.groups_rounded;
      case 'memberAdded':
        return Icons.person;
      case 'expenseAdded':
        return Icons.currency_rupee;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    if (_isLoadingUserGroups) {
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          centerTitle: true,
          backgroundColor: dark_blue,
          title: Text(
            "Activity",
            style: GoogleFonts.inter(
              fontSize: size.width * 0.07,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: dark_blue,
        title: Text(
          "Activity",
          style: GoogleFonts.inter(
            fontSize: size.width * 0.07,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('activities')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          final allActivities = snapshot.data!.docs;
          // Filter activities to only include those for groups that the user belongs to.
          final activities = allActivities.where((doc) {
            String groupId = doc['groupId'];
            return userGroupIds.contains(groupId);
          }).toList();

          if (activities.isEmpty) {
            return Center(child: Text("No recent activity."));
          }
          return Padding(
            padding: EdgeInsets.only(top: 6),
            child: ListView.builder(
              itemCount: activities.length,
              itemBuilder: (context, index) {
                final doc = activities[index];
                return Card(
                  color: light_blue,
                  margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  child: ListTile(
                    leading: Icon(_getIcon(doc['type']), color: dark_blue),
                    title: Text(
                      doc['message'],
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: dark_blue,
                      ),
                    ),
                    subtitle: Text(
                      doc['timestamp'] != null
                          ? DateFormat('yyyy-MM-dd  HH:mm')
                              .format((doc['timestamp'] as Timestamp).toDate())
                          : "",
                      style: GoogleFonts.inter(color: dark_blue),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
