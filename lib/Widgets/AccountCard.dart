// lib/views/widgets/account_card.dart
import 'package:flutter/material.dart';
import '../Models/AuthenticatorAccountModel.dart';

class AccountCard extends StatelessWidget {
  final AuthenticatorAccount account;
  final VoidCallback onCopy;
  final VoidCallback onMoreOptions;

  const AccountCard({
    super.key,
    required this.account,
    required this.onCopy,
    required this.onMoreOptions,
  });

  @override
  Widget build(BuildContext context) {
    // Generate a consistent random color if not already set
    final avatarColor = account.color ?? Colors.grey[400];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.zero, // Remove default card margin
      child: InkWell(
        // Make the entire card tappable for copying
        onTap: onCopy,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  CircleAvatar(
                    backgroundColor: avatarColor,
                    child: Text(
                      account.initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account.issuer,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          account.username,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // More Options Icon
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: onMoreOptions,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // OTP Code and Timer
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatOtp(account.currentOtp),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        fontFeatures: [
                          FontFeature.tabularFigures(),
                        ], // For monospaced numbers
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Timer Circle
                  SizedBox(
                    width: 30, // Fixed width for the timer circle
                    height: 30,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: account.secondsRemaining / account.period,
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            account.secondsRemaining < 5
                                ? Colors.red
                                : Colors.grey[600]!,
                          ),
                          backgroundColor: Colors.grey[300],
                        ),
                        Text(
                          '${account.secondsRemaining}s',
                          style: TextStyle(
                            fontSize: 10,
                            color: account.secondsRemaining < 5
                                ? Colors.red
                                : Colors.grey[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper to format OTP with spaces (e.g., "123 456")
  String _formatOtp(String otp) {
    if (otp.length == 6) {
      return '${otp.substring(0, 3)} ${otp.substring(3, 6)}';
    } else if (otp.length == 8) {
      return '${otp.substring(0, 4)} ${otp.substring(4, 8)}';
    }
    return otp; // Return as-is if not 6 or 8 digits
  }
}
