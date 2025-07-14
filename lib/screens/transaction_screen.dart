import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/transaction_service.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _receiverEmailController = TextEditingController();

  List<Map<String, dynamic>> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final transactionService = TransactionService();
    final txns = await transactionService.getTransactions();

    setState(() {
      _transactions = txns;
    });
  }

  void _sendMoney() async {
    final amount = int.tryParse(_amountController.text.trim());
    final email = _receiverEmailController.text.trim();

    if (amount == null || email.isEmpty) return;

    try {
      final transactionService = TransactionService();
      await transactionService.sendMoney(email, amount);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Transaction successful')),
      );
      await _loadTransactions(); // Refresh after sending
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ ${e.toString()}')),
      );
    }

    _amountController.clear();
    _receiverEmailController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12121C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Transactions",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: [Color(0xFF5D3FD3), Color(0xFF8E44AD)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Send Money',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _inputField(_receiverEmailController, 'Recipient Email'),
                  const SizedBox(height: 14),
                  _inputField(_amountController, 'Amount (Rs.)', isNumeric: true),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _sendMoney,
                      icon: const Icon(Icons.send),
                      label: const Text("Transfer"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              "Recent Transactions",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _transactions.length,
              itemBuilder: (context, index) {
                final txn = _transactions[index];
                final isSent = txn['type'] == 'sent';
                final color = isSent ? Colors.redAccent : Colors.greenAccent;
                final icon = isSent ? Icons.call_made : Icons.call_received;

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: const Color(0xFF1F1F2E),
                    boxShadow: const [
                      BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 3)),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: color.withOpacity(0.2),
                        child: Icon(icon, color: color),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${txn['type'] == 'sent' ? 'To' : 'From'} ${txn['toFrom']}',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              txn['time'],
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'Rs. ${txn['amount']}',
                        style: GoogleFonts.poppins(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputField(TextEditingController controller, String hint, {bool isNumeric = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
