/// Lab Test Component Models
/// 
/// Shared data models and enums for lab test components.
/// Provides consistent typing across all lab-related screens.

import 'dart:convert';
import 'package:flutter/material.dart';

/// Lab order status with display labels
enum LabOrderStatus {
  draft('draft', 'Draft', 'Order not yet submitted'),
  ordered('ordered', 'Ordered', 'Order placed, awaiting collection'),
  collected('collected', 'Collected', 'Specimen collected'),
  inProgress('in_progress', 'In Progress', 'Testing in progress'),
  completed('completed', 'Completed', 'Results available'),
  cancelled('cancelled', 'Cancelled', 'Order cancelled');

  const LabOrderStatus(this.value, this.label, this.description);
  final String value;
  final String label;
  final String description;

  static LabOrderStatus fromValue(String value) {
    return LabOrderStatus.values.firstWhere(
      (e) => e.value == value.toLowerCase().replaceAll(' ', '_'),
      orElse: () => LabOrderStatus.ordered,
    );
  }
  
  /// Get appropriate icon for status
  String get iconName {
    switch (this) {
      case LabOrderStatus.draft:
        return 'edit';
      case LabOrderStatus.ordered:
        return 'schedule';
      case LabOrderStatus.collected:
        return 'science';
      case LabOrderStatus.inProgress:
        return 'pending';
      case LabOrderStatus.completed:
        return 'check_circle';
      case LabOrderStatus.cancelled:
        return 'cancel';
    }
  }
}

/// Lab order priority/urgency levels
enum LabPriority {
  stat('stat', 'STAT', 'Immediate - life threatening'),
  urgent('urgent', 'Urgent', 'Within 24 hours'),
  routine('routine', 'Routine', 'Standard processing time');

  const LabPriority(this.value, this.label, this.description);
  final String value;
  final String label;
  final String description;

  static LabPriority fromValue(String value) {
    return LabPriority.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => LabPriority.routine,
    );
  }
  
  /// Display name with first letter capitalized
  String get displayName => label;
}

/// Specimen types for lab tests
enum LabSpecimenType {
  blood('blood', 'Blood', 'Venous or capillary blood'),
  urine('urine', 'Urine', 'Urine sample'),
  stool('stool', 'Stool', 'Stool sample'),
  swab('swab', 'Swab', 'Nasal, throat, or wound swab'),
  tissue('tissue', 'Tissue', 'Tissue biopsy'),
  csf('csf', 'CSF', 'Cerebrospinal fluid'),
  sputum('sputum', 'Sputum', 'Respiratory secretions'),
  other('other', 'Other', 'Other specimen type');

  const LabSpecimenType(this.value, this.label, this.description);
  final String value;
  final String label;
  final String description;

  static LabSpecimenType fromValue(String value) {
    return LabSpecimenType.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => LabSpecimenType.blood,
    );
  }
  
  /// Get all specimen types as string list for dropdowns
  static List<String> get allValues => 
      LabSpecimenType.values.map((e) => e.value).toList();
  
  /// Icon for specimen type
  IconData get icon {
    switch (this) {
      case LabSpecimenType.blood:
        return Icons.water_drop_rounded;
      case LabSpecimenType.urine:
        return Icons.science_rounded;
      case LabSpecimenType.stool:
        return Icons.inbox_rounded;
      case LabSpecimenType.swab:
        return Icons.cleaning_services_rounded;
      case LabSpecimenType.tissue:
        return Icons.biotech_rounded;
      case LabSpecimenType.csf:
        return Icons.bubble_chart_rounded;
      case LabSpecimenType.sputum:
        return Icons.air_rounded;
      case LabSpecimenType.other:
        return Icons.category_rounded;
    }
  }
}

/// Lab test categories
enum LabCategory {
  hematology('Hematology', 'Blood cell tests'),
  chemistry('Chemistry', 'Blood chemistry'),
  hepatic('Hepatic', 'Liver function'),
  renal('Renal', 'Kidney function'),
  diabetes('Diabetes', 'Glucose monitoring'),
  lipids('Lipids', 'Cholesterol & lipids'),
  endocrine('Endocrine', 'Hormone tests'),
  cardiac('Cardiac', 'Heart markers'),
  coagulation('Coagulation', 'Clotting tests'),
  infectious('Infectious', 'Infection testing'),
  immunology('Immunology', 'Immune system'),
  urinalysis('Urine', 'Urine analysis'),
  tumorMarkers('Tumor Markers', 'Cancer markers'),
  vitamins('Vitamins', 'Vitamin levels'),
  other('Other', 'Other tests');

  const LabCategory(this.label, this.description);
  final String label;
  final String description;
  
  String get value => name;
}

/// Result status for lab results
enum LabResultStatus {
  normal('Normal', 'Within normal range'),
  abnormal('Abnormal', 'Outside normal range'),
  high('High', 'Above normal range'),
  low('Low', 'Below normal range'),
  critical('Critical', 'Critical value - urgent attention'),
  pending('Pending', 'Results pending');

  const LabResultStatus(this.label, this.description);
  final String label;
  final String description;
  
  String get value => name.toLowerCase();
  
  static LabResultStatus fromValue(String value) {
    return LabResultStatus.values.firstWhere(
      (e) => e.value == value.toLowerCase() || e.label.toLowerCase() == value.toLowerCase(),
      orElse: () => LabResultStatus.pending,
    );
  }
  
  bool get isAbnormal => this != LabResultStatus.normal && this != LabResultStatus.pending;
}

/// Complete lab test data model for UI components
class LabTestData {
  const LabTestData({
    required this.name,
    this.testCode,
    this.category = LabCategory.other,
    this.specimenType = LabSpecimenType.blood,
    this.priority = LabPriority.routine,
    this.status = LabOrderStatus.ordered,
    this.clinicalIndication,
    this.labName,
    this.orderDate,
    this.collectionDate,
    this.resultDate,
    this.result,
    this.referenceRange,
    this.units,
    this.resultStatus = LabResultStatus.pending,
    this.isAbnormal = false,
    this.isCritical = false,
    this.notes,
    this.orderingProvider,
    this.interpretation,
  });

  final String name;
  final String? testCode;
  final LabCategory category;
  final LabSpecimenType specimenType;
  final LabPriority priority;
  final LabOrderStatus status;
  final String? clinicalIndication;
  final String? labName;
  final DateTime? orderDate;
  final DateTime? collectionDate;
  final DateTime? resultDate;
  final String? result;
  final String? referenceRange;
  final String? units;
  final LabResultStatus resultStatus;
  final bool isAbnormal;
  final bool isCritical;
  final String? notes;
  final String? orderingProvider;
  final String? interpretation;

  /// Create from JSON map
  factory LabTestData.fromJson(Map<String, dynamic> json) {
    return LabTestData(
      name: json['name'] as String? ?? json['test_name'] as String? ?? '',
      testCode: json['testCode'] as String? ?? json['test_code'] as String?,
      category: json['category'] != null 
          ? LabCategory.values.firstWhere(
              (c) => c.label == json['category'] || c.name == json['category'],
              orElse: () => LabCategory.other,
            )
          : LabCategory.other,
      specimenType: LabSpecimenType.fromValue(
        json['specimenType'] as String? ?? json['specimen_type'] as String? ?? 'blood',
      ),
      priority: LabPriority.fromValue(
        json['priority'] as String? ?? json['urgency'] as String? ?? 'routine',
      ),
      status: LabOrderStatus.fromValue(json['status'] as String? ?? 'ordered'),
      clinicalIndication: json['clinicalIndication'] as String? ?? json['clinical_indication'] as String?,
      labName: json['labName'] as String? ?? json['lab_name'] as String?,
      orderDate: _parseDateTime(json['orderDate'] ?? json['order_date']),
      collectionDate: _parseDateTime(json['collectionDate'] ?? json['collection_date']),
      resultDate: _parseDateTime(json['resultDate'] ?? json['result_date']),
      result: json['result'] as String?,
      referenceRange: json['referenceRange'] as String? ?? json['reference_range'] as String?,
      units: json['units'] as String?,
      resultStatus: LabResultStatus.fromValue(
        json['resultStatus'] as String? ?? json['result_status'] as String? ?? 'pending',
      ),
      isAbnormal: json['isAbnormal'] as bool? ?? json['is_abnormal'] as bool? ?? false,
      isCritical: json['isCritical'] as bool? ?? json['is_critical'] as bool? ?? false,
      notes: json['notes'] as String?,
      orderingProvider: json['orderingProvider'] as String? ?? json['ordering_provider'] as String?,
      interpretation: json['interpretation'] as String?,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() => {
    'name': name,
    'testCode': testCode,
    'category': category.label,
    'specimenType': specimenType.value,
    'priority': priority.value,
    'status': status.value,
    'clinicalIndication': clinicalIndication,
    'labName': labName,
    'orderDate': orderDate?.toIso8601String(),
    'collectionDate': collectionDate?.toIso8601String(),
    'resultDate': resultDate?.toIso8601String(),
    'result': result,
    'referenceRange': referenceRange,
    'units': units,
    'resultStatus': resultStatus.value,
    'isAbnormal': isAbnormal,
    'isCritical': isCritical,
    'notes': notes,
    'orderingProvider': orderingProvider,
    'interpretation': interpretation,
  };

  /// Serialize to JSON string
  String toJsonString() => jsonEncode(toJson());

  /// Create copy with modifications
  LabTestData copyWith({
    String? name,
    String? testCode,
    LabCategory? category,
    LabSpecimenType? specimenType,
    LabPriority? priority,
    LabOrderStatus? status,
    String? clinicalIndication,
    String? labName,
    DateTime? orderDate,
    DateTime? collectionDate,
    DateTime? resultDate,
    String? result,
    String? referenceRange,
    String? units,
    LabResultStatus? resultStatus,
    bool? isAbnormal,
    bool? isCritical,
    String? notes,
    String? orderingProvider,
    String? interpretation,
  }) {
    return LabTestData(
      name: name ?? this.name,
      testCode: testCode ?? this.testCode,
      category: category ?? this.category,
      specimenType: specimenType ?? this.specimenType,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      clinicalIndication: clinicalIndication ?? this.clinicalIndication,
      labName: labName ?? this.labName,
      orderDate: orderDate ?? this.orderDate,
      collectionDate: collectionDate ?? this.collectionDate,
      resultDate: resultDate ?? this.resultDate,
      result: result ?? this.result,
      referenceRange: referenceRange ?? this.referenceRange,
      units: units ?? this.units,
      resultStatus: resultStatus ?? this.resultStatus,
      isAbnormal: isAbnormal ?? this.isAbnormal,
      isCritical: isCritical ?? this.isCritical,
      notes: notes ?? this.notes,
      orderingProvider: orderingProvider ?? this.orderingProvider,
      interpretation: interpretation ?? this.interpretation,
    );
  }

  /// Check if test has valid required fields
  bool get isValid => name.isNotEmpty;

  /// Check if results are available
  bool get hasResults => result != null && result!.isNotEmpty;

  /// Check if requires fasting (common tests)
  bool get maybeFasting {
    final lower = name.toLowerCase();
    return lower.contains('fasting') ||
           lower.contains('lipid') ||
           lower.contains('glucose') ||
           lower.contains('cholesterol');
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

/// Lab test panel - collection of related tests
class LabTestPanel {
  const LabTestPanel({
    required this.name,
    required this.description,
    required this.tests,
    this.clinicalIndication,
    this.category,
  });

  final String name;
  final String description;
  final List<LabTestData> tests;
  final String? clinicalIndication;
  final LabCategory? category;

  /// Number of tests in panel
  int get testCount => tests.length;

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'tests': tests.map((t) => t.toJson()).toList(),
    'clinicalIndication': clinicalIndication,
    'category': category?.label,
  };
}

/// Lab test template for quick selection (lighter weight than full LabTestData)
class LabTestTemplate {
  const LabTestTemplate({
    required this.name,
    required this.category,
    this.testCode,
    this.specimenType = 'blood',
    this.urgency = 'routine',
    this.clinicalIndication,
    this.notes,
    this.referenceRange,
    this.units,
  });

  final String name;
  final String category;
  final String? testCode;
  final String specimenType;
  final String urgency;
  final String? clinicalIndication;
  final String? notes;
  final String? referenceRange;
  final String? units;

  /// Convert to full LabTestData
  LabTestData toLabTestData() {
    return LabTestData(
      name: name,
      testCode: testCode,
      category: LabCategory.values.firstWhere(
        (c) => c.label.toLowerCase() == category.toLowerCase(),
        orElse: () => LabCategory.other,
      ),
      specimenType: LabSpecimenType.fromValue(specimenType),
      priority: LabPriority.fromValue(urgency),
      clinicalIndication: clinicalIndication,
      notes: notes,
      referenceRange: referenceRange,
      units: units,
      orderDate: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'category': category,
    'testCode': testCode,
    'specimenType': specimenType,
    'urgency': urgency,
    'clinicalIndication': clinicalIndication,
    'notes': notes,
    'referenceRange': referenceRange,
    'units': units,
  };
}
