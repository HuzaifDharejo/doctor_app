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

class AddInvoiceScreen extends ConsumerStatefulWidget {
  final int? patientId;
  final String? patientName;

  const AddInvoiceScreen({
    super.key,
    this.patientId,
    this.patientName,
  });

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
  DateTime _invoiceDate = DateTime.now();
  DateTime? _dueDate;

  // Common Services for quick add - using BillingSuggestions
  List<Map<String, dynamic>> get _commonServices => BillingSuggestions.serviceTypes.take(10).map((service) {
    // Assign default prices based on service type
    double price = 500.0;
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
    for (var item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  double get _subtotal {
    return _items.fold(0.0, (sum, item) => sum + item.total);
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
      item.descriptionController.text = service['name'];
      item.amountController.text = service['amount'].toString();
      item.type = service['type'];
      _items.add(item);
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items[index].dispose();
      _items.removeAt(index);
    });
  }

  Future<void> _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Map<String, dynamic> _buildInvoiceJson() {
    return {
      'invoice_number': _invoiceNumber,
      'invoice_date': _invoiceDate.toIso8601String(),
      'due_date': _dueDate?.toIso8601String(),
      'patient_id': _selectedPatientId,
      'patient_name': _selectedPatient != null ? _getPatientName(_selectedPatient!) : '',
      'items': _items.map((item) => item.toJson()).toList(),
      'subtotal': _subtotal,
      'discount_percent': _discountPercent,
      'discount_amount': _discountAmount,
      'tax_percent': double.tryParse(_taxController.text) ?? 0,
      'tax_amount': _taxAmount,
      'grand_total': _grandTotal,
      'payment_method': _paymentMethod,
      'payment_status': _paymentStatus,
      'notes': _notesController.text,
    };
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
        
        // Prepare items JSON
        final itemsJson = jsonEncode(_items.map((item) => item.toJson()).toList());
        
        // Create invoice companion
        final invoiceCompanion = InvoicesCompanion.insert(
          patientId: _selectedPatientId!,
          invoiceNumber: _invoiceNumber,
          invoiceDate: _invoiceDate,
          dueDate: Value(_dueDate),
          itemsJson: itemsJson,
          subtotal: Value(_subtotal),
          discountPercent: Value(_discountPercent),
          discountAmount: Value(_discountAmount),
          taxPercent: Value(double.tryParse(_taxController.text) ?? 0),
          taxAmount: Value(_taxAmount),
          grandTotal: Value(_grandTotal),
          paymentMethod: Value(_paymentMethod),
          paymentStatus: Value(_paymentStatus),
          notes: Value(_notesController.text.isNotEmpty ? _notesController.text : ''),
        );
        
        await db.insertInvoice(invoiceCompanion);
        
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
          Navigator.pop(context, true); // Return true to indicate success
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
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Gradient Header
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.all(padding),
                    child: Column(
                      children: [
                        // Custom App Bar
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                              ),
                            ),
                            const Expanded(
                              child: Text(
                                'Create Invoice',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: _printInvoice,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.print, color: Colors.white, size: 20),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Invoice Icon with Status Badge
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.receipt_long_rounded,
                                size: 48,
                                color: Colors.white,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(_paymentStatus),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: Text(
                                  _paymentStatus,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _invoiceNumber,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('EEEE, dd MMMM yyyy').format(_invoiceDate),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                        if (_dueDate != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Due: ${DateFormat('dd MMM yyyy').format(_dueDate!)}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                      ],
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
                child: _buildPatientSelector(colorScheme),
              ),
              const SizedBox(height: 16),

              // Quick Add Services
              _buildSectionCard(
                title: 'Quick Add Services',
                icon: Icons.flash_on,
                colorScheme: colorScheme,
                child: _buildQuickAddSection(colorScheme),
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
                child: _buildItemsSection(colorScheme),
              ),
              const SizedBox(height: 16),

              // Totals Section
              _buildTotalsSection(colorScheme),
              const SizedBox(height: 16),

              // Payment Details
              _buildSectionCard(
                title: 'Payment Details',
                icon: Icons.payment,
                colorScheme: colorScheme,
                child: _buildPaymentSection(colorScheme),
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
                  appendMode: true,
                  separator: '. ',
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _printInvoice,
                      icon: const Icon(Icons.print),
                      label: const Text('Print'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _saveInvoice,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Invoice'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientSelector(ColorScheme colorScheme) {
    if (_selectedPatient != null) {
      final patient = _selectedPatient!;
      final patientName = _getPatientName(patient);
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: colorScheme.primary,
              child: Text(
                patient.firstName.isNotEmpty ? patient.firstName[0] : '?',
                style: TextStyle(color: colorScheme.onPrimary, fontWeight: FontWeight.bold),
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
                      color: colorScheme.onSurface.withOpacity(0.7),
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
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search patient...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        if (_patients.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            child: const Text('Loading patients...'),
          )
        else if (filteredPatients.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            child: const Text('No patients found'),
          )
        else
          Container(
            constraints: const BoxConstraints(maxHeight: 160),
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(12),
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

  Widget _buildQuickAddSection(ColorScheme colorScheme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _commonServices.map((service) {
        return ActionChip(
          avatar: Icon(_getServiceIcon(service['type']), size: 16),
          label: Text(
            '${service['name']} - Rs.${service['amount'].toInt()}',
            style: const TextStyle(fontSize: 12),
          ),
          onPressed: () => _addQuickService(service),
        );
      }).toList(),
    );
  }

  Widget _buildItemsSection(ColorScheme colorScheme) {
    if (_items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outlineVariant, style: BorderStyle.solid),
        ),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'No items added yet',
              style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5)),
            ),
            const SizedBox(height: 8),
            Text(
              'Use Quick Add or click Add Item',
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.4),
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
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(flex: 3, child: Text('Description', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: colorScheme.onSurface.withOpacity(0.7)))),
              Expanded(child: Text('Qty', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: colorScheme.onSurface.withOpacity(0.7)))),
              Expanded(flex: 2, child: Text('Rate', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: colorScheme.onSurface.withOpacity(0.7)))),
              Expanded(flex: 2, child: Text('Amount', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: colorScheme.onSurface.withOpacity(0.7)))),
              const SizedBox(width: 40),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Items
        for (int i = 0; i < _items.length; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outlineVariant),
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
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                      filled: true,
                    ),
                    validator: (v) => v?.isEmpty == true ? 'Required' : null,
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
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
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

  Widget _buildTotalsSection(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
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
                  style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
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
                  style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
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
          style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
        ),
        Text(
          'Rs. ${amount.toStringAsFixed(0)}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildPaymentSection(ColorScheme colorScheme) {
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
          children: BillingSuggestions.paymentMethods.map((method) {
            final isSelected = _paymentMethod == method;
            return ChoiceChip(
              label: Text(method),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _paymentMethod = method);
              },
              avatar: Icon(_getPaymentIcon(method), size: 16),
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
          children: ['Pending', 'Partial', 'Paid'].map((status) {
            final isSelected = _paymentStatus == status;
            return ChoiceChip(
              label: Text(status),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _paymentStatus = status);
              },
              selectedColor: _getStatusColor(status).withOpacity(0.3),
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
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: colorScheme.primary, size: 20),
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
      ),
    );
  }

  IconData _getServiceIcon(String type) {
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
