import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/core.dart';
import '../../db/doctor_db.dart';
import '../../providers/db_provider.dart';
import '../../services/pdf_service.dart';
import '../../services/whatsapp_service.dart';
import '../../theme/app_theme.dart';
import 'patient_view_screen.dart';

class BillingScreen extends ConsumerStatefulWidget {
  const BillingScreen({super.key});

  @override
  ConsumerState<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends ConsumerState<BillingScreen> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(doctorDbProvider);
    
    return Scaffold(
      body: SafeArea(
        child: dbAsync.when(
          data: (db) => _buildContent(context, db),
          loading: () => const LoadingState(),
          error: (err, stack) => ErrorState.generic(
            message: err.toString(),
            onRetry: () => ref.invalidate(doctorDbProvider),
          ),
        ),
      ),

    );
  }

  Widget _buildContent(BuildContext context, DoctorDatabase db) {
    return Column(
      children: [
        _buildHeader(context),
        FutureBuilder<Map<String, double>>(
          future: db.getInvoiceStats(),
          builder: (context, statsSnapshot) {
            final stats = statsSnapshot.data ?? {
              'totalRevenue': 0.0,
              'pending': 0.0,
              'pendingCount': 0.0,
            };
            return _buildSummaryCards(context, stats);
          },
        ),
        _buildFilterChips(context),
        Expanded(child: _buildInvoiceList(context, db)),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isCompact = AppBreakpoint.isCompact(MediaQuery.of(context).size.width);
    
    return AppHeader(
      title: AppStrings.billing,
      subtitle: 'Manage invoices & payments',
      trailing: Container(
        padding: EdgeInsets.all(isCompact ? AppSpacing.xs : AppSpacing.sm),
        decoration: BoxDecoration(
          color: const Color(0xFF6366F1).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Icon(
          Icons.account_balance_wallet_rounded,
          color: const Color(0xFF6366F1),
          size: isCompact ? AppIconSize.smCompact : AppIconSize.md,
        ),
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context, Map<String, double> stats) {
    final currencyFormat = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 400;
    final padding = isCompact ? 12.0 : 20.0;
    
    return Padding(
      padding: EdgeInsets.all(padding),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _buildSummaryCard(
                context,
                'Total Revenue',
                currencyFormat.format(stats['totalRevenue'] ?? 0),
                Icons.trending_up_rounded,
              AppColors.success,
              'All time',
              useGradient: true,
            ),
          ),
          SizedBox(width: isCompact ? 8 : 12),
          Expanded(
            child: _buildSummaryCard(
              context,
              'Pending',
              currencyFormat.format(stats['pending'] ?? 0),
              Icons.schedule_rounded,
              AppColors.warning,
              '${(stats['pendingCount'] ?? 0).toInt()} invoices',
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle, {
    bool useGradient = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 400;
    
    return Container(
      padding: EdgeInsets.all(isCompact ? 14 : 18),
      decoration: BoxDecoration(
        gradient: useGradient 
            ? LinearGradient(
                colors: [color, color.withValues(alpha: 0.85)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: useGradient ? null : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: useGradient ? null : Border.all(
          color: (isDark ? AppColors.darkDivider : AppColors.divider).withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: useGradient 
                ? color.withValues(alpha: 0.35)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(isCompact ? 8 : 10),
                decoration: BoxDecoration(
                  color: useGradient 
                      ? Colors.white.withValues(alpha: 0.2)
                      : color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon, 
                  color: useGradient ? Colors.white : color, 
                  size: isCompact ? 20 : 22,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: useGradient 
                      ? Colors.white.withValues(alpha: 0.2)
                      : color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  subtitle,
                  style: TextStyle(
                    color: useGradient ? Colors.white : color,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isCompact ? 14 : 18),
          Text(
            title,
            style: TextStyle(
              fontSize: isCompact ? 11 : 12,
              fontWeight: FontWeight.w500,
              color: useGradient 
                  ? Colors.white.withValues(alpha: 0.85)
                  : isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: isCompact ? 16 : 20,
                fontWeight: FontWeight.w800,
                color: useGradient 
                    ? Colors.white 
                    : Theme.of(context).colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    final filters = ['All', 'Paid', 'Pending', 'Overdue'];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((filter) {
            final isSelected = _selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(filter),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() => _selectedFilter = filter);
                },
                backgroundColor: Theme.of(context).colorScheme.surface,
                selectedColor: const Color(0xFF6366F1).withValues(alpha: 0.15),
                checkmarkColor: const Color(0xFF6366F1),
                labelStyle: TextStyle(
                  color: isSelected ? const Color(0xFF6366F1) : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                side: BorderSide(
                  color: isSelected ? const Color(0xFF6366F1) : (isDark ? AppColors.darkDivider : AppColors.divider),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildInvoiceList(BuildContext context, DoctorDatabase db) {
    return FutureBuilder<List<Invoice>>(
      future: db.getAllInvoices(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        var invoices = snapshot.data!;
        
        // Apply filter
        if (_selectedFilter != 'All') {
          invoices = invoices.where((inv) => inv.paymentStatus == _selectedFilter).toList();
        }

        if (invoices.isEmpty) {
          return _buildEmptyState(context);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: invoices.length,
          itemBuilder: (context, index) {
            return _buildInvoiceCard(context, db, invoices[index]);
          },
        );
      },
    );
  }

  Widget _buildInvoiceCard(BuildContext context, DoctorDatabase db, Invoice invoice) {
    Color statusColor;
    IconData statusIcon;
    switch (invoice.paymentStatus) {
      case 'Paid':
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle_rounded;
      case 'Pending':
        statusColor = AppColors.warning;
        statusIcon = Icons.schedule_rounded;
      case 'Overdue':
        statusColor = AppColors.error;
        statusIcon = Icons.error_rounded;
      case 'Partial':
        statusColor = AppColors.info;
        statusIcon = Icons.pie_chart_rounded;
      default:
        statusColor = AppColors.textSecondary;
        statusIcon = Icons.receipt_long_rounded;
    }

    final dateFormat = DateFormat('MMM d, yyyy');
    final currencyFormat = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 400;

    return FutureBuilder<Patient?>(
      future: db.getPatientById(invoice.patientId),
      builder: (context, patientSnapshot) {
        final patient = patientSnapshot.data;
        final patientName = patient != null 
            ? '${patient.firstName} ${patient.lastName}'
            : 'Patient #${invoice.patientId}';

        return Container(
          margin: EdgeInsets.only(bottom: isCompact ? 12 : 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: (isDark ? AppColors.darkDivider : AppColors.divider).withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: AppColors.billing.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showInvoiceDetails(context, db, invoice, patient),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: EdgeInsets.all(isCompact ? 14 : 18),
                child: Row(
                  children: [
                    // Invoice icon with gradient
                    Container(
                      padding: EdgeInsets.all(isCompact ? 12 : 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.billing,
                            AppColors.billing.withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.billing.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.receipt_long_rounded,
                        color: Colors.white,
                        size: isCompact ? 22 : 24,
                      ),
                    ),
                    SizedBox(width: isCompact ? 12 : 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  invoice.invoiceNumber,
                                  style: TextStyle(
                                    fontSize: isCompact ? 13 : 15,
                                    fontWeight: FontWeight.w800,
                                    color: Theme.of(context).colorScheme.onSurface,
                                    letterSpacing: -0.3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      statusColor.withValues(alpha: 0.2),
                                      statusColor.withValues(alpha: 0.1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(statusIcon, size: 12, color: statusColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      invoice.paymentStatus,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: patient != null ? () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute<void>(
                                        builder: (_) => PatientViewScreen(patient: patient),
                                      ),
                                    );
                                  } : null,
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Icon(
                                          Icons.person_rounded,
                                          size: 12,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          patientName,
                                          style: TextStyle(
                                            fontSize: isCompact ? 10 : 11,
                                            fontWeight: FontWeight.w500,
                                            color: patient != null 
                                                ? AppColors.primary 
                                                : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  currencyFormat.format(invoice.grandTotal),
                                  style: TextStyle(
                                    fontSize: isCompact ? 14 : 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.success,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 12,
                                color: isDark ? AppColors.darkTextHint : AppColors.textHint,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                dateFormat.format(invoice.invoiceDate),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? AppColors.darkTextHint : AppColors.textHint,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showInvoiceDetails(BuildContext context, DoctorDatabase db, Invoice invoice, Patient? patient) {
    final dateFormat = DateFormat('MMMM d, yyyy');
    final currencyFormat = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);
    
    List<dynamic> items = [];
    try {
      items = jsonDecode(invoice.itemsJson) as List<dynamic>;
    } catch (_) {}

    Color statusColor;
    switch (invoice.paymentStatus) {
      case 'Paid':
        statusColor = AppColors.success;
      case 'Pending':
        statusColor = AppColors.warning;
      case 'Overdue':
        statusColor = AppColors.error;
      default:
        statusColor = AppColors.info;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Container(
            padding: const EdgeInsets.all(24),
            child: ListView(
              controller: scrollController,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkDivider : AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'INVOICE',
                          style: TextStyle(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          invoice.invoiceNumber,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        invoice.paymentStatus,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Dates
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoColumn('Invoice Date', dateFormat.format(invoice.invoiceDate)),
                    ),
                    if (invoice.dueDate != null)
                      Expanded(
                        child: _buildInfoColumn('Due Date', dateFormat.format(invoice.dueDate!)),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Patient
                if (patient != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBackground : AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.primary,
                          child: Text(
                            patient.firstName[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${patient.firstName} ${patient.lastName}',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              if (patient.phone.isNotEmpty)
                                Text(
                                  patient.phone,
                                  style: TextStyle(
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.open_in_new, size: 20),
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => PatientViewScreen(patient: patient),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
                
                // Items
                Text(
                  'Items',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...items.map((item) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBackground : AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (item as Map<String, dynamic>)['description'] as String? ?? 'Item',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              Text(
                                'Qty: ${item['quantity']} × ${currencyFormat.format((item['rate'] as num?) ?? 0)}',
                                style: TextStyle(
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          currencyFormat.format(item['total'] ?? 0),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  );
                }),
                
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                
                // Totals
                _buildTotalRow('Subtotal', invoice.subtotal, currencyFormat),
                if (invoice.discountAmount > 0)
                  _buildTotalRow('Discount (${invoice.discountPercent}%)', -invoice.discountAmount, currencyFormat, isDiscount: true),
                if (invoice.taxAmount > 0)
                  _buildTotalRow('Tax (${invoice.taxPercent}%)', invoice.taxAmount, currencyFormat),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Grand Total',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      currencyFormat.format(invoice.grandTotal),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          if (patient != null) {
                            final doctorSettings = ref.read(doctorSettingsProvider);
                            final profile = doctorSettings.profile;
                            await PdfService.shareInvoicePdf(
                              patient: patient,
                              invoice: invoice,
                              clinicName: profile.clinicName.isNotEmpty ? profile.clinicName : 'Medical Clinic',
                              clinicPhone: profile.clinicPhone,
                              clinicAddress: profile.clinicAddress,
                              signatureData: (profile.signatureData?.isNotEmpty ?? false) ? profile.signatureData : null,
                              doctorName: profile.displayName.isNotEmpty ? profile.displayName : null,
                            );
                          }
                        },
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('PDF'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          if (patient != null) {
                            final doctorSettings = ref.read(doctorSettingsProvider);
                            final profile = doctorSettings.profile;
                            await WhatsAppService.shareInvoice(
                              patient: patient,
                              invoice: invoice,
                              clinicName: profile.clinicName.isNotEmpty ? profile.clinicName : 'Medical Clinic',
                              clinicPhone: profile.clinicPhone,
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Patient information not available'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.chat, color: Color(0xFF25D366)),
                        label: const Text('WhatsApp'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF25D366),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (invoice.paymentStatus != 'Paid')
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await db.updateInvoice(invoice.copyWith(paymentStatus: 'Paid'));
                            Navigator.pop(context);
                            setState(() {});
                          },
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Mark Paid'),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTotalRow(String label, double amount, NumberFormat format, {bool isDiscount = false}) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
              ),
              Text(
                isDiscount ? '- ${format.format(amount.abs())}' : format.format(amount),
                style: TextStyle(
                  color: isDiscount ? AppColors.error : null,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 56,
                color: Color(0xFF6366F1),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Invoices Yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Invoices will appear here when created from patient details',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),

          ],
        ),
      ),
    );
  }
}
