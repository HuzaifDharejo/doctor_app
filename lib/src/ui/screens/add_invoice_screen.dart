import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../db/doctor_db.dart';
import '../../providers/db_provider.dart';
import '../../services/suggestions_service.dart';
import '../../core/components/app_input.dart';
import '../../core/widgets/app_card.dart';
import '../../core/components/app_button.dart';
import '../../core/theme/design_tokens.dart';
import '../widgets/suggestion_text_field.dart';
import '../../core/widgets/keyboard_aware_scaffold.dart';
import '../../core/extensions/context_extensions.dart';
import '../../theme/app_theme.dart';

class AddInvoiceScreen extends ConsumerStatefulWidget {

  const AddInvoiceScreen({
    super.key,
    this.patientId,
    this.patientName,
    this.preselectedPatient,
    this.encounterId,
    this.appointmentId,
    this.prescriptionId,
    this.diagnosis,
  });
  final int? patientId;
  final String? patientName;
  /// Pre-selected patient from workflow
  final Patient? preselectedPatient;
  /// Associated encounter ID from workflow
  final int? encounterId;
  /// Associated appointment ID from workflow
  final int? appointmentId;
  /// Associated prescription ID from workflow
  final int? prescriptionId;
  /// Diagnosis for invoice notes
  final String? diagnosis;

  @override
  ConsumerState<AddInvoiceScreen> createState() => _AddInvoiceScreenState();
}

class _AddInvoiceScreenState extends ConsumerState<AddInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Patient Selection
  int? _selectedPatientId;
  Patient? _selectedPatient;
  List<Patient> _patients = [];
  final _searchController = TextEditingController();

  // Invoice Items
  final List<InvoiceItem> _items = [];

  // Payment Details
  String _paymentMethod = 'Cash';
  String _paymentStatus = 'Pending';
  double _discountPercent = 0;
  final _discountController = TextEditingController(text: '0');
  final _taxController = TextEditingController(text: '0');
  final _notesController = TextEditingController();

  // Invoice Info
  late String _invoiceNumber;
  final DateTime _invoiceDate = DateTime.now();
  DateTime? _dueDate;

  // Common Services for quick add - using BillingSuggestions
  List<Map<String, dynamic>> get _commonServices => BillingSuggestions.serviceTypes.take(10).map((service) {
    // Assign default prices based on service type
    double price = 500;
    String type = 'Service';
    
    if (service.contains('Consultation')) {
      price = service.contains('Emergency') ? 5000.0 : service.contains('Follow') ? 2000.0 : 3000.0;
      type = 'Service';
    } else if (service.contains('Lab') || service.contains('Blood')) {
      price = 800.0;
      type = 'Lab';
    } else if (service.contains('X-Ray') || service.contains('ECG')) {
      price = 1200.0;
      type = 'Procedure';
    } else if (service.contains('Injection') || service.contains('Dressing') || service.contains('IV')) {
      price = 300.0;
      type = 'Procedure';
    }
    
    return {'name': service, 'amount': price, 'type': type};
  }).toList();

  @override
  void initState() {
    super.initState();
    _invoiceNumber = _generateInvoiceNumber();
    if (widget.patientId != null) {
      _selectedPatientId = widget.patientId;
    } else if (widget.preselectedPatient != null) {
      _selectedPatientId = widget.preselectedPatient?.id;
      _selectedPatient = widget.preselectedPatient;
    }
    // Pre-fill notes with diagnosis if provided
    if (widget.diagnosis != null && widget.diagnosis!.isNotEmpty) {
      _notesController.text = 'Diagnosis: ${widget.diagnosis}';
    }
    _dueDate = DateTime.now().add(const Duration(days: 7));
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    final db = await ref.read(doctorDbProvider.future);
    final patients = await db.getAllPatients();
    setState(() {
      _patients = patients;
      if (_selectedPatientId != null) {
        _selectedPatient = _patients.where((p) => p.id == _selectedPatientId).firstOrNull;
      }
    });
  }

  String _getPatientName(Patient patient) {
    return '${patient.firstName} ${patient.lastName}'.trim();
  }

  String _generateInvoiceNumber() {
    final now = DateTime.now();
    return 'INV-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecond}';
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _discountController.dispose();
    _taxController.dispose();
    _notesController.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  double get _subtotal {
    return _items.fold<double>(0, (sum, item) => sum + item.total);
  }

  double get _discountAmount {
    return _subtotal * (_discountPercent / 100);
  }

  double get _taxAmount {
    final taxPercent = double.tryParse(_taxController.text) ?? 0;
    return (_subtotal - _discountAmount) * (taxPercent / 100);
  }

  double get _grandTotal {
    return _subtotal - _discountAmount + _taxAmount;
  }

  void _addItem() {
    setState(() {
      _items.add(InvoiceItem());
    });
  }

  void _addQuickService(Map<String, dynamic> service) {
    setState(() {
      final item = InvoiceItem();
      item.descriptionController.text = service['name'] as String;
      item.amountController.text = (service['amount'] as num).toString();
      item.type = service['type'] as String;
      _items.add(item);
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items[index].dispose();
      _items.removeAt(index);
    });
  }

  Future<void> _saveInvoice() async {
    if (_selectedPatientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 12),
              Text('Please select a patient'),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 12),
              Text('Please add at least one item'),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      try {
        final db = await ref.read(doctorDbProvider.future);
        
        // V5: itemsJson is deprecated - use InvoiceLineItems table instead
        final itemsJson = '[]'; // Empty JSON - data is in normalized table
        
        // Create invoice companion with linked data
        final invoiceCompanion = InvoicesCompanion.insert(
          patientId: _selectedPatientId!,
          invoiceNumber: _invoiceNumber,
          invoiceDate: _invoiceDate,
          dueDate: Value(_dueDate),
          itemsJson: itemsJson, // V5: Empty - using normalized table
          subtotal: Value(_subtotal),
          discountPercent: Value(_discountPercent),
          discountAmount: Value(_discountAmount),
          taxPercent: Value(double.tryParse(_taxController.text) ?? 0),
          taxAmount: Value(_taxAmount),
          grandTotal: Value(_grandTotal),
          paymentMethod: Value(_paymentMethod),
          paymentStatus: Value(_paymentStatus),
          notes: Value(_notesController.text.isNotEmpty ? _notesController.text : ''),
          appointmentId: Value(widget.appointmentId),
          prescriptionId: Value(widget.prescriptionId),
        );
        
        final invoiceId = await db.insertInvoice(invoiceCompanion);
        
        // V5: Save line items to normalized InvoiceLineItems table
        for (int i = 0; i < _items.length; i++) {
          final item = _items[i];
          await db.insertInvoiceLineItem(
            InvoiceLineItemsCompanion.insert(
              invoiceId: invoiceId,
              patientId: _selectedPatientId!,
              description: item.descriptionController.text,
              itemType: Value(item.type.toLowerCase()),
              unitPrice: Value(item.rate),
              quantity: Value(item.quantity),
              totalAmount: Value(item.total),
              displayOrder: Value(i),
            ),
          );
        }
        
        // Fetch the created invoice to return it
        final createdInvoice = await db.getInvoiceById(invoiceId);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Invoice $_invoiceNumber created successfully!'),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
          Navigator.pop(context, createdInvoice); // Return created invoice entity
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Error saving invoice: $e'),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        }
      }
    }
  }

  void _printInvoice() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.print, color: Colors.white),
            SizedBox(width: 12),
            Text('Preparing invoice for print...'),
          ],
        ),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 400;
    final padding = isCompact ? 12.0 : 20.0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Modern SliverAppBar
            SliverAppBar(
              expandedHeight: 160,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: colorScheme.surface,
              surfaceTintColor: Colors.transparent,
              leading: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark 
                        ? Colors.white.withValues(alpha: 0.1) 
                        : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [const Color(0xFF1A1A2E), colorScheme.surface]
                          : [colorScheme.surface, Theme.of(context).scaffoldBackgroundColor],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(context.responsivePadding),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
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
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'New Invoice',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Create invoice for patient',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
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
            ),
            // Body Content
            SliverPadding(
              padding: EdgeInsets.all(padding),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
              // Patient Selection
              _buildSectionCard(
                title: 'Bill To',
                icon: Icons.person,
                colorScheme: colorScheme,
                child: _buildPatientSelector(colorScheme, isDark),
              ),
              const SizedBox(height: 16),

              // Quick Add Services
              _buildSectionCard(
                title: 'Quick Add Services',
                icon: Icons.flash_on,
                colorScheme: colorScheme,
                child: _buildQuickAddSection(colorScheme, isDark),
              ),
              const SizedBox(height: 16),

              // Invoice Items
              _buildSectionCard(
                title: 'Invoice Items',
                icon: Icons.receipt_long,
                colorScheme: colorScheme,
                trailing: FilledButton.tonalIcon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Item'),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                child: _buildItemsSection(colorScheme, isDark),
              ),
              const SizedBox(height: 16),

              // Totals Section
              _buildTotalsSection(colorScheme, isDark),
              const SizedBox(height: 16),

              // Payment Details
              _buildSectionCard(
                title: 'Payment Details',
                icon: Icons.payment,
                colorScheme: colorScheme,
                child: _buildPaymentSection(colorScheme, isDark),
              ),
              const SizedBox(height: 16),

              // Notes
              _buildSectionCard(
                title: 'Notes',
                icon: Icons.note,
                colorScheme: colorScheme,
                child: SuggestionTextField(
                  controller: _notesController,
                  label: 'Notes / Terms',
                  hint: 'Additional notes or terms...',
                  prefixIcon: Icons.note_outlined,
                  maxLines: 3,
                  suggestions: BillingSuggestions.discountReasons,
                  separator: '. ',
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: AppButton.tertiary(
                      label: 'Print',
                      icon: Icons.print,
                      onPressed: _printInvoice,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: AppButton.primary(
                      label: 'Save Invoice',
                      icon: Icons.save,
                      onPressed: _saveInvoice,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
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

  Widget _buildPatientSelector(ColorScheme colorScheme, bool isDark) {
    if (_selectedPatient != null) {
      final patient = _selectedPatient!;
      final patientName = _getPatientName(patient);
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.billing.withValues(alpha: 0.15),
              AppColors.billing.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.billing.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.billing, AppColors.billing.withValues(alpha: 0.8)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.billing.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                patient.firstName.isNotEmpty ? patient.firstName[0] : '?',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patientName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    patient.phone.isNotEmpty ? patient.phone : 'No phone',
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() {
                _selectedPatientId = null;
                _selectedPatient = null;
              }),
            ),
          ],
        ),
      );
    }

    // Filter patients based on search
    final searchQuery = _searchController.text.toLowerCase();
    final filteredPatients = searchQuery.isEmpty
        ? _patients
        : _patients.where((p) => _getPatientName(p).toLowerCase().contains(searchQuery)).toList();

    return Column(
      children: [
        AppInput.search(
          controller: _searchController,
          hint: 'Search patient...',
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        if (_patients.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: const Text('Loading patients...'),
          )
        else if (filteredPatients.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: const Text('No patients found'),
          )
        else
          Container(
            constraints: const BoxConstraints(maxHeight: 160),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.billing.withValues(alpha: 0.08),
                  AppColors.billing.withValues(alpha: 0.03),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.billing.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: filteredPatients.length,
              itemBuilder: (context, index) {
                final patient = filteredPatients[index];
                final patientName = _getPatientName(patient);
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    child: Text(patient.firstName.isNotEmpty ? patient.firstName[0] : '?'),
                  ),
                  title: Text(patientName),
                  subtitle: Text(patient.phone.isNotEmpty ? patient.phone : 'No phone'),
                  dense: true,
                  onTap: () => setState(() {
                    _selectedPatientId = patient.id;
                    _selectedPatient = patient;
                  }),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildQuickAddSection(ColorScheme colorScheme, bool isDark) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _commonServices.map((service) {
        return GestureDetector(
          onTap: () => _addQuickService(service),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.billing.withValues(alpha: 0.15),
                  AppColors.billing.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.billing.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getServiceIcon(service['type'] as String?),
                  size: 16,
                  color: AppColors.billing,
                ),
                const SizedBox(width: 6),
                Text(
                  '${service['name']} - Rs.${(service['amount'] as num).toInt()}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildItemsSection(ColorScheme colorScheme, bool isDark) {
    if (_items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.billing.withValues(alpha: 0.1),
              AppColors.billing.withValues(alpha: 0.03),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.billing.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.billing.withValues(alpha: 0.2),
                    AppColors.billing.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                size: 48,
                color: AppColors.billing,
              ),
            ),
            const SizedBox(height: 12),
            const SizedBox(height: 16),
            Text(
              'No items added yet',
              style: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Use Quick Add or click Add Item',
              style: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(flex: 3, child: Text('Description', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.7)))),
              Expanded(child: Text('Qty', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.7)))),
              Expanded(flex: 2, child: Text('Rate', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.7)))),
              Expanded(flex: 2, child: Text('Amount', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.7)))),
              const SizedBox(width: 40),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Items
        for (int i = 0; i < _items.length; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              border: Border.all(
                color: (isDark ? AppColors.darkDivider : AppColors.divider).withValues(alpha: 0.3),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _items[i].descriptionController,
                    decoration: InputDecoration(
                      hintText: 'Item description',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: (isDark ? AppColors.darkDivider : AppColors.divider).withValues(alpha: 0.3),
                        ),
                      ),
                      isDense: true,
                      filled: true,
                    ),
                    validator: (v) => v?.isEmpty ?? false ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 60,
                  child: TextFormField(
                    controller: _items[i].quantityController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: 'Qty',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: (isDark ? AppColors.darkDivider : AppColors.divider).withValues(alpha: 0.3),
                        ),
                      ),
                      isDense: true,
                      filled: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _items[i].amountController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      hintText: 'Rate',
                      prefixText: 'Rs.',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: (isDark ? AppColors.darkDivider : AppColors.divider).withValues(alpha: 0.3),
                        ),
                      ),
                      isDense: true,
                      filled: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 80,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Rs.${_items[i].total.toStringAsFixed(0)}',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: colorScheme.error, size: 20),
                  onPressed: () => _removeItem(i),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTotalsSection(ColorScheme colorScheme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.billing.withValues(alpha: 0.12),
            AppColors.billing.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.billing.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTotalRow('Subtotal', _subtotal, colorScheme),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Discount',
                  style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7)),
                ),
              ),
              SizedBox(
                width: 80,
                child: TextFormField(
                  controller: _discountController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    suffixText: '%',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    isDense: true,
                    filled: true,
                  ),
                  onChanged: (v) {
                    setState(() {
                      _discountPercent = double.tryParse(v) ?? 0;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 100,
                child: Text(
                  '- Rs.${_discountAmount.toStringAsFixed(0)}',
                  textAlign: TextAlign.right,
                  style: TextStyle(color: colorScheme.error),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Tax',
                  style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7)),
                ),
              ),
              SizedBox(
                width: 80,
                child: TextFormField(
                  controller: _taxController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    suffixText: '%',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    isDense: true,
                    filled: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 100,
                child: Text(
                  '+ Rs.${_taxAmount.toStringAsFixed(0)}',
                  textAlign: TextAlign.right,
                  style: TextStyle(color: colorScheme.tertiary),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Grand Total',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              Text(
                'Rs. ${_grandTotal.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7)),
        ),
        Text(
          'Rs. ${amount.toStringAsFixed(0)}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildPaymentSection(ColorScheme colorScheme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Method',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: BillingSuggestions.paymentMethods.map((method) {
            final isSelected = _paymentMethod == method;
            return GestureDetector(
              onTap: () => setState(() => _paymentMethod = method),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [
                            AppColors.billing,
                            AppColors.billing.withValues(alpha: 0.8),
                          ],
                        )
                      : LinearGradient(
                          colors: [
                            AppColors.billing.withValues(alpha: 0.12),
                            AppColors.billing.withValues(alpha: 0.05),
                          ],
                        ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.billing.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: AppColors.billing.withValues(alpha: 0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getPaymentIcon(method),
                      size: 16,
                      color: isSelected ? Colors.white : AppColors.billing,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      method,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        const Text(
          'Payment Status',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['Pending', 'Partial', 'Paid'].map((status) {
            final isSelected = _paymentStatus == status;
            final statusColor = _getStatusColor(status);
            return GestureDetector(
              onTap: () => setState(() => _paymentStatus = status),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [statusColor, statusColor.withValues(alpha: 0.8)],
                        )
                      : LinearGradient(
                          colors: [
                            statusColor.withValues(alpha: 0.15),
                            statusColor.withValues(alpha: 0.08),
                          ],
                        ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: statusColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: statusColor.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required ColorScheme colorScheme,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.billing.withValues(alpha: 0.1),
            AppColors.billing.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.billing.withValues(alpha: 0.08),
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
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.billing.withValues(alpha: 0.2),
                        AppColors.billing.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.billing, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
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
    );
  }

  IconData _getServiceIcon(String? type) {
    switch (type) {
      case 'Service':
        return Icons.medical_services_outlined;
      case 'Lab':
        return Icons.science_outlined;
      case 'Imaging':
        return Icons.image_outlined;
      case 'Procedure':
        return Icons.healing_outlined;
      default:
        return Icons.receipt_outlined;
    }
  }

  IconData _getPaymentIcon(String method) {
    switch (method) {
      case 'Cash':
        return Icons.money;
      case 'Card':
        return Icons.credit_card;
      case 'UPI':
        return Icons.qr_code;
      case 'Net Banking':
        return Icons.account_balance;
      case 'Insurance':
        return Icons.health_and_safety;
      case 'Credit':
        return Icons.credit_score;
      default:
        return Icons.payment;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Paid':
        return Colors.green;
      case 'Partial':
        return Colors.orange;
      case 'Pending':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

// Invoice Item Class
class InvoiceItem {
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController quantityController = TextEditingController(text: '1');
  final TextEditingController amountController = TextEditingController();
  String type = 'Service';

  double get quantity => double.tryParse(quantityController.text) ?? 1;
  double get rate => double.tryParse(amountController.text) ?? 0;
  double get total => quantity * rate;

  void dispose() {
    descriptionController.dispose();
    quantityController.dispose();
    amountController.dispose();
  }

  Map<String, dynamic> toJson() {
    return {
      'description': descriptionController.text,
      'quantity': quantity,
      'rate': rate,
      'total': total,
      'type': type,
    };
  }
}


