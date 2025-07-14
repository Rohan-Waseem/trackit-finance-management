import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Send money to another user
  Future<void> sendMoney(String receiverEmail, int amount) async {
    final sender = _auth.currentUser;

    if (sender == null) throw Exception("User not logged in");

    final senderDoc = await _firestore.collection('users').doc(sender.uid).get();
    final receiverQuery = await _firestore
        .collection('users')
        .where('email', isEqualTo: receiverEmail)
        .get();

    if (!senderDoc.exists) throw Exception("Sender account does not exist");
    if (receiverQuery.docs.isEmpty) throw Exception("Receiver not found");

    final senderBalance = senderDoc.data()!['balance'] ?? 0;
    if (senderBalance < amount) throw Exception("Insufficient balance");

    final receiverDoc = receiverQuery.docs.first;
    final receiverId = receiverDoc.id;

    final batch = _firestore.batch();

    // Update balances
    batch.update(_firestore.collection('users').doc(sender.uid), {
      'balance': senderBalance - amount,
    });

    final receiverBalance = receiverDoc.data()['balance'] ?? 0;
    batch.update(_firestore.collection('users').doc(receiverId), {
      'balance': receiverBalance + amount,
    });

    // Add transaction records
    final now = DateTime.now().toString();
    final senderTxnRef = _firestore
        .collection('users')
        .doc(sender.uid)
        .collection('transactions')
        .doc();
    final receiverTxnRef = _firestore
        .collection('users')
        .doc(receiverId)
        .collection('transactions')
        .doc();

    batch.set(senderTxnRef, {
      'type': 'sent',
      'amount': amount,
      'toFrom': receiverEmail,
      'time': now,
    });

    batch.set(receiverTxnRef, {
      'type': 'received',
      'amount': amount,
      'toFrom': sender.email,
      'time': now,
    });

    await batch.commit();
  }

  // Receive money (used only for mock testing if needed)
  Future<void> receiveMoney(String senderEmail, int amount) async {
    final receiver = _auth.currentUser;
    if (receiver == null) throw Exception("User not logged in");

    final receiverDoc = await _firestore.collection('users').doc(receiver.uid).get();
    if (!receiverDoc.exists) throw Exception("Receiver account not found");

    final balance = receiverDoc.data()!['balance'] ?? 0;

    final newBalance = balance + amount;

    await _firestore.collection('users').doc(receiver.uid).update({
      'balance': newBalance,
    });

    await _firestore
        .collection('users')
        .doc(receiver.uid)
        .collection('transactions')
        .add({
      'type': 'received',
      'amount': amount,
      'toFrom': senderEmail,
      'time': DateTime.now().toString(),
    });
  }

  // Get current user's transaction history
  Future<List<Map<String, dynamic>>> getTransactions() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('transactions')
        .orderBy('time', descending: true)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  // Get current balance
  Future<int> getCurrentBalance() async {
    final user = _auth.currentUser;
    if (user == null) return 0;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    return (doc.data()?['balance'] ?? 0) as int;
  }
}
