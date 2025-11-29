import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../db/doctor_db.dart';
import '../../providers/db_provider.dart';
import '../screens/patient_view_screen.dart';

/// Represents a search result item
class SearchResult {
  const SearchResult({
    required this.title,
    required this.subtitle,
    required this.type,
    required this.data,
  });

  final String title;
  final String subtitle;
  final String type;
  final dynamic data;

  IconData get icon {
    switch (type) {
      case 'patient':
        return Icons.person;
      case 'appointment':
        return Icons.calendar_today;
      case 'prescription':
        return Icons.medication;
      case 'invoice':
        return Icons.receipt;
      default:
        return Icons.search;
    }
  }
}

/// A global search bar widget that searches across patients, appointments, etc.
class GlobalSearchBar extends ConsumerStatefulWidget {
  const GlobalSearchBar({super.key});

  @override
  ConsumerState<GlobalSearchBar> createState() => _GlobalSearchBarState();
}

class _GlobalSearchBarState extends ConsumerState<GlobalSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  
  OverlayEntry? _overlayEntry;
  List<SearchResult> _results = [];
  bool _isSearching = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      _removeOverlay();
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showOverlay() {
    _removeOverlay();
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _isSearching = false;
      });
      _removeOverlay();
      return;
    }

    setState(() => _isSearching = true);
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    final dbAsync = ref.read(doctorDbProvider);
    final lowerQuery = query.toLowerCase();
    
    dbAsync.whenData((db) async {
      // Search patients by name
      final allPatients = await db.getAllPatients();
      final patients = allPatients.where((p) {
        final fullName = '${p.firstName} ${p.lastName}'.toLowerCase();
        return fullName.contains(lowerQuery) ||
          p.phone.toLowerCase().contains(lowerQuery);
      }).take(5).toList();
      
      if (!mounted) return;
      
      final results = <SearchResult>[];
      
      for (final patient in patients) {
        results.add(SearchResult(
          title: '${patient.firstName} ${patient.lastName}',
          subtitle: patient.phone.isEmpty ? 'No phone' : patient.phone,
          type: 'patient',
          data: patient,
        ),);
      }
      
      setState(() {
        _results = results;
        _isSearching = false;
      });
      
      if (results.isNotEmpty) {
        _showOverlay();
      } else {
        _removeOverlay();
      }
    });
  }

  void _onResultTap(SearchResult result) {
    _removeOverlay();
    _controller.clear();
    _focusNode.unfocus();
    
    switch (result.type) {
      case 'patient':
        final patient = result.data as Patient;
        Navigator.push<void>(
          context,
          MaterialPageRoute<void>(
            builder: (_) => PatientViewScreen(patient: patient),
          ),
        );
      case 'appointment':
      case 'prescription':
      case 'invoice':
        final dbAsync = ref.read(doctorDbProvider);
        dbAsync.whenData((db) async {
          final int patientId = (result.data as dynamic).patientId as int;
          final patient = await db.getPatientById(patientId);
          if (patient != null && mounted) {
            Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (_) => PatientViewScreen(patient: patient),
              ),
            );
          }
        });
    }
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject()! as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 4),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 300),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: _isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _results.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No results found'),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: _results.length,
                          itemBuilder: (context, index) {
                            final result = _results[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                child: Icon(
                                  result.icon,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                ),
                              ),
                              title: Text(result.title),
                              subtitle: Text(result.subtitle),
                              onTap: () => _onResultTap(result),
                            );
                          },
                        ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search patients, appointments...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _controller.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}
