import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_splitter/helper/color.dart';
import 'package:expense_splitter/helper/ledger_helper.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ExpenseDetailPage extends StatefulWidget {
  final String groupId;
  final DocumentSnapshot expenseDoc;
  const ExpenseDetailPage({
    Key? key,
    required this.expenseDoc,
    required this.groupId,
  }) : super(key: key);

  @override
  State<ExpenseDetailPage> createState() => _ExpenseDetailPageState();
}

class _ExpenseDetailPageState extends State<ExpenseDetailPage> {
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  Future<String>? paidByNameFuture;
  Future<String>? splitNamesFuture;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.expenseDoc['title']);
    _amountController = TextEditingController(
      text: widget.expenseDoc['amount'].toString(),
    );
    paidByNameFuture = fetchPaidByName();
    splitNamesFuture = fetchSplitNames();
  }

  Future<String> fetchPaidByName() async {
    // Fetch the user document for the UID stored in 'paidBy'
    String paidByUid = widget.expenseDoc['paidBy'];
    DocumentSnapshot userSnapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(paidByUid)
            .get();
    if (userSnapshot.exists) {
      return userSnapshot['userName'] ?? paidByUid;
    }
    return paidByUid;
  }

  Future<String> fetchSplitNames() async {
    // Fetch display names for all UIDs in the 'splitAmong' field.
    List<dynamic> splitUids = widget.expenseDoc['splitAmong'] ?? [];
    List<String> names = [];
    for (var uid in splitUids) {
      DocumentSnapshot userSnapshot =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userSnapshot.exists) {
        names.add(userSnapshot['userName'] ?? uid);
      } else {
        names.add(uid);
      }
    }
    return names.join(', ');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _showEditDialog() {
    showDialog(
      context: context,
      builder: (context) {
        // Use StatefulBuilder to manage local state for the dialog.
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(
                "Edit Expense",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: dark_blue,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(labelText: "Expense Title"),
                    ),
                    TextField(
                      controller: _amountController,
                      decoration: InputDecoration(labelText: "Expense Amount"),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // close dialog
                  },
                  child: Text(
                    "Cancel",
                    style: GoogleFonts.inter(color: dark_blue),
                  ),
                ),
                // If update is in progress, show a CircularProgressIndicator.
                _isUpdating
                    ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: CircularProgressIndicator(),
                    )
                    : TextButton(
                      onPressed: () async {
                        String newTitle = _titleController.text.trim();
                        double? newAmount = double.tryParse(
                          _amountController.text.trim(),
                        );
                        if (newTitle.isNotEmpty && newAmount != null) {
                          // Capture the old expense amount before updating.
                          double oldAmount = widget.expenseDoc['amount'];

                          // Set the dialog's updating state.
                          setStateDialog(() {
                            _isUpdating = true;
                          });

                          // Update the expense document.
                          await widget.expenseDoc.reference.update({
                            'title': newTitle,
                            'amount': newAmount,
                          });

                          // If the amount has changed, update the ledger.
                          if (newAmount != oldAmount) {
                            await updateLedgerForEditedExpense(
                              groupId: widget.groupId,
                              payer: widget.expenseDoc['paidBy'],
                              splitMembers: List<String>.from(
                                widget.expenseDoc['splitAmong'],
                              ),
                              oldExpenseAmount: oldAmount,
                              newExpenseAmount: newAmount,
                            );
                          }

                          // Wait a short moment to let Firestore process the update.
                          await Future.delayed(Duration(seconds: 1));

                          // Get the updated expense snapshot.
                          DocumentSnapshot updatedExpense =
                              await widget.expenseDoc.reference.get();
                          String? activityId = updatedExpense['activityId'];

                          if (activityId != null) {
                            // Update existing activity.
                            await FirebaseFirestore.instance
                                .collection('activities')
                                .doc(activityId)
                                .update({
                                  'message':
                                      "Expense updated: '$newTitle' of amount ₹$newAmount",
                                  'timestamp': FieldValue.serverTimestamp(),
                                });
                          } else {
                            // Create a new activity and save its ID in the expense document.
                            DocumentReference
                            newActivityRef = await FirebaseFirestore.instance
                                .collection('activities')
                                .add({
                                  'type': 'expenseUpdated',
                                  'groupId': widget.groupId,
                                  'actorUid':
                                      widget
                                          .expenseDoc['paidBy'], // or use current user UID
                                  'message':
                                      "Expense updated: '$newTitle' of amount ₹$newAmount",
                                  'timestamp': FieldValue.serverTimestamp(),
                                });
                            await widget.expenseDoc.reference.update({
                              'activityId': newActivityRef.id,
                            });
                          }

                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Expense updated successfully!"),
                            ),
                          );
                          setState(() {
                            // Refresh FutureBuilders.
                            paidByNameFuture = fetchPaidByName();
                            splitNamesFuture = fetchSplitNames();
                            _isUpdating = false;
                          });
                        }
                      },
                      child: Text(
                        "Save",
                        style: GoogleFonts.inter(color: dark_blue),
                      ),
                    ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: dark_blue,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          "Expense Details",
          style: GoogleFonts.inter(
            fontSize: size.width * 0.06,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _showEditDialog,
            icon: Icon(Icons.edit, color: Colors.white),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('groups')
                .doc(widget.groupId)
                .collection('expenses')
                .doc(widget.expenseDoc.id)
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          var expenseData = snapshot.data!;
          List<dynamic> splitAmong = expenseData['splitAmong'] ?? [];
          return Padding(
            padding: EdgeInsets.all(size.width * 0.04),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Expense Title
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: "Title: \n",
                          style: GoogleFonts.inter(
                            fontSize: size.width * 0.05,
                            fontWeight: FontWeight.bold,
                            color: dark_blue,
                          ),
                        ),
                        TextSpan(
                          text: "${expenseData['title']}",
                          style: GoogleFonts.inter(
                            fontSize: size.width * 0.047,
                            color: dark_blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: size.height * 0.02),
                  // Expense Amount
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: "Amount: \n",
                          style: GoogleFonts.inter(
                            fontSize: size.width * 0.05,
                            fontWeight: FontWeight.bold,
                            color: dark_blue,
                          ),
                        ),
                        TextSpan(
                          text: "₹${expenseData['amount']}",
                          style: GoogleFonts.inter(
                            fontSize: size.width * 0.047,
                            color: dark_blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: size.height * 0.02),
                  // Paid By Field with FutureBuilder to display username
                  FutureBuilder<String>(
                    future:
                        fetchPaidByName(), // You might modify it to use expenseData['paidBy']
                    builder: (context, snapshot) {
                      String paidByDisplay;
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        paidByDisplay = "Loading...";
                      } else if (snapshot.hasError) {
                        paidByDisplay = expenseData['paidBy'];
                      } else if (snapshot.hasData) {
                        paidByDisplay = snapshot.data!;
                      } else {
                        paidByDisplay = expenseData['paidBy'];
                      }
                      return RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: "Paid By: \n",
                              style: GoogleFonts.inter(
                                fontSize: size.width * 0.05,
                                fontWeight: FontWeight.bold,
                                color: dark_blue,
                              ),
                            ),
                            TextSpan(
                              text: paidByDisplay,
                              style: GoogleFonts.inter(
                                fontSize: size.width * 0.047,
                                color: dark_blue,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  SizedBox(height: size.height * 0.02),
                  // Expense Date
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: "Date: \n",
                          style: GoogleFonts.inter(
                            fontSize: size.width * 0.05,
                            fontWeight: FontWeight.bold,
                            color: dark_blue,
                          ),
                        ),
                        TextSpan(
                          text:
                              "${DateFormat('yyyy-MM-dd HH:mm').format(expenseData['date'].toDate())}",
                          style: GoogleFonts.inter(
                            fontSize: size.width * 0.047,
                            color: dark_blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: size.height * 0.02),
                  // Split Between Field with FutureBuilder to display usernames instead of UIDs
                  FutureBuilder<String>(
                    future:
                        fetchSplitNames(), // Adapted to use updated expenseData if needed
                    builder: (context, snapshot) {
                      String splitDisplay;
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        splitDisplay = "Loading...";
                      } else if (snapshot.hasError) {
                        splitDisplay = splitAmong.join(', ');
                      } else if (snapshot.hasData) {
                        splitDisplay = snapshot.data!;
                      } else {
                        splitDisplay = splitAmong.join(', ');
                      }
                      return RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: "Split Between: \n",
                              style: GoogleFonts.inter(
                                fontSize: size.width * 0.05,
                                fontWeight: FontWeight.bold,
                                color: dark_blue,
                              ),
                            ),
                            TextSpan(
                              text: splitDisplay,
                              style: GoogleFonts.inter(
                                fontSize: size.width * 0.047,
                                color: dark_blue,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  SizedBox(height: size.height * 0.02),
                  // Display an image for visual details
                  Image.asset(
                    "assets/images/expense_detail.jpg",
                    height: size.height * 0.45,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
