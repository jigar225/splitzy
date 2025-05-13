import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_splitter/helper/ledger_helper.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expense_splitter/helper/border.dart';
import 'package:expense_splitter/helper/color.dart';

class AddExpense extends StatefulWidget {
  final String groupId;

  const AddExpense({Key? key, required this.groupId}) : super(key: key);

  @override
  State<AddExpense> createState() => _AddExpenseState();
}

class _AddExpenseState extends State<AddExpense> {
  @override
  void dispose() {
    title.dispose();
    expense.dispose();
    super.dispose();
  }


  String? selectedPayer;
  String? gName;
  List<Map<String, String>> members = [];
  List<String> selectedSplitMembers = [];
  bool selectAll = false;
  TextEditingController title = TextEditingController();
  TextEditingController expense = TextEditingController();

  bool _isLoadingMembers = true;
  bool _isAddingExpense = false;

  @override
  void initState() {
    super.initState();
    fetchGroupMembers();
  }

  Future<void> fetchGroupMembers() async {
    try {
      DocumentSnapshot groupSnapshot =
          await FirebaseFirestore.instance
              .collection('groups')
              .doc(widget.groupId)
              .get();

      if (groupSnapshot.exists) {
        gName = groupSnapshot["name"];
        List<dynamic> userIds = groupSnapshot["members"];
        List<Map<String, String>> fetchedMembers = [];

        for (String userId in userIds) {
          DocumentSnapshot userSnapshot =
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .get();
          if (userSnapshot.exists) {
            fetchedMembers.add({
              'uid': userId,
              'userName': userSnapshot["userName"],
            });
          }
        }

        setState(() {
          members = fetchedMembers;
          _isLoadingMembers = false;
        });
      } else {
        setState(() {
          _isLoadingMembers = false;
        });
      }
    } catch (e) {
      print("Error fetching members: $e");
      setState(() {
        _isLoadingMembers = false;
      });
    }
  }

  void addExpenseToFirestore() async {
    if (title.text.isEmpty ||
        expense.text.isEmpty ||
        selectedPayer == null ||
        selectedSplitMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please fill in all fields."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isAddingExpense = true;
    });

    try {
      final expenseData = {
        'title': title.text,
        'amount': double.parse(expense.text),
        'paidBy': selectedPayer, 
        'splitAmong': selectedSplitMembers,
        'date': Timestamp.now(),
      };

      DocumentReference newExpenseRef = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('expenses')
          .add(expenseData);

      await updateLedger(
        groupId: widget.groupId,
        payer: selectedPayer!,
        splitMembers: selectedSplitMembers,
        expenseAmount: double.parse(expense.text),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Expense added successfully!"),
          backgroundColor: Colors.green,
        ),
      );

      DocumentReference newActivityRef = await FirebaseFirestore.instance
          .collection('activities')
          .add({
            'type': 'expenseAdded',
            'groupId': widget.groupId,
            'actorUid': selectedPayer,
            'message': "₹${expense.text} of ${title.text} added to ${gName}",
            'timestamp': FieldValue.serverTimestamp(),
          });

      await newExpenseRef.update({'activityId': newActivityRef.id});

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error adding expense: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      setState(() {
        _isAddingExpense = false;
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
            "Add Expense",
            style: GoogleFonts.inter(
              fontSize: size.width * 0.07,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(size.width * 0.04),
        child: SingleChildScrollView(
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  "assets/images/expense.png",
                  height: size.height * 0.4,
                ),
               
                Padding(
                  padding: EdgeInsets.symmetric(vertical: size.width * 0.04),
                  child: SizedBox(
                    width: size.width * 0.8,
                    child: TextFormField(
                      controller: title,
                      maxLines: 1,
                      style: GoogleFonts.inter(
                        color: dark_blue,
                        fontSize: size.width * 0.035,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          Icons.note_add_rounded,
                          color: dark_blue,
                          size: size.width * 0.1,
                        ),
                        hintText: "Expense Title",
                        hintStyle: GoogleFonts.inter(
                          color: dark_blue,
                          fontSize: size.width * 0.035,
                          fontWeight: FontWeight.bold,
                        ),
                        filled: true,
                        fillColor: light_blue,
                        focusedBorder: border,
                        enabledBorder: border,
                        errorBorder: border,
                        focusedErrorBorder: border,
                      ),
                    ),
                  ),
                ),
                
                SizedBox(
                  width: size.width * 0.8,
                  child: TextFormField(
                    controller: expense,
                    keyboardType: TextInputType.number,
                    maxLines: 1,
                    style: GoogleFonts.inter(
                      color: dark_blue,
                      fontSize: size.width * 0.035,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.currency_rupee,
                        color: dark_blue,
                        size: size.width * 0.1,
                      ),
                      hintText: "Expense Amount",
                      hintStyle: GoogleFonts.inter(
                        color: dark_blue,
                        fontSize: size.width * 0.035,
                        fontWeight: FontWeight.bold,
                      ),
                      filled: true,
                      fillColor: light_blue,
                      focusedBorder: border,
                      enabledBorder: border,
                      errorBorder: border,
                      focusedErrorBorder: border,
                    ),
                  ),
                ),
                SizedBox(height: size.height * 0.02),
                SizedBox(
                  width: size.width * 0.8,
                  child:
                      _isLoadingMembers
                          ? Center(
                            child: Text(
                              "Loading members...",
                              style: GoogleFonts.inter(
                                color: dark_blue,
                                fontSize: size.width * 0.035,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                          : DropdownButtonFormField<String>(
                            borderRadius: BorderRadius.circular(15),
                            dropdownColor: dark_blue,
                            style: GoogleFonts.inter(color: Colors.white),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: light_blue,
                              focusedBorder: border,
                              enabledBorder: border,
                            ),
                            value: selectedPayer,
                            hint: Text(
                              "Paid By",
                              style: GoogleFonts.inter(
                                fontSize: size.width * 0.035,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            selectedItemBuilder: (BuildContext context) {
                              return members.map<Widget>((member) {
                                return Text(
                                  member['userName']!,
                                  style: GoogleFonts.inter(
                                    fontSize: size.width * 0.045,
                                    fontWeight: FontWeight.bold,
                                    color: dark_blue,
                                  ),
                                );
                              }).toList();
                            },
                            items:
                                members.map((member) {
                                  return DropdownMenuItem<String>(
                                    value: member['uid'], 
                                    child: Text(
                                      member['userName']!,
                                      style: GoogleFonts.inter(
                                        fontSize: size.width * 0.045,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  );
                                }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedPayer = value;
                              });
                            },
                          ),
                ),
                SizedBox(height: size.height * 0.02),
                SizedBox(
                  width: size.width * 0.8,
                  child:
                      _isLoadingMembers
                          ? Center(
                            child: Text(
                              "Loading members...",
                              style: GoogleFonts.inter(
                                color: dark_blue,
                                fontSize: size.width * 0.045,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                          : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Split Among:",
                                style: GoogleFonts.inter(
                                  color: dark_blue,
                                  fontSize: size.width * 0.045,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Wrap(
                                spacing: 8.0,
                                children: [
                                  ChoiceChip(
                                    checkmarkColor: Colors.white,
                                    label: Text(
                                      "Select All",
                                      style: TextStyle(
                                        fontSize: size.width * 0.035,
                                        color:
                                            selectAll
                                                ? Colors.white
                                                : dark_blue,
                                      ),
                                    ),
                                    selected: selectAll,
                                    selectedColor: dark_blue,
                                    backgroundColor: light_blue,
                                    onSelected: (selected) {
                                      setState(() {
                                        selectAll = selected;
                                        selectedSplitMembers =
                                            selected
                                                ? members
                                                    .map(
                                                      (member) =>
                                                          member['uid']!,
                                                    )
                                                    .toList()
                                                : [];
                                      });
                                    },
                                  ),
                                  ...members.map((member) {
                                    bool isSelected = selectedSplitMembers
                                        .contains(member['uid']);
                                    return ChoiceChip(
                                      checkmarkColor: Colors.white,
                                      label: Text(
                                        member['userName']!,
                                        style: TextStyle(
                                          color:
                                              isSelected
                                                  ? Colors.white
                                                  : dark_blue,
                                        ),
                                      ),
                                      selected: isSelected,
                                      selectedColor: dark_blue,
                                      backgroundColor: light_blue,
                                      onSelected: (selected) {
                                        setState(() {
                                          if (selected) {
                                            selectedSplitMembers.add(
                                              member['uid']!,
                                            );
                                          } else {
                                            selectedSplitMembers.remove(
                                              member['uid'],
                                            );
                                          }
                                          selectAll =
                                              selectedSplitMembers.length ==
                                              members.length;
                                        });
                                      },
                                    );
                                  }).toList(),
                                ],
                              ),
                            ],
                          ),
                ),
                SizedBox(height: size.height * 0.04),
                _isAddingExpense
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                      onPressed: () {
                        addExpenseToFirestore();
                        print("Title: ${title.text}");
                        print("Amount: ${expense.text}");
                        print("Paid By (UID): $selectedPayer");
                        print("Split Among (UIDs): $selectedSplitMembers");
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: dark_blue,
                        padding: EdgeInsets.symmetric(
                          vertical: size.height * 0.015,
                          horizontal: size.width * 0.2,
                        ),
                      ),
                      child: Text(
                        "Add Expense",
                        style: GoogleFonts.inter(
                          fontSize: size.width * 0.05,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
