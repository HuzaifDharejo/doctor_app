import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';
import '../../services/quick_phrases_service.dart';
import '../../theme/app_theme.dart';

/// A widget that shows quick phrase shortcuts for clinical documentation
/// Can be shown as a bottom sheet or inline picker
class QuickPhrasePicker extends StatefulWidget {
  const QuickPhrasePicker({
    super.key,
    required this.onPhraseSelected,
    this.category,
    this.showSearch = true,
  });

  /// Called when a phrase is selected
  final ValueChanged<String> onPhraseSelected;
  
  /// Filter by category (null shows all)
  final String? category;
  
  /// Whether to show search bar
  final bool showSearch;

  /// Show as bottom sheet
  static Future<String?> showAsBottomSheet(
    BuildContext context, {
    String? category,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkSurfaceMid
                : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: QuickPhrasePicker(
            category: category,
            onPhraseSelected: (phrase) => Navigator.pop(context, phrase),
          ),
        ),
      ),
    );
  }

  @override
  State<QuickPhrasePicker> createState() => _QuickPhrasePickerState();
}

class _QuickPhrasePickerState extends State<QuickPhrasePicker> {
  final _searchController = TextEditingController();
  String _selectedCategory = 'all';
  String _searchQuery = '';

  List<Map<String, String>> get _filteredPhrases {
    var phrases = QuickPhrasesService.defaultPhrases;
    
    // Filter by category
    if (widget.category != null) {
      phrases = phrases.where((p) => p['category'] == widget.category).toList();
    } else if (_selectedCategory != 'all') {
      phrases = phrases.where((p) => p['category'] == _selectedCategory).toList();
    }
    
    // Filter by search
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      phrases = phrases.where((p) {
        final shortcut = p['shortcut']?.toLowerCase() ?? '';
        final expansion = p['expansion']?.toLowerCase() ?? '';
        return shortcut.contains(query) || expansion.contains(query);
      }).toList();
    }
    
    return phrases;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      children: [
        // Handle bar
        Container(
          margin: const EdgeInsets.only(top: 8),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: isDark ? Colors.white24 : Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        
        // Header
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Phrases',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Type shortcut or tap to insert',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        
        // Search bar
        if (widget.showSearch)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search shortcuts or phrases...',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
        
        // Category tabs
        if (widget.category == null) ...[
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                _buildCategoryChip('all', 'All', Icons.apps_rounded),
                _buildCategoryChip('diagnosis', 'Diagnosis', Icons.medical_information_rounded),
                _buildCategoryChip('exam', 'Exam', Icons.healing_rounded),
                _buildCategoryChip('history', 'History', Icons.history_rounded),
                _buildCategoryChip('plan', 'Plan', Icons.checklist_rounded),
                _buildCategoryChip('vitals', 'Vitals', Icons.monitor_heart_rounded),
                _buildCategoryChip('general', 'General', Icons.notes_rounded),
              ],
            ),
          ),
        ],
        
        const SizedBox(height: AppSpacing.sm),
        
        // Phrases list
        Expanded(
          child: _filteredPhrases.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 48,
                        color: isDark ? Colors.white24 : Colors.grey[300],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No phrases found',
                        style: TextStyle(
                          color: isDark ? Colors.white54 : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  itemCount: _filteredPhrases.length,
                  itemBuilder: (context, index) {
                    final phrase = _filteredPhrases[index];
                    return _buildPhraseItem(phrase, isDark);
                  },
                ),
        ),
        
        // Tip at bottom
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[50],
            border: Border(
              top: BorderSide(
                color: isDark ? Colors.white12 : Colors.grey[200]!,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                size: 16,
                color: Colors.amber[600],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tip: Type shortcut (e.g., .htn) in any text field to auto-expand',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String value, String label, IconData icon) {
    final isSelected = _selectedCategory == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white70 : AppColors.textSecondary),
            ),
            const SizedBox(width: 4),
            Text(label),
          ],
        ),
        labelStyle: TextStyle(
          fontSize: 12,
          color: isSelected
              ? Colors.white
              : (isDark ? Colors.white70 : AppColors.textPrimary),
        ),
        selectedColor: AppColors.primary,
        backgroundColor: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey[100],
        checkmarkColor: Colors.white,
        showCheckmark: false,
        onSelected: (_) => setState(() => _selectedCategory = value),
      ),
    );
  }

  Widget _buildPhraseItem(Map<String, String> phrase, bool isDark) {
    final shortcut = phrase['shortcut'] ?? '';
    final expansion = phrase['expansion'] ?? '';
    final category = phrase['category'] ?? '';
    
    Color categoryColor;
    switch (category) {
      case 'diagnosis':
        categoryColor = AppColors.primary;
      case 'exam':
        categoryColor = AppColors.quickActionGreen;
      case 'history':
        categoryColor = AppColors.warning;
      case 'plan':
        categoryColor = AppColors.info;
      case 'vitals':
        categoryColor = AppColors.error;
      default:
        categoryColor = AppColors.purple;
    }
    
    return InkWell(
      onTap: () => widget.onPhraseSelected(expansion),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.grey[200]!,
          ),
        ),
        child: Row(
          children: [
            // Shortcut badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                shortcut,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: categoryColor,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Expansion text
            Expanded(
              child: Text(
                expansion,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Insert icon
            Icon(
              Icons.add_circle_outline_rounded,
              size: 20,
              color: isDark ? Colors.white38 : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}

/// Extension to add quick phrase functionality to TextEditingController
extension QuickPhraseExpansion on TextEditingController {
  /// Check and expand quick phrase shortcut at current cursor position
  bool expandQuickPhrase() {
    final text = this.text;
    final selection = this.selection;
    
    if (!selection.isValid || selection.start != selection.end) return false;
    
    // Find word before cursor
    final beforeCursor = text.substring(0, selection.start);
    final match = RegExp(r'\.[\w]+$').firstMatch(beforeCursor);
    
    if (match == null) return false;
    
    final shortcut = match.group(0);
    final phrase = QuickPhrasesService.defaultPhrases.firstWhere(
      (p) => p['shortcut'] == shortcut,
      orElse: () => {},
    );
    
    if (phrase.isEmpty) return false;
    
    final expansion = phrase['expansion'] ?? '';
    final newText = text.replaceRange(match.start, selection.start, expansion);
    final newCursorPos = match.start + expansion.length;
    
    this.text = newText;
    this.selection = TextSelection.collapsed(offset: newCursorPos);
    
    return true;
  }
}
