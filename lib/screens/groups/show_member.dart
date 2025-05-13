import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expense_splitter/helper/color.dart';

class ShowMember extends StatefulWidget {
  final String groupId;

  const ShowMember({super.key, required this.groupId});

  @override
  State<ShowMember> createState() => _ShowMemberState();
}

class _ShowMemberState extends State<ShowMember> {
  List<Map<String, dynamic>> membersList = [];

  @override
  void initState() {
    super.initState();
    fetchGroupMembers();
  }

  Future<void> fetchGroupMembers() async {
    try {
      // Step 1: Fetch group data
      DocumentSnapshot groupSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .get();

      if (!groupSnapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Group not found!")),
        );
        return;
      }

      Map<String, dynamic>? groupData =
          groupSnapshot.data() as Map<String, dynamic>?;

      List<dynamic> memberIds = groupData?["members"] ?? [];

      // Step 2: Fetch user details
      List<Map<String, dynamic>> tempList = [];
      for (String userId in memberIds) {
        DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (userSnapshot.exists) {
          Map<String, dynamic>? userData =
              userSnapshot.data() as Map<String, dynamic>?;
          tempList.add({
            "username": userData?["userName"] ?? "Unknown",
            "email": userData?["email"] ?? "No email",
          });
        }
      }

      // Update UI
      setState(() {
        membersList = tempList;
      });
    } catch (e) {
      print("Error fetching members: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load members!")),
      );
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
            "Members",
            style: GoogleFonts.inter(
              fontSize: size.width * 0.07,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
      body: membersList.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: membersList.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: Icon(Icons.person, color: dark_blue),
                  title: Text(
                    membersList[index]["username"],
                    style: GoogleFonts.inter(fontSize: size.width*0.045,)
                  ),
                  subtitle: Text(
                    membersList[index]["email"],
                    style: GoogleFonts.inter(fontSize: size.width*0.035, color: Colors.grey),
                  ),
                );
              },
            ),
    );
  }
}
