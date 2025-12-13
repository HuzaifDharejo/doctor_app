import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../db/doctor_db.dart';
import '../../models/clinical_letter.dart';
import '../../providers/db_provider.dart';
import '../../services/clinical_letter_service.dart';
import '../../theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';

/// Screen for managing clinical letters and documents
class ClinicalLettersScreen extends ConsumerStatefulWidget {
  const ClinicalLettersScreen({super.key});

  @override
  ConsumerState<ClinicalLettersScreen> createState() => _ClinicalLettersScreenState();
}

class _ClinicalLettersScreenState extends ConsumerState<ClinicalLettersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _letterService = ClinicalLetterService();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
                  child: PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    ),
                    onSelected: (value) {
                      if (value == 'templates') _showTemplates();
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'templates',
                        child: Row(
                          children: [
                            Icon(Icons.description),
                            SizedBox(width: 8),
                            Text('Letter Templates'),
                          ],
                        ),
                      ),
                    ],
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
                              colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.description,
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
                                'Clinical Letters',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Letters, certificates & documents',
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
              isScrollable: true,
              tabs: const [
                Tab(text: 'Draft'),
                Tab(text: 'Pending'),
                Tab(text: 'Sent'),
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
                  hintText: 'Search letters...',
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
                  _buildLettersTab('draft'),
                  _buildLettersTab('pending_signature'),
                  _buildLettersTab('sent'),
                  _buildLettersTab(null), // All
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateLetterDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New Letter'),
        backgroundColor: const Color(0xFF8B5CF6),
      ),
    );
  }

  Widget _buildLettersTab(String? status) {
    return FutureBuilder<List<ClinicalLetterData>>(
      future: status != null
          ? _letterService.getLettersByStatus(status)
          : _letterService.getAllLetters(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(status);
        }

        final letters = snapshot.data!
            .where((l) => _matchesSearch(l))
            .toList();

        if (letters.isEmpty) {
          return _buildEmptyState(status);
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: letters.length,
            itemBuilder: (context, index) {
              return _buildLetterCard(letters[index]);
            },
          ),
        );
      },
    );
  }

  bool _matchesSearch(ClinicalLetterData letter) {
    if (_searchController.text.isEmpty) return true;
    final query = _searchController.text.toLowerCase();
    return letter.letterType.toLowerCase().contains(query) ||
        letter.title.toLowerCase().contains(query) ||
        letter.recipientName.toLowerCase().contains(query);
  }

  Widget _buildLetterCard(ClinicalLetterData letter) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final model = _letterService.toModel(letter);
    final typeColor = _getLetterTypeColor(letter.letterType);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      color: isDark ? AppColors.darkSurface : Colors.white,
      child: InkWell(
        onTap: () => _showLetterDetails(letter),
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
                      _getLetterTypeIcon(letter.letterType),
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
                          letter.title.isNotEmpty ? letter.title : _getLetterTypeName(letter.letterType),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          ClinicalLetterType.fromValue(letter.letterType).label,
                          style: TextStyle(
                            fontSize: 13,
                            color: typeColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(letter.status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (letter.recipientName.isNotEmpty)
                    Expanded(
                      child: _buildInfoChip(
                        Icons.person,
                        'To: ${letter.recipientName}',
                        Colors.blue,
                      ),
                    ),
                  if (letter.recipientName.isNotEmpty) const SizedBox(width: 8),
                  _buildInfoChip(
                    Icons.calendar_today,
                    _formatDate(letter.createdAt),
                    Colors.grey,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (letter.status == 'draft') ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _editLetter(letter),
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _submitForSignature(letter.id),
                        icon: const Icon(Icons.send, size: 16),
                        label: const Text('Submit'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ] else if (letter.status == 'pending_signature') ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _signLetter(letter.id),
                        icon: const Icon(Icons.draw, size: 16),
                        label: const Text('Sign'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ] else if (letter.status == 'signed') ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _printLetter(letter),
                        icon: const Icon(Icons.print, size: 16),
                        label: const Text('Print'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _sendLetter(letter.id),
                        icon: const Icon(Icons.send, size: 16),
                        label: const Text('Send'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ] else if (letter.status == 'sent') ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _printLetter(letter),
                        icon: const Icon(Icons.print, size: 16),
                        label: const Text('Print Copy'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;

    switch (status) {
      case 'draft':
        color = Colors.grey;
        label = 'DRAFT';
        break;
      case 'pending_signature':
        color = Colors.orange;
        label = 'PENDING';
        break;
      case 'signed':
        color = Colors.blue;
        label = 'SIGNED';
        break;
      case 'sent':
        color = Colors.green;
        label = 'SENT';
        break;
      default:
        color = Colors.grey;
        label = status.toUpperCase();
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
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _getLetterTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'referral':
        return Colors.blue;
      case 'medical_certificate':
        return Colors.green;
      case 'sick_leave':
        return Colors.orange;
      case 'prescription':
        return Colors.red;
      case 'lab_request':
        return Colors.purple;
      case 'discharge_summary':
        return Colors.teal;
      case 'consultation_report':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  IconData _getLetterTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'referral':
        return Icons.send;
      case 'medical_certificate':
        return Icons.verified;
      case 'sick_leave':
        return Icons.sick;
      case 'prescription':
        return Icons.medication;
      case 'lab_request':
        return Icons.science;
      case 'discharge_summary':
        return Icons.summarize;
      case 'consultation_report':
        return Icons.assignment;
      default:
        return Icons.description;
    }
  }

  String _getLetterTypeName(String type) {
    return type.split('_').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
  }

  Widget _buildEmptyState(String? status) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String message;
    IconData icon;

    switch (status) {
      case 'draft':
        message = 'No draft letters';
        icon = Icons.edit_document;
        break;
      case 'pending_signature':
        message = 'No letters pending signature';
        icon = Icons.draw;
        break;
      case 'sent':
        message = 'No sent letters';
        icon = Icons.outbox;
        break;
      default:
        message = 'No letters found';
        icon = Icons.description;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
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
          const SizedBox(height: 8),
          Text(
            'Create a new letter to get started',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showLetterDetails(ClinicalLetterData letter) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final model = _letterService.toModel(letter);

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
                          color: isDark ? Colors.grey[600] : Colors.grey[300],
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
                            color: _getLetterTypeColor(letter.letterType).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getLetterTypeIcon(letter.letterType),
                            color: _getLetterTypeColor(letter.letterType),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                letter.title.isNotEmpty ? letter.title : ClinicalLetterType.fromValue(letter.letterType).label,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Patient #${letter.patientId}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildStatusBadge(letter.status),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildDetailRow('Type', ClinicalLetterType.fromValue(letter.letterType).label),
                    _buildDetailRow('Status', ClinicalLetterStatus.fromValue(letter.status).label),
                    if (letter.recipientName.isNotEmpty)
                      _buildDetailRow('Recipient', letter.recipientName),
                    if (letter.recipientAddress.isNotEmpty)
                      _buildDetailRow('Address', letter.recipientAddress),
                    _buildDetailRow('Created', _formatDateTime(letter.createdAt)),
                    if (letter.signedAt != null)
                      _buildDetailRow('Signed', _formatDateTime(letter.signedAt!)),
                    if (letter.sentAt != null)
                      _buildDetailRow('Sent', _formatDateTime(letter.sentAt!)),
                    if (letter.sentMethod.isNotEmpty)
                      _buildDetailRow('Sent Via', letter.sentMethod),
                    const Divider(height: 32),
                    const Text(
                      'Content',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        letter.content ?? 'No content',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _deleteLetter(letter.id),
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Delete'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _printLetter(letter),
                            icon: const Icon(Icons.print),
                            label: const Text('Print'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8B5CF6),
                            ),
                          ),
                        ),
                      ],
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
            width: 100,
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _submitForSignature(int id) async {
    await _letterService.submitForSignature(id);
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Letter submitted for signature')),
      );
    }
  }

  Future<void> _signLetter(int id) async {
    await _letterService.signLetter(id, 'Current User');
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Letter signed')),
      );
    }
  }

  Future<void> _sendLetter(int id) async {
    final method = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Letter'),
        content: const Text('How would you like to send this letter?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'email'),
            child: const Text('Email'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'fax'),
            child: const Text('Fax'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'print'),
            child: const Text('Print & Mail'),
          ),
        ],
      ),
    );

    if (method != null) {
      await _letterService.sendLetter(id: id, method: method);
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Letter sent via $method')),
        );
      }
    }
  }

  Future<void> _deleteLetter(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Letter'),
        content: const Text('Are you sure you want to delete this letter?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _letterService.deleteLetter(id);
      if (mounted) {
        Navigator.pop(context);
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Letter deleted')),
        );
      }
    }
  }

  void _printLetter(ClinicalLetterData letter) {
    // In real app, this would generate a PDF and print
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preparing letter for printing...')),
    );
  }

  void _editLetter(ClinicalLetterData letter) {
    _showCreateLetterDialog(context, existing: letter);
  }

  void _showTemplates() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final templates = [
      {'name': 'Referral Letter', 'type': 'referral'},
      {'name': 'Medical Certificate', 'type': 'medical_certificate'},
      {'name': 'Sick Leave', 'type': 'sick_leave'},
      {'name': 'Lab Request', 'type': 'lab_request'},
      {'name': 'Discharge Summary', 'type': 'discharge_summary'},
      {'name': 'Consultation Report', 'type': 'consultation_report'},
    ];

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
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[600] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Letter Templates',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...templates.map((t) => ListTile(
                leading: Icon(
                  _getLetterTypeIcon(t['type']!),
                  color: _getLetterTypeColor(t['type']!),
                ),
                title: Text(t['name']!),
                onTap: () {
                  Navigator.pop(context);
                  _showCreateLetterDialog(context, templateType: t['type']);
                },
              )),
            ],
          ),
        );
      },
    );
  }

  void _showCreateLetterDialog(BuildContext context, {ClinicalLetterData? existing, String? templateType}) {
    final type = existing?.letterType ?? templateType ?? 'referral';
    final subjectController = TextEditingController(text: existing?.title);
    final recipientController = TextEditingController(text: existing?.recipientName);
    final addressController = TextEditingController(text: existing?.recipientAddress);
    final contentController = TextEditingController(text: existing?.content);
    int? selectedPatientId = existing?.patientId;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final letterTypes = ['referral', 'medical_certificate', 'sick_leave', 'prescription', 'lab_request', 'discharge_summary', 'consultation_report'];
    String selectedType = type;

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
              child: DraggableScrollableSheet(
                initialChildSize: 0.9,
                maxChildSize: 0.95,
                minChildSize: 0.5,
                expand: false,
                builder: (context, scrollController) {
                  return Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.grey[600] : Colors.grey[300],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            existing == null ? 'Create Letter' : 'Edit Letter',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Patient selector
                          if (existing == null) ...[
                            FutureBuilder<List<Patient>>(
                              future: ref.read(doctorDbProvider).value?.getAllPatients() ?? Future.value([]),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator());
                                }
                                final patientList = snapshot.data ?? [];
                                return DropdownButtonFormField<int>(
                                  decoration: const InputDecoration(
                                    labelText: 'Select Patient *',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.person),
                                  ),
                                  value: selectedPatientId,
                                  items: patientList.map((p) => DropdownMenuItem(
                                    value: p.id,
                                    child: Text('${p.firstName} ${p.lastName}'),
                                  )).toList(),
                                  onChanged: (value) {
                                    setModalState(() => selectedPatientId = value);
                                  },
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                          ],
                          const Text('Letter Type'),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: letterTypes.map((lt) {
                              return ChoiceChip(
                                label: Text(_getLetterTypeName(lt)),
                                selected: selectedType == lt,
                                selectedColor: _getLetterTypeColor(lt).withValues(alpha: 0.2),
                                onSelected: (selected) {
                                  setModalState(() => selectedType = lt);
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: subjectController,
                            decoration: const InputDecoration(
                              labelText: 'Subject',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: recipientController,
                            decoration: const InputDecoration(
                              labelText: 'Recipient Name',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: addressController,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Recipient Address',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: contentController,
                            maxLines: 8,
                            decoration: const InputDecoration(
                              labelText: 'Letter Content',
                              border: OutlineInputBorder(),
                              alignLabelWithHint: true,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: (existing == null && selectedPatientId == null) ? null : () async {
                                    // Save as draft
                                    if (existing == null) {
                                      await _letterService.createLetter(
                                        patientId: selectedPatientId!,
                                        letterType: selectedType,
                                        title: subjectController.text.isNotEmpty ? subjectController.text : 'Untitled',
                                        letterDate: DateTime.now(),
                                        recipientName: recipientController.text.isNotEmpty ? recipientController.text : null,
                                        recipientAddress: addressController.text.isNotEmpty ? addressController.text : null,
                                        content: contentController.text.isNotEmpty ? contentController.text : '',
                                      );
                                    } else {
                                      await _letterService.updateLetter(
                                        id: existing.id,
                                        title: subjectController.text.isNotEmpty ? subjectController.text : null,
                                        recipientName: recipientController.text.isNotEmpty ? recipientController.text : null,
                                        recipientAddress: addressController.text.isNotEmpty ? addressController.text : null,
                                        content: contentController.text.isNotEmpty ? contentController.text : null,
                                      );
                                    }

                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      setState(() {});
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Letter saved as draft')),
                                      );
                                    }
                                  },
                                  child: const Text('Save Draft'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: (existing == null && selectedPatientId == null) ? null : () async {
                                    // Create and submit for signature
                                    int letterId;
                                    if (existing == null) {
                                      letterId = await _letterService.createLetter(
                                        patientId: selectedPatientId!,
                                        letterType: selectedType,
                                        title: subjectController.text.isNotEmpty ? subjectController.text : 'Untitled',
                                        letterDate: DateTime.now(),
                                        recipientName: recipientController.text.isNotEmpty ? recipientController.text : null,
                                        recipientAddress: addressController.text.isNotEmpty ? addressController.text : null,
                                        content: contentController.text.isNotEmpty ? contentController.text : '',
                                      );
                                    } else {
                                      letterId = existing.id;
                                      await _letterService.updateLetter(
                                        id: letterId,
                                        title: subjectController.text.isNotEmpty ? subjectController.text : null,
                                        recipientName: recipientController.text.isNotEmpty ? recipientController.text : null,
                                        recipientAddress: addressController.text.isNotEmpty ? addressController.text : null,
                                        content: contentController.text.isNotEmpty ? contentController.text : null,
                                      );
                                    }
                                    await _letterService.submitForSignature(letterId);

                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      setState(() {});
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Letter submitted for signature')),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF8B5CF6),
                                  ),
                                  child: const Text('Submit'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
