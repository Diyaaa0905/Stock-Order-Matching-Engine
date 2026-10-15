import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'add_balance_dialog.dart';
import 'account_details_dialog.dart';

void showProfileModal(BuildContext context, AuthService auth) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => _ProfileModalContent(auth: auth),
  );
}

class _ProfileModalContent extends StatelessWidget {
  final AuthService auth;
  const _ProfileModalContent({required this.auth});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: auth,
      builder: (context, _) {
        final user = auth.currentUser;
        final name = user?.fullName.isNotEmpty == true ? user!.fullName : (user?.username ?? 'Trader');
        final initial = name.isNotEmpty ? name[0].toUpperCase() : 'T';
        final balance = user?.balance ?? 0.0;

        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF131722),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: Color(0xFF2A2E39), width: 1.5),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pull indicator handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2E39),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // PFP (Profile Picture) Avatar
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00C087), Color(0xFF007A54)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00C087).withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Name under PFP
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),

              // Email / Username tag
              Text(
                '@${user?.username ?? 'trader'} • ${user?.email ?? ''}',
                style: const TextStyle(
                  color: Color(0xFF848E9C),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),

              // Current Balance Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E222D),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF2A2E39)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Available Cash Balance', style: TextStyle(color: Color(0xFF848E9C), fontSize: 11)),
                        Text('Rupees (INR)', style: TextStyle(color: Color(0xFF5E6673), fontSize: 10)),
                      ],
                    ),
                    Text(
                      '₹${balance.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Color(0xFF00C087),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // 3 Options Required:
              // 1. Add balance (new user starts with 0 rupees)
              _buildOptionTile(
                icon: Icons.add_circle_outline,
                title: 'Add Balance',
                subtitle: 'Deposit funds into your trading account',
                color: const Color(0xFF00C087),
                onTap: () {
                  Navigator.of(context).pop();
                  showAddBalanceDialog(context, auth);
                },
              ),
              const SizedBox(height: 10),

              // 2. Change/view account details
              _buildOptionTile(
                icon: Icons.person_outline,
                title: 'Change / View Account Details',
                subtitle: 'Manage name, email, and encrypted password',
                color: const Color(0xFF2962FF),
                onTap: () {
                  Navigator.of(context).pop();
                  showAccountDetailsDialog(context, auth);
                },
              ),
              const SizedBox(height: 10),

              // 3. Log out
              _buildOptionTile(
                icon: Icons.logout,
                title: 'Log Out',
                subtitle: 'Sign out from this device',
                color: const Color(0xFFF6465D),
                onTap: () {
                  Navigator.of(context).pop();
                  auth.logout();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFF1E222D),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF848E9C),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Color(0xFF848E9C), size: 14),
            ],
          ),
        ),
      ),
    );
  }
}
