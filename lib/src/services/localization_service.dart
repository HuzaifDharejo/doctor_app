import 'package:flutter/material.dart';

/// Localization Service
/// Manages app localization with multi-language support (English, Spanish, French, Arabic, Mandarin)
/// and RTL language handling.
class LocalizationService extends ChangeNotifier {
  static const List<Locale> supportedLocales = [
    Locale('en'), // English
    Locale('es'), // Spanish
    Locale('fr'), // French
    Locale('ar'), // Arabic (RTL)
    Locale('zh'), // Mandarin Chinese
  ];

  static const Locale defaultLocale = Locale('en');

  static final LocalizationService _instance = LocalizationService._internal();

  factory LocalizationService() {
    return _instance;
  }

  LocalizationService._internal() {
    _currentLocale = defaultLocale;
  }

  late Locale _currentLocale;

  Locale get currentLocale => _currentLocale;

  String get currentLanguageName {
    switch (_currentLocale.languageCode) {
      case 'en':
        return 'English';
      case 'es':
        return 'Español';
      case 'fr':
        return 'Français';
      case 'ar':
        return 'العربية';
      case 'zh':
        return '中文';
      default:
        return 'English';
    }
  }

  /// Check if current language is RTL (Arabic)
  bool get isRTL => _currentLocale.languageCode == 'ar';

  /// Get text direction for current locale
  TextDirection get textDirection => isRTL ? TextDirection.rtl : TextDirection.ltr;

  /// Set app locale
  void setLocale(Locale locale) {
    if (supportedLocales.contains(locale)) {
      _currentLocale = locale;
      notifyListeners();
    }
  }

  /// Set locale by language code
  void setLocaleByCode(String languageCode) {
    final locale = Locale(languageCode);
    setLocale(locale);
  }

  /// Get all available languages with their display names
  Map<String, String> getAvailableLanguages() {
    return {
      'en': 'English',
      'es': 'Español',
      'fr': 'Français',
      'ar': 'العربية',
      'zh': '中文',
    };
  }

  /// Get language code for current locale
  String get languageCode => _currentLocale.languageCode;

  /// Initialize locale from saved preference (would be persisted via SharedPreferences in real app)
  Future<void> initializeLocale(String? savedLocaleCode) async {
    if (savedLocaleCode != null) {
      final locale = Locale(savedLocaleCode);
      if (supportedLocales.contains(locale)) {
        _currentLocale = locale;
      }
    }
    notifyListeners();
  }

  /// Get locale-aware number formatter
  String formatNumber(num value, {int decimals = 2}) {
    if (decimals == 0) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(decimals);
  }

  /// Get locale-aware date formatter
  String formatDate(DateTime date) {
    switch (languageCode) {
      case 'es':
        return _formatDateES(date);
      case 'fr':
        return _formatDateFR(date);
      case 'ar':
        return _formatDateAR(date);
      case 'zh':
        return _formatDateZH(date);
      case 'en':
      default:
        return _formatDateEN(date);
    }
  }

  String _formatDateEN(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatDateES(DateTime date) {
    final months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
    ];
    return '${date.day} de ${months[date.month - 1]} de ${date.year}';
  }

  String _formatDateFR(DateTime date) {
    final months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatDateAR(DateTime date) {
    final months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatDateZH(DateTime date) {
    return '${date.year}年${date.month.toString().padLeft(2, '0')}月${date.day.toString().padLeft(2, '0')}日';
  }

  /// Get locale-aware time formatter
  String formatTime(TimeOfDay time) {
    switch (languageCode) {
      case 'ar':
        return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      case 'zh':
        final period = time.hour >= 12 ? '下午' : '上午';
        final displayHour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
        return '$period ${displayHour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      case 'en':
      case 'es':
      case 'fr':
      default:
        final period = time.hour >= 12 ? 'PM' : 'AM';
        final displayHour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
        return '${displayHour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $period';
    }
  }

  /// Get translated gender
  String translateGender(String gender) {
    switch (languageCode) {
      case 'es':
        switch (gender.toLowerCase()) {
          case 'male':
            return 'Masculino';
          case 'female':
            return 'Femenino';
          case 'other':
            return 'Otro';
          default:
            return gender;
        }
      case 'fr':
        switch (gender.toLowerCase()) {
          case 'male':
            return 'Masculin';
          case 'female':
            return 'Féminin';
          case 'other':
            return 'Autre';
          default:
            return gender;
        }
      case 'ar':
        switch (gender.toLowerCase()) {
          case 'male':
            return 'ذكر';
          case 'female':
            return 'أنثى';
          case 'other':
            return 'آخر';
          default:
            return gender;
        }
      case 'zh':
        switch (gender.toLowerCase()) {
          case 'male':
            return '男性';
          case 'female':
            return '女性';
          case 'other':
            return '其他';
          default:
            return gender;
        }
      case 'en':
      default:
        return gender;
    }
  }

  /// Common translations (for UI elements that need runtime translation)
  Map<String, String> getTranslations() {
    switch (languageCode) {
      case 'es':
        return _translationsES();
      case 'fr':
        return _translationsFR();
      case 'ar':
        return _translationsAR();
      case 'zh':
        return _translationsZH();
      case 'en':
      default:
        return _translationsEN();
    }
  }

  Map<String, String> _translationsEN() => {
        'app_name': 'Doctor App',
        'language': 'Language',
        'english': 'English',
        'spanish': 'Spanish',
        'french': 'French',
        'arabic': 'Arabic',
        'mandarin': 'Mandarin',
        'settings': 'Settings',
        'language_settings': 'Language Settings',
        'select_language': 'Select Language',
        'change_language': 'Change Language',
        'confirm': 'Confirm',
        'cancel': 'Cancel',
        'save': 'Save',
        'delete': 'Delete',
        'edit': 'Edit',
        'add': 'Add',
        'close': 'Close',
        'search': 'Search',
        'filter': 'Filter',
        'sort': 'Sort',
        'logout': 'Logout',
        'home': 'Home',
        'patients': 'Patients',
        'appointments': 'Appointments',
        'prescriptions': 'Prescriptions',
        'billing': 'Billing',
        'analytics': 'Analytics',
        'offline_sync': 'Offline Sync',
        'about': 'About',
        'help': 'Help',
        'version': 'Version',
        'loading': 'Loading...',
        'error': 'Error',
        'success': 'Success',
        'warning': 'Warning',
        'no_data': 'No data available',
        'try_again': 'Try Again',
      };

  Map<String, String> _translationsES() => {
        'app_name': 'Aplicación Médica',
        'language': 'Idioma',
        'english': 'Inglés',
        'spanish': 'Español',
        'french': 'Francés',
        'arabic': 'Árabe',
        'mandarin': 'Mandarín',
        'settings': 'Configuración',
        'language_settings': 'Configuración de Idioma',
        'select_language': 'Seleccionar Idioma',
        'change_language': 'Cambiar Idioma',
        'confirm': 'Confirmar',
        'cancel': 'Cancelar',
        'save': 'Guardar',
        'delete': 'Eliminar',
        'edit': 'Editar',
        'add': 'Añadir',
        'close': 'Cerrar',
        'search': 'Buscar',
        'filter': 'Filtrar',
        'sort': 'Ordenar',
        'logout': 'Cerrar Sesión',
        'home': 'Inicio',
        'patients': 'Pacientes',
        'appointments': 'Citas',
        'prescriptions': 'Prescripciones',
        'billing': 'Facturación',
        'analytics': 'Análisis',
        'offline_sync': 'Sincronización Offline',
        'about': 'Acerca de',
        'help': 'Ayuda',
        'version': 'Versión',
        'loading': 'Cargando...',
        'error': 'Error',
        'success': 'Éxito',
        'warning': 'Advertencia',
        'no_data': 'Sin datos disponibles',
        'try_again': 'Intentar de Nuevo',
      };

  Map<String, String> _translationsFR() => {
        'app_name': 'Application Médicale',
        'language': 'Langue',
        'english': 'Anglais',
        'spanish': 'Espagnol',
        'french': 'Français',
        'arabic': 'Arabe',
        'mandarin': 'Mandarin',
        'settings': 'Paramètres',
        'language_settings': 'Paramètres de Langue',
        'select_language': 'Sélectionner la Langue',
        'change_language': 'Changer la Langue',
        'confirm': 'Confirmer',
        'cancel': 'Annuler',
        'save': 'Enregistrer',
        'delete': 'Supprimer',
        'edit': 'Modifier',
        'add': 'Ajouter',
        'close': 'Fermer',
        'search': 'Rechercher',
        'filter': 'Filtrer',
        'sort': 'Trier',
        'logout': 'Déconnexion',
        'home': 'Accueil',
        'patients': 'Patients',
        'appointments': 'Rendez-vous',
        'prescriptions': 'Prescriptions',
        'billing': 'Facturation',
        'analytics': 'Analyse',
        'offline_sync': 'Synchronisation Hors Ligne',
        'about': 'À Propos',
        'help': 'Aide',
        'version': 'Version',
        'loading': 'Chargement...',
        'error': 'Erreur',
        'success': 'Succès',
        'warning': 'Avertissement',
        'no_data': 'Aucune donnée disponible',
        'try_again': 'Réessayer',
      };

  Map<String, String> _translationsAR() => {
        'app_name': 'تطبيق الطبيب',
        'language': 'اللغة',
        'english': 'الإنجليزية',
        'spanish': 'الإسبانية',
        'french': 'الفرنسية',
        'arabic': 'العربية',
        'mandarin': 'الماندرين',
        'settings': 'الإعدادات',
        'language_settings': 'إعدادات اللغة',
        'select_language': 'اختر اللغة',
        'change_language': 'تغيير اللغة',
        'confirm': 'تأكيد',
        'cancel': 'إلغاء',
        'save': 'حفظ',
        'delete': 'حذف',
        'edit': 'تعديل',
        'add': 'إضافة',
        'close': 'إغلاق',
        'search': 'بحث',
        'filter': 'تصفية',
        'sort': 'فرز',
        'logout': 'تسجيل الخروج',
        'home': 'الرئيسية',
        'patients': 'المرضى',
        'appointments': 'المواعيد',
        'prescriptions': 'الوصفات الطبية',
        'billing': 'الفواتير',
        'analytics': 'التحليلات',
        'offline_sync': 'مزامنة غير متصلة',
        'about': 'حول',
        'help': 'مساعدة',
        'version': 'الإصدار',
        'loading': 'جاري التحميل...',
        'error': 'خطأ',
        'success': 'نجح',
        'warning': 'تحذير',
        'no_data': 'لا توجد بيانات متاحة',
        'try_again': 'حاول مرة أخرى',
      };

  Map<String, String> _translationsZH() => {
        'app_name': '医生应用',
        'language': '语言',
        'english': '英文',
        'spanish': '西班牙文',
        'french': '法文',
        'arabic': '阿拉伯文',
        'mandarin': '普通话',
        'settings': '设置',
        'language_settings': '语言设置',
        'select_language': '选择语言',
        'change_language': '更改语言',
        'confirm': '确认',
        'cancel': '取消',
        'save': '保存',
        'delete': '删除',
        'edit': '编辑',
        'add': '添加',
        'close': '关闭',
        'search': '搜索',
        'filter': '筛选',
        'sort': '排序',
        'logout': '退出登录',
        'home': '主页',
        'patients': '患者',
        'appointments': '预约',
        'prescriptions': '处方',
        'billing': '账单',
        'analytics': '分析',
        'offline_sync': '离线同步',
        'about': '关于',
        'help': '帮助',
        'version': '版本',
        'loading': '正在加载...',
        'error': '错误',
        'success': '成功',
        'warning': '警告',
        'no_data': '没有可用的数据',
        'try_again': '重试',
      };
}
