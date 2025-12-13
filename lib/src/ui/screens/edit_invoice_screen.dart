import 'dart:convert';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../db/doctor_db.dart';
import '../../providers/db_provider.dart';
import '../../services/suggestions_service.dart';
import '../../theme/app_theme.dart';
import '../widgets/suggestion_text_field.dart';
import '../../core/widgets/keyboard_aware_scaffold.dart';

class EditInvoiceScreen extends ConsumerStatefulWidget {
  const EditInvoiceScreen({
    super.key,
    required this.invoice,
    this.patient,
  });

  final Invoice invoice;
  final Patient? patient;

  @override
  ConsumerState<EditInvoiceScreen> createState() => _EditInvoiceScreenState();
}

class _EditInvoiceScreenState extends ConsumerState<EditInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Invoice Items
  final List<_InvoiceItem> _items = [];

  // Payment Details
  late String _paymentMethod;
  late String _paymentStatus;
  final _discountController = TextEditingController();
  final _taxController = TextEditingController();
  final _notesController = TextEditingController();

  // Invoice Info
  DateTime? _dueDate;

  bool _isSaving = false;

  final List<String> _paymentMethods = ['Cash', 'Card', 'UPI', 'Bank Transfer', 'Insurance', 'Other'];
  final List<String> _paymentStatuses = ['Pending', 'Partial', 'Paid', 'Overdue'];

  @override
  void initState() {
    super.initState();
    _loadInvoiceData();
  }

  Future<void> _loadInvoiceData() async {
    _paymentMethod = widget.invoice.paymentMethod;
    _paymentStatus = widget.invoice.paymentStatus;
    _discountController.text = widget.invoice.discountPercent.toString();
    _taxController.text = widget.invoice.taxPercent.toString();
    _notesController.text = widget.invoice.notes;
    _dueDate = widget.invoice.dueDate;

    // V5: Load items from normalized table first
    final db = await ref.read(doctorDbProvider.future);
    final normalizedItems = await db.getLineItemsForInvoiceCompat(widget.invoice.id);
    
    if (normalizedItems.isNotEmpty) {
      // Use normalized data
      for (final item in normalizedItems) {
        _items.add(_InvoiceItem(
          description: item['description']?.toString() ?? '',
          quantity: (item['quantity'] as num?)?.toInt() ?? 1,
          rate: (item['rate'] as num?)?.toDouble() ?? 0,
          type: item['type']?.toString() ?? 'Service',
        ));
      }
    } else {
      // Fallback: Parse items from JSON
      try {
        final items = jsonDecode(widget.invoice.itemsJson);
        if (items is List) {
          for (final item in items) {
            if (item is Map<String, dynamic>) {
              _items.add(_InvoiceItem(
                description: item['description']?.toString() ?? '',
                quantity: (item['quantity'] as num?)?.toInt() ?? 1,
                rate: (item['rate'] as num?)?.toDouble() ?? 0,
                type: item['type']?.toString() ?? 'Service',
              ));
            }
          }
        }
      } catch (e) {
        // If parsing fails, add one empty item
      }
    }

    if (_items.isEmpty) {
      _items.add(_InvoiceItem());
    }
    
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _discountController.dispose();
    _taxController.dispose();
    _notesController.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  double get _subtotal => _items.fold(0, (sum, item) => sum + (item.rate * item.quantity));
  
  double get _discountAmount {
    final percent = double.tryParse(_discountController.text) ?? 0;
    return _subtotal * (percent / 100);
  }
  
  double get _taxAmount {
    final percent = double.tryParse(_taxController.text) ?? 0;
    return (_subtotal - _discountAmount) * (percent / 100);
  }
  
  double get _grandTotal => _subtotal - _discountAmount + _taxAmount;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 400;
    final padding = isCompact ? 16.0 : 20.0;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF8F9FA),
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            _buildModernSliverAppBar(context, isDark),
            SliverPadding(
              padding: EdgeInsets.all(padding),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Patient Info Card
                  if (widget.patient != null) _buildPatientCard(context, isDark),
                  if (widget.patient != null) const SizedBox(height: 16),

                  // Invoice Items Section
                  _buildModernSectionCard(
                    title: 'Invoice Items',
                    icon: Icons.receipt_long_rounded,
                    iconColor: const Color(0xFF6366F1),
                    isDark: isDark,
                    trailing: _buildAddItemButton(context),
                    child: _buildItemsList(context, isDark),
                  ),
                  const SizedBox(height: 16),

                  // Payment Details Section
                  _buildModernSectionCard(
                    title: 'Payment Details',
                    icon: Icons.payments_rounded,
                    iconColor: const Color(0xFF10B981),
                    isDark: isDark,
                    child: _buildPaymentDetails(context, isDark),
                  ),
                  const SizedBox(height: 16),

                  // Summary Section
                  _buildSummaryCard(context, isDark),
                  const SizedBox(height: 16),

                  // Notes Section
                  _buildModernSectionCard(
                    title: 'Notes',
                    icon: Icons.note_alt_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    isDark: isDark,
                    child: TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Additional notes...',
                        hintStyle: TextStyle(color: isDark ? Colors.grey[600] : Colors.grey[400]),
                        filled: true,
                        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Save Button
                  _buildModernSaveButton(context, isDark),
                  const SizedBox(height: 40),
                ]),
              ),
            ),
            // Keyboard-aware bottom padding
            const SliverKeyboardPadding(),
          ],
        ),
      ),
    );
  }

  Widget _buildModernSliverAppBar(BuildContext context, bool isDark) {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 1,
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.arrow_back_rounded,
              color: isDark ? Colors.white : Colors.black87,
              size: 22,
            ),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF1A1A1A), const Color(0xFF0F0F0F)]
                  : [Colors.white, const Color(0xFFF8F9FA)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.edit_document, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Edit Invoice',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : Colors.black87,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.invoice.invoiceNumber,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPatientCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.patient!.firstName} ${widget.patient!.lastName}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (widget.patient!.phone.isNotEmpty)
                  Text(
                    widget.patient!.phone,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildAddItemButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _items.add(_InvoiceItem());
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF6366F1).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, color: Color(0xFF6366F1), size: 16),
            SizedBox(width: 4),
            Text(
              'Add Item',
              style: TextStyle(
                color: Color(0xFF6366F1),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList(BuildContext context, bool isDark) {
    return Column(
      children: [
        for (int i = 0; i < _items.length; i++)
          _buildItemCard(context, isDark, i),
      ],
    );
  }

  Widget _buildItemCard(BuildContext context, bool isDark, int index) {
    final item = _items[index];
    return Container(
      margin: EdgeInsets.only(bottom: index < _items.length - 1 ? 12 : 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with item number and delete button
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Item ${index + 1}',
                  style: const TextStyle(
                    color: Color(0xFF6366F1),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              // Item type selector
              _buildTypeChip(item, 'Service', isDark),
              const SizedBox(width: 4),
              _buildTypeChip(item, 'Lab', isDark),
              const SizedBox(width: 4),
              _buildTypeChip(item, 'Procedure', isDark),
              const SizedBox(width: 8),
              if (_items.length > 1)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _items[index].dispose();
                      _items.removeAt(index);
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.close_rounded, color: AppColors.error, size: 16),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Description
          SuggestionTextField(
            controller: item.descriptionController,
            label: 'Description',
            hint: 'e.g., Consultation Fee',
            suggestions: BillingSuggestions.serviceTypes,
          ),
          const SizedBox(height: 12),

          // Quantity and Rate row
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: item.quantityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Qty',
                    labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                    filled: true,
                    fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  onChanged: (v) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: item.rateController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Rate (Rs.)',
                    labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                    filled: true,
                    fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  onChanged: (v) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Rs. ${NumberFormat('#,##0').format(item.rate * item.quantity)}',
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(_InvoiceItem item, String type, bool isDark) {
    final isSelected = item.type == type;
    return GestureDetector(
      onTap: () => setState(() => item.type = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6366F1).withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
          ),
        ),
        child: Text(
          type,
          style: TextStyle(
            color: isSelected ? const Color(0xFF6366F1) : (isDark ? Colors.grey : Colors.grey[600]),
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentDetails(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Payment Method
        Text(
          'Payment Method',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _paymentMethods.map((method) {
            final isSelected = _paymentMethod == method;
            return GestureDetector(
              onTap: () => setState(() => _paymentMethod = method),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF10B981).withValues(alpha: 0.15)
                      : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1)),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF10B981) : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  method,
                  style: TextStyle(
                    color: isSelected ? const Color(0xFF10B981) : (isDark ? Colors.grey : Colors.grey[600]),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Payment Status
        Text(
          'Payment Status',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _paymentStatuses.map((status) {
            final isSelected = _paymentStatus == status;
            Color statusColor;
            switch (status) {
              case 'Paid':
                statusColor = AppColors.success;
              case 'Pending':
                statusColor = AppColors.warning;
              case 'Overdue':
                statusColor = AppColors.error;
              case 'Partial':
                statusColor = AppColors.info;
              default:
                statusColor = AppColors.textSecondary;
            }
            return GestureDetector(
              onTap: () => setState(() => _paymentStatus = status),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? statusColor.withValues(alpha: 0.15)
                      : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1)),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? statusColor : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: isSelected ? statusColor : (isDark ? Colors.grey : Colors.grey[600]),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Due Date
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 7)),
              firstDate: DateTime.now().subtract(const Duration(days: 30)),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (picked != null) {
              setState(() => _dueDate = picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Due Date',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      Text(
                        _dueDate != null
                            ? DateFormat('MMM d, yyyy').format(_dueDate!)
                            : 'Not set',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Discount and Tax
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _discountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Discount %',
                  labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                  filled: true,
                  fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _taxController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Tax %',
                  labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                  filled: true,
                  fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context, bool isDark) {
    final currencyFormat = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF10B981), const Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSummaryRow('Subtotal', currencyFormat.format(_subtotal)),
          const SizedBox(height: 8),
          _buildSummaryRow('Discount', '- ${currencyFormat.format(_discountAmount)}'),
          const SizedBox(height: 8),
          _buildSummaryRow('Tax', '+ ${currencyFormat.format(_taxAmount)}'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Colors.white30),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Grand Total',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                currencyFormat.format(_grandTotal),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildModernSaveButton(BuildContext context, bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isSaving ? null : _saveInvoice,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.save_rounded, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Save Changes',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _saveInvoice() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if at least one item has a description
    final hasValidItem = _items.any((item) => item.description.isNotEmpty);
    if (!hasValidItem) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text('Please add at least one item'),
            ],
          ),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final db = await ref.read(doctorDbProvider.future);

      // Build items JSON
      final itemsJson = jsonEncode(
        _items
            .where((item) => item.description.isNotEmpty)
            .map((item) => item.toJson())
            .toList(),
      );

      final discountPercent = double.tryParse(_discountController.text) ?? 0;
      final taxPercent = double.tryParse(_taxController.text) ?? 0;

      final updatedInvoice = InvoicesCompanion(
        id: Value(widget.invoice.id),
        patientId: Value(widget.invoice.patientId),
        invoiceNumber: Value(widget.invoice.invoiceNumber),
        invoiceDate: Value(widget.invoice.invoiceDate),
        dueDate: Value(_dueDate),
        itemsJson: Value(itemsJson),
        subtotal: Value(_subtotal),
        discountPercent: Value(discountPercent),
        discountAmount: Value(_discountAmount),
        taxPercent: Value(taxPercent),
        taxAmount: Value(_taxAmount),
        grandTotal: Value(_grandTotal),
        paymentMethod: Value(_paymentMethod),
        paymentStatus: Value(_paymentStatus),
        notes: Value(_notesController.text),
        appointmentId: Value(widget.invoice.appointmentId),
        prescriptionId: Value(widget.invoice.prescriptionId),
        treatmentSessionId: Value(widget.invoice.treatmentSessionId),
        createdAt: Value(widget.invoice.createdAt),
      );

      await db.updateInvoice(updatedInvoice);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 12),
                Text('Invoice updated successfully'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

// Invoice Item Class
class _InvoiceItem {
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController quantityController = TextEditingController(text: '1');
  final TextEditingController rateController = TextEditingController(text: '0');
  String type;

  _InvoiceItem({
    String description = '',
    int quantity = 1,
    double rate = 0,
    this.type = 'Service',
  }) {
    descriptionController.text = description;
    quantityController.text = quantity.toString();
    rateController.text = rate.toString();
  }

  String get description => descriptionController.text;
  int get quantity => int.tryParse(quantityController.text) ?? 1;
  double get rate => double.tryParse(rateController.text) ?? 0;
  double get total => quantity * rate;

  void dispose() {
    descriptionController.dispose();
    quantityController.dispose();
    rateController.dispose();
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'quantity': quantity,
      'rate': rate,
      'type': type,
    };
  }
}
