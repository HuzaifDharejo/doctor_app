// Patient View - Billing Tab
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../db/doctor_db.dart';
import '../../../providers/db_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../core/theme/design_tokens.dart';
import '../add_invoice_screen.dart';
import '../invoice_detail_screen.dart';
import 'patient_view_widgets.dart';

class PatientBillingTab extends ConsumerWidget {
  const PatientBillingTab({
    super.key,
    required this.patient,
  });

  final Patient patient;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbAsync = ref.watch(doctorDbProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return dbAsync.when(
      data: (db) => FutureBuilder<List<Invoice>>(
        future: db.getInvoicesForPatient(patient.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final invoices = snapshot.data ?? [];

          if (invoices.isEmpty) {
            return PatientTabEmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No Invoices',
              subtitle: 'Create an invoice for this patient',
              actionLabel: 'Create Invoice',
              onAction: () => _navigateToAddInvoice(context),
            );
          }

          invoices.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: invoices.length,
            itemBuilder: (context, index) => _InvoiceCard(
              invoice: invoices[index],
              patient: patient,
              isDark: isDark,
            ),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (err, stack) => PatientTabEmptyState(
        icon: Icons.error_outline,
        title: 'Error Loading Invoices',
        subtitle: 'Please try again later',
      ),
    );
  }

  void _navigateToAddInvoice(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddInvoiceScreen(patientId: patient.id),
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  const _InvoiceCard({
    required this.invoice,
    required this.patient,
    required this.isDark,
  });

  final Invoice invoice;
  final Patient patient;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final currencyFormat = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    
    final isPaid = invoice.paymentStatus.toLowerCase() == 'paid';
    final statusColor = isPaid ? AppColors.success : AppColors.warning;

    return PatientItemCard(
      icon: Icons.receipt,
      iconColor: AppColors.billing,
      title: 'Invoice #${invoice.invoiceNumber}',
      subtitle: dateFormat.format(invoice.createdAt),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => InvoiceDetailScreen(
            invoice: invoice,
            patient: patient,
          ),
        ),
      ),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            currencyFormat.format(invoice.grandTotal),
            style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
          ),
          const SizedBox(height: 4),
          StatusBadge(
            label: invoice.paymentStatus,
            color: statusColor,
          ),
        ],
      ),
    );
  }
}
