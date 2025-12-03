import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../db/doctor_db.dart';
import '../../providers/db_provider.dart';
import '../../services/doctor_settings_service.dart';
import '../../services/pdf_service.dart';
import '../../services/whatsapp_service.dart';
import '../../core/components/app_button.dart';
import '../../theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';

class InvoiceDetailScreen extends ConsumerStatefulWidget {
  const InvoiceDetailScreen({
    required this.invoice,
    this.patient,
    super.key,
  });

  final Invoice invoice;
  final Patient? patient;

  @override
  ConsumerState<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends ConsumerState<InvoiceDetailScreen> {
  late Invoice _invoice;
  Patient? _patient;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _invoice = widget.invoice;
    _patient = widget.patient;
    if (_patient == null) {
      _loadPatient();
    }
  }

  Future<void> _loadPatient() async {
    final dbAsync = ref.read(doctorDbProvider);
    final db = dbAsync.when(
      data: (db) => db,
      loading: () => null,
      error: (_, __) => null,
    );
    if (db != null) {
      final patient = await db.getPatientById(_invoice.patientId);
      if (mounted) {
        setState(() => _patient = patient);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormat = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);
    final dateFormat = DateFormat('MMMM d, yyyy');
    
    final surfaceColor = isDark ? AppColors.darkSurface : Colors.white;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final secondaryColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final borderColor = isDark ? AppColors.darkDivider : AppColors.divider;
    
    Color statusColor;
    IconData statusIcon;
    switch (_invoice.paymentStatus.toLowerCase()) {
      case 'paid':
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'pending':
        statusColor = AppColors.warning;
        statusIcon = Icons.pending_rounded;
        break;
      case 'overdue':
        statusColor = AppColors.error;
        statusIcon = Icons.error_rounded;
        break;
      case 'partial':
        statusColor = AppColors.info;
        statusIcon = Icons.timelapse_rounded;
        break;
      default:
        statusColor = AppColors.textSecondary;
        statusIcon = Icons.receipt_rounded;
    }

    // Parse items
    List<Map<String, dynamic>> items = [];
    try {
      items = (jsonDecode(_invoice.itemsJson) as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();
    } catch (e) {
      // Handle parsing error
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // Modern SliverAppBar
                SliverAppBar(
                  expandedHeight: 140,
                  floating: false,
                  pinned: true,
                  backgroundColor: surfaceColor,
                  foregroundColor: textColor,
                  elevation: 0,
                  scrolledUnderElevation: 1,
                  leading: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_back,
                          color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  actions: [
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert,
                          color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                        ),
                        onSelected: (value) => _handleMenuAction(value),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'pdf',
                            child: ListTile(
                              leading: Icon(Icons.picture_as_pdf),
                              title: Text('Export PDF'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'whatsapp',
                            child: ListTile(
                              leading: Icon(Icons.chat, color: Color(0xFF25D366)),
                              title: Text('Share via WhatsApp'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem(
                            value: 'edit',
                            child: ListTile(
                              leading: Icon(Icons.edit),
                              title: Text('Edit Invoice'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: ListTile(
                              leading: Icon(Icons.delete, color: AppColors.error),
                              title: Text('Delete', style: TextStyle(color: AppColors.error)),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                              : [const Color(0xFFF8FAFC), surfaceColor],
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [statusColor, statusColor.withValues(alpha: 0.8)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: statusColor.withValues(alpha: 0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Icon(statusIcon, color: Colors.white, size: 28),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _invoice.invoiceNumber,
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        _invoice.paymentStatus.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: statusColor,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    currencyFormat.format(_invoice.grandTotal),
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    dateFormat.format(_invoice.invoiceDate),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: secondaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Body Content
                SliverPadding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                  // Patient Info Card
                  if (_patient != null)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                            child: Text(
                              _patient!.firstName.isNotEmpty
                                  ? _patient!.firstName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_patient!.firstName} ${_patient!.lastName}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                                if (_patient!.phone.isNotEmpty)
                                  Text(
                                    _patient!.phone,
                                    style: TextStyle(color: secondaryColor, fontSize: 13),
                                  ),
                              ],
                            ),
                          ),
                          const Icon(Icons.person_outline, color: AppColors.primary),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Items List
                  Container(
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Text(
                            'Items',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: textColor,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const Divider(height: 1),
                        ...items.map((item) => _buildItemRow(
                          item['description'] as String? ?? 'Item',
                          item['quantity'] as num? ?? 1,
                          (item['unitPrice'] as num?)?.toDouble() ?? 0,
                          (item['total'] as num?)?.toDouble() ?? 0,
                          isDark,
                        )),
                        const Divider(height: 1),
                        // Subtotal
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Subtotal', style: TextStyle(color: secondaryColor)),
                              Text(
                                currencyFormat.format(_invoice.subtotal),
                                style: TextStyle(color: textColor),
                              ),
                            ],
                          ),
                        ),
                        // Discount
                        if (_invoice.discountAmount > 0)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Discount (${_invoice.discountPercent.toStringAsFixed(0)}%)',
                                  style: TextStyle(color: AppColors.success),
                                ),
                                Text(
                                  '-${currencyFormat.format(_invoice.discountAmount)}',
                                  style: const TextStyle(color: AppColors.success),
                                ),
                              ],
                            ),
                          ),
                        // Tax
                        if (_invoice.taxAmount > 0)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Tax (${_invoice.taxPercent.toStringAsFixed(0)}%)',
                                  style: TextStyle(color: secondaryColor),
                                ),
                                Text(
                                  currencyFormat.format(_invoice.taxAmount),
                                  style: TextStyle(color: textColor),
                                ),
                              ],
                            ),
                          ),
                        const Divider(height: 1),
                        // Grand Total
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Grand Total',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                currencyFormat.format(_invoice.grandTotal),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Payment Info
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment Details',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: textColor,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow('Payment Method', _invoice.paymentMethod, isDark),
                        if (_invoice.dueDate != null)
                          _buildInfoRow('Due Date', dateFormat.format(_invoice.dueDate!), isDark),
                        if (_invoice.notes.isNotEmpty)
                          _buildInfoRow('Notes', _invoice.notes, isDark),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                      // Action Buttons
                      if (_invoice.paymentStatus.toLowerCase() != 'paid')
                        AppButton(
                          label: 'Mark as Paid',
                          icon: Icons.check_circle,
                          fullWidth: true,
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          onPressed: _markAsPaid,
                        ),
                      const SizedBox(height: 12),
                      AppButton.tertiary(
                        label: 'Export PDF',
                        icon: Icons.picture_as_pdf,
                        fullWidth: true,
                        onPressed: () => _handleMenuAction('pdf'),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildItemRow(String description, num quantity, double unitPrice, double total, bool isDark) {
    final currencyFormat = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final secondaryColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(description, style: TextStyle(color: textColor)),
                Text(
                  '${quantity.toInt()} × ${currencyFormat.format(unitPrice)}',
                  style: TextStyle(color: secondaryColor, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            currencyFormat.format(total),
            style: TextStyle(fontWeight: FontWeight.w500, color: textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final secondaryColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(color: secondaryColor)),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: textColor)),
          ),
        ],
      ),
    );
  }

  Future<void> _markAsPaid() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Paid'),
        content: const Text('Are you sure you want to mark this invoice as paid?'),
        actions: [
          AppButton.tertiary(
            label: 'Cancel',
            onPressed: () => Navigator.pop(context, false),
          ),
          AppButton(
            label: 'Mark as Paid',
            onPressed: () => Navigator.pop(context, true),
            backgroundColor: AppColors.success,
            foregroundColor: Colors.white,
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final dbAsync = ref.read(doctorDbProvider);
      final db = dbAsync.when(
        data: (db) => db,
        loading: () => throw Exception('Database loading'),
        error: (e, _) => throw e,
      );

      // Create updated invoice with Paid status
      final updatedInvoice = Invoice(
        id: _invoice.id,
        patientId: _invoice.patientId,
        invoiceNumber: _invoice.invoiceNumber,
        invoiceDate: _invoice.invoiceDate,
        dueDate: _invoice.dueDate,
        itemsJson: _invoice.itemsJson,
        subtotal: _invoice.subtotal,
        discountPercent: _invoice.discountPercent,
        discountAmount: _invoice.discountAmount,
        taxPercent: _invoice.taxPercent,
        taxAmount: _invoice.taxAmount,
        grandTotal: _invoice.grandTotal,
        paymentMethod: _invoice.paymentMethod,
        paymentStatus: 'Paid',
        notes: _invoice.notes,
        createdAt: _invoice.createdAt,
      );

      await db.updateInvoice(updatedInvoice);

      if (mounted) {
        setState(() {
          _invoice = updatedInvoice;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invoice marked as paid'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'pdf':
        _exportPdf();
        break;
      case 'whatsapp':
        _shareWhatsApp();
        break;
      case 'edit':
        _showNotImplemented('Edit invoice');
        break;
      case 'delete':
        _confirmDelete();
        break;
    }
  }

  Future<void> _exportPdf() async {
    if (_patient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Patient information not available'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final doctorSettings = ref.read(doctorSettingsProvider);
      final profile = doctorSettings.profile;

      await PdfService.shareInvoicePdf(
        patient: _patient!,
        invoice: _invoice,
        clinicName: profile.clinicName.isNotEmpty ? profile.clinicName : 'Medical Clinic',
        clinicPhone: profile.clinicPhone,
        clinicAddress: profile.clinicAddress,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _shareWhatsApp() async {
    if (_patient == null || _patient!.phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Patient phone number not available'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final doctorSettings = ref.read(doctorSettingsProvider);
      final profile = doctorSettings.profile;

      await WhatsAppService.shareInvoice(
        patient: _patient!,
        invoice: _invoice,
        clinicName: profile.clinicName.isNotEmpty ? profile.clinicName : 'Medical Clinic',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showNotImplemented(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: AppColors.error),
            SizedBox(width: 8),
            Text('Delete Invoice'),
          ],
        ),
        content: Text('Are you sure you want to delete invoice ${_invoice.invoiceNumber}? This action cannot be undone.'),
        actions: [
          AppButton.tertiary(
            label: 'Cancel',
            onPressed: () => Navigator.pop(context, false),
          ),
          AppButton.danger(
            label: 'Delete',
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final dbAsync = ref.read(doctorDbProvider);
      final db = dbAsync.when(
        data: (db) => db,
        loading: () => throw Exception('Database loading'),
        error: (e, _) => throw e,
      );

      await db.deleteInvoice(_invoice.id);

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate deletion
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invoice deleted'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting invoice: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}


