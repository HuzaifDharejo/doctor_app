import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/db_provider.dart';
import '../../services/search_service.dart';
import '../../theme/app_theme.dart';
import '../screens/patient_view_screen.dart';

class GlobalSearchBar extends ConsumerStatefulWidget {
  const GlobalSearchBar({super.key});

  @override
  ConsumerState<GlobalSearchBar> createState() => _GlobalSearchBarState();
}

class _GlobalSearchBarState extends ConsumerState<GlobalSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<SearchResult> _results = [];
  bool _isLoading = false;
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) setState(() => _showResults = false);
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _showResults = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    final dbAsync = ref.read(doctorDbProvider);
    dbAsync.whenData((db) async {
      final searchService = SearchService(db);
      final results = await searchService.search(query);
      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
          _showResults = true;
        });
      }
    });
  }

  void _onResultTap(SearchResult result) {
    _focusNode.unfocus();
    setState(() => _showResults = false);
    _controller.clear();

    switch (result.type) {
      case 'patient':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PatientViewScreen(patient: result.data),
          ),
        );
        break;
      case 'appointment':
      case 'prescription':
      case 'invoice':
        // Navigate to patient view for now
        final dbAsync = ref.read(doctorDbProvider);
        dbAsync.whenData((db) async {
          int patientId;
          if (result.type == 'appointment') {
            patientId = result.data.patientId;
          } else if (result.type == 'prescription') {
            patientId = result.data.patientId;
          } else {
            patientId = result.data.patientId;
          }
          final patient = await db.getPatientById(patientId);
          if (patient != null && mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PatientViewScreen(patient: patient),
              ),
            );
          }
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 400;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: isCompact ? 40 : 48,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBackground : AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _focusNode.hasFocus 
                  ? AppColors.primary 
                  : (isDark ? AppColors.darkDivider : AppColors.divider),
            ),
          ),
          child: Row(
            children: [
              SizedBox(width: isCompact ? 10 : 12),
              Icon(
                Icons.search,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                size: isCompact ? 18 : 20,
              ),
              SizedBox(width: isCompact ? 6 : 8),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  onChanged: _search,
                  style: TextStyle(
                    fontSize: isCompact ? 12 : 14,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search patients, appointments...',
                    hintStyle: TextStyle(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textHint,
                      fontSize: isCompact ? 11 : 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              if (_isLoading)
                Padding(
                  padding: EdgeInsets.only(right: isCompact ? 10 : 12),
                  child: SizedBox(
                    width: isCompact ? 14 : 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                )
              else if (_controller.text.isNotEmpty)
                IconButton(
                  icon: Icon(
                    Icons.close,
                    size: 18,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                  onPressed: () {
                    _controller.clear();
                    setState(() {
                      _results = [];
                      _showResults = false;
                    });
                  },
                ),
            ],
          ),
        ),
        if (_showResults && _results.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 300),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.divider),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _results.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: isDark ? AppColors.darkDivider : AppColors.divider,
                ),
                itemBuilder: (context, index) {
                  final result = _results[index];
                  return _buildResultItem(result, isDark);
                },
              ),
            ),
          ),
        if (_showResults && _results.isEmpty && !_isLoading && _controller.text.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.divider),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  'No results found',
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildResultItem(SearchResult result, bool isDark) {
    IconData icon;
    Color color;

    switch (result.type) {
      case 'patient':
        icon = Icons.person;
        color = AppColors.primary;
        break;
      case 'appointment':
        icon = Icons.calendar_today;
        color = AppColors.accent;
        break;
      case 'prescription':
        icon = Icons.medication;
        color = AppColors.warning;
        break;
      case 'invoice':
        icon = Icons.receipt_long;
        color = AppColors.success;
        break;
      default:
        icon = Icons.search;
        color = AppColors.textSecondary;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onResultTap(result),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      result.subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (result.date != null)
                Text(
                  DateFormat('MMM d').format(result.date!),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
