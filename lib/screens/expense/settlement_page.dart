import 'dart:convert';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_splitter/helper/color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe hide Card;
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

enum SettlementType { pay, receive }

class SettlementPage extends StatefulWidget {
  final String groupId;
  final SettlementType settlementType;
  final String currentUserId; // The current user's UID

  const SettlementPage({
    Key? key,
    required this.groupId,
    required this.settlementType,
    required this.currentUserId,
  }) : super(key: key);

  @override
  _SettlementPageState createState() => _SettlementPageState();
}

class _SettlementPageState extends State<SettlementPage> {
  // Mapping of UID to display name for group members.
  Map<String, String> memberNames = {};

  // Dummy client secret for demo purposes.
  final String dummyClientSecret =
      "${dotenv.env['DUMMYCLIENTSECRET']}";

  @override
  void initState() {
    super.initState();
    fetchMemberNames();
  }

  /// Fetch all member UIDs from the group document and build a map of UID -> userName.
  Future<void> fetchMemberNames() async {
    try {
      DocumentSnapshot groupSnap =
          await FirebaseFirestore.instance
              .collection('groups')
              .doc(widget.groupId)
              .get();
      if (groupSnap.exists) {
        List<dynamic> memberIds = groupSnap['members'] ?? [];
        Map<String, String> tempMap = {};
        for (String uid in memberIds) {
          DocumentSnapshot userSnap =
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .get();
          if (userSnap.exists) {
            tempMap[uid] = userSnap['userName'] ?? uid;
          }
        }
        setState(() {
          memberNames = tempMap;
        });
      }
    } catch (e) {
      log("Error fetching member names: $e");
    }
  }

  /// Safely converts the raw balance value to a double.
  double getBalance(DocumentSnapshot ledgerDoc) {
    dynamic raw = ledgerDoc['balance'];
    if (raw is int) return raw.toDouble();
    if (raw is double) return raw;
    return 0.0;
  }

  // Filtering for "Have to Pay": show ledger entries where the current user owes money.
  bool includeForPay(DocumentSnapshot ledgerDoc) {
    double balance = getBalance(ledgerDoc);
    if (balance == 0) return false;
    List<String> users = ledgerDoc.id.split("_");
    if (users.length < 2) return false;
    // Only include if the current user is one of the two.
    if (widget.currentUserId != users[0] && widget.currentUserId != users[1])
      return false;
    // If the current user is the first (payer), then a negative balance means they owe money.
    return widget.currentUserId == users[0] ? balance < 0 : balance > 0;
  }

  // Filtering for "Have to Receive" pending: net amount (from current user's perspective) > 0.
  bool includePending(DocumentSnapshot ledgerDoc) {
    double balance = getBalance(ledgerDoc);
    if (balance == 0) return false;
    List<String> users = ledgerDoc.id.split("_");
    if (users.length < 2) return false;

    // ADD THIS CHECK:
    if (widget.currentUserId != users[0] && widget.currentUserId != users[1]) {
      return false;
    }

    double netAmount = widget.currentUserId == users[0] ? balance : -balance;
    return netAmount > 0;
  }

  // Filtering for "Have to Receive" completed: ledger balance equals 0, payment details exist,
  // and the current user is the receiver (i.e. not the one who actually paid).
  bool includeCompleted(DocumentSnapshot ledgerDoc) {
    final data = ledgerDoc.data() as Map<String, dynamic>;
    if (getBalance(ledgerDoc) != 0) return false;
    if (!data.containsKey('paymentMethod')) return false;
    if (data['actualPayer'] == widget.currentUserId) return false;

    List<String> users = ledgerDoc.id.split("_");
    if (users.length < 2) return false;

    // ADD THIS CHECK:
    if (widget.currentUserId != users[0] && widget.currentUserId != users[1]) {
      return false;
    }

    return true;
  }

  /// Returns a display string for pending ledger entries.
  String getDisplayString(DocumentSnapshot ledgerDoc) {
    double balance = getBalance(ledgerDoc);
    List<String> users = ledgerDoc.id.split("_");
    if (users.length < 2) return "Invalid ledger ID";
    String payer = users.first;
    String receiver = users.last;
    double netAmount;
    String otherUserUid;
    if (widget.currentUserId == payer) {
      netAmount = balance;
      otherUserUid = receiver;
    } else {
      netAmount = -balance;
      otherUserUid = payer;
    }
    String otherUserName = memberNames[otherUserUid] ?? "Loading...";
    if (netAmount > 0) {
      return "$otherUserName: ₹${netAmount.toStringAsFixed(2)}";
    } else if (netAmount < 0) {
      return "₹${(-netAmount).toStringAsFixed(2)} to $otherUserName";
    }
    return "Settled up";
  }

  /// Builds a ListTile for completed ledger entries.
  Widget buildCompletedTile(DocumentSnapshot ledgerDoc) {
    final data = ledgerDoc.data() as Map<String, dynamic>;
    // Safely convert paidAmount to double.
    dynamic rawPaidAmount = data['paidAmount'];
    double paidAmount;
    if (rawPaidAmount is int) {
      paidAmount = rawPaidAmount.toDouble();
    } else if (rawPaidAmount is double) {
      paidAmount = rawPaidAmount;
    } else {
      paidAmount = 0.0;
    }
    String paymentMethod = data['paymentMethod'] ?? "cash";
    Timestamp paymentTimestamp = data['paymentTimestamp'] as Timestamp;
    String formattedTime = DateFormat(
      'yyyy-MM-dd HH:mm',
    ).format(paymentTimestamp.toDate());
    // actualPayer is the UID of the user who initiated the payment.
    String actualPayer = data['actualPayer'] ?? ledgerDoc.id.split("_").first;
    String payerName = memberNames[actualPayer] ?? actualPayer;

    return Card(
      color: light_blue,
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(Icons.check_circle, color: dark_blue),
        title: Text(
          "$payerName completed payment of ₹${paidAmount.toStringAsFixed(2)}",
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: dark_blue,
          ),
        ),
        subtitle: Text(
          "on $formattedTime",
          style: GoogleFonts.inter(fontSize: 14, color: dark_blue),
        ),
        trailing: Text(
          paymentMethod,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: dark_blue,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Future<String?> createPaymentIntent(double amount) async {
    try {
      final url = Uri.parse('${dotenv.env['PAYMENTINTENT']}');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount':
              (amount * 100).toInt(), // Stripe uses smallest currency unit
          'currency': 'inr',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['clientSecret'];
      } else {
        log('Failed to create payment intent: ${response.body}');
        return null;
      }
    } catch (e) {
      log('Exception while creating payment intent: $e');
      return null;
    }
  }

  /// Processes an online payment via Stripe.
  Future<void> processOnlinePayment(DocumentSnapshot ledgerDoc) async {
    log("Pay button pressed – starting payment process");
    try {
      final double amount = getBalance(ledgerDoc).abs();
      final String? clientSecret = await createPaymentIntent(amount);

      if (clientSecret == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to initiate payment.")));
        return;
      }

      await stripe.Stripe.instance.initPaymentSheet(
        paymentSheetParameters: stripe.SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Splitzy',
          style: ThemeMode.light,
        ),
      );
      await stripe.Stripe.instance.presentPaymentSheet();
      // On successful payment, update ledger with payment details.
      await ledgerDoc.reference.set({
        'balance': 0,
        'paymentMethod': 'online',
        'paidAmount': getBalance(ledgerDoc).abs(), // assuming full payment
        'paymentTimestamp': FieldValue.serverTimestamp(),
        'actualPayer': widget.currentUserId,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Online payment processed successfully."),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Payment failed: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Processes a cash payment for "Have to Receive" pending.
  Future<void> processCashPayment(DocumentSnapshot ledgerDoc) async {
    await Future.delayed(Duration(seconds: 2));
    // For cash payment, set the actualPayer to the other party (i.e. the one who owes money)
    List<String> users = ledgerDoc.id.split("_");
    String actualPayer =
        widget.currentUserId == users.first ? users.last : users.first;
    await ledgerDoc.reference.set({
      'balance': 0,
      'paymentMethod': 'cash',
      'paidAmount': getBalance(ledgerDoc).abs(),
      'paymentTimestamp': FieldValue.serverTimestamp(),
      'actualPayer': actualPayer,
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Cash payment processed successfully."),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    if (widget.settlementType == SettlementType.pay) {
      // "Have to Pay" view with a "Pay" button.
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          centerTitle: true,
          automaticallyImplyLeading: false,
          title: Text(
            "Have to Pay",
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: size.width * 0.07,
            ),
          ),
          backgroundColor: dark_blue,
        ),
        body: Container(
          padding: EdgeInsets.all(8),
          child:
              memberNames.isEmpty
                  ? Center(child: CircularProgressIndicator())
                  : StreamBuilder<QuerySnapshot>(
                    stream:
                        FirebaseFirestore.instance
                            .collection('groups')
                            .doc(widget.groupId)
                            .collection('balances')
                            .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData) {
                        return Center(
                          child: Text(
                            "No ledger data found.",
                            style: GoogleFonts.inter(
                              color: dark_blue,
                              fontSize: 16,
                            ),
                          ),
                        );
                      }
                      final ledgerDocs =
                          snapshot.data!.docs.where(includeForPay).toList();
                      if (ledgerDocs.isEmpty) {
                        return Center(
                          child: Text(
                            "No pending payments.",
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: dark_blue,
                            ),
                          ),
                        );
                      }
                      return ListView.builder(
                        itemCount: ledgerDocs.length,
                        itemBuilder: (context, index) {
                          DocumentSnapshot ledgerDoc = ledgerDocs[index];
                          return Card(
                            color: light_blue,
                            elevation: 3,
                            margin: EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 4,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: Icon(
                                Icons.account_balance_wallet,
                                color: dark_blue,
                              ),
                              title: Text(
                                getDisplayString(ledgerDoc),
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: dark_blue,
                                ),
                              ),
                              trailing: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: dark_blue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () async {
                                  log("Pay button pressed");
                                  await processOnlinePayment(ledgerDoc);
                                },
                                child: Text(
                                  "Pay",
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
        ),
      );
    } else {
      // "Have to Receive" view: Two tabs – Pending and Completed.
      return DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: dark_blue,
            centerTitle: true,
            automaticallyImplyLeading: false,
            title: Text(
              "Have to Receive",
              style: GoogleFonts.inter(
                fontSize: size.width * 0.07,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            bottom: TabBar(
              labelColor: Colors.white,
              unselectedLabelColor: light_blue,
              tabs: [Tab(text: "Pending"), Tab(text: "Completed")],
            ),
          ),
          body: TabBarView(
            children: [
              // Pending Tab: List pending ledger entries with a "Paid Cash" button.
              StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('groups')
                        .doc(widget.groupId)
                        .collection('balances')
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData) {
                    return Center(
                      child: Text(
                        "No ledger data found.",
                        style: GoogleFonts.inter(
                          color: dark_blue,
                          fontSize: 16,
                        ),
                      ),
                    );
                  }
                  final pendingDocs =
                      snapshot.data!.docs.where(includePending).toList();
                  if (pendingDocs.isEmpty) {
                    return Center(
                      child: Text(
                        "No pending receipts.",
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: dark_blue,
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: pendingDocs.length,
                    itemBuilder: (context, index) {
                      DocumentSnapshot ledgerDoc = pendingDocs[index];
                      return Card(
                        color: light_blue,
                        elevation: 3,
                        margin: EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: Icon(
                            Icons.account_balance_wallet,
                            color: dark_blue,
                          ),
                          title: Text(
                            getDisplayString(ledgerDoc),
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: dark_blue,
                            ),
                          ),
                          trailing: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: dark_blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () async {
                              await processCashPayment(ledgerDoc);
                            },
                            child: Text(
                              "Paid Cash",
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              // Completed Tab: List completed ledger entries with customized layout.
              StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('groups')
                        .doc(widget.groupId)
                        .collection('balances')
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData) {
                    return Center(
                      child: Text(
                        "No ledger data found.",
                        style: GoogleFonts.inter(
                          color: dark_blue,
                          fontSize: 16,
                        ),
                      ),
                    );
                  }
                  final completedDocs =
                      snapshot.data!.docs.where(includeCompleted).toList();
                  if (completedDocs.isEmpty) {
                    return Center(
                      child: Text(
                        "No completed receipts.",
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: dark_blue,
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: completedDocs.length,
                    itemBuilder: (context, index) {
                      DocumentSnapshot ledgerDoc = completedDocs[index];
                      return buildCompletedTile(ledgerDoc);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      );
    }
  }
}
