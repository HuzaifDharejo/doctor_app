/// Configuration for PDF prescription templates
class PdfTemplateConfig {
  PdfTemplateConfig({
    this.templateType = 'custom', // 'custom', 'standard'
    this.showHeader = true,
    this.showPatientName = true,
    this.showMrNumber = false,
    this.showAge = true,
    this.showOccupation = false,
    this.showAddress = true,
    this.showHistory = true,
    this.showImpressionDiagnosis = true,
    this.showLabsInvestigations = true,
    this.showRadiology = false,
    this.showNextVisitDate = true,
    this.showFooter = true,
    this.headerLayout = 'default', // 'default', 'custom'
    this.footerLayout = 'default',
    this.clinicAddressLine1 = '',
    this.clinicAddressLine2 = '',
    this.clinicPhone1 = '',
    this.clinicPhone2 = '',
    this.clinicHours = '',
    this.showExpertInDiseases = false,
    this.expertInDiseases = '',
    this.showWorkingExperience = false,
    this.workingExperience = '',
    this.logoData,
    this.backgroundImageType = 'none',
    this.customBackgroundData,
    this.sectionLabels, // Maps section type to label text (e.g., {'lab_tests': 'Labs/Investigations:'})
  });

  final String templateType;
  final bool showHeader;
  final bool showPatientName;
  final bool showMrNumber;
  final bool showAge;
  final bool showOccupation;
  final bool showAddress;
  final bool showHistory;
  final bool showImpressionDiagnosis;
  final bool showLabsInvestigations;
  final bool showRadiology;
  final bool showNextVisitDate;
  final bool showFooter;
  final String headerLayout;
  final String footerLayout;
  final String clinicAddressLine1;
  final String clinicAddressLine2;
  final String clinicPhone1;
  final String clinicPhone2;
  final String clinicHours;
  final bool showExpertInDiseases;
  final String expertInDiseases;
  final bool showWorkingExperience;
  final String workingExperience;
  final String? logoData; // Base64 encoded logo image
  final String backgroundImageType; // 'none', 'lungs', 'heart', 'brain', 'xray', 'custom'
  final String? customBackgroundData; // Base64 encoded custom background image
  final Map<String, String>? sectionLabels; // Maps section type to label text (e.g., {'lab_tests': 'Labs/Investigations:'})

  /// Default template matching Dr. Farzand Ali's format
  factory PdfTemplateConfig.defaultFarzandAliTemplate() {
    return PdfTemplateConfig(
      templateType: 'custom',
      showHeader: true,
      showPatientName: true,
      showMrNumber: true,
      showAge: true,
      showOccupation: true,
      showAddress: true,
      showHistory: true,
      showImpressionDiagnosis: true,
      showLabsInvestigations: true,
      showRadiology: true,
      showNextVisitDate: true,
      showFooter: true,
      headerLayout: 'custom',
      footerLayout: 'custom',
      showExpertInDiseases: true,
      showWorkingExperience: true,
    );
  }

  /// Standard template (simpler version)
  factory PdfTemplateConfig.standardTemplate() {
    return PdfTemplateConfig(
      templateType: 'standard',
      showHeader: true,
      showPatientName: true,
      showAge: true,
      showAddress: true,
      showHistory: true,
      showImpressionDiagnosis: true,
      showNextVisitDate: true,
      showFooter: true,
    );
  }

  factory PdfTemplateConfig.fromJson(Map<String, dynamic> json) {
    return PdfTemplateConfig(
      templateType: (json['templateType'] as String?) ?? 'custom',
      showHeader: (json['showHeader'] as bool?) ?? true,
      showPatientName: (json['showPatientName'] as bool?) ?? true,
      showMrNumber: (json['showMrNumber'] as bool?) ?? false,
      showAge: (json['showAge'] as bool?) ?? true,
      showOccupation: (json['showOccupation'] as bool?) ?? false,
      showAddress: (json['showAddress'] as bool?) ?? true,
      showHistory: (json['showHistory'] as bool?) ?? true,
      showImpressionDiagnosis: (json['showImpressionDiagnosis'] as bool?) ?? true,
      showLabsInvestigations: (json['showLabsInvestigations'] as bool?) ?? true,
      showRadiology: (json['showRadiology'] as bool?) ?? false,
      showNextVisitDate: (json['showNextVisitDate'] as bool?) ?? true,
      showFooter: (json['showFooter'] as bool?) ?? true,
      headerLayout: (json['headerLayout'] as String?) ?? 'default',
      footerLayout: (json['footerLayout'] as String?) ?? 'default',
      clinicAddressLine1: (json['clinicAddressLine1'] as String?) ?? '',
      clinicAddressLine2: (json['clinicAddressLine2'] as String?) ?? '',
      clinicPhone1: (json['clinicPhone1'] as String?) ?? '',
      clinicPhone2: (json['clinicPhone2'] as String?) ?? '',
      clinicHours: (json['clinicHours'] as String?) ?? '',
      showExpertInDiseases: (json['showExpertInDiseases'] as bool?) ?? false,
      expertInDiseases: (json['expertInDiseases'] as String?) ?? '',
      showWorkingExperience: (json['showWorkingExperience'] as bool?) ?? false,
      workingExperience: (json['workingExperience'] as String?) ?? '',
      logoData: json['logoData'] as String?,
      backgroundImageType: (json['backgroundImageType'] as String?) ?? 'none',
      customBackgroundData: json['customBackgroundData'] as String?,
      sectionLabels: json['sectionLabels'] != null 
          ? Map<String, String>.from(json['sectionLabels'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'templateType': templateType,
      'showHeader': showHeader,
      'showPatientName': showPatientName,
      'showMrNumber': showMrNumber,
      'showAge': showAge,
      'showOccupation': showOccupation,
      'showAddress': showAddress,
      'showHistory': showHistory,
      'showImpressionDiagnosis': showImpressionDiagnosis,
      'showLabsInvestigations': showLabsInvestigations,
      'showRadiology': showRadiology,
      'showNextVisitDate': showNextVisitDate,
      'showFooter': showFooter,
      'headerLayout': headerLayout,
      'footerLayout': footerLayout,
      'clinicAddressLine1': clinicAddressLine1,
      'clinicAddressLine2': clinicAddressLine2,
      'clinicPhone1': clinicPhone1,
      'clinicPhone2': clinicPhone2,
      'clinicHours': clinicHours,
      'showExpertInDiseases': showExpertInDiseases,
      'expertInDiseases': expertInDiseases,
      'showWorkingExperience': showWorkingExperience,
      'workingExperience': workingExperience,
      'logoData': logoData,
      'backgroundImageType': backgroundImageType,
      'customBackgroundData': customBackgroundData,
      'sectionLabels': sectionLabels,
    };
  }

  PdfTemplateConfig copyWith({
    String? templateType,
    bool? showHeader,
    bool? showPatientName,
    bool? showMrNumber,
    bool? showAge,
    bool? showOccupation,
    bool? showAddress,
    bool? showHistory,
    bool? showImpressionDiagnosis,
    bool? showLabsInvestigations,
    bool? showRadiology,
    bool? showNextVisitDate,
    bool? showFooter,
    String? headerLayout,
    String? footerLayout,
    String? clinicAddressLine1,
    String? clinicAddressLine2,
    String? clinicPhone1,
    String? clinicPhone2,
    String? clinicHours,
    bool? showExpertInDiseases,
    String? expertInDiseases,
    bool? showWorkingExperience,
    String? workingExperience,
    String? logoData,
    String? backgroundImageType,
    String? customBackgroundData,
    Map<String, String>? sectionLabels,
  }) {
    return PdfTemplateConfig(
      templateType: templateType ?? this.templateType,
      showHeader: showHeader ?? this.showHeader,
      showPatientName: showPatientName ?? this.showPatientName,
      showMrNumber: showMrNumber ?? this.showMrNumber,
      showAge: showAge ?? this.showAge,
      showOccupation: showOccupation ?? this.showOccupation,
      showAddress: showAddress ?? this.showAddress,
      showHistory: showHistory ?? this.showHistory,
      showImpressionDiagnosis: showImpressionDiagnosis ?? this.showImpressionDiagnosis,
      showLabsInvestigations: showLabsInvestigations ?? this.showLabsInvestigations,
      showRadiology: showRadiology ?? this.showRadiology,
      showNextVisitDate: showNextVisitDate ?? this.showNextVisitDate,
      showFooter: showFooter ?? this.showFooter,
      headerLayout: headerLayout ?? this.headerLayout,
      footerLayout: footerLayout ?? this.footerLayout,
      clinicAddressLine1: clinicAddressLine1 ?? this.clinicAddressLine1,
      clinicAddressLine2: clinicAddressLine2 ?? this.clinicAddressLine2,
      clinicPhone1: clinicPhone1 ?? this.clinicPhone1,
      clinicPhone2: clinicPhone2 ?? this.clinicPhone2,
      clinicHours: clinicHours ?? this.clinicHours,
      showExpertInDiseases: showExpertInDiseases ?? this.showExpertInDiseases,
      expertInDiseases: expertInDiseases ?? this.expertInDiseases,
      showWorkingExperience: showWorkingExperience ?? this.showWorkingExperience,
      workingExperience: workingExperience ?? this.workingExperience,
      logoData: logoData ?? this.logoData,
      backgroundImageType: backgroundImageType ?? this.backgroundImageType,
      customBackgroundData: customBackgroundData ?? this.customBackgroundData,
      sectionLabels: sectionLabels ?? this.sectionLabels,
    );
  }
}

