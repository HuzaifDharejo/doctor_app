import 'dart:async';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/design_tokens.dart';
import '../../theme/app_theme.dart';
import '../../db/doctor_db.dart';
import '../../providers/db_provider.dart';
import '../../services/search_cache_service.dart';
import '../screens/patient_view/patient_view_screen.dart';
import '../../services/logger_service.dart';

/// Persistent quick search bar widget
/// Shows in app bar or as floating search button
/// Supports keyboard shortcut Ctrl+K / Cmd+K
class QuickSearchBar extends ConsumerStatefulWidget {
  const QuickSearchBar({
    super.key,
    this.onPatientSelected,
    this.showRecentPatients = true,
    this.maxRecentPatients = 5,
    this.variant = QuickSearchVariant.button,
  });

  final void Function(Patient patient)? onPatientSelected;
  final bool showRecentPatients;
  final int maxRecentPatients;
  final QuickSearchVariant variant;

  @override
  ConsumerState<QuickSearchBar> createState() => _QuickSearchBarState();
}

enum QuickSearchVariant {
  button, // Shows as button, opens search dialog
  bar, // Shows as persistent search bar
}

class _QuickSearchBarState extends ConsumerState<QuickSearchBar> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounceTimer;
  List<Patient> _searchResults = [];
  List<Patient> _recentPatients = [];
  bool _isSearching = false;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _loadRecentPatients();
    _searchController.addListener(_onSearchChanged);
    
  }

  @override
  void dispose() {
    // Cancel timer first
    _debounceTimer?.cancel();
    
    // Remove overlay entry before disposing controllers
    _overlayEntry?.remove();
    _overlayEntry = null;
    
    // Remove listener BEFORE clearing controller to prevent setState after dispose
    _searchController.removeListener(_onSearchChanged);
    
    // Unfocus before disposing focus node (may fail if already disposed, that's ok)
    try {
      _focusNode.unfocus();
    } catch (_) {
      // Ignore if already unfocused or disposed
    }
    
    // Dispose controller (no need to clear, listener is already removed)
    _searchController.dispose();
    _focusNode.dispose();
    
    super.dispose();
  }

  Future<void> _loadRecentPatients() async {
    try {
      final db = await ref.read(doctorDbProvider.future);
      // Get recent patients (last viewed or last visited today)
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      
      // Get appointments today and extract patient IDs
      final appointments = await (db.select(db.appointments)
        ..where((a) => a.appointmentDateTime.isBiggerOrEqualValue(startOfDay))
        ..orderBy([(a) => drift.OrderingTerm.desc(a.appointmentDateTime)]))
        .get();
      
      final patientIds = appointments.map((a) => a.patientId).toSet().take(widget.maxRecentPatients).toList();
      
      final recent = <Patient>[];
      for (final id in patientIds) {
        final patient = await db.getPatientById(id);
        if (patient != null) {
          recent.add(patient);
        }
      }
      
      if (mounted) {
        setState(() {
          _recentPatients = recent;
        });
      }
    } catch (e) {
      log.e('QUICK_SEARCH', 'Error loading recent patients', error: e);
    }
  }

  void _onSearchChanged() {
    // Don't process changes if widget is disposed
    if (!mounted) return;
    
    final query = _searchController.text.trim();
    
    if (query.isEmpty) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
        _updateOverlay();
      }
      return;
    }

    if (mounted) {
      setState(() => _isSearching = true);
    }
    
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        _performSearch(query);
      }
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.length < 2) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      _updateOverlay();
      return;
    }

    try {
      final cacheService = SearchCacheService();
      final cacheParams = {'query': query, 'category': 'Patients'};
      
      final cached = cacheService.getCached<Patient>(
        cacheType: 'quick_search_patients',
        params: cacheParams,
      );
      
      if (cached != null) {
        setState(() {
          _searchResults = cached;
          _isSearching = false;
        });
        _updateOverlay();
        return;
      }

      final db = await ref.read(doctorDbProvider.future);
      final patients = await db.searchPatientsLimited(query, limit: 8);
      
      cacheService.setCached<Patient>(
        cacheType: 'quick_search_patients',
        params: cacheParams,
        data: patients,
      );

      if (mounted) {
        setState(() {
          _searchResults = patients;
          _isSearching = false;
        });
        _updateOverlay();
      }
    } catch (e) {
      log.e('QUICK_SEARCH', 'Search failed', error: e);
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;
    
    _overlayEntry = OverlayEntry(
      builder: (context) => _SearchOverlay(
        searchResults: _searchResults,
        recentPatients: _recentPatients,
        isSearching: _isSearching,
        query: _searchController.text,
        onPatientSelected: (patient) {
          _hideOverlay();
          widget.onPatientSelected?.call(patient);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PatientViewScreen(patient: patient),
            ),
          );
          // Update recent patients
          _loadRecentPatients();
        },
        onClose: _hideOverlay,
      ),
    );
    
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _updateOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
    }
  }

  void _hideOverlay() {
    // Remove overlay first to prevent any callbacks from trying to use disposed controllers
    _overlayEntry?.remove();
    _overlayEntry = null;
    // Only interact with controllers/focus node if mounted
    if (mounted) {
      try {
        _focusNode.unfocus();
        _searchController.clear();
      } catch (_) {
        // Ignore errors if already disposed (can happen if called after dispose started)
      }
    }
  }

  void _handleTap() {
    if (widget.variant == QuickSearchVariant.button) {
      _showSearchDialog();
    } else {
      _focusNode.requestFocus();
      _showOverlay();
    }
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (BuildContext context) => _QuickSearchDialog(
        onPatientSelected: (patient) {
          Navigator.pop(context);
          widget.onPatientSelected?.call(patient);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PatientViewScreen(patient: patient),
            ),
          );
          _loadRecentPatients();
        },
        recentPatients: _recentPatients,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (widget.variant == QuickSearchVariant.button) {
      return IconButton(
        icon: const Icon(Icons.search),
        tooltip: 'Quick Search (Ctrl+K)',
        onPressed: _showSearchDialog,
      );
    }

    // Bar variant
    return GestureDetector(
      onTap: _handleTap,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isDark ? AppColors.darkDivider : Colors.grey.shade300,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Icon(
              Icons.search,
              size: 20,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                onTap: () => _showOverlay(),
                decoration: InputDecoration(
                  hintText: 'Quick search patient...',
                  hintStyle: TextStyle(
                    color: isDark ? AppColors.darkTextHint : AppColors.textHint,
                    fontSize: AppFontSize.md,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                style: TextStyle(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  fontSize: AppFontSize.md,
                ),
              ),
            ),
            if (_searchController.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  _searchController.clear();
                  _hideOverlay();
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _QuickSearchDialog extends ConsumerStatefulWidget {
  const _QuickSearchDialog({
    required this.onPatientSelected,
    required this.recentPatients,
  });

  final void Function(Patient patient) onPatientSelected;
  final List<Patient> recentPatients;

  @override
  ConsumerState<_QuickSearchDialog> createState() => _QuickSearchDialogState();
}

class _QuickSearchDialogState extends ConsumerState<_QuickSearchDialog> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounceTimer;
  List<Patient> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.length < 2) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    try {
      final cacheService = SearchCacheService();
      final cacheParams = {'query': query, 'category': 'Patients'};
      
      final cached = cacheService.getCached<Patient>(
        cacheType: 'quick_search_patients',
        params: cacheParams,
      );
      
      if (cached != null) {
        setState(() {
          _searchResults = cached;
          _isSearching = false;
        });
        return;
      }

      final db = await ref.read(doctorDbProvider.future);
      final patients = await db.searchPatientsLimited(query, limit: 10);
      
      cacheService.setCached<Patient>(
        cacheType: 'quick_search_patients',
        params: cacheParams,
        data: patients,
      );

      if (mounted) {
        setState(() {
          _searchResults = patients;
          _isSearching = false;
        });
      }
    } catch (e) {
      log.e('QUICK_SEARCH', 'Search failed', error: e);
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasQuery = _searchController.text.trim().isNotEmpty;
    final hasResults = _searchResults.isNotEmpty || (!hasQuery && widget.recentPatients.isNotEmpty);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(40),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Search input
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search patients by name, phone, or ID...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.darkDivider : Colors.grey.shade300,
                    ),
                  ),
                ),
                onSubmitted: (value) {
                  if (_searchResults.isNotEmpty) {
                    widget.onPatientSelected(_searchResults.first);
                  }
                },
              ),
            ),
            
            // Results
            if (hasResults)
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    // Recent patients section
                    if (!hasQuery && widget.recentPatients.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          'Recent Patients',
                          style: TextStyle(
                            fontSize: AppFontSize.sm,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      ...widget.recentPatients.map((patient) => _PatientListItem(
                        patient: patient,
                        onTap: () => widget.onPatientSelected(patient),
                        isDark: isDark,
                      )),
                    ],
                    
                    // Search results
                    if (hasQuery && _isSearching)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (hasQuery && _searchResults.isEmpty && !_isSearching)
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            'No patients found',
                            style: TextStyle(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      )
                    else if (hasQuery)
                      ..._searchResults.map((patient) => _PatientListItem(
                        patient: patient,
                        onTap: () => widget.onPatientSelected(patient),
                        isDark: isDark,
                      )),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PatientListItem extends StatelessWidget {
  const _PatientListItem({
    required this.patient,
    required this.onTap,
    required this.isDark,
  });

  final Patient patient;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withOpacity(0.1),
        child: Text(
          patient.firstName.isNotEmpty ? patient.firstName[0].toUpperCase() : '?',
          style: TextStyle(color: AppColors.primary),
        ),
      ),
      title: Text(
        '${patient.firstName} ${patient.lastName}',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        patient.phone.isNotEmpty ? patient.phone : 'No phone',
        style: TextStyle(
          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
      ),
      onTap: onTap,
    );
  }
}

class _SearchOverlay extends StatelessWidget {
  const _SearchOverlay({
    required this.searchResults,
    required this.recentPatients,
    required this.isSearching,
    required this.query,
    required this.onPatientSelected,
    required this.onClose,
  });

  final List<Patient> searchResults;
  final List<Patient> recentPatients;
  final bool isSearching;
  final String query;
  final void Function(Patient patient) onPatientSelected;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasQuery = query.trim().isNotEmpty;
    final hasResults = searchResults.isNotEmpty || (!hasQuery && recentPatients.isNotEmpty);

    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black.withValues(alpha: 0.3),
        child: Center(
            child: GestureDetector(
            onTap: () {
              // Prevent closing when tapping content
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 100),
              constraints: const BoxConstraints(maxWidth: 600, maxHeight: 500),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                    ),
                  ],
              ),
              child: hasResults
                  ? ListView(
                      shrinkWrap: true,
                      children: [
                        if (!hasQuery && recentPatients.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'Recent Patients',
                              style: TextStyle(
                                fontSize: AppFontSize.sm,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              ),
                            ),
                          ),
                          ...recentPatients.map((p) => _PatientListItem(
                            patient: p,
                            onTap: () => onPatientSelected(p),
                            isDark: isDark,
                          )),
                        ],
                        if (hasQuery && isSearching)
                          const Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (hasQuery && searchResults.isEmpty && !isSearching)
                          Padding(
                            padding: const EdgeInsets.all(32),
                            child: Center(
                              child: Text(
                                'No patients found',
                                style: TextStyle(
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          )
                        else if (hasQuery)
                          ...searchResults.map((p) => _PatientListItem(
                            patient: p,
                            onTap: () => onPatientSelected(p),
                            isDark: isDark,
                          )),
                      ],
                    )
                  : const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

