import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/design_tokens.dart';
import '../../core/components/app_button.dart';
import '../../theme/app_theme.dart';
import '../widgets/communication_panel.dart';

/// Main communications screen for managing patient messages and calls
class CommunicationsScreen extends ConsumerStatefulWidget {
  const CommunicationsScreen();

  @override
  ConsumerState<CommunicationsScreen> createState() => _CommunicationsScreenState();
}

class _CommunicationsScreenState extends ConsumerState<CommunicationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
            expandedHeight: 200,
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
                              colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.forum_rounded,
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
                                'Communications',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Messages, calls & history',
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
                Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.message_rounded, size: 18), SizedBox(width: 6), Text('Messages')])),
                Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.phone_in_talk_rounded, size: 18), SizedBox(width: 6), Text('Calls')])),
                Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.history_rounded, size: 18), SizedBox(width: 6), Text('History')])),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            // Messages tab
            _buildMessagesTab(context),
            // Calls tab
            _buildCallsTab(context),
            // History tab
            _buildHistoryTab(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesTab(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;

    return ListView(
      primary: false,
      children: [
        // Active conversations
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Active Conversations',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  AppButton.tertiary(
                    label: 'New',
                    onPressed: () {
                      // Show new conversation dialog
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ..._buildConversationCards(context),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildConversationCards(BuildContext context) {
    final conversations = [
      {
        'name': 'Ahmed Hassan',
        'lastMessage': 'When should I reschedule?',
        'time': '2 minutes ago',
        'unread': 0,
        'avatar': 'A',
        'status': 'online',
      },
      {
        'name': 'Fatima Al-Mansouri',
        'lastMessage': 'Thank you for the prescription',
        'time': '1 hour ago',
        'unread': 1,
        'avatar': 'F',
        'status': 'offline',
      },
      {
        'name': 'Mohammed Al-Jaber',
        'lastMessage': 'Doctor sent lab results',
        'time': '3 hours ago',
        'unread': 2,
        'avatar': 'M',
        'status': 'offline',
      },
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final secondaryText = isDark ? Colors.grey[400] : Colors.grey[600];

    return conversations.asMap().entries.map((entry) {
      final index = entry.key;
      final conv = entry.value;
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => MessageThreadDialog(
                patientId: index + 1, // Use index-based ID for demo data
                patientName: conv['name'] as String,
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFF6366F1),
                      child: Text(
                        (conv['avatar'] as String),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: (conv['status'] as String) == 'online'
                              ? Colors.green
                              : Colors.grey,
                          shape: BoxShape.circle,
                          border: Border.all(color: cardColor, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        conv['name'] as String,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        conv['lastMessage'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      conv['time'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        color: secondaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if ((conv['unread'] as int) > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          (conv['unread'] as int).toString(),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
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
    }).toList();
  }

  Widget _buildCallsTab(BuildContext context) {
    return CallLogsWidget(patientId: 0);
  }

  Widget _buildHistoryTab(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;

    return SingleChildScrollView(
      primary: false,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Communication statistics
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Communication Summary',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 16),
                _buildStatRow(context, 'Total Messages', '42', Colors.blue),
                const SizedBox(height: 12),
                _buildStatRow(context, 'Total Calls', '7', Colors.green),
                const SizedBox(height: 12),
                _buildStatRow(context, 'Avg Response Time', '2 hours 15 min', Colors.orange),
                const SizedBox(height: 12),
                _buildStatRow(context, 'Message Success Rate', '98%', Colors.purple),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Recent activity
          Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          ..._buildActivityTimeline(context),
        ],
      ),
    );
  }

  Widget _buildStatRow(BuildContext context, String label, String value, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final valueColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: labelColor,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildActivityTimeline(BuildContext context) {
    final activities = [
      {
        'type': 'call',
        'patient': 'Ahmed Hassan',
        'detail': 'Voice call completed - 22 minutes',
        'time': '2 hours ago',
        'icon': Icons.phone_in_talk_rounded,
        'color': Color(0xFF10B981),
      },
      {
        'type': 'message',
        'patient': 'Fatima Al-Mansouri',
        'detail': 'Sent prescription follow-up message',
        'time': '5 hours ago',
        'icon': Icons.message_rounded,
        'color': Color(0xFF6366F1),
      },
      {
        'type': 'call',
        'patient': 'Mohammed Al-Jaber',
        'detail': 'Voice call - Missed by patient',
        'time': '1 day ago',
        'icon': Icons.call_missed_rounded,
        'color': Color(0xFFDC2626),
      },
      {
        'type': 'message',
        'patient': 'Sarah Johnson',
        'detail': 'Received appointment reschedule request',
        'time': '2 days ago',
        'icon': Icons.message_rounded,
        'color': Color(0xFF6366F1),
      },
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final secondaryText = isDark ? Colors.grey[400] : Colors.grey[600];
    final lineColor = isDark ? Colors.grey[700] : Colors.grey[300];

    return activities.asMap().entries.map((entry) {
      final isLast = entry.key == activities.length - 1;
      final activity = entry.value;

      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                CircleAvatar(
                  backgroundColor: (activity['color'] as Color).withValues(alpha: 0.2),
                  child: Icon(
                    activity['icon'] as IconData,
                    color: activity['color'] as Color,
                    size: 18,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 40,
                    color: lineColor,
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity['patient'] as String,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activity['detail'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      color: secondaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activity['time'] as String,
                    style: TextStyle(
                      fontSize: 11,
                      color: secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}


