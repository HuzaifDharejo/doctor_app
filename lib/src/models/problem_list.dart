/// Problem status
enum ProblemStatus {
  active('active', 'Active'),
  chronic('chronic', 'Chronic'),
  resolved('resolved', 'Resolved'),
  inactive('inactive', 'Inactive'),
  ruledOut('ruled_out', 'Ruled Out');

  const ProblemStatus(this.value, this.label);
  final String value;
  final String label;

  static ProblemStatus fromValue(String value) {
    return ProblemStatus.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => ProblemStatus.active,
    );
  }
}

/// Problem severity
enum ProblemSeverity {
  mild('mild', 'Mild'),
  moderate('moderate', 'Moderate'),
  severe('severe', 'Severe'),
  lifeThreatening('life_threatening', 'Life Threatening');

  const ProblemSeverity(this.value, this.label);
  final String value;
  final String label;

  static ProblemSeverity fromValue(String value) {
    return ProblemSeverity.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => ProblemSeverity.moderate,
    );
  }
}

/// Problem category
enum ProblemCategory {
  medical('medical', 'Medical'),
  surgical('surgical', 'Surgical'),
  psychiatric('psychiatric', 'Psychiatric'),
  social('social', 'Social'),
  functional('functional', 'Functional');

  const ProblemCategory(this.value, this.label);
  final String value;
  final String label;

  static ProblemCategory fromValue(String value) {
    return ProblemCategory.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => ProblemCategory.medical,
    );
  }
}

/// Clinical status for diagnosis certainty
enum ClinicalStatus {
  confirmed('confirmed', 'Confirmed'),
  provisional('provisional', 'Provisional'),
  differential('differential', 'Differential'),
  ruleOut('rule_out', 'Rule Out');

  const ClinicalStatus(this.value, this.label);
  final String value;
  final String label;

  static ClinicalStatus fromValue(String value) {
    return ClinicalStatus.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => ClinicalStatus.confirmed,
    );
  }
}

/// Problem list item data model
class ProblemModel {
  const ProblemModel({
    required this.patientId,
    required this.problemName,
    this.id,
    this.diagnosisId,
    this.icdCode = '',
    this.snomedCode = '',
    this.category = ProblemCategory.medical,
    this.status = ProblemStatus.active,
    this.severity = ProblemSeverity.moderate,
    this.clinicalStatus = ClinicalStatus.confirmed,
    this.priority = 5,
    this.onsetDate,
    this.diagnosedDate,
    this.resolvedDate,
    this.lastReviewedDate,
    this.treatmentGoal = '',
    this.currentTreatment = '',
    this.isChiefConcern = false,
    this.notes = '',
    this.createdAt,
    this.updatedAt,
  });

  factory ProblemModel.fromJson(Map<String, dynamic> json) {
    return ProblemModel(
      id: json['id'] as int?,
      patientId: json['patientId'] as int? ?? json['patient_id'] as int? ?? 0,
      diagnosisId: json['diagnosisId'] as int? ?? json['diagnosis_id'] as int?,
      problemName: json['problemName'] as String? ?? json['problem_name'] as String? ?? '',
      icdCode: json['icdCode'] as String? ?? json['icd_code'] as String? ?? '',
      snomedCode: json['snomedCode'] as String? ?? json['snomed_code'] as String? ?? '',
      category: ProblemCategory.fromValue(json['category'] as String? ?? 'medical'),
      status: ProblemStatus.fromValue(json['status'] as String? ?? 'active'),
      severity: ProblemSeverity.fromValue(json['severity'] as String? ?? 'moderate'),
      clinicalStatus: ClinicalStatus.fromValue(json['clinicalStatus'] as String? ?? json['clinical_status'] as String? ?? 'confirmed'),
      priority: json['priority'] as int? ?? 5,
      onsetDate: _parseDateTime(json['onsetDate'] ?? json['onset_date']),
      diagnosedDate: _parseDateTime(json['diagnosedDate'] ?? json['diagnosed_date']),
      resolvedDate: _parseDateTime(json['resolvedDate'] ?? json['resolved_date']),
      lastReviewedDate: _parseDateTime(json['lastReviewedDate'] ?? json['last_reviewed_date']),
      treatmentGoal: json['treatmentGoal'] as String? ?? json['treatment_goal'] as String? ?? '',
      currentTreatment: json['currentTreatment'] as String? ?? json['current_treatment'] as String? ?? '',
      isChiefConcern: json['isChiefConcern'] as bool? ?? json['is_chief_concern'] as bool? ?? false,
      notes: json['notes'] as String? ?? '',
      createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']),
      updatedAt: _parseDateTime(json['updatedAt'] ?? json['updated_at']),
    );
  }

  final int? id;
  final int patientId;
  final int? diagnosisId;
  final String problemName;
  final String icdCode;
  final String snomedCode;
  final ProblemCategory category;
  final ProblemStatus status;
  final ProblemSeverity severity;
  final ClinicalStatus clinicalStatus;
  final int priority;
  final DateTime? onsetDate;
  final DateTime? diagnosedDate;
  final DateTime? resolvedDate;
  final DateTime? lastReviewedDate;
  final String treatmentGoal;
  final String currentTreatment;
  final bool isChiefConcern;
  final String notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'patientId': patientId,
      'diagnosisId': diagnosisId,
      'problemName': problemName,
      'icdCode': icdCode,
      'snomedCode': snomedCode,
      'category': category.value,
      'status': status.value,
      'severity': severity.value,
      'clinicalStatus': clinicalStatus.value,
      'priority': priority,
      'onsetDate': onsetDate?.toIso8601String(),
      'diagnosedDate': diagnosedDate?.toIso8601String(),
      'resolvedDate': resolvedDate?.toIso8601String(),
      'lastReviewedDate': lastReviewedDate?.toIso8601String(),
      'treatmentGoal': treatmentGoal,
      'currentTreatment': currentTreatment,
      'isChiefConcern': isChiefConcern,
      'notes': notes,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  ProblemModel copyWith({
    int? id,
    int? patientId,
    int? diagnosisId,
    String? problemName,
    String? icdCode,
    String? snomedCode,
    ProblemCategory? category,
    ProblemStatus? status,
    ProblemSeverity? severity,
    ClinicalStatus? clinicalStatus,
    int? priority,
    DateTime? onsetDate,
    DateTime? diagnosedDate,
    DateTime? resolvedDate,
    DateTime? lastReviewedDate,
    String? treatmentGoal,
    String? currentTreatment,
    bool? isChiefConcern,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProblemModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      diagnosisId: diagnosisId ?? this.diagnosisId,
      problemName: problemName ?? this.problemName,
      icdCode: icdCode ?? this.icdCode,
      snomedCode: snomedCode ?? this.snomedCode,
      category: category ?? this.category,
      status: status ?? this.status,
      severity: severity ?? this.severity,
      clinicalStatus: clinicalStatus ?? this.clinicalStatus,
      priority: priority ?? this.priority,
      onsetDate: onsetDate ?? this.onsetDate,
      diagnosedDate: diagnosedDate ?? this.diagnosedDate,
      resolvedDate: resolvedDate ?? this.resolvedDate,
      lastReviewedDate: lastReviewedDate ?? this.lastReviewedDate,
      treatmentGoal: treatmentGoal ?? this.treatmentGoal,
      currentTreatment: currentTreatment ?? this.currentTreatment,
      isChiefConcern: isChiefConcern ?? this.isChiefConcern,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if problem is currently active
  bool get isActive => status == ProblemStatus.active || status == ProblemStatus.chronic;

  /// Check if problem needs review (not reviewed in last 90 days)
  bool get needsReview {
    if (lastReviewedDate == null) return true;
    return DateTime.now().difference(lastReviewedDate!).inDays > 90;
  }

  /// Get duration of problem
  Duration? get duration {
    if (onsetDate == null) return null;
    final endDate = resolvedDate ?? DateTime.now();
    return endDate.difference(onsetDate!);
  }

  /// Get duration in human-readable format
  String get durationDisplay {
    final d = duration;
    if (d == null) return 'Unknown';
    
    if (d.inDays > 365) {
      final years = d.inDays ~/ 365;
      return '$years year${years > 1 ? 's' : ''}';
    } else if (d.inDays > 30) {
      final months = d.inDays ~/ 30;
      return '$months month${months > 1 ? 's' : ''}';
    } else if (d.inDays > 0) {
      return '${d.inDays} day${d.inDays > 1 ? 's' : ''}';
    } else {
      return 'Today';
    }
  }

  /// Get display text with ICD code
  String get displayWithCode {
    if (icdCode.isNotEmpty) {
      return '$problemName ($icdCode)';
    }
    return problemName;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

/// Problem list summary for a patient
class ProblemListSummary {
  const ProblemListSummary({
    required this.patientId,
    required this.problems,
  });

  final int patientId;
  final List<ProblemModel> problems;

  /// Get active problems
  List<ProblemModel> get activeProblems =>
      problems.where((p) => p.isActive).toList()
        ..sort((a, b) => a.priority.compareTo(b.priority));

  /// Get chronic problems
  List<ProblemModel> get chronicProblems =>
      problems.where((p) => p.status == ProblemStatus.chronic).toList();

  /// Get resolved problems
  List<ProblemModel> get resolvedProblems =>
      problems.where((p) => p.status == ProblemStatus.resolved).toList();

  /// Get problems by category
  List<ProblemModel> getByCategory(ProblemCategory category) =>
      problems.where((p) => p.category == category && p.isActive).toList();

  /// Get high priority problems
  List<ProblemModel> get highPriorityProblems =>
      activeProblems.where((p) => p.priority <= 3).toList();

  /// Get problems needing review
  List<ProblemModel> get problemsNeedingReview =>
      activeProblems.where((p) => p.needsReview).toList();

  /// Get chief concerns
  List<ProblemModel> get chiefConcerns =>
      problems.where((p) => p.isChiefConcern && p.isActive).toList();

  /// Get all ICD codes for active problems
  List<String> get activeIcdCodes =>
      activeProblems.where((p) => p.icdCode.isNotEmpty).map((p) => p.icdCode).toList();

  /// Check if patient has specific condition
  bool hasCondition(String condition) {
    final lowerCondition = condition.toLowerCase();
    return problems.any((p) => 
      p.isActive && 
      (p.problemName.toLowerCase().contains(lowerCondition) ||
       p.icdCode.toLowerCase().contains(lowerCondition))
    );
  }

  /// Get problem count by category
  Map<ProblemCategory, int> get countByCategory {
    final counts = <ProblemCategory, int>{};
    for (final category in ProblemCategory.values) {
      counts[category] = getByCategory(category).length;
    }
    return counts;
  }
}
