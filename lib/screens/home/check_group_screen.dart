import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_splitter/Screens/groups/havenot_group.dart';
import 'package:expense_splitter/Screens/groups/show_group.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CheckGroupScreen extends StatefulWidget {
  const CheckGroupScreen({super.key});

  @override
  State<CheckGroupScreen> createState() => _CheckGroupScreenState();
}

class _CheckGroupScreenState extends State<CheckGroupScreen> {
  bool _isLoading = true;
  bool _hasGroups = false;

  @override
  void initState() {
    super.initState();
    checkUserGroups();
  }

  void checkUserGroups() async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      setState(() {
        _isLoading = false;
        _hasGroups = false;
      });
      return;
    }

    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (userDoc.exists && userDoc.data() is Map<String, dynamic>) {
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      if (userData.containsKey("groupIds")) {
        List<dynamic> groupIds = userData["groupIds"];
        bool hasValidGroup = false;

        // Check if at least one group in the list actually exists
        for (var groupId in groupIds) {
          DocumentSnapshot groupDoc =
              await FirebaseFirestore.instance
                  .collection('groups')
                  .doc(groupId)
                  .get();
          if (groupDoc.exists) {
            hasValidGroup = true;
            break;
          }
        }

        setState(() {
          _hasGroups = hasValidGroup;
        });
      } else {
        setState(() {
          _hasGroups = false;
        });
      }
    } else {
      setState(() {
        _hasGroups = false;
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return _hasGroups ? const ShowGroup() : const HavenotGroup();
  }
}
