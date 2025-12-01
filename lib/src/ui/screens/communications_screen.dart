import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Communications'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Messages', icon: Icon(Icons.message_rounded, size: 18)),
            Tab(text: 'Calls', icon: Icon(Icons.phone_in_talk_rounded, size: 18)),
            Tab(text: 'History', icon: Icon(Icons.history_rounded, size: 18)),
          ],
          indicatorColor: const Color(0xFF6366F1),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
        ),
      ),
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
    );
  }

  Widget _buildMessagesTab(BuildContext context) {
    return ListView(
      children: [
        // Active conversations
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Active Conversations',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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

    return conversations.map((conv) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => MessageThreadDialog(
                patientId: 1,
                patientName: conv['name'] as String,
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[800]!),
            ),
            padding: const EdgeInsets.all(12),
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
                          border: Border.all(color: Colors.grey[900]!, width: 2),
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
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        conv['lastMessage'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
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
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    if ((conv['unread'] as int) > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Communication statistics
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[800]!),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Communication Summary',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildStatRow('Total Messages', '42', Colors.blue),
                const SizedBox(height: 12),
                _buildStatRow('Total Calls', '7', Colors.green),
                const SizedBox(height: 12),
                _buildStatRow('Avg Response Time', '2 hours 15 min', Colors.orange),
                const SizedBox(height: 12),
                _buildStatRow('Message Success Rate', '98%', Colors.purple),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Recent activity
          const Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ..._buildActivityTimeline(context),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
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
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white,
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
                  backgroundColor: (activity['color'] as Color).withOpacity(0.2),
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
                    color: Colors.grey[800],
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
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activity['detail'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activity['time'] as String,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
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
