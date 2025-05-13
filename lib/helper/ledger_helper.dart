import 'package:cloud_firestore/cloud_firestore.dart';

String getBalanceDocId(String user1, String user2) {
  List<String> users = [user1, user2];
  users.sort();
  return users.join("_");
}

Future<void> updateLedger({
  required String groupId,
  required String payer,
  required List<String> splitMembers,
  required double expenseAmount,
}) async {
  int totalParticipants = splitMembers.length;
  if (totalParticipants == 0) return;

  double share = expenseAmount / totalParticipants;

  for (String member in splitMembers) {
    if (member == payer) continue;

    String docId = getBalanceDocId(payer, member);
    DocumentReference ledgerDoc = FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .collection('balances')
        .doc(docId);

    DocumentSnapshot ledgerSnap = await ledgerDoc.get();
    double currentBalance = 0.0;
    if (ledgerSnap.exists) {
      currentBalance = (ledgerSnap['balance'] as num).toDouble();
    }

    double newBalance;
    List<String> orderedUsers = docId.split("_");
    if (orderedUsers.first == payer) {
      // Positive balance means the second user owes the payer.
      newBalance = currentBalance + share;
    } else {
      // Otherwise, subtract the share.
      newBalance = currentBalance - share;
    }

    await ledgerDoc.set({'balance': newBalance});
  }
}

Future<void> updateLedgerForEditedExpense({
  required String groupId,
  required String payer,
  required List<String> splitMembers,
  required double oldExpenseAmount,
  required double newExpenseAmount,
}) async {
  double delta = newExpenseAmount - oldExpenseAmount;
  int totalParticipants = splitMembers.length;
  if (totalParticipants == 0) return;

  double shareDelta = delta / totalParticipants;

  for (String member in splitMembers) {
    if (member == payer) continue;

    String docId = getBalanceDocId(payer, member);
    DocumentReference ledgerDoc = FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .collection('balances')
        .doc(docId);

    DocumentSnapshot ledgerSnap = await ledgerDoc.get();
    double currentBalance = ledgerSnap.exists ? (ledgerSnap['balance'] as num).toDouble() : 0.0;

    double newBalance;
    List<String> orderedUsers = docId.split("_");
    if (orderedUsers.first == payer) {
      newBalance = currentBalance + shareDelta;
    } else {
      newBalance = currentBalance - shareDelta;
    }

    await ledgerDoc.set({'balance': newBalance});
  }
}