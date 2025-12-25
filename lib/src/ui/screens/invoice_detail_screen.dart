import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../db/doctor_db.dart';
import '../../providers/db_provider.dart';
import '../../services/pdf_service.dart';
import '../../services/whatsapp_service.dart';
import '../../core/components/app_button.dart';
import '../../theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import 'edit_invoice_screen.dart';

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
  List<Map<String, dynamic>> _items = []; // V5: Store loaded items

  @override
  void initState() {
    super.initState();
    _invoice = widget.invoice;
    _patient = widget.patient;
    if (_patient == null) {
      _loadPatient();
    }
    _loadItems(); // V5: Load items on init
  }

  // V5: Load items from normalized table
  Future<void> _loadItems() async {
    final dbAsync = ref.read(doctorDbProvider);
    final db = dbAsync.when(
      data: (db) => db,
      loading: () => null,
      error: (_, __) => null,
    );
    if (db != null) {
      final items = await db.getLineItemsForInvoiceCompat(_invoice.id);
      if (mounted) {
        setState(() => _items = items);
      }
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

    // V5: Use pre-loaded items from normalized table
    final items = _items;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _patient == null
              ? const Center(child: CircularProgressIndicator())
              : CustomScrollView(
              slivers: [
                // Modern SliverAppBar
                SliverAppBar(
                  expandedHeight: 160,
                  floating: false,
                  pinned: true,
                  backgroundColor: surfaceColor,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  leading: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark 
                            ? Colors.white.withValues(alpha: 0.1) 
                            : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: AppIconSize.sm,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  actions: [
                    Container(
                      margin: const EdgeInsets.only(right: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(AppRadius.md),
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
                              ? [const Color(0xFF1A1A2E), Theme.of(context).colorScheme.surface]
                              : [Theme.of(context).scaffoldBackgroundColor, surfaceColor],
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xxxxl, AppSpacing.xl, AppSpacing.xl),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(AppRadius.xl),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.billing.withValues(alpha: 0.4),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.receipt_long_rounded,
                                  color: Colors.white,
                                  size: AppIconSize.xl,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.lg),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _invoice.invoiceNumber,
                                      style: TextStyle(
                                        fontSize: AppFontSize.display,
                                        fontWeight: FontWeight.w800,
                                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                statusColor.withValues(alpha: 0.2),
                                                statusColor.withValues(alpha: 0.1),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(AppRadius.md),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(statusIcon, size: AppIconSize.xs, color: statusColor),
                                              const SizedBox(width: AppSpacing.xs),
                                              Text(
                                                _invoice.paymentStatus,
                                                style: TextStyle(
                                                  fontSize: AppFontSize.sm,
                                                  fontWeight: FontWeight.w700,
                                                  color: statusColor,
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
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    currencyFormat.format(_invoice.grandTotal),
                                    style: TextStyle(
                                      fontSize: AppFontSize.xxxl,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xxs),
                                  Text(
                                    dateFormat.format(_invoice.invoiceDate),
                                    style: TextStyle(
                                      fontSize: AppFontSize.sm,
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
                        gradient: LinearGradient(
                          colors: [
                            AppColors.billing.withValues(alpha: 0.15),
                            AppColors.billing.withValues(alpha: 0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.billing.withValues(alpha: 0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppColors.billing, AppColors.billing.withValues(alpha: 0.8)],
                              ),
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.billing.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Text(
                              _patient!.firstName.isNotEmpty
                                  ? _patient!.firstName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: AppFontSize.xxl,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_patient!.firstName} ${_patient!.lastName}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: textColor,
                                    fontSize: AppFontSize.xl,
                                  ),
                                ),
                                if (_patient!.phone.isNotEmpty)
                                  Text(
                                    _patient!.phone,
                                    style: TextStyle(color: secondaryColor, fontSize: AppFontSize.md),
                                  ),
                              ],
                            ),
                          ),
                          Icon(Icons.person_outline, color: AppColors.billing, size: AppIconSize.md),
                        ],
                      ),
                    ),
                  const SizedBox(height: AppSpacing.lg),

                  // Items List
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          surfaceColor,
                          isDark 
                              ? AppColors.billing.withValues(alpha: 0.05)
                              : AppColors.billing.withValues(alpha: 0.02),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.billing.withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.billing.withValues(alpha: 0.2),
                                      AppColors.billing.withValues(alpha: 0.1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                ),
                                child: Icon(
                                  Icons.receipt_long_rounded,
                                  color: AppColors.billing,
                                  size: AppIconSize.sm,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Text(
                                'Items',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: textColor,
                                  fontSize: AppFontSize.xl,
                                ),
                              ),
                            ],
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
                                  fontSize: AppFontSize.xl,
                                ),
                              ),
                              Text(
                                currencyFormat.format(_invoice.grandTotal),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                  fontSize: AppFontSize.xxl,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Payment Info
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          statusColor.withValues(alpha: 0.15),
                          statusColor.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withValues(alpha: 0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    statusColor.withValues(alpha: 0.2),
                                    statusColor.withValues(alpha: 0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                              child: Icon(
                                statusIcon,
                                color: statusColor,
                                size: AppIconSize.sm,
                              ),
                            ),
                              const SizedBox(width: AppSpacing.md),
                            Text(
                              'Payment Details',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: textColor,
                                fontSize: AppFontSize.xl,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _buildInfoRow('Payment Method', _invoice.paymentMethod, isDark),
                        if (_invoice.dueDate != null)
                          _buildInfoRow('Due Date', dateFormat.format(_invoice.dueDate!), isDark),
                        if (_invoice.notes.isNotEmpty)
                          _buildInfoRow('Notes', _invoice.notes, isDark),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

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
                      const SizedBox(height: AppSpacing.md),
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
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(color: secondaryColor, fontSize: AppFontSize.md)),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: textColor, fontSize: AppFontSize.md)),
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
        _editInvoice();
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
      final db = await ref.read(doctorDbProvider.future);
      final lineItems = await db.getLineItemsForInvoiceCompat(_invoice.id);
      
      final doctorSettings = ref.read(doctorSettingsProvider);
      final profile = doctorSettings.profile;

      await PdfService.shareInvoicePdf(
        patient: _patient!,
        invoice: _invoice,
        clinicName: profile.clinicName.isNotEmpty ? profile.clinicName : 'Medical Clinic',
        clinicPhone: profile.clinicPhone,
        clinicAddress: profile.clinicAddress,
        signatureData: (profile.signatureData?.isNotEmpty ?? false) ? profile.signatureData : null,
        doctorName: profile.displayName.isNotEmpty ? profile.displayName : null,
        lineItemsList: lineItems,
        templateConfig: profile.pdfTemplateConfig,
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

  Future<void> _editInvoice() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditInvoiceScreen(
          invoice: _invoice,
          patient: _patient,
        ),
      ),
    );

    if (result == true && mounted) {
      // Reload the invoice data
      final db = ref.read(doctorDbProvider).valueOrNull;
      if (db != null) {
        final updatedInvoice = await db.getInvoiceById(_invoice.id);
        if (updatedInvoice != null) {
          setState(() {
            _invoice = updatedInvoice;
          });
        } else {
          // Invoice was deleted
          Navigator.pop(context, true);
        }
      }
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: AppColors.error),
            SizedBox(width: AppSpacing.sm),
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


