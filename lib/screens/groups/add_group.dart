import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_splitter/helper/color.dart';
import 'package:expense_splitter/helper/validator.dart';
import 'package:expense_splitter/widgets/customfield.dart';
import 'package:expense_splitter/widgets/group_button.dart';
import 'package:expense_splitter/Screens/home/homepage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddGroup extends StatefulWidget {
  const AddGroup({super.key});

  @override
  State<AddGroup> createState() => _AddGroupState();
}

class _AddGroupState extends State<AddGroup> {
  TextEditingController addGroup = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void addGroupToFirestore() async {
    String groupName = addGroup.text.trim();

    if (groupName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: const Text("Please enter a group name"),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      );
      return;
    }

    User? user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("User not logged in")));
      return;
    }

    String userId = user.uid;
    DocumentReference userDoc = _firestore.collection('users').doc(userId);
    CollectionReference groupsCollection = _firestore.collection('groups');

    try {
      // Step 1: Create the group document and get the new group ID.
      DocumentReference newGroupRef = await groupsCollection.add({
        'name': groupName,
        'createdAt': FieldValue.serverTimestamp(),
        'adminId': userId,
        'members': [userId], // Add the creator as the first member
      });

      // Step 2: Add the new group ID to the user's "groupIds" list.
      await userDoc.update({
        'groupIds': FieldValue.arrayUnion([newGroupRef.id]),
      });

      // **NEW STEP: Log the group creation activity**
      await _firestore.collection('activities').add({
        'type': 'groupCreated',
        'groupId': newGroupRef.id,
        'actorUid': userId,
        'message': "Created group $groupName",
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text("Group added successfully"),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      );

      addGroup.clear();

      // Redirect to Homepage (or ShowGroup) and remove AddGroup from the stack.
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => Homepage()),
        (route) => false,
      );
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    }
  }

  @override
  void dispose() {
    addGroup.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: dark_blue,
        centerTitle: true,
        title: Text(
          "Add Group",
          style: GoogleFonts.inter(
            fontSize: size.width * 0.07,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(size.width * 0.03),
            child: Column(
              children: [
                CustomField(
                  size: size,
                  htext: "Group Name",
                  preicon: Icons.group_add_outlined,
                  title: "Group Name",
                  controller: addGroup,
                  valid: validateGroup,
                ),
                GroupButton(
                  size: size,
                  txt: "Add Group",
                  icon: Icons.add,
                  bgColor: dark_blue,
                  fn: addGroupToFirestore,
                  txtColor: Colors.white,
                  iconColor: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
