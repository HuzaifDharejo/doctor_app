import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../db/doctor_db.dart';
import '../../../providers/db_provider.dart';
import '../../../services/dynamic_suggestions_service.dart';
import '../../../theme/app_theme.dart';

/// A screen to manage user-added suggestions
/// Allows viewing, searching, and deleting saved suggestions
class ManageSuggestionsScreen extends ConsumerStatefulWidget {
  const ManageSuggestionsScreen({super.key});

  @override
  ConsumerState<ManageSuggestionsScreen> createState() => _ManageSuggestionsScreenState();
}

class _ManageSuggestionsScreenState extends ConsumerState<ManageSuggestionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  
  static const _categories = [
    (SuggestionCategory.chiefComplaint, 'Chief Complaint', Icons.report_problem_rounded),
    (SuggestionCategory.examinationFindings, 'Examination', Icons.medical_services_rounded),
    (SuggestionCategory.investigationResults, 'Investigation Results', Icons.biotech_rounded),
    (SuggestionCategory.diagnosis, 'Diagnosis', Icons.medical_information_rounded),
    (SuggestionCategory.treatment, 'Treatment', Icons.healing_rounded),
    (SuggestionCategory.clinicalNotes, 'Clinical Notes', Icons.note_alt_rounded),
    (SuggestionCategory.medication, 'Medications', Icons.medication_rounded),
    (SuggestionCategory.symptom, 'Symptoms', Icons.sick_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Suggestions'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search suggestions...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
              // Category tabs
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: _categories.map((cat) => Tab(
                  icon: Icon(cat.$3, size: 20),
                  text: cat.$2,
                )).toList(),
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _categories.map((cat) => _buildCategoryTab(cat.$1)).toList(),
      ),
    );
  }

  Widget _buildCategoryTab(SuggestionCategory category) {
    final dbAsync = ref.watch(doctorDbProvider);
    
    return dbAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
      data: (db) => _SuggestionsList(
        db: db,
        category: category,
        searchQuery: _searchQuery,
        onDelete: (id) => _confirmDelete(db, id),
      ),
    );
  }

  Future<void> _confirmDelete(DoctorDatabase db, int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Suggestion'),
        content: const Text('Are you sure you want to delete this suggestion?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final service = DynamicSuggestionsService(db);
      await service.deleteSuggestion(id);
      setState(() {}); // Refresh
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Suggestion deleted')),
        );
      }
    }
  }
}

class _SuggestionsList extends StatelessWidget {
  const _SuggestionsList({
    required this.db,
    required this.category,
    required this.searchQuery,
    required this.onDelete,
  });

  final DoctorDatabase db;
  final SuggestionCategory category;
  final String searchQuery;
  final void Function(int id) onDelete;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<UserSuggestion>>(
      future: _loadSuggestions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final suggestions = snapshot.data ?? [];
        
        // Filter by search query
        final filtered = searchQuery.isEmpty
            ? suggestions
            : suggestions.where((s) => 
                s.value.toLowerCase().contains(searchQuery.toLowerCase())
              ).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  searchQuery.isEmpty
                      ? 'No custom suggestions yet'
                      : 'No matching suggestions',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
                if (searchQuery.isEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Your suggestions will appear here\nas you use the app',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final suggestion = filtered[index];
            return _SuggestionCard(
              suggestion: suggestion,
              onDelete: () => onDelete(suggestion.id),
            );
          },
        );
      },
    );
  }

  Future<List<UserSuggestion>> _loadSuggestions() async {
    final service = DynamicSuggestionsService(db);
    return service.getUserSuggestions(category);
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({
    required this.suggestion,
    required this.onDelete,
  });

  final UserSuggestion suggestion;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          suggestion.value,
          style: const TextStyle(fontSize: 14),
        ),
        subtitle: Text(
          'Used ${suggestion.usageCount} time${suggestion.usageCount == 1 ? '' : 's'} • '
          'Last used ${_formatDate(suggestion.lastUsedAt)}',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.delete_outline_rounded,
            color: Colors.red[400],
          ),
          onPressed: onDelete,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes}m ago';
      }
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
