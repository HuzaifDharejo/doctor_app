/// Immunization status
enum ImmunizationStatus {
  scheduled('scheduled', 'Scheduled'),
  completed('completed', 'Completed'),
  refused('refused', 'Refused'),
  contraindicated('contraindicated', 'Contraindicated'),
  deferred('deferred', 'Deferred');

  const ImmunizationStatus(this.value, this.label);
  final String value;
  final String label;

  static ImmunizationStatus fromValue(String value) {
    return ImmunizationStatus.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => ImmunizationStatus.completed,
    );
  }
}

/// Common routes of administration
enum VaccineRoute {
  im('IM', 'Intramuscular'),
  sc('SC', 'Subcutaneous'),
  po('PO', 'Oral'),
  intranasal('IN', 'Intranasal'),
  id('ID', 'Intradermal');

  const VaccineRoute(this.value, this.label);
  final String value;
  final String label;

  static VaccineRoute fromValue(String value) {
    return VaccineRoute.values.firstWhere(
      (e) => e.value == value.toUpperCase(),
      orElse: () => VaccineRoute.im,
    );
  }
}

/// Common vaccines with CVX codes
class CommonVaccines {
  static const List<VaccineInfo> all = [
    VaccineInfo('COVID-19', '207', 'COVID-19 mRNA', 2),
    VaccineInfo('Influenza', '141', 'Influenza (Flu)', 1),
    VaccineInfo('Tdap', '115', 'Tetanus, Diphtheria, Pertussis', 1),
    VaccineInfo('Td', '09', 'Tetanus, Diphtheria', 1),
    VaccineInfo('MMR', '03', 'Measles, Mumps, Rubella', 2),
    VaccineInfo('Varicella', '21', 'Chickenpox', 2),
    VaccineInfo('Hepatitis A', '83', 'Hepatitis A', 2),
    VaccineInfo('Hepatitis B', '08', 'Hepatitis B', 3),
    VaccineInfo('HPV', '165', 'Human Papillomavirus', 3),
    VaccineInfo('Meningococcal', '136', 'Meningococcal (MenACWY)', 2),
    VaccineInfo('Pneumococcal', '133', 'Pneumococcal (PCV13)', 4),
    VaccineInfo('PPSV23', '33', 'Pneumococcal (PPSV23)', 2),
    VaccineInfo('Shingles', '187', 'Shingrix (Herpes Zoster)', 2),
    VaccineInfo('Polio', '10', 'Inactivated Poliovirus (IPV)', 4),
    VaccineInfo('Rotavirus', '119', 'Rotavirus', 3),
    VaccineInfo('DTaP', '20', 'Diphtheria, Tetanus, Pertussis (childhood)', 5),
    VaccineInfo('Hib', '17', 'Haemophilus influenzae type b', 4),
    VaccineInfo('RSV', '305', 'Respiratory Syncytial Virus', 1),
  ];

  static VaccineInfo? findByName(String name) {
    try {
      return all.firstWhere(
        (v) => v.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }
}

/// Vaccine information
class VaccineInfo {
  const VaccineInfo(this.name, this.cvxCode, this.fullName, this.seriesTotal);
  final String name;
  final String cvxCode;
  final String fullName;
  final int seriesTotal;
}

/// Immunization data model
class ImmunizationModel {
  const ImmunizationModel({
    required this.patientId,
    required this.vaccineName,
    required this.administeredDate,
    this.id,
    this.encounterId,
    this.vaccineCode = '',
    this.manufacturer = '',
    this.lotNumber = '',
    this.expirationDate,
    this.administeredBy = '',
    this.administrationSite = '',
    this.route = VaccineRoute.im,
    this.dose = '',
    this.doseNumber = 1,
    this.seriesTotal,
    this.status = ImmunizationStatus.completed,
    this.refusalReason = '',
    this.contraindication = '',
    this.hadReaction = false,
    this.reactionDetails = '',
    this.reactionSeverity = '',
    this.nextDoseDate,
    this.reminderSent = false,
    this.notes = '',
    this.createdAt,
  });

  factory ImmunizationModel.fromJson(Map<String, dynamic> json) {
    return ImmunizationModel(
      id: json['id'] as int?,
      patientId: json['patientId'] as int? ?? json['patient_id'] as int? ?? 0,
      encounterId: json['encounterId'] as int? ?? json['encounter_id'] as int?,
      vaccineName: json['vaccineName'] as String? ?? json['vaccine_name'] as String? ?? '',
      vaccineCode: json['vaccineCode'] as String? ?? json['vaccine_code'] as String? ?? '',
      manufacturer: json['manufacturer'] as String? ?? '',
      lotNumber: json['lotNumber'] as String? ?? json['lot_number'] as String? ?? '',
      expirationDate: _parseDateTime(json['expirationDate'] ?? json['expiration_date']),
      administeredDate: _parseDateTime(json['administeredDate'] ?? json['administered_date']) ?? DateTime.now(),
      administeredBy: json['administeredBy'] as String? ?? json['administered_by'] as String? ?? '',
      administrationSite: json['administrationSite'] as String? ?? json['administration_site'] as String? ?? '',
      route: VaccineRoute.fromValue(json['route'] as String? ?? 'IM'),
      dose: json['dose'] as String? ?? '',
      doseNumber: json['doseNumber'] as int? ?? json['dose_number'] as int? ?? 1,
      seriesTotal: json['seriesTotal'] as int? ?? json['series_total'] as int?,
      status: ImmunizationStatus.fromValue(json['status'] as String? ?? 'completed'),
      refusalReason: json['refusalReason'] as String? ?? json['refusal_reason'] as String? ?? '',
      contraindication: json['contraindication'] as String? ?? '',
      hadReaction: json['hadReaction'] as bool? ?? json['had_reaction'] as bool? ?? false,
      reactionDetails: json['reactionDetails'] as String? ?? json['reaction_details'] as String? ?? '',
      reactionSeverity: json['reactionSeverity'] as String? ?? json['reaction_severity'] as String? ?? '',
      nextDoseDate: _parseDateTime(json['nextDoseDate'] ?? json['next_dose_date']),
      reminderSent: json['reminderSent'] as bool? ?? json['reminder_sent'] as bool? ?? false,
      notes: json['notes'] as String? ?? '',
      createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']),
    );
  }

  final int? id;
  final int patientId;
  final int? encounterId;
  final String vaccineName;
  final String vaccineCode;
  final String manufacturer;
  final String lotNumber;
  final DateTime? expirationDate;
  final DateTime administeredDate;
  final String administeredBy;
  final String administrationSite;
  final VaccineRoute route;
  final String dose;
  final int doseNumber;
  final int? seriesTotal;
  final ImmunizationStatus status;
  final String refusalReason;
  final String contraindication;
  final bool hadReaction;
  final String reactionDetails;
  final String reactionSeverity;
  final DateTime? nextDoseDate;
  final bool reminderSent;
  final String notes;
  final DateTime? createdAt;

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'patientId': patientId,
      'encounterId': encounterId,
      'vaccineName': vaccineName,
      'vaccineCode': vaccineCode,
      'manufacturer': manufacturer,
      'lotNumber': lotNumber,
      'expirationDate': expirationDate?.toIso8601String(),
      'administeredDate': administeredDate.toIso8601String(),
      'administeredBy': administeredBy,
      'administrationSite': administrationSite,
      'route': route.value,
      'dose': dose,
      'doseNumber': doseNumber,
      'seriesTotal': seriesTotal,
      'status': status.value,
      'refusalReason': refusalReason,
      'contraindication': contraindication,
      'hadReaction': hadReaction,
      'reactionDetails': reactionDetails,
      'reactionSeverity': reactionSeverity,
      'nextDoseDate': nextDoseDate?.toIso8601String(),
      'reminderSent': reminderSent,
      'notes': notes,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  ImmunizationModel copyWith({
    int? id,
    int? patientId,
    int? encounterId,
    String? vaccineName,
    String? vaccineCode,
    String? manufacturer,
    String? lotNumber,
    DateTime? expirationDate,
    DateTime? administeredDate,
    String? administeredBy,
    String? administrationSite,
    VaccineRoute? route,
    String? dose,
    int? doseNumber,
    int? seriesTotal,
    ImmunizationStatus? status,
    String? refusalReason,
    String? contraindication,
    bool? hadReaction,
    String? reactionDetails,
    String? reactionSeverity,
    DateTime? nextDoseDate,
    bool? reminderSent,
    String? notes,
    DateTime? createdAt,
  }) {
    return ImmunizationModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      encounterId: encounterId ?? this.encounterId,
      vaccineName: vaccineName ?? this.vaccineName,
      vaccineCode: vaccineCode ?? this.vaccineCode,
      manufacturer: manufacturer ?? this.manufacturer,
      lotNumber: lotNumber ?? this.lotNumber,
      expirationDate: expirationDate ?? this.expirationDate,
      administeredDate: administeredDate ?? this.administeredDate,
      administeredBy: administeredBy ?? this.administeredBy,
      administrationSite: administrationSite ?? this.administrationSite,
      route: route ?? this.route,
      dose: dose ?? this.dose,
      doseNumber: doseNumber ?? this.doseNumber,
      seriesTotal: seriesTotal ?? this.seriesTotal,
      status: status ?? this.status,
      refusalReason: refusalReason ?? this.refusalReason,
      contraindication: contraindication ?? this.contraindication,
      hadReaction: hadReaction ?? this.hadReaction,
      reactionDetails: reactionDetails ?? this.reactionDetails,
      reactionSeverity: reactionSeverity ?? this.reactionSeverity,
      nextDoseDate: nextDoseDate ?? this.nextDoseDate,
      reminderSent: reminderSent ?? this.reminderSent,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Check if series is complete
  bool get isSeriesComplete {
    if (seriesTotal == null) return true;
    return doseNumber >= seriesTotal!;
  }

  /// Check if next dose is overdue
  bool get isNextDoseOverdue {
    if (nextDoseDate == null) return false;
    return DateTime.now().isAfter(nextDoseDate!);
  }

  /// Get dose display string
  String get doseDisplay {
    if (seriesTotal != null) {
      return 'Dose $doseNumber of $seriesTotal';
    }
    return 'Dose $doseNumber';
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

/// Immunization schedule recommendation
class ImmunizationSchedule {
  const ImmunizationSchedule({
    required this.vaccineName,
    required this.recommendedAge,
    this.ageMonths,
    this.catchUpAge,
    this.notes = '',
  });

  final String vaccineName;
  final String recommendedAge;
  final int? ageMonths;
  final String? catchUpAge;
  final String notes;

  /// Standard CDC childhood immunization schedule
  static const List<ImmunizationSchedule> childhoodSchedule = [
    ImmunizationSchedule(vaccineName: 'Hepatitis B', recommendedAge: 'Birth', ageMonths: 0),
    ImmunizationSchedule(vaccineName: 'Hepatitis B', recommendedAge: '1-2 months', ageMonths: 1),
    ImmunizationSchedule(vaccineName: 'DTaP', recommendedAge: '2 months', ageMonths: 2),
    ImmunizationSchedule(vaccineName: 'Hib', recommendedAge: '2 months', ageMonths: 2),
    ImmunizationSchedule(vaccineName: 'Polio', recommendedAge: '2 months', ageMonths: 2),
    ImmunizationSchedule(vaccineName: 'Pneumococcal', recommendedAge: '2 months', ageMonths: 2),
    ImmunizationSchedule(vaccineName: 'Rotavirus', recommendedAge: '2 months', ageMonths: 2),
    ImmunizationSchedule(vaccineName: 'DTaP', recommendedAge: '4 months', ageMonths: 4),
    ImmunizationSchedule(vaccineName: 'Hib', recommendedAge: '4 months', ageMonths: 4),
    ImmunizationSchedule(vaccineName: 'Polio', recommendedAge: '4 months', ageMonths: 4),
    ImmunizationSchedule(vaccineName: 'Pneumococcal', recommendedAge: '4 months', ageMonths: 4),
    ImmunizationSchedule(vaccineName: 'Rotavirus', recommendedAge: '4 months', ageMonths: 4),
    ImmunizationSchedule(vaccineName: 'DTaP', recommendedAge: '6 months', ageMonths: 6),
    ImmunizationSchedule(vaccineName: 'Hepatitis B', recommendedAge: '6-18 months', ageMonths: 6),
    ImmunizationSchedule(vaccineName: 'Polio', recommendedAge: '6-18 months', ageMonths: 6),
    ImmunizationSchedule(vaccineName: 'Influenza', recommendedAge: '6 months annually', ageMonths: 6),
    ImmunizationSchedule(vaccineName: 'MMR', recommendedAge: '12-15 months', ageMonths: 12),
    ImmunizationSchedule(vaccineName: 'Varicella', recommendedAge: '12-15 months', ageMonths: 12),
    ImmunizationSchedule(vaccineName: 'Hepatitis A', recommendedAge: '12-23 months', ageMonths: 12),
    ImmunizationSchedule(vaccineName: 'DTaP', recommendedAge: '15-18 months', ageMonths: 15),
    ImmunizationSchedule(vaccineName: 'DTaP', recommendedAge: '4-6 years', ageMonths: 48),
    ImmunizationSchedule(vaccineName: 'Polio', recommendedAge: '4-6 years', ageMonths: 48),
    ImmunizationSchedule(vaccineName: 'MMR', recommendedAge: '4-6 years', ageMonths: 48),
    ImmunizationSchedule(vaccineName: 'Varicella', recommendedAge: '4-6 years', ageMonths: 48),
    ImmunizationSchedule(vaccineName: 'Tdap', recommendedAge: '11-12 years', ageMonths: 132),
    ImmunizationSchedule(vaccineName: 'HPV', recommendedAge: '11-12 years', ageMonths: 132),
    ImmunizationSchedule(vaccineName: 'Meningococcal', recommendedAge: '11-12 years', ageMonths: 132),
    ImmunizationSchedule(vaccineName: 'Meningococcal', recommendedAge: '16 years', ageMonths: 192),
  ];

  /// Standard adult immunization recommendations
  static const List<ImmunizationSchedule> adultSchedule = [
    ImmunizationSchedule(vaccineName: 'Influenza', recommendedAge: 'Annually', notes: 'For all adults'),
    ImmunizationSchedule(vaccineName: 'Td/Tdap', recommendedAge: 'Every 10 years', notes: 'Tdap once, then Td boosters'),
    ImmunizationSchedule(vaccineName: 'Shingles', recommendedAge: '50+ years', notes: '2 doses of Shingrix'),
    ImmunizationSchedule(vaccineName: 'PPSV23', recommendedAge: '65+ years', notes: 'Pneumococcal'),
    ImmunizationSchedule(vaccineName: 'COVID-19', recommendedAge: 'As recommended', notes: 'Follow current CDC guidance'),
    ImmunizationSchedule(vaccineName: 'RSV', recommendedAge: '60+ years', notes: 'Single dose'),
  ];
}
