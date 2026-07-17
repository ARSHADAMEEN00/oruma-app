import 'package:flutter/material.dart';
import 'package:oruma_app/services/auth_service.dart';
import 'package:provider/provider.dart';

class TrialEndedScreen extends StatelessWidget {
  const TrialEndedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final support = auth.accessBlockedSupport ?? const {};
    final supportName = support['name']?.toString();
    final supportPhone = support['phone']?.toString();
    final supportEmail = support['email']?.toString();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 30,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F2),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.lock_clock_outlined,
                        color: Color(0xFFE11D48),
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Trial period is ended',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        height: 1.12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      auth.accessBlockedMessage ??
                          'Trial period is ended. Contact support team to purchase a plan.',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if ([supportName, supportPhone, supportEmail]
                        .where(
                          (value) => value != null && value.trim().isNotEmpty,
                        )
                        .isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Support team',
                              style: TextStyle(
                                color: Color(0xFF334155),
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (supportName != null &&
                                supportName.trim().isNotEmpty)
                              _SupportLine(
                                icon: Icons.person_outline,
                                text: supportName,
                              ),
                            if (supportPhone != null &&
                                supportPhone.trim().isNotEmpty)
                              _SupportLine(
                                icon: Icons.phone_outlined,
                                text: supportPhone,
                              ),
                            if (supportEmail != null &&
                                supportEmail.trim().isNotEmpty)
                              _SupportLine(
                                icon: Icons.email_outlined,
                                text: supportEmail,
                              ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () =>
                            context.read<AuthService>().clearAccessBlocked(),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF1D4ED8),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Back to login'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SupportLine extends StatelessWidget {
  const _SupportLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF64748B), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
