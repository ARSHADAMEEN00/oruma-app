import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:oruma_app/models/billing.dart';
import 'package:oruma_app/services/billing_service.dart';
import 'package:url_launcher/url_launcher.dart';

class BillingPlanScreen extends StatefulWidget {
  const BillingPlanScreen({super.key});

  @override
  State<BillingPlanScreen> createState() => _BillingPlanScreenState();
}

class _BillingPlanScreenState extends State<BillingPlanScreen> {
  final BillingService _billingService = const BillingService();
  final NumberFormat _currency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );
  final DateFormat _date = DateFormat('d MMM yyyy');

  BillingPortal? _portal;
  String? _error;
  bool _loading = true;
  bool _submittingEnquiry = false;

  @override
  void initState() {
    super.initState();
    _loadBilling();
  }

  Future<void> _loadBilling() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await _billingService.fetchBillingPortal();
    if (!mounted) return;

    setState(() {
      _loading = false;
      if (result.isSuccess && result.data != null) {
        _portal = result.data;
      } else {
        _error = result.error ?? 'Unable to load billing details.';
      }
    });
  }

  Future<void> _openPlanPage() async {
    final uri = Uri.parse('http://localhost:5173/plan');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unable to open plan page')));
    }
  }

  Future<void> _showUpgradeSheet(BillingPlan plan) async {
    final portal = _portal;
    if (portal == null) return;

    final controller = TextEditingController(
      text: portal.unit.contactPhone ?? '',
    );
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> submit() async {
              if (!(formKey.currentState?.validate() ?? false)) return;
              setSheetState(() => _submittingEnquiry = true);
              final result = await _billingService.createPlanEnquiry(
                selectedPlanId: plan.id,
                contactNumber: controller.text.trim(),
              );
              setSheetState(() => _submittingEnquiry = false);
              if (!mounted) return;
              Navigator.of(this.context).pop();
              ScaffoldMessenger.of(this.context).showSnackBar(
                SnackBar(
                  content: Text(
                    result.isSuccess
                        ? 'Upgrade enquiry sent to Oruma team.'
                        : result.error ?? 'Failed to send enquiry.',
                  ),
                ),
              );
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 46,
                          height: 5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0E3EA),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'Request ${plan.name}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'We will contact you to confirm pricing, modules, and migration needs.',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: controller,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Contact number',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return 'Contact number is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submittingEnquiry ? null : submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A73E8),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _submittingEnquiry
                                ? 'Sending...'
                                : 'Create enquiry',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        title: const Text('Billing & Plan'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0.4,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null || _portal == null) {
      return _ErrorState(
        message: _error ?? 'Billing details are not available.',
        onRetry: _loadBilling,
      );
    }

    final portal = _portal!;
    return RefreshIndicator(
      onRefresh: _loadBilling,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _CurrentPlanCard(
            portal: portal,
            currency: _money,
            date: _formatDate,
            onOpenPlanPage: _openPlanPage,
          ),
          const SizedBox(height: 14),
          _SummaryGrid(
            summary: portal.summary,
            currency: _money,
            date: _formatDate,
          ),
          const SizedBox(height: 14),
          _PlansSection(
            plans: portal.plans,
            currentPlanId: portal.currentPlan?.id ?? portal.unit.planId,
            currency: _money,
            featureLabel: _featureLabel,
            onUpgrade: _showUpgradeSheet,
          ),
          const SizedBox(height: 14),
          _SubscriptionSection(portal: portal, date: _formatDate),
          const SizedBox(height: 14),
          _PlanDetailsSection(
            plan: portal.currentPlan,
            featureLabel: _featureLabel,
          ),
          const SizedBox(height: 14),
          _MaintenanceSection(
            entries: portal.maintenanceHistory,
            currency: _money,
            date: _formatDate,
          ),
          const SizedBox(height: 14),
          _PaymentSection(
            rows: portal.paymentRows,
            currency: _money,
            date: _formatDate,
          ),
          const SizedBox(height: 14),
          _BillingSummarySection(
            summary: portal.summary,
            currency: _money,
            date: _formatDate,
          ),
        ],
      ),
    );
  }

  String _money(double value) => _currency.format(value);

  String _formatDate(DateTime? value) {
    if (value == null) return '-';
    return _date.format(value.toLocal());
  }
}

class _CurrentPlanCard extends StatelessWidget {
  const _CurrentPlanCard({
    required this.portal,
    required this.currency,
    required this.date,
    required this.onOpenPlanPage,
  });

  final BillingPortal portal;
  final String Function(double value) currency;
  final String Function(DateTime? value) date;
  final VoidCallback onOpenPlanPage;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0FE),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.workspace_premium_outlined,
                  color: Color(0xFF1A73E8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      portal.summary.planName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${portal.unit.name} • ${portal.summary.billingCycle}',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
              _StatusBadge(label: portal.summary.subscriptionStatus),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _SmallInfo(
                  label: 'Next payment',
                  value: currency(portal.summary.upcomingPaymentAmount),
                  helper: date(portal.summary.upcomingPaymentDueDate),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SmallInfo(
                  label: 'Plan page',
                  value: 'More info',
                  helper: 'Pricing and modules',
                  onTap: onOpenPlanPage,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({
    required this.summary,
    required this.currency,
    required this.date,
  });

  final BillingSummary summary;
  final String Function(double value) currency;
  final String Function(DateTime? value) date;

  @override
  Widget build(BuildContext context) {
    final items = [
      _SummaryItem('Plan', summary.planName, summary.billingCycle),
      _SummaryItem(
        'Outstanding',
        currency(summary.outstandingAmount),
        'Balance due',
      ),
      _SummaryItem(
        'Upcoming',
        currency(summary.upcomingPaymentAmount),
        date(summary.upcomingPaymentDueDate),
      ),
      _SummaryItem(
        'Total paid',
        currency(summary.totalPaid),
        'Collected payments',
      ),
    ];

    return GridView.builder(
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 112,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return _SectionCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                item.label.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey.shade600,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.helper,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PlansSection extends StatelessWidget {
  const _PlansSection({
    required this.plans,
    required this.currentPlanId,
    required this.currency,
    required this.featureLabel,
    required this.onUpgrade,
  });

  final List<BillingPlan> plans;
  final String currentPlanId;
  final String Function(double value) currency;
  final String Function(String featureId) featureLabel;
  final ValueChanged<BillingPlan> onUpgrade;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            title: 'Available plans',
            subtitle: 'Compare plan levels and request an upgrade.',
          ),
          const SizedBox(height: 12),
          ...plans.map((plan) {
            final isCurrent = plan.id == currentPlanId;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isCurrent
                    ? const Color(0xFFE8F0FE)
                    : const Color(0xFFF8FAFD),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isCurrent
                      ? const Color(0xFF1A73E8)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          plan.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ),
                      if (isCurrent) const _StatusBadge(label: 'Current'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${currency(plan.price)} / month • ${currency(plan.oneTimePrice)} one-time',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A73E8),
                    ),
                  ),
                  if ((plan.bestFor ?? '').isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      plan.bestFor!,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: plan.featureIds.take(6).map((featureId) {
                      return _FeatureChip(label: featureLabel(featureId));
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: isCurrent ? null : () => onUpgrade(plan),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1A73E8),
                        side: BorderSide(
                          color: isCurrent
                              ? Colors.grey.shade300
                              : const Color(0xFF1A73E8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isCurrent ? 'Current plan' : 'Request upgrade',
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SubscriptionSection extends StatelessWidget {
  const _SubscriptionSection({required this.portal, required this.date});

  final BillingPortal portal;
  final String Function(DateTime? value) date;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            title: 'Subscription',
            subtitle: 'Current subscription terms for this unit.',
          ),
          const SizedBox(height: 12),
          _DetailRow(label: 'Status', value: portal.summary.subscriptionStatus),
          _DetailRow(
            label: 'Billing cycle',
            value: portal.summary.billingCycle,
          ),
          _DetailRow(
            label: 'Start date',
            value: date(
              portal.subscription?.startDate ??
                  portal.unit.subscriptionStartDate,
            ),
          ),
          _DetailRow(
            label: 'Trial end',
            value: date(
              portal.subscription?.trialEndDate ?? portal.unit.trialEndDate,
            ),
          ),
          _DetailRow(
            label: 'Next renewal',
            value: date(
              portal.subscription?.renewalDate ?? portal.unit.renewalDate,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanDetailsSection extends StatelessWidget {
  const _PlanDetailsSection({required this.plan, required this.featureLabel});

  final BillingPlan? plan;
  final String Function(String featureId) featureLabel;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            title: 'Plan details',
            subtitle: plan?.included ?? 'Included features and usage scope.',
          ),
          const SizedBox(height: 12),
          if (plan == null)
            const _EmptyText('No plan details available.')
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: plan!.featureIds.map((featureId) {
                return _FeatureChip(label: featureLabel(featureId));
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _MaintenanceSection extends StatelessWidget {
  const _MaintenanceSection({
    required this.entries,
    required this.currency,
    required this.date,
  });

  final List<MaintenanceHistoryEntry> entries;
  final String Function(double value) currency;
  final String Function(DateTime? value) date;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'Maintenance history',
            subtitle: 'Yearly maintenance and service fee records.',
          ),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            const _EmptyText('No maintenance entries yet.')
          else
            ...entries.take(6).map((entry) {
              return _ListRow(
                title: entry.label,
                subtitle: date(entry.dueDate),
                trailing: currency(entry.amount),
                badge: entry.status,
              );
            }),
        ],
      ),
    );
  }
}

class _PaymentSection extends StatelessWidget {
  const _PaymentSection({
    required this.rows,
    required this.currency,
    required this.date,
  });

  final List<PaymentHistoryRow> rows;
  final String Function(double value) currency;
  final String Function(DateTime? value) date;

  @override
  Widget build(BuildContext context) {
    final openBills = rows
        .where((row) => !row.isPayment && !row.isPaid && row.displayAmount > 0)
        .toList();
    final paymentHistory = rows
        .where((row) => row.isPayment || row.isPaid)
        .toList()
        .reversed
        .toList();

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'Payment details',
            subtitle: 'Open bills and payments recorded for this unit.',
          ),
          const SizedBox(height: 12),
          if (openBills.isEmpty && paymentHistory.isEmpty)
            const _EmptyText('No billing records found.')
          else ...[
            if (openBills.isNotEmpty) ...[
              const _InlineLabel('Open bills'),
              ...openBills.take(4).map((row) {
                return _ListRow(
                  title: row.label,
                  subtitle: _openBillSubtitle(row),
                  trailing: currency(row.displayAmount),
                  badge: row.paidAmount > 0 ? 'partial due' : row.status,
                );
              }),
              const SizedBox(height: 10),
            ],
            const _InlineLabel('Payment history'),
            if (paymentHistory.isEmpty)
              const _EmptyText('No payments recorded yet.')
            else
              ...paymentHistory.take(8).map((row) {
                return _ListRow(
                  title: row.label,
                  subtitle: _historySubtitle(row),
                  trailing: currency(row.amount),
                  badge: row.status,
                );
              }),
          ],
        ],
      ),
    );
  }

  String _openBillSubtitle(PaymentHistoryRow row) {
    final pieces = <String>['invoice'];
    if (row.amount > row.displayAmount) {
      pieces.add('${currency(row.amount)} total');
    }
    if (row.paidAmount > 0) {
      pieces.add('${currency(row.paidAmount)} paid');
    }
    pieces.add('due ${date(row.dueDate)}');
    return pieces.join(' • ');
  }

  String _historySubtitle(PaymentHistoryRow row) {
    final type = row.isPayment ? 'payment' : 'invoice';
    final paidText = row.paidAt != null
        ? 'paid ${date(row.paidAt)}'
        : 'due ${date(row.dueDate)}';
    return '$type • $paidText';
  }
}

class _BillingSummarySection extends StatelessWidget {
  const _BillingSummarySection({
    required this.summary,
    required this.currency,
    required this.date,
  });

  final BillingSummary summary;
  final String Function(double value) currency;
  final String Function(DateTime? value) date;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'Billing summary',
            subtitle:
                'Outstanding balance reduces when invoices are marked paid or manual payments are recorded.',
          ),
          const SizedBox(height: 12),
          _DetailRow(
            label: 'Total invoiced',
            value: currency(summary.totalInvoiced),
          ),
          _DetailRow(label: 'Total paid', value: currency(summary.totalPaid)),
          _DetailRow(
            label: 'Outstanding amount',
            value: currency(summary.outstandingAmount),
          ),
          _DetailRow(
            label: 'Upcoming payment',
            value:
                '${currency(summary.upcomingPaymentAmount)} • ${date(summary.upcomingPaymentDueDate)}',
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            height: 1.35,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}

class _InlineLabel extends StatelessWidget {
  const _InlineLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Colors.grey.shade600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF111827),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ListRow extends StatelessWidget {
  const _ListRow({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.badge,
  });

  final String title;
  final String subtitle;
  final String trailing;
  final String badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                trailing,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 5),
              _StatusBadge(label: badge),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final normal = label.toLowerCase();
    final color =
        normal.contains('paid') ||
            normal.contains('active') ||
            normal.contains('current')
        ? const Color(0xFF188038)
        : normal.contains('trial') ||
              normal.contains('due') ||
              normal.contains('pending')
        ? const Color(0xFFB06000)
        : const Color(0xFF5F6368);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SmallInfo extends StatelessWidget {
  const _SmallInfo({
    required this.label,
    required this.value,
    required this.helper,
    this.onTap,
  });

  final String label;
  final String value;
  final String helper;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFD),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              helper,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0FE),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check, size: 14, color: Color(0xFF1A73E8)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF174EA6),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyText extends StatelessWidget {
  const _EmptyText(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Text(message, style: TextStyle(color: Colors.grey.shade600)),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: Color(0xFF5F6368),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem {
  const _SummaryItem(this.label, this.value, this.helper);

  final String label;
  final String value;
  final String helper;
}

String _featureLabel(String featureId) {
  const labels = {
    'patients': 'Patient management',
    'home_visits': 'Home visits',
    'volunteers': 'Volunteers',
    'social_support': 'Social support',
    'equipment': 'Equipment inventory',
    'equipment_distribution': 'Equipment distribution',
    'patient_pdf': 'Patient PDF reports',
    'nhc_assessment': 'NHC visit assessment',
    'nhc_pdf': 'NHC PDF report',
    'medicine_master': 'Medicine master',
    'medicine_stock': 'Medicine stock entry',
    'medicine_supply': 'Medicine supply',
    'advanced_reports': 'Advanced reports',
    'analytics': 'Analytics dashboard',
    'backup_export': 'Backup & export',
    'whatsapp_sms': 'WhatsApp/SMS reminders',
    'multi_centre': 'Multi-centre mode',
    'custom_forms': 'Custom forms',
  };
  return labels[featureId] ?? featureId.replaceAll('_', ' ');
}
