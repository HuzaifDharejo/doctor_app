import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../db/doctor_db.dart';
import '../../extensions/drift_extensions.dart';
import '../../models/consent.dart';
import '../../providers/db_provider.dart';
import '../../services/consent_service.dart';
import '../../theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';

/// Screen for managing patient consents
class ConsentScreen extends ConsumerStatefulWidget {
  const ConsentScreen({super.key});

  @override
  ConsumerState<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends ConsumerState<ConsentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _consentService = ConsentService();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : Colors.white;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: surfaceColor,
            foregroundColor: textColor,
            elevation: 0,
            scrolledUnderElevation: 1,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.warning_amber,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    ),
                    onPressed: _showExpiringConsents,
                    tooltip: 'Expiring consents',
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                        : [const Color(0xFFF8FAFC), surfaceColor],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF14B8A6), Color(0xFF2DD4BF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF14B8A6).withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.verified_user,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Consent Management',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Patient consent forms & documentation',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'Active'),
                Tab(text: 'Expired'),
                Tab(text: 'All'),
              ],
            ),
          ),
        ],
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search consents...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                ),
                onChanged: (value) => setState(() {}),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildConsentsTab('active'),
                  _buildConsentsTab('expired'),
                  _buildConsentsTab(null),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateConsentDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New Consent'),
        backgroundColor: const Color(0xFF14B8A6),
      ),
    );
  }

  Widget _buildConsentsTab(String? filter) {
    return FutureBuilder<List<ConsentData>>(
      future: _fetchConsents(filter),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(filter);
        }

        final consents = snapshot.data!
            .where((c) => _matchesSearch(c))
            .toList();

        if (consents.isEmpty) {
          return _buildEmptyState(filter);
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: consents.length,
            itemBuilder: (context, index) {
              return _buildConsentCard(consents[index]);
            },
          ),
        );
      },
    );
  }

  Future<List<ConsentData>> _fetchConsents(String? filter) async {
    switch (filter) {
      case 'active':
        return _consentService.getActiveConsents();
      case 'expired':
        return _consentService.getExpiredConsents();
      default:
        return _consentService.getAllConsents();
    }
  }

  bool _matchesSearch(ConsentData consent) {
    if (_searchController.text.isEmpty) return true;
    final query = _searchController.text.toLowerCase();
    return consent.consentType.toLowerCase().contains(query) ||
        (consent.description?.toLowerCase().contains(query) ?? false);
  }

  Widget _buildConsentCard(ConsentData consent) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final model = _consentService.toModel(consent);
    final typeColor = _getConsentTypeColor(consent.consentType);
    final isExpired = consent.expirationDate?.isBefore(DateTime.now()) ?? false;
    final isExpiringSoon = !isExpired &&
        consent.expirationDate != null &&
        consent.expirationDate!.difference(DateTime.now()).inDays <= 30;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      color: isDark ? AppColors.darkSurface : Colors.white,
      child: InkWell(
        onTap: () => _showConsentDetails(consent),
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getConsentTypeIcon(consent.consentType),
                      color: typeColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          model.type.displayName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Patient #${consent.patientId}',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(isExpired, isExpiringSoon),
                ],
              ),
              if (consent.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  consent.description!,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(
                    Icons.event,
                    'Signed: ${_formatDate(consent.consentDate)}',
                    Colors.green,
                  ),
                  const SizedBox(width: 8),
                  if (consent.expirationDate != null)
                    _buildInfoChip(
                      Icons.timer,
                      'Expires: ${_formatDate(consent.expirationDate!)}',
                      isExpired ? Colors.red : (isExpiringSoon ? Colors.orange : Colors.grey),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (!isExpired) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _revokeConsent(consent.id),
                        icon: const Icon(Icons.cancel, size: 16),
                        label: const Text('Revoke'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showConsentDetails(consent),
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('View'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF14B8A6),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isExpired, bool isExpiringSoon) {
    Color color;
    String label;

    if (isExpired) {
      color = Colors.red;
      label = 'EXPIRED';
    } else if (isExpiringSoon) {
      color = Colors.orange;
      label = 'EXPIRING';
    } else {
      color = Colors.green;
      label = 'ACTIVE';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getConsentTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'treatment':
        return Colors.blue;
      case 'procedure':
        return Colors.purple;
      case 'hipaa':
        return Colors.teal;
      case 'research':
        return Colors.orange;
      case 'telehealth':
        return Colors.green;
      case 'medication':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getConsentTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'treatment':
        return Icons.medical_services;
      case 'procedure':
        return Icons.healing;
      case 'hipaa':
        return Icons.security;
      case 'research':
        return Icons.science;
      case 'telehealth':
        return Icons.video_call;
      case 'medication':
        return Icons.medication;
      default:
        return Icons.description;
    }
  }

  Widget _buildEmptyState(String? filter) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String message = filter == 'expired' ? 'No expired consents' : 'No consents found';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.verified_user,
            size: 64,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showConsentDetails(ConsentData consent) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final model = _consentService.toModel(consent);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _getConsentTypeColor(consent.consentType).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getConsentTypeIcon(consent.consentType),
                            color: _getConsentTypeColor(consent.consentType),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                model.type.displayName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Patient #${consent.patientId}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildDetailRow('Status', model.status.displayName),
                    _buildDetailRow('Consent Date', _formatDate(consent.consentDate)),
                    if (consent.expirationDate != null)
                      _buildDetailRow('Expiration Date', _formatDate(consent.expirationDate!)),
                    if (consent.witnessName != null)
                      _buildDetailRow('Witness', consent.witnessName!),
                    if (consent.description != null) ...[
                      const Divider(height: 32),
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        consent.description!,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Generating PDF...')),
                          );
                        },
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Download PDF'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _revokeConsent(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke Consent'),
        content: const Text('Are you sure you want to revoke this consent?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _consentService.revokeConsent(consentId: id);
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Consent revoked')),
        );
      }
    }
  }

  void _showExpiringConsents() async {
    final expiring = await _consentService.getExpiringSoonConsents(days: 30);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Expiring Consents',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${expiring.length} consent(s) expiring within 30 days',
                style: const TextStyle(color: Colors.orange),
              ),
              const SizedBox(height: 16),
              if (expiring.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text('No expiring consents')),
                )
              else
                ...expiring.take(5).map((c) => ListTile(
                  leading: Icon(
                    _getConsentTypeIcon(c.consentType),
                    color: Colors.orange,
                  ),
                  title: Text(_consentService.toModel(c).type.displayName),
                  subtitle: Text('Expires: ${_formatDate(c.expirationDate!)}'),
                )),
            ],
          ),
        );
      },
    );
  }

  void _showCreateConsentDialog(BuildContext context) {
    String selectedType = 'treatment';
    DateTime consentDate = DateTime.now();
    DateTime? expirationDate;
    final descriptionController = TextEditingController();
    final witnessController = TextEditingController();

    final consentTypes = ['treatment', 'procedure', 'hipaa', 'research', 'telehealth', 'medication'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'New Consent',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text('Consent Type'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: consentTypes.map((type) {
                          return ChoiceChip(
                            label: Text(type[0].toUpperCase() + type.substring(1)),
                            selected: selectedType == type,
                            selectedColor: _getConsentTypeColor(type).withValues(alpha: 0.2),
                            onSelected: (selected) {
                              setModalState(() => selectedType = type);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: consentDate,
                                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                                  lastDate: DateTime.now(),
                                );
                                if (date != null) {
                                  setModalState(() => consentDate = date);
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Consent Date',
                                  border: OutlineInputBorder(),
                                ),
                                child: Text(_formatDate(consentDate)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now().add(const Duration(days: 365)),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 730)),
                                );
                                setModalState(() => expirationDate = date);
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Expiration (Optional)',
                                  border: OutlineInputBorder(),
                                ),
                                child: Text(expirationDate != null ? _formatDate(expirationDate!) : 'No expiration'),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: witnessController,
                        decoration: const InputDecoration(
                          labelText: 'Witness Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            await _consentService.recordConsent(
                              patientId: 1, // placeholder
                              consentType: selectedType,
                              consentDate: consentDate,
                              expirationDate: expirationDate,
                              description: descriptionController.text.isNotEmpty ? descriptionController.text : null,
                              witnessName: witnessController.text.isNotEmpty ? witnessController.text : null,
                            );

                            if (context.mounted) {
                              Navigator.pop(context);
                              setState(() {});
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Consent recorded')),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF14B8A6),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Record Consent'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
