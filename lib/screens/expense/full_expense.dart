import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_splitter/helper/color.dart';
import 'package:expense_splitter/Screens/expense/expense_details.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class FullExpense extends StatefulWidget {
  final String groupId;
  const FullExpense({super.key, required this.groupId});

  @override
  State<FullExpense> createState() => _FullExpenseState();
}

class _FullExpenseState extends State<FullExpense> {
  String groupName = "Loading...";
  String? adminName = "Loading...";
  int totalMembers = 0;
  
  // Map of UID to userName.
  Map<String, String> memberNames = {};

  @override
  void initState() {
    super.initState();
    fetchGroupDetails();
    fetchMemberNames();
  }

  // Fetch group details like group name, admin, and member count.
  void fetchGroupDetails() async {
    DocumentSnapshot groupDoc = await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .get();

    if (groupDoc.exists) {
      String adminId = groupDoc['adminId'];
      List<dynamic> membersList = groupDoc['members'] ?? [];

      String fetchedAdminName = "Unknown";
      if (adminId.isNotEmpty) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(adminId)
            .get();

        if (userDoc.exists) {
          fetchedAdminName = userDoc['userName'] ?? "Unknown";
        }
      }

      setState(() {
        groupName = groupDoc['name'] ?? "Unnamed Group";
        adminName = fetchedAdminName;
        totalMembers = membersList.length;
      });
    } else {
      print("Group document does not exist!");
    }
  }

  // Build a map of member UID to userName from the group's members.
  Future<void> fetchMemberNames() async {
    try {
      DocumentSnapshot groupSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .get();
      if (groupSnapshot.exists) {
        List<dynamic> userIds = groupSnapshot["members"];
        Map<String, String> tempMap = {};
        for (String uid in userIds) {
          DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .get();
          if (userSnapshot.exists) {
            tempMap[uid] = userSnapshot["userName"];
          }
        }
        setState(() {
          memberNames = tempMap;
        });
      }
    } catch (e) {
      print("Error fetching member names: $e");
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
            "All Expenses",
            style: GoogleFonts.inter(
              fontSize: size.width * 0.06,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.groupId)
            .collection('expenses')
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "No expenses found.",
                style: GoogleFonts.inter(
                  fontSize: size.width * 0.05,
                  fontWeight: FontWeight.bold,
                  color: dark_blue,
                ),
              ),
            );
          }
          return Padding(
            padding: EdgeInsets.only(top: size.height * 0.02),
            child: ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                DocumentSnapshot expenseDoc = snapshot.data!.docs[index];
                // Use memberNames to display the userName instead of the UID.
                String paidByUid = expenseDoc['paidBy'];
                String paidByName =
                    memberNames[paidByUid] ?? "Loading..."; // placeholder
                String formattedDate =
                    DateFormat('yyyy-MM-dd').format(expenseDoc['date'].toDate());
                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: size.width * 0.03,
                    vertical: size.height * 0.002,
                  ),
                  child: Card(
                    color: dark_blue,
                    margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    child: ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ExpenseDetailPage(expenseDoc: expenseDoc, groupId: widget.groupId,),
                          ),
                        );
                      },
                      title: Text(
                        expenseDoc['title'] ?? "No Title",
                        style: GoogleFonts.inter(
                          fontSize: size.width * 0.045,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      subtitle: Text(
                        "Paid by: $paidByName | Date: $formattedDate",
                        style: GoogleFonts.inter(
                          fontSize: size.width * 0.03,
                          color: Colors.white,
                        ),
                      ),
                      trailing: Text(
                        "₹${expenseDoc['amount']}",
                        style: GoogleFonts.inter(
                          fontSize: size.width * 0.035,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
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
