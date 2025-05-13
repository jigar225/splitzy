import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_splitter/helper/color.dart';
import 'package:expense_splitter/helper/validator.dart';
import 'package:expense_splitter/widgets/customfield.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddMember extends StatefulWidget {
  final String groupId; // Group ID to add a member

  const AddMember({super.key, required this.groupId});

  @override
  State<AddMember> createState() => _AddMemberState();
}

class _AddMemberState extends State<AddMember> {
  String? gName;
  TextEditingController username = TextEditingController();
  bool _isLoading = false; // Track if the add operation is in progress

  @override
  void dispose() {
    username.dispose();
    super.dispose();
  }

  Future<void> addMemberToGroup() async {
    String enteredUsername = username.text.trim();

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
      // Step 1: Check if the username exists in Firestore
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

      // Step 2: Get user ID from the document
      DocumentSnapshot userDoc = querySnapshot.docs.first;
      String userId = userDoc.id;

      DocumentReference groupRef = FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId);
      DocumentReference userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId);

      // Step 3: Fetch current group data
      DocumentSnapshot groupSnapshot = await groupRef.get();

      if (groupSnapshot.exists) {
        List<dynamic> members = groupSnapshot['members'] ?? [];

        gName = groupSnapshot['name'];

        // Step 4: Check if the user is already a member
        if (members.contains(userId)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("User is already a member!")),
          );
          return;
        }
      }

      // Step 5: Add the user to the group
      await groupRef
          .update({
            "members": FieldValue.arrayUnion([userId]),
          })
          .then((_) async {
            // Step 6: Add the group to the user's groups list
            await userRef.update({
              "groupIds": FieldValue.arrayUnion([widget.groupId]),
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Member added successfully!"),
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            );

            await FirebaseFirestore.instance.collection('activities').add({
              'type': 'memberAdded',
              'groupId': widget.groupId,
              'actorUid': FirebaseAuth.instance.currentUser!.uid,
              'message': " $enteredUsername added to $gName",
              'timestamp': FieldValue.serverTimestamp(),
            });

            // Clear the input field
            username.clear();
          });
    } catch (e) {
      print("Error adding member: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to add member. Please try again!"),
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
            "Add Member",
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
              preicon: Icons.person_add_alt_sharp,
              title: "Add Member",
              controller: username,
              valid: validateUsernameField,
            ),
          ),
          // Show a CircularProgressIndicator if loading; otherwise, show the button.
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
                onPressed: addMemberToGroup,
                child: Text(
                  "Add Member",
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
