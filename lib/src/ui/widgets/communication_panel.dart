import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Panel for displaying patient communication history and initiating messages
class CommunicationPanel extends ConsumerStatefulWidget {
  const CommunicationPanel({
    required this.patientId,
    this.patientName,
  });

  final int patientId;
  final String? patientName;

  @override
  ConsumerState<CommunicationPanel> createState() => _CommunicationPanelState();
}

class _CommunicationPanelState extends ConsumerState<CommunicationPanel> {
  late TextEditingController _messageController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Communication stats header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[800]!),
            ),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem(
                  context,
                  icon: Icons.message_rounded,
                  label: 'Messages',
                  value: '12',
                ),
                Container(height: 30, width: 1, color: Colors.grey[700]),
                _buildStatItem(
                  context,
                  icon: Icons.phone_in_talk_rounded,
                  label: 'Calls',
                  value: '3',
                ),
                Container(height: 30, width: 1, color: Colors.grey[700]),
                _buildStatItem(
                  context,
                  icon: Icons.schedule_rounded,
                  label: 'Avg Response',
                  value: '4h 30m',
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        // Communication history list
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            children: [
              _buildHistorySection(
                context,
                title: 'Recent Messages',
                items: [
                  _MessageHistoryItem(
                    from: 'Doctor',
                    message: 'Your test results came back normal',
                    time: '2 hours ago',
                    isRead: true,
                  ),
                  _MessageHistoryItem(
                    from: 'Patient',
                    message: 'Thank you, Doctor!',
                    time: '1 hour ago',
                    isRead: true,
                  ),
                ],
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _buildHistorySection(
                context,
                title: 'Recent Calls',
                items: [
                  _CallHistoryItem(
                    status: 'Completed',
                    duration: '15 minutes',
                    date: 'Yesterday at 2:30 PM',
                  ),
                  _CallHistoryItem(
                    status: 'Completed',
                    duration: '22 minutes',
                    date: '2 days ago at 10:00 AM',
                  ),
                ],
              ),
            ],
          ),
        ),
        // Message composer
        Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Colors.grey[800]!)),
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Send message to patient...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: Colors.grey[700]!),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                    suffixIcon: GestureDetector(
                      onTap: () {
                        // Future: Add attachment functionality
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Icon(Icons.attach_file_rounded, color: Colors.grey[600]),
                      ),
                    ),
                  ),
                  maxLines: null,
                ),
              ),
              const SizedBox(width: 8),
              FloatingActionButton(
                mini: true,
                backgroundColor: const Color(0xFF6366F1),
                onPressed: _isLoading
                    ? null
                    : () {
                        if (_messageController.text.trim().isNotEmpty) {
                          setState(() => _isLoading = true);
                          // Simulate sending message
                          Future.delayed(const Duration(milliseconds: 500), () {
                            _messageController.clear();
                            setState(() => _isLoading = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Message sent')),
                            );
                          });
                        }
                      },
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.send_rounded),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF6366F1), size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection(
    BuildContext context, {
    required String title,
    required List<dynamic> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...items.map((item) {
          if (item is _MessageHistoryItem) {
            return _buildMessageCard(context, item);
          } else if (item is _CallHistoryItem) {
            return _buildCallCard(context, item);
          }
          return const SizedBox.shrink();
        }),
      ],
    );
  }

  Widget _buildMessageCard(BuildContext context, _MessageHistoryItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
        leading: CircleAvatar(
          backgroundColor: item.from == 'Doctor' ? const Color(0xFF6366F1) : const Color(0xFF10B981),
          child: Text(
            item.from[0],
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          item.from,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        subtitle: Text(
          item.message,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, color: Colors.grey[400]),
        ),
        trailing: Text(
          item.time,
          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
        ),
      ),
    );
  }

  Widget _buildCallCard(BuildContext context, _CallHistoryItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF10B981).withOpacity(0.2),
          child: const Icon(Icons.phone_in_talk_rounded, color: Color(0xFF10B981), size: 20),
        ),
        title: Row(
          children: [
            Text(
              item.status,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(width: 8),
            Text(
              item.duration,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
        subtitle: Text(
          item.date,
          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
        ),
        trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey[700]),
      ),
    );
  }
}

/// Call history item for internal use
class _CallHistoryItem {
  final String status;
  final String duration;
  final String date;

  _CallHistoryItem({
    required this.status,
    required this.duration,
    required this.date,
  });
}

/// Message history item for internal use
class _MessageHistoryItem {
  final String from;
  final String message;
  final String time;
  final bool isRead;

  _MessageHistoryItem({
    required this.from,
    required this.message,
    required this.time,
    required this.isRead,
  });
}

/// Dialog for viewing detailed message thread
class MessageThreadDialog extends StatefulWidget {
  const MessageThreadDialog({
    required this.patientId,
    this.patientName,
  });

  final int patientId;
  final String? patientName;

  @override
  State<MessageThreadDialog> createState() => _MessageThreadDialogState();
}

class _MessageThreadDialogState extends State<MessageThreadDialog> {
  late TextEditingController _replyController;

  @override
  void initState() {
    super.initState();
    _replyController = TextEditingController();
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey[800]!)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Conversation with ${widget.patientName ?? 'Patient'}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Online',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Messages
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  _buildMessageBubble(
                    'Your test results came back normal. Continue with current medication.',
                    isFromDoctor: true,
                    time: '2 hours ago',
                  ),
                  const SizedBox(height: 12),
                  _buildMessageBubble(
                    'Thank you, Doctor! When should I schedule my next appointment?',
                    isFromDoctor: false,
                    time: '1 hour ago',
                  ),
                  const SizedBox(height: 12),
                  _buildMessageBubble(
                    'Please schedule a follow-up in 2 weeks.',
                    isFromDoctor: true,
                    time: '1 hour ago',
                  ),
                ],
              ),
            ),
            // Reply input
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey[800]!)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _replyController,
                      decoration: InputDecoration(
                        hintText: 'Type your reply...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.grey[700]!),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                      ),
                      maxLines: null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    mini: true,
                    backgroundColor: const Color(0xFF6366F1),
                    onPressed: () {
                      if (_replyController.text.trim().isNotEmpty) {
                        _replyController.clear();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Message sent')),
                        );
                      }
                    },
                    child: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
    String message, {
    required bool isFromDoctor,
    required String time,
  }) {
    return Align(
      alignment: isFromDoctor ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 250),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isFromDoctor
              ? Colors.grey[800]
              : const Color(0xFF6366F1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget for displaying call logs
class CallLogsWidget extends ConsumerWidget {
  const CallLogsWidget({required this.patientId});

  final int patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Call History',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(4, (index) {
            final isCompleted = index != 2;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[800]!),
                ),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: isCompleted
                          ? const Color(0xFF10B981).withOpacity(0.2)
                          : const Color(0xFFDC2626).withOpacity(0.2),
                      child: Icon(
                        isCompleted ? Icons.phone_in_talk_rounded : Icons.call_missed_rounded,
                        color: isCompleted ? const Color(0xFF10B981) : const Color(0xFFDC2626),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isCompleted ? 'Completed' : 'Missed',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isCompleted ? '${15 + index} minutes' : 'No answer',
                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${index + 1} day${index > 0 ? 's' : ''} ago',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

