import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/drug_reference_service.dart';

/// Drug search and selection widget
class DrugSearchWidget extends ConsumerStatefulWidget {
  final Function(DrugInfo) onDrugSelected;
  final List<DrugInfo> selectedDrugs;
  final String? placeholder;
  final int maxSelections;

  const DrugSearchWidget({
    Key? key,
    required this.onDrugSelected,
    required this.selectedDrugs,
    this.placeholder,
    this.maxSelections = 10,
  }) : super(key: key);

  @override
  ConsumerState<DrugSearchWidget> createState() => _DrugSearchWidgetState();
}

class _DrugSearchWidgetState extends ConsumerState<DrugSearchWidget> {
  late TextEditingController _searchController;
  List<DrugInfo> _searchResults = [];
  bool _isSearching = false;
  final DrugReferenceService _drugService = const DrugReferenceService();

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);

    try {
      final results = await _drugService.searchDrugs(
        query,
        limit: 10,
      );

      setState(() {
        _searchResults = results
            .where((drug) =>
                !widget.selectedDrugs.any((selected) => selected.id == drug.id))
            .toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching drugs: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  void _selectDrug(DrugInfo drug) {
    if (widget.selectedDrugs.length < widget.maxSelections) {
      widget.onDrugSelected(drug);
      _searchController.clear();
      setState(() => _searchResults = []);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Maximum ${widget.maxSelections} drugs allowed',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search field
        AppInput.search(
          controller: _searchController,
          hint: widget.placeholder ?? 'Search drugs...',
          prefixIcon: Icons.medication_outlined,
          suffixIcon: _isSearching ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : null,
          onChanged: _performSearch,
        ),
        const SizedBox(height: 12),

        // Search results
        if (_searchResults.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey.withValues(alpha: 0.3),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final drug = _searchResults[index];
                return ListTile(
                  onTap: () => _selectDrug(drug),
                  title: Text(drug.name),
                  subtitle: Text(
                    '${drug.genericName} • ${drug.drugClass}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.add_circle_outline),
                  dense: true,
                );
              },
            ),
          )
        else if (_searchController.text.isNotEmpty && !_isSearching)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Text(
              'No drugs found',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ),

        // Selected drugs
        if (widget.selectedDrugs.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Selected Drugs (${widget.selectedDrugs.length})',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.selectedDrugs
                .map(
                  (drug) => Chip(
                    label: Text(drug.name),
                    onDeleted: () {
                      // Note: actual deletion handled by parent
                    },
                    backgroundColor: Colors.indigo.withValues(alpha: 0.1),
                    labelStyle: const TextStyle(
                      color: Colors.indigo,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}

/// Drug interaction checker dialog
class InteractionCheckerDialog extends ConsumerStatefulWidget {
  final List<DrugInfo> drugs;
  final VoidCallback? onClose;

  const InteractionCheckerDialog({
    Key? key,
    required this.drugs,
    this.onClose,
  }) : super(key: key);

  @override
  ConsumerState<InteractionCheckerDialog> createState() =>
      _InteractionCheckerDialogState();
}

class _InteractionCheckerDialogState
    extends ConsumerState<InteractionCheckerDialog> {
  late Future<List<DrugInteraction>> _interactionsFuture;
  final DrugReferenceService _drugService = const DrugReferenceService();

  @override
  void initState() {
    super.initState();
    _checkInteractions();
  }

  void _checkInteractions() {
    _interactionsFuture = _drugService.checkInteractions(
      widget.drugs.map((d) => d.id).toList(),
      includeLowRisk: true,
    );
  }

  Color _getSeverityColor(InteractionSeverity severity) {
    switch (severity) {
      case InteractionSeverity.none:
        return const Color(0xFF4CAF50); // green
      case InteractionSeverity.minor:
        return const Color(0xFF2196F3); // blue
      case InteractionSeverity.moderate:
        return const Color(0xFFFFC107); // amber
      case InteractionSeverity.significant:
        return const Color(0xFFFF9800); // orange
      case InteractionSeverity.contraindicated:
        return const Color(0xFFF44336); // red
    }
  }

  String _getSeverityLabel(InteractionSeverity severity) {
    switch (severity) {
      case InteractionSeverity.none:
        return 'None';
      case InteractionSeverity.minor:
        return 'Minor';
      case InteractionSeverity.moderate:
        return 'Moderate';
      case InteractionSeverity.significant:
        return 'Significant';
      case InteractionSeverity.contraindicated:
        return 'Contraindicated';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_outlined,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Drug Interaction Check',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${widget.drugs.length} drugs selected',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onClose?.call();
                  },
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: FutureBuilder<List<DrugInteraction>>(
              future: _interactionsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                final interactions = snapshot.data ?? [];

                if (interactions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 48,
                          color: Colors.green[600],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No Interactions Found',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'These drugs appear safe to use together',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: interactions.length,
                  itemBuilder: (context, index) {
                    final interaction = interactions[index];
                    final color = _getSeverityColor(interaction.severity);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ExpansionTile(
                        title: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${interaction.drug1Name} + ${interaction.drug2Name}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    _getSeverityLabel(interaction.severity),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: color,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mechanism',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  interaction.mechanism,
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Management',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  interaction.management,
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.grey.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppButton.tertiary(
                  label: 'Close',
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onClose?.call();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Drug warnings panel widget
class DrugWarningsPanel extends ConsumerWidget {
  final String drugId;
  final String drugName;

  const DrugWarningsPanel({
    Key? key,
    required this.drugId,
    required this.drugName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const drugService = DrugReferenceService();

    return FutureBuilder<List<FDAWarning>>(
      future: drugService.getFDAWarnings(drugId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 100,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final warnings = snapshot.data ?? [];

        if (warnings.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
              child: Text(
                'FDA Warnings',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            ...warnings.map(
              (warning) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: const Color(0xFFF44336).withValues(alpha: 0.1),
                  border: Border.all(
                    color: const Color(0xFFF44336).withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.warning_rounded,
                          color: Color(0xFFF44336),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            warning.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Color(0xFFF44336),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      warning.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

