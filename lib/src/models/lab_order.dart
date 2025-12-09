import 'dart:convert';

/// Lab order status
enum LabOrderStatus {
  draft('draft', 'Draft'),
  pending('pending', 'Pending'),
  sent('sent', 'Sent to Lab'),
  received('received', 'Specimen Received'),
  inProgress('in_progress', 'In Progress'),
  resulted('resulted', 'Results Available'),
  cancelled('cancelled', 'Cancelled');

  const LabOrderStatus(this.value, this.label);
  final String value;
  final String label;

  static LabOrderStatus fromValue(String value) {
    return LabOrderStatus.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => LabOrderStatus.pending,
    );
  }
}

/// Lab order priority
enum LabPriority {
  stat('stat', 'STAT', 'Immediate'),
  urgent('urgent', 'Urgent', 'Within 24 hours'),
  routine('routine', 'Routine', 'Standard processing');

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
}

/// Lab order type
enum LabOrderType {
  lab('lab', 'Laboratory'),
  imaging('imaging', 'Imaging/Radiology'),
  pathology('pathology', 'Pathology'),
  genetic('genetic', 'Genetic Testing');

  const LabOrderType(this.value, this.label);
  final String value;
  final String label;

  static LabOrderType fromValue(String value) {
    return LabOrderType.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => LabOrderType.lab,
    );
  }
}

/// Common lab tests with LOINC codes
class CommonLabTests {
  static const List<LabTestInfo> all = [
    // Basic metabolic panel
    LabTestInfo('BMP', '51990-0', 'Basic Metabolic Panel', 'blood', false),
    LabTestInfo('CMP', '24323-8', 'Comprehensive Metabolic Panel', 'blood', false),
    
    // Complete blood count
    LabTestInfo('CBC', '57021-8', 'Complete Blood Count with Differential', 'blood', false),
    LabTestInfo('CBC w/o Diff', '57782-5', 'Complete Blood Count without Differential', 'blood', false),
    
    // Lipid panel
    LabTestInfo('Lipid Panel', '57698-3', 'Lipid Panel', 'blood', true),
    LabTestInfo('Total Cholesterol', '2093-3', 'Total Cholesterol', 'blood', true),
    LabTestInfo('HDL', '2085-9', 'HDL Cholesterol', 'blood', true),
    LabTestInfo('LDL', '2089-1', 'LDL Cholesterol', 'blood', true),
    LabTestInfo('Triglycerides', '2571-8', 'Triglycerides', 'blood', true),
    
    // Diabetes
    LabTestInfo('Glucose Fasting', '1558-6', 'Fasting Glucose', 'blood', true),
    LabTestInfo('Glucose Random', '2345-7', 'Random Glucose', 'blood', false),
    LabTestInfo('HbA1c', '4548-4', 'Hemoglobin A1c', 'blood', false),
    
    // Thyroid
    LabTestInfo('TSH', '3016-3', 'Thyroid Stimulating Hormone', 'blood', false),
    LabTestInfo('Free T4', '3024-7', 'Free Thyroxine (T4)', 'blood', false),
    LabTestInfo('Free T3', '3051-0', 'Free Triiodothyronine (T3)', 'blood', false),
    LabTestInfo('Thyroid Panel', '34533-0', 'Thyroid Panel', 'blood', false),
    
    // Liver
    LabTestInfo('Hepatic Panel', '24325-3', 'Hepatic Function Panel', 'blood', false),
    LabTestInfo('ALT', '1742-6', 'Alanine Aminotransferase (ALT)', 'blood', false),
    LabTestInfo('AST', '1920-8', 'Aspartate Aminotransferase (AST)', 'blood', false),
    LabTestInfo('Bilirubin Total', '1975-2', 'Total Bilirubin', 'blood', false),
    
    // Kidney
    LabTestInfo('BUN', '3094-0', 'Blood Urea Nitrogen', 'blood', false),
    LabTestInfo('Creatinine', '2160-0', 'Creatinine', 'blood', false),
    LabTestInfo('eGFR', '33914-3', 'Estimated GFR', 'blood', false),
    
    // Electrolytes
    LabTestInfo('Sodium', '2951-2', 'Sodium', 'blood', false),
    LabTestInfo('Potassium', '2823-3', 'Potassium', 'blood', false),
    LabTestInfo('Chloride', '2075-0', 'Chloride', 'blood', false),
    LabTestInfo('CO2', '2028-9', 'Carbon Dioxide', 'blood', false),
    
    // Iron studies
    LabTestInfo('Iron', '2498-4', 'Serum Iron', 'blood', true),
    LabTestInfo('Ferritin', '2276-4', 'Ferritin', 'blood', false),
    LabTestInfo('TIBC', '2500-7', 'Total Iron Binding Capacity', 'blood', true),
    
    // Vitamins
    LabTestInfo('Vitamin D', '1989-3', 'Vitamin D, 25-Hydroxy', 'blood', false),
    LabTestInfo('Vitamin B12', '2132-9', 'Vitamin B12', 'blood', false),
    LabTestInfo('Folate', '2284-8', 'Folate', 'blood', false),
    
    // Cardiac
    LabTestInfo('Troponin', '6598-7', 'Troponin I', 'blood', false),
    LabTestInfo('BNP', '33762-6', 'B-type Natriuretic Peptide', 'blood', false),
    LabTestInfo('CK-MB', '13969-1', 'Creatine Kinase MB', 'blood', false),
    
    // Inflammatory markers
    LabTestInfo('CRP', '1988-5', 'C-Reactive Protein', 'blood', false),
    LabTestInfo('ESR', '4537-7', 'Erythrocyte Sedimentation Rate', 'blood', false),
    
    // Coagulation
    LabTestInfo('PT/INR', '5902-2', 'Prothrombin Time/INR', 'blood', false),
    LabTestInfo('PTT', '3173-2', 'Partial Thromboplastin Time', 'blood', false),
    
    // Urinalysis
    LabTestInfo('UA', '24356-8', 'Urinalysis Complete', 'urine', false),
    LabTestInfo('Urine Culture', '630-4', 'Urine Culture', 'urine', false),
    
    // STI screening
    LabTestInfo('HIV', '7917-8', 'HIV 1/2 Antibody', 'blood', false),
    LabTestInfo('Hepatitis Panel', '24362-6', 'Hepatitis Panel', 'blood', false),
    LabTestInfo('RPR', '5292-8', 'RPR (Syphilis)', 'blood', false),
    LabTestInfo('Chlamydia/GC', '36903-3', 'Chlamydia/Gonorrhea NAA', 'urine', false),
    
    // Hormones
    LabTestInfo('Testosterone', '2986-8', 'Testosterone Total', 'blood', false),
    LabTestInfo('Estradiol', '2243-4', 'Estradiol', 'blood', false),
    LabTestInfo('FSH', '15067-2', 'Follicle Stimulating Hormone', 'blood', false),
    LabTestInfo('LH', '10501-5', 'Luteinizing Hormone', 'blood', false),
    
    // Drug levels
    LabTestInfo('Lithium', '3719-2', 'Lithium Level', 'blood', false),
    LabTestInfo('Valproic Acid', '4086-5', 'Valproic Acid Level', 'blood', false),
    LabTestInfo('Carbamazepine', '3432-2', 'Carbamazepine Level', 'blood', false),
    
    // Tumor markers
    LabTestInfo('PSA', '2857-1', 'Prostate Specific Antigen', 'blood', false),
    LabTestInfo('CEA', '2039-6', 'Carcinoembryonic Antigen', 'blood', false),
    LabTestInfo('CA-125', '10334-1', 'CA-125 Tumor Marker', 'blood', false),
  ];

  static LabTestInfo? findByCode(String code) {
    try {
      return all.firstWhere((t) => t.loincCode == code);
    } catch (_) {
      return null;
    }
  }

  static LabTestInfo? findByName(String name) {
    try {
      return all.firstWhere((t) => t.name.toLowerCase() == name.toLowerCase());
    } catch (_) {
      return null;
    }
  }

  /// Get tests by specimen type
  static List<LabTestInfo> getBySpecimen(String specimen) {
    return all.where((t) => t.specimenType == specimen.toLowerCase()).toList();
  }

  /// Get fasting tests
  static List<LabTestInfo> get fastingRequired {
    return all.where((t) => t.fastingRequired).toList();
  }
}

/// Lab test information
class LabTestInfo {
  const LabTestInfo(
    this.name,
    this.loincCode,
    this.fullName,
    this.specimenType,
    this.fastingRequired,
  );

  final String name;
  final String loincCode;
  final String fullName;
  final String specimenType;
  final bool fastingRequired;
}

/// Lab order data model
class LabOrderModel {
  const LabOrderModel({
    required this.patientId,
    required this.orderNumber,
    required this.testCodes,
    required this.testNames,
    required this.orderingProvider,
    required this.orderedDate,
    this.id,
    this.encounterId,
    this.orderType = LabOrderType.lab,
    this.diagnosisCodes = const [],
    this.priority = LabPriority.routine,
    this.fasting = 'no',
    this.specialInstructions = '',
    this.labName = '',
    this.labAddress = '',
    this.labPhone = '',
    this.labFax = '',
    this.collectionDate,
    this.collectionSite = '',
    this.specimenType = '',
    this.specimenId = '',
    this.status = LabOrderStatus.pending,
    this.medicalRecordId,
    this.resultedDate,
    this.hasAbnormal = false,
    this.hasCritical = false,
    this.reviewed = false,
    this.reviewedBy = '',
    this.reviewedAt,
    this.notes = '',
    this.createdAt,
  });

  factory LabOrderModel.fromJson(Map<String, dynamic> json) {
    return LabOrderModel(
      id: json['id'] as int?,
      patientId: json['patientId'] as int? ?? json['patient_id'] as int? ?? 0,
      encounterId: json['encounterId'] as int? ?? json['encounter_id'] as int?,
      orderNumber: json['orderNumber'] as String? ?? json['order_number'] as String? ?? '',
      orderType: LabOrderType.fromValue(json['orderType'] as String? ?? json['order_type'] as String? ?? 'lab'),
      testCodes: _parseStringList(json['testCodes'] ?? json['test_codes']),
      testNames: _parseStringList(json['testNames'] ?? json['test_names']),
      diagnosisCodes: _parseStringList(json['diagnosisCodes'] ?? json['diagnosis_codes']),
      orderingProvider: json['orderingProvider'] as String? ?? json['ordering_provider'] as String? ?? '',
      orderedDate: _parseDateTime(json['orderedDate'] ?? json['ordered_date']) ?? DateTime.now(),
      priority: LabPriority.fromValue(json['priority'] as String? ?? 'routine'),
      fasting: json['fasting'] as String? ?? 'no',
      specialInstructions: json['specialInstructions'] as String? ?? json['special_instructions'] as String? ?? '',
      labName: json['labName'] as String? ?? json['lab_name'] as String? ?? '',
      labAddress: json['labAddress'] as String? ?? json['lab_address'] as String? ?? '',
      labPhone: json['labPhone'] as String? ?? json['lab_phone'] as String? ?? '',
      labFax: json['labFax'] as String? ?? json['lab_fax'] as String? ?? '',
      collectionDate: _parseDateTime(json['collectionDate'] ?? json['collection_date']),
      collectionSite: json['collectionSite'] as String? ?? json['collection_site'] as String? ?? '',
      specimenType: json['specimenType'] as String? ?? json['specimen_type'] as String? ?? '',
      specimenId: json['specimenId'] as String? ?? json['specimen_id'] as String? ?? '',
      status: LabOrderStatus.fromValue(json['status'] as String? ?? 'pending'),
      medicalRecordId: json['medicalRecordId'] as int? ?? json['medical_record_id'] as int?,
      resultedDate: _parseDateTime(json['resultedDate'] ?? json['resulted_date']),
      hasAbnormal: json['hasAbnormal'] as bool? ?? json['has_abnormal'] as bool? ?? false,
      hasCritical: json['hasCritical'] as bool? ?? json['has_critical'] as bool? ?? false,
      reviewed: json['reviewed'] as bool? ?? false,
      reviewedBy: json['reviewedBy'] as String? ?? json['reviewed_by'] as String? ?? '',
      reviewedAt: _parseDateTime(json['reviewedAt'] ?? json['reviewed_at']),
      notes: json['notes'] as String? ?? '',
      createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']),
    );
  }

  final int? id;
  final int patientId;
  final int? encounterId;
  final String orderNumber;
  final LabOrderType orderType;
  final List<String> testCodes;
  final List<String> testNames;
  final List<String> diagnosisCodes;
  final String orderingProvider;
  final DateTime orderedDate;
  final LabPriority priority;
  final String fasting;
  final String specialInstructions;
  final String labName;
  final String labAddress;
  final String labPhone;
  final String labFax;
  final DateTime? collectionDate;
  final String collectionSite;
  final String specimenType;
  final String specimenId;
  final LabOrderStatus status;
  final int? medicalRecordId;
  final DateTime? resultedDate;
  final bool hasAbnormal;
  final bool hasCritical;
  final bool reviewed;
  final String reviewedBy;
  final DateTime? reviewedAt;
  final String notes;
  final DateTime? createdAt;

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'patientId': patientId,
      'encounterId': encounterId,
      'orderNumber': orderNumber,
      'orderType': orderType.value,
      'testCodes': jsonEncode(testCodes),
      'testNames': jsonEncode(testNames),
      'diagnosisCodes': jsonEncode(diagnosisCodes),
      'orderingProvider': orderingProvider,
      'orderedDate': orderedDate.toIso8601String(),
      'priority': priority.value,
      'fasting': fasting,
      'specialInstructions': specialInstructions,
      'labName': labName,
      'labAddress': labAddress,
      'labPhone': labPhone,
      'labFax': labFax,
      'collectionDate': collectionDate?.toIso8601String(),
      'collectionSite': collectionSite,
      'specimenType': specimenType,
      'specimenId': specimenId,
      'status': status.value,
      'medicalRecordId': medicalRecordId,
      'resultedDate': resultedDate?.toIso8601String(),
      'hasAbnormal': hasAbnormal,
      'hasCritical': hasCritical,
      'reviewed': reviewed,
      'reviewedBy': reviewedBy,
      'reviewedAt': reviewedAt?.toIso8601String(),
      'notes': notes,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  LabOrderModel copyWith({
    int? id,
    int? patientId,
    int? encounterId,
    String? orderNumber,
    LabOrderType? orderType,
    List<String>? testCodes,
    List<String>? testNames,
    List<String>? diagnosisCodes,
    String? orderingProvider,
    DateTime? orderedDate,
    LabPriority? priority,
    String? fasting,
    String? specialInstructions,
    String? labName,
    String? labAddress,
    String? labPhone,
    String? labFax,
    DateTime? collectionDate,
    String? collectionSite,
    String? specimenType,
    String? specimenId,
    LabOrderStatus? status,
    int? medicalRecordId,
    DateTime? resultedDate,
    bool? hasAbnormal,
    bool? hasCritical,
    bool? reviewed,
    String? reviewedBy,
    DateTime? reviewedAt,
    String? notes,
    DateTime? createdAt,
  }) {
    return LabOrderModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      encounterId: encounterId ?? this.encounterId,
      orderNumber: orderNumber ?? this.orderNumber,
      orderType: orderType ?? this.orderType,
      testCodes: testCodes ?? this.testCodes,
      testNames: testNames ?? this.testNames,
      diagnosisCodes: diagnosisCodes ?? this.diagnosisCodes,
      orderingProvider: orderingProvider ?? this.orderingProvider,
      orderedDate: orderedDate ?? this.orderedDate,
      priority: priority ?? this.priority,
      fasting: fasting ?? this.fasting,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      labName: labName ?? this.labName,
      labAddress: labAddress ?? this.labAddress,
      labPhone: labPhone ?? this.labPhone,
      labFax: labFax ?? this.labFax,
      collectionDate: collectionDate ?? this.collectionDate,
      collectionSite: collectionSite ?? this.collectionSite,
      specimenType: specimenType ?? this.specimenType,
      specimenId: specimenId ?? this.specimenId,
      status: status ?? this.status,
      medicalRecordId: medicalRecordId ?? this.medicalRecordId,
      resultedDate: resultedDate ?? this.resultedDate,
      hasAbnormal: hasAbnormal ?? this.hasAbnormal,
      hasCritical: hasCritical ?? this.hasCritical,
      reviewed: reviewed ?? this.reviewed,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Check if order is pending collection
  bool get isPendingCollection => status == LabOrderStatus.pending || status == LabOrderStatus.sent;

  /// Check if order has results
  bool get hasResults => status == LabOrderStatus.resulted && resultedDate != null;

  /// Check if results need review
  bool get needsReview => hasResults && !reviewed;

  /// Check if fasting is required
  bool get isFastingRequired => fasting == 'yes';

  /// Get all test display names
  String get testsDisplay => testNames.join(', ');

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.cast<String>();
    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) return decoded.cast<String>();
      } catch (_) {}
    }
    return [];
  }
}
