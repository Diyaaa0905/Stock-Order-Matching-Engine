import 'package:flutter/material.dart';
import '../services/auth_service.dart';

void showAddBalanceDialog(BuildContext context, AuthService auth) {
  showDialog(
    context: context,
    builder: (ctx) => _AddBalanceDialogContent(auth: auth),
  );
}

class _AddBalanceDialogContent extends StatefulWidget {
  final AuthService auth;
  const _AddBalanceDialogContent({required this.auth});

  @override
  State<_AddBalanceDialogContent> createState() => _AddBalanceDialogContentState();
}

class _AddBalanceDialogContentState extends State<_AddBalanceDialogContent> {
  final TextEditingController _amountController = TextEditingController(text: '5000');
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _handleDeposit() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Please enter a valid amount greater than 0.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final success = await widget.auth.addBalance(amount);
    if (!mounted) return;

    setState(() => _loading = false);

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully added ₹${amount.toStringAsFixed(2)} to your balance!'),
          backgroundColor: const Color(0xFF00C087),
        ),
      );
    } else {
      setState(() => _error = widget.auth.errorMessage ?? 'Deposit failed.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.auth.currentUser;
    final currentBal = user != null ? user.balance : 0.0;

    return Dialog(
      backgroundColor: const Color(0xFF131722),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF2A2E39)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.account_balance_wallet, color: Color(0xFF00C087), size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Add Balance',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF848E9C), size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E222D),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Current Balance:', style: TextStyle(color: Color(0xFF848E9C), fontSize: 13)),
                  Text(
                    '₹${currentBal.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Enter Amount in Rupees (₹)',
              style: TextStyle(color: Color(0xFF848E9C), fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixText: '₹ ',
                prefixStyle: const TextStyle(color: Color(0xFF00C087), fontSize: 20, fontWeight: FontWeight.bold),
                filled: true,
                fillColor: const Color(0xFF1E222D),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2A2E39)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2A2E39)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF00C087)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Quick preset chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [500, 1000, 5000, 10000, 50000].map((amt) {
                return InkWell(
                  onTap: () => setState(() => _amountController.text = amt.toString()),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E222D),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF2A2E39)),
                    ),
                    child: Text(
                      '+₹$amt',
                      style: const TextStyle(color: Color(0xFF00C087), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                );
              }).toList(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Color(0xFFF6465D), fontSize: 12)),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _handleDeposit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C087),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Add Funds Now', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
