import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_splitter/helper/color.dart';
import 'package:expense_splitter/Screens/expense/add_expense.dart';
import 'package:expense_splitter/Screens/expense/full_expense.dart';
import 'package:expense_splitter/Screens/expense/settlement_page.dart';
import 'package:expense_splitter/Screens/groups/add_member.dart';
import 'package:expense_splitter/Screens/groups/remove_member.dart';
import 'package:expense_splitter/Screens/groups/show_member.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class GroupDetailPage extends StatefulWidget {
  final String groupId;
  const GroupDetailPage({super.key, required this.groupId});

  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage> {
  String groupName = "Loading..."; // Default text until we fetch data
  String? adminName = "Loading...";
  int totalMembers = 0;
  Map<String, String> memberNames = {}; // UID -> userName map

  @override
  void initState() {
    super.initState();
    fetchGroupDetails(); // Fetch group details (name, admin, count)
    fetchMemberNames();  // Build a map of UID -> userName for display
  }

  // Fetch group details (like group name, admin, total members)
  void fetchGroupDetails() async {
    DocumentSnapshot groupDoc = await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .get();

    if (groupDoc.exists) {
      String adminId = groupDoc['adminId']; // Fetch admin ID
      List<dynamic> membersList = groupDoc['members'] ?? []; // Members List

      print("Fetched Admin ID: $adminId"); // Debugging

      String fetchedAdminName = "Unknown";

      if (adminId.isNotEmpty) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(adminId)
            .get();

        if (userDoc.exists) {
          print("User document found: ${userDoc.data()}");
          fetchedAdminName = userDoc['userName'] ?? "Unknown";
        } else {
          print("User document NOT found for ID: $adminId");
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

  // Fetch all members' usernames based on their UIDs from the group document.
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
            groupName, // Display dynamic group name
            style: GoogleFonts.inter(
              fontSize: size.width * 0.07,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Top action buttons: Add/Remove Member, Add Expense, Show Members
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: size.height * 0.02,
              horizontal: size.width * 0.03,
            ),
            child: Wrap(
              spacing: size.width * 0.02,
              runSpacing: size.height * 0.01,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                    backgroundColor: light_blue,
                    foregroundColor: dark_blue,
                  ),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddMember(groupId: widget.groupId),
                      ),
                    );
                    fetchGroupDetails(); // Refresh details
                    fetchMemberNames();  // Refresh member names map
                  },
                  child: Text(
                    "Add Member",
                    style: GoogleFonts.inter(
                      fontSize: size.width * 0.045,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                    backgroundColor: light_blue,
                    foregroundColor: dark_blue,
                  ),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RemoveMember(groupId: widget.groupId),
                      ),
                    );
                    fetchGroupDetails();
                    fetchMemberNames();
                  },
                  child: Text(
                    "Remove Member",
                    style: GoogleFonts.inter(
                      fontSize: size.width * 0.045,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                    backgroundColor: light_blue,
                    foregroundColor: dark_blue,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddExpense(groupId: widget.groupId),
                      ),
                    );
                  },
                  child: Text(
                    "Add Expense",
                    style: GoogleFonts.inter(
                      fontSize: size.width * 0.045,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                    backgroundColor: light_blue,
                    foregroundColor: dark_blue,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ShowMember(groupId: widget.groupId),
                      ),
                    );
                  },
                  child: Text(
                    "Show Members",
                    style: GoogleFonts.inter(
                      fontSize: size.width * 0.045,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Group details: Admin and Members count
          Padding(
            padding: EdgeInsets.symmetric(horizontal: size.width * 0.00),
            child: Wrap(
              spacing: size.width * 0.08,
              children: [
                Text(
                  "👑 Admin: $adminName",
                  style: GoogleFonts.inter(
                    fontSize: size.width * 0.045,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ShowMember(groupId: widget.groupId),
                      ),
                    );
                  },
                  child: Text(
                    "👥 Members: $totalMembers",
                    style: GoogleFonts.inter(
                      fontSize: size.width * 0.045,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Settlement Buttons
          Padding(
            padding: EdgeInsets.only(top: size.height * 0.01),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    backgroundColor: dark_blue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SettlementPage(
                          groupId: widget.groupId,
                          settlementType: SettlementType.pay,
                          currentUserId: FirebaseAuth.instance.currentUser!.uid,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    "Have to Pay",
                    style: GoogleFonts.inter(
                      fontSize: size.width * 0.035,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    backgroundColor: dark_blue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SettlementPage(
                          groupId: widget.groupId,
                          settlementType: SettlementType.receive,
                          currentUserId: FirebaseAuth.instance.currentUser!.uid,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    "Have to Receive",
                    style: GoogleFonts.inter(
                      fontSize: size.width * 0.035,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Expenses section: Show last 5 transactions
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('groups')
                  .doc(widget.groupId)
                  .collection('expenses')
                  .orderBy('date', descending: true)
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: size.height * 0.04),
                      Expanded(
                        child: Text(
                          "No expense for this group.",
                          style: GoogleFonts.inter(
                            fontSize: size.width * 0.05,
                            fontWeight: FontWeight.bold,
                            color: dark_blue,
                          ),
                        ),
                      ),
                      SizedBox(height: size.height * 0.02),
                      Image.asset(
                        "assets/images/group.png",
                        height: size.height * 0.5,
                      ),
                    ],
                  );
                }
                // Display the last 5 transactions
                return Column(
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  FullExpense(groupId: widget.groupId),
                            ),
                          );
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "See Full Details",
                              style: GoogleFonts.inter(
                                color: dark_blue,
                                fontSize: size.width * 0.04,
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: dark_blue,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          DocumentSnapshot expenseDoc =
                              snapshot.data!.docs[index];
                          return Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: size.width * 0.03,
                              vertical: size.height * 0.002,
                            ),
                            child: Card(
                              color: dark_blue,
                              margin: EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 8,
                              ),
                              child: ListTile(
                                title: Text(
                                  expenseDoc['title'] ?? "No Title",
                                  style: GoogleFonts.inter(
                                    fontSize: size.width * 0.045,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                subtitle: Text(
                                  // Replace UID with username using memberNames map:
                                  "Paid by: ${memberNames[expenseDoc['paidBy']] ?? 'Loading...'} | Date: ${DateFormat('yyyy-MM-dd').format(expenseDoc['date'].toDate())}",
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
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
