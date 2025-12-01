import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/components/app_button.dart';
import '../../core/theme/design_tokens.dart';
import '../../services/localization_service.dart';

// ============================================================================
// Language Selector Widget
// ============================================================================

/// Simple dropdown/button-based language selector
class LanguageSelector extends ConsumerWidget {
  final void Function(Locale)? onLanguageChanged;

  const LanguageSelector({
    Key? key,
    this.onLanguageChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locService = LocalizationService();
    final languages = locService.getAvailableLanguages();

    return PopupMenuButton<String>(
      onSelected: (languageCode) {
        locService.setLocaleByCode(languageCode);
        onLanguageChanged?.call(Locale(languageCode));
      },
      itemBuilder: (context) => languages.entries.map((entry) {
        return PopupMenuItem<String>(
          value: entry.key,
          child: Row(
            children: [
              if (locService.languageCode == entry.key)
                const Icon(Icons.check, color: Colors.green, size: 20)
              else
                const SizedBox(width: 20),
              const SizedBox(width: 12),
              Text(entry.value),
            ],
          ),
        );
      }).toList(),
      child: const Padding(
        padding: EdgeInsets.all(AppSpacing.sm),
        child: Icon(Icons.language_outlined),
      ),
    );
  }
}

// ============================================================================
// Language Settings Card
// ============================================================================

/// Language settings card for display in settings screen
class LanguageSettingsCard extends ConsumerWidget {
  final void Function(Locale)? onLanguageChanged;

  const LanguageSettingsCard({
    Key? key,
    this.onLanguageChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locService = LocalizationService();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.language_outlined,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 12),
                Text(
                  'Language',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Current: ${locService.currentLanguageName}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: LocalizationService.supportedLocales.map((locale) {
                final isSelected = locService.currentLocale == locale;
                return FilterChip(
                  label: Text(
                    LocalizationService()
                        .getAvailableLanguages()[locale.languageCode]!,
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      locService.setLocale(locale);
                      onLanguageChanged?.call(locale);
                    }
                  },
                  backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                  selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Language Switcher Dialog
// ============================================================================

/// Dialog for selecting language with detailed information
class LanguageSwitcherDialog extends StatefulWidget {
  final Locale initialLocale;
  final ValueChanged<Locale> onLanguageSelected;

  const LanguageSwitcherDialog({
    Key? key,
    required this.initialLocale,
    required this.onLanguageSelected,
  }) : super(key: key);

  @override
  State<LanguageSwitcherDialog> createState() => _LanguageSwitcherDialogState();
}

class _LanguageSwitcherDialogState extends State<LanguageSwitcherDialog> {
  late Locale _selectedLocale;

  @override
  void initState() {
    super.initState();
    _selectedLocale = widget.initialLocale;
  }

  @override
  Widget build(BuildContext context) {
    final locService = LocalizationService();
    final languages = locService.getAvailableLanguages();

    return AlertDialog(
      title: const Text('Select Language'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: LocalizationService.supportedLocales.map((locale) {
            final isSelected = _selectedLocale == locale;
            final languageName = languages[locale.languageCode]!;

            return Card(
              elevation: isSelected ? 4 : 0,
              color: isSelected
                  ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                  : Colors.transparent,
              child: ListTile(
                title: Text(languageName),
                trailing: isSelected ? const Icon(Icons.check_circle) : null,
                onTap: () {
                  setState(() {
                    _selectedLocale = locale;
                  });
                },
              ),
            );
          }).toList(),
        ),
      ),
      actions: [
        AppButton.tertiary(
          label: 'Cancel',
          onPressed: Navigator.of(context).pop,
        ),
        AppButton.primary(
          label: 'Confirm',
          onPressed: () {
            widget.onLanguageSelected(_selectedLocale);
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

// ============================================================================
// RTL Support Widget
// ============================================================================

/// Wrapper widget for RTL support
class RTLSupportedWidget extends ConsumerWidget {
  final Widget child;

  const RTLSupportedWidget({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locService = LocalizationService();

    return Directionality(
      textDirection: locService.textDirection,
      child: child,
    );
  }
}

// ============================================================================
// Locale Info Widget
// ============================================================================

/// Displays current locale and language information
class LocaleInfoWidget extends ConsumerWidget {
  const LocaleInfoWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locService = LocalizationService();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Locale Information',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          _buildInfoRow('Language:', locService.currentLanguageName),
          _buildInfoRow('Code:', locService.languageCode),
          _buildInfoRow('Direction:', locService.isRTL ? 'RTL' : 'LTR'),
          _buildInfoRow(
            'Text Direction:',
            locService.textDirection == TextDirection.rtl ? 'RTL' : 'LTR',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

