import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expense_splitter/helper/color.dart';
import 'package:expense_splitter/helper/validator.dart';
import 'package:expense_splitter/widgets/customfield.dart';

class RemoveMember extends StatefulWidget {
  final String groupId;

  const RemoveMember({super.key, required this.groupId});

  @override
  State<RemoveMember> createState() => _RemoveMemberState();
}

class _RemoveMemberState extends State<RemoveMember> {
  TextEditingController username = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false; // Loading flag

  @override
  void dispose() {
    username.dispose();
    super.dispose();
  }

  Future<void> removeMemberFromGroup() async {
    String enteredUsername = username.text.trim();
    String? currentUserId = _auth.currentUser?.uid;

    if (enteredUsername.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please enter a username")));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Step 1: Fetch group details
      DocumentSnapshot groupSnapshot =
          await FirebaseFirestore.instance
              .collection('groups')
              .doc(widget.groupId)
              .get();

      if (!groupSnapshot.exists) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Group not found!")));
        return;
      }

      Map<String, dynamic>? groupData =
          groupSnapshot.data() as Map<String, dynamic>?;

      List<dynamic> members = groupData?["members"] ?? [];
      String adminId = groupData?["adminId"] ?? "";

      print("Admin ID from Firestore: $adminId"); // Debugging log

      // Step 2: Ensure current user is the admin
      if (currentUserId != adminId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Only the admin can remove members!")),
        );
        return;
      }

      // Step 3: Find the user by username
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('userName', isEqualTo: enteredUsername)
              .get();

      if (querySnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("User not found!")));
        return;
      }

      // Step 4: Get the user ID
      DocumentSnapshot userDoc = querySnapshot.docs.first;
      String userId = userDoc.id;

      print("User ID found for $enteredUsername: $userId"); // Debugging log

      // Step 5: Check if the user is in the group
      if (!members.contains(userId)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User is not in the group!")),
        );
        return;
      }

      // Step 6: Remove user from the group
      DocumentReference groupRef = FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId);
      await groupRef.update({
        "members": FieldValue.arrayRemove([userId]),
      });

      // Step 7: Remove group from the user's group list
      DocumentReference userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId);
      await userRef.update({
        "groupIds": FieldValue.arrayRemove([widget.groupId]),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Member removed successfully!"),
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      );

      // Clear the input field
      username.clear();
    } catch (e) {
      print("Error removing member: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to remove member. Please try again!"),
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: dark_blue,
        automaticallyImplyLeading: false,
        title: Center(
          child: Text(
            "Remove Member",
            style: GoogleFonts.inter(
              fontSize: size.width * 0.07,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: size.width * 0.04),
            child: CustomField(
              size: size,
              htext: "Enter Username",
              preicon: Icons.person_remove_sharp,
              title: "Remove Member",
              controller: username,
              valid: validateUsernameField,
            ),
          ),
          // Show CircularProgressIndicator if loading; else show the button.
          _isLoading
              ? CircularProgressIndicator()
              : ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.all(size.width * 0.03),
                  backgroundColor: dark_blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: removeMemberFromGroup,
                child: Text(
                  "Remove Member",
                  style: GoogleFonts.inter(
                    fontSize: size.width * 0.05,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
