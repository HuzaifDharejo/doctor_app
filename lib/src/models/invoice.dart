import 'dart:convert';

/// Payment status enum
enum PaymentStatus {
  pending('Pending', 'Payment not yet received'),
  partial('Partial', 'Partially paid'),
  paid('Paid', 'Fully paid'),
  overdue('Overdue', 'Payment past due date'),
  cancelled('Cancelled', 'Invoice cancelled'),
  refunded('Refunded', 'Payment refunded');

  final String label;
  final String description;
  
  const PaymentStatus(this.label, this.description);

  static PaymentStatus fromValue(String value) {
    return PaymentStatus.values.firstWhere(
      (s) => s.label.toLowerCase() == value.toLowerCase() || s.name.toLowerCase() == value.toLowerCase(),
      orElse: () => PaymentStatus.pending,
    );
  }
}

/// Payment method enum
enum PaymentMethod {
  cash('Cash'),
  upi('UPI'),
  card('Card'),
  netBanking('Net Banking'),
  insurance('Insurance'),
  credit('Credit');

  final String label;
  
  const PaymentMethod(this.label);

  static PaymentMethod fromValue(String value) {
    return PaymentMethod.values.firstWhere(
      (m) => m.label.toLowerCase() == value.toLowerCase() || m.name.toLowerCase() == value.toLowerCase(),
      orElse: () => PaymentMethod.cash,
    );
  }
}

/// Individual invoice line item
class InvoiceItem {

  const InvoiceItem({
    required this.description,
    required this.unitPrice, this.quantity = 1,
    this.discount,
    this.hsnCode,
    this.category,
  });

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      description: json['description'] as String? ?? json['name'] as String? ?? '',
      quantity: json['quantity'] as int? ?? json['qty'] as int? ?? 1,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 
                 (json['unit_price'] as num?)?.toDouble() ?? 
                 (json['price'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble(),
      hsnCode: json['hsnCode'] as String? ?? json['hsn_code'] as String?,
      category: json['category'] as String?,
    );
  }
  final String description;
  final int quantity;
  final double unitPrice;
  final double? discount;
  final String? hsnCode;
  final String? category;

  /// Calculate total for this line item
  double get total {
    final subtotal = quantity * unitPrice;
    if (discount != null && discount! > 0) {
      return subtotal - (subtotal * discount! / 100);
    }
    return subtotal;
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
      if (discount != null) 'discount': discount,
      if (hsnCode != null) 'hsnCode': hsnCode,
      if (category != null) 'category': category,
    };
  }

  InvoiceItem copyWith({
    String? description,
    int? quantity,
    double? unitPrice,
    double? discount,
    String? hsnCode,
    String? category,
  }) {
    return InvoiceItem(
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      discount: discount ?? this.discount,
      hsnCode: hsnCode ?? this.hsnCode,
      category: category ?? this.category,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InvoiceItem &&
        other.description == description &&
        other.quantity == quantity &&
        other.unitPrice == unitPrice;
  }

  @override
  int get hashCode => Object.hash(description, quantity, unitPrice);

  @override
  String toString() => 'InvoiceItem($description x$quantity @ $unitPrice)';
}

/// Invoice data model
class InvoiceModel {

  const InvoiceModel({
    required this.patientId, required this.invoiceNumber, required this.invoiceDate, this.id,
    this.patientName,
    this.dueDate,
    this.items = const [],
    this.subtotal = 0.0,
    this.discountPercent = 0.0,
    this.discountAmount = 0.0,
    this.taxPercent = 0.0,
    this.taxAmount = 0.0,
    this.grandTotal = 0.0,
    this.paymentMethod = PaymentMethod.cash,
    this.paymentStatus = PaymentStatus.pending,
    this.amountPaid,
    this.notes = '',
    this.createdAt,
  });

  /// Calculate totals from items
  factory InvoiceModel.calculateFromItems({
    required int patientId, required String invoiceNumber, required DateTime invoiceDate, required List<InvoiceItem> items, int? id,
    String? patientName,
    DateTime? dueDate,
    double discountPercent = 0.0,
    double taxPercent = 0.0,
    PaymentMethod paymentMethod = PaymentMethod.cash,
    PaymentStatus paymentStatus = PaymentStatus.pending,
    double? amountPaid,
    String notes = '',
  }) {
    final subtotal = items.fold<double>(0, (sum, item) => sum + item.total);
    final discountAmount = subtotal * discountPercent / 100;
    final afterDiscount = subtotal - discountAmount;
    final taxAmount = afterDiscount * taxPercent / 100;
    final grandTotal = afterDiscount + taxAmount;

    return InvoiceModel(
      id: id,
      patientId: patientId,
      patientName: patientName,
      invoiceNumber: invoiceNumber,
      invoiceDate: invoiceDate,
      dueDate: dueDate,
      items: items,
      subtotal: subtotal,
      discountPercent: discountPercent,
      discountAmount: discountAmount,
      taxPercent: taxPercent,
      taxAmount: taxAmount,
      grandTotal: grandTotal,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus,
      amountPaid: amountPaid,
      notes: notes,
    );
  }

  /// Create from JSON map
  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    List<InvoiceItem> items = [];
    
    if (json['items'] is List) {
      items = (json['items'] as List<dynamic>)
          .map((item) => InvoiceItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } else if (json['itemsJson'] is String) {
      items = parseItemsJson(json['itemsJson'] as String);
    } else if (json['items_json'] is String) {
      items = parseItemsJson(json['items_json'] as String);
    }

    return InvoiceModel(
      id: json['id'] as int?,
      patientId: json['patientId'] as int? ?? json['patient_id'] as int? ?? 0,
      patientName: json['patientName'] as String? ?? json['patient_name'] as String?,
      invoiceNumber: json['invoiceNumber'] as String? ?? json['invoice_number'] as String? ?? '',
      invoiceDate: json['invoiceDate'] != null
          ? DateTime.parse(json['invoiceDate'] as String)
          : json['invoice_date'] != null
              ? DateTime.parse(json['invoice_date'] as String)
              : DateTime.now(),
      dueDate: json['dueDate'] != null
          ? DateTime.tryParse(json['dueDate'] as String)
          : json['due_date'] != null
              ? DateTime.tryParse(json['due_date'] as String)
              : null,
      items: items,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      discountPercent: (json['discountPercent'] as num?)?.toDouble() ?? 
                       (json['discount_percent'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 
                      (json['discount_amount'] as num?)?.toDouble() ?? 0.0,
      taxPercent: (json['taxPercent'] as num?)?.toDouble() ?? 
                  (json['tax_percent'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 
                 (json['tax_amount'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (json['grandTotal'] as num?)?.toDouble() ?? 
                  (json['grand_total'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: PaymentMethod.fromValue(
        json['paymentMethod'] as String? ?? json['payment_method'] as String? ?? 'Cash',
      ),
      paymentStatus: PaymentStatus.fromValue(
        json['paymentStatus'] as String? ?? json['payment_status'] as String? ?? 'Pending',
      ),
      amountPaid: (json['amountPaid'] as num?)?.toDouble() ?? 
                  (json['amount_paid'] as num?)?.toDouble(),
      notes: json['notes'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : json['created_at'] != null
              ? DateTime.tryParse(json['created_at'] as String)
              : null,
    );
  }

  /// Create from JSON string
  factory InvoiceModel.fromJsonString(String jsonString) {
    return InvoiceModel.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }
  final int? id;
  final int patientId;
  final String? patientName; // For display purposes
  final String invoiceNumber;
  final DateTime invoiceDate;
  final DateTime? dueDate;
  final List<InvoiceItem> items;
  final double subtotal;
  final double discountPercent;
  final double discountAmount;
  final double taxPercent;
  final double taxAmount;
  final double grandTotal;
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;
  final double? amountPaid;
  final String notes;
  final DateTime? createdAt;

  /// Calculate balance due
  double get balanceDue {
    if (paymentStatus == PaymentStatus.paid) return 0;
    return grandTotal - (amountPaid ?? 0);
  }

  /// Check if invoice is overdue
  bool get isOverdue {
    if (paymentStatus == PaymentStatus.paid) return false;
    if (dueDate == null) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  /// Get formatted invoice date
  String get formattedDate {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[invoiceDate.month - 1]} ${invoiceDate.day}, ${invoiceDate.year}';
  }

  /// Get formatted grand total with currency
  String get formattedTotal => '₹${grandTotal.toStringAsFixed(2)}';

  /// Parse items from JSON string
  static List<InvoiceItem> parseItemsJson(String jsonString) {
    if (jsonString.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(jsonString) as List<dynamic>;
      return list.map((item) => InvoiceItem.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Convert items to JSON string
  String get itemsJsonString => jsonEncode(items.map((i) => i.toJson()).toList());

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'patientId': patientId,
      if (patientName != null) 'patientName': patientName,
      'invoiceNumber': invoiceNumber,
      'invoiceDate': invoiceDate.toIso8601String(),
      if (dueDate != null) 'dueDate': dueDate!.toIso8601String(),
      'items': items.map((i) => i.toJson()).toList(),
      'subtotal': subtotal,
      'discountPercent': discountPercent,
      'discountAmount': discountAmount,
      'taxPercent': taxPercent,
      'taxAmount': taxAmount,
      'grandTotal': grandTotal,
      'paymentMethod': paymentMethod.label,
      'paymentStatus': paymentStatus.label,
      if (amountPaid != null) 'amountPaid': amountPaid,
      'notes': notes,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }

  /// Convert to JSON string
  String toJsonString() => jsonEncode(toJson());

  /// Create a copy with modified fields
  InvoiceModel copyWith({
    int? id,
    int? patientId,
    String? patientName,
    String? invoiceNumber,
    DateTime? invoiceDate,
    DateTime? dueDate,
    List<InvoiceItem>? items,
    double? subtotal,
    double? discountPercent,
    double? discountAmount,
    double? taxPercent,
    double? taxAmount,
    double? grandTotal,
    PaymentMethod? paymentMethod,
    PaymentStatus? paymentStatus,
    double? amountPaid,
    String? notes,
    DateTime? createdAt,
  }) {
    return InvoiceModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      dueDate: dueDate ?? this.dueDate,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discountPercent: discountPercent ?? this.discountPercent,
      discountAmount: discountAmount ?? this.discountAmount,
      taxPercent: taxPercent ?? this.taxPercent,
      taxAmount: taxAmount ?? this.taxAmount,
      grandTotal: grandTotal ?? this.grandTotal,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      amountPaid: amountPaid ?? this.amountPaid,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InvoiceModel &&
        other.id == id &&
        other.invoiceNumber == invoiceNumber &&
        other.patientId == patientId;
  }

  @override
  int get hashCode => Object.hash(id, invoiceNumber, patientId);

  @override
  String toString() => 'InvoiceModel(id: $id, #$invoiceNumber, total: $formattedTotal)';
}
