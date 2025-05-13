import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_splitter/helper/color.dart';
import 'package:expense_splitter/widgets/group_button.dart';
import 'package:expense_splitter/Screens/groups/add_group.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HavenotGroup extends StatefulWidget {
  const HavenotGroup({super.key});

  @override
  State<HavenotGroup> createState() => _HavenotGroupState();
}

class _HavenotGroupState extends State<HavenotGroup> {
  String firstName = "";
  String lastName = "";
  String userName = "";
  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  void createNavigate() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddGroup()),
    );
  }


  void fetchUserData() async {
    String userDocId = FirebaseAuth.instance.currentUser!.uid;

    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userDocId)
            .get();

    if (userDoc.exists) {
      setState(() {
        firstName = userDoc["firstName"] ?? "";
        lastName = userDoc["lastName"] ?? "";
        userName = userDoc["userName"] ?? "";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: Center(
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (firstName.isNotEmpty && lastName.isNotEmpty)
                  Align(
                    alignment: Alignment(0, 0),
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        "Welcome $firstName $lastName",
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: dark_blue,
                        ),
                      ),
                    ),
                  ),
                Center(
                  child: Text(
                    "You haven't join / create group.",
                    style: GoogleFonts.inter(
                      fontSize: size.width * 0.065,
                      fontWeight: FontWeight.bold,
                      color: dark_blue,
                    ),
                  ),
                ),
                SizedBox(height: size.height * 0.04),
                GroupButton(
                  size: size,
                  txt: "Create Group",
                  icon: Icons.add_circle_rounded,
                  bgColor: dark_blue,
                  fn: createNavigate,
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
