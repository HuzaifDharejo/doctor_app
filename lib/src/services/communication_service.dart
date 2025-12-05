import 'package:flutter/material.dart';

/// Service for managing patient communication history, messaging, and call logs
/// Currently uses in-memory storage; can be upgraded to database storage later
class CommunicationService {
  CommunicationService();
  
  // In-memory storage for messages and calls (per patient)
  final Map<int, List<CommunicationMessage>> _messagesCache = {};
  final Map<int, List<VoiceCallLog>> _callsCache = {};

  /// Create a new message in communication history
  Future<CommunicationMessage> createMessage({
    required int patientId,
    required String senderType, // 'doctor', 'patient'
    required String messageType, // 'text', 'audio', 'document', 'video'
    required String content,
    String? attachmentUrl,
    String? attachmentType, // 'document', 'image', 'audio', 'video'
  }) async {
    final message = CommunicationMessage(
      id: '${patientId}_${DateTime.now().millisecondsSinceEpoch}',
      patientId: patientId,
      senderType: senderType,
      messageType: messageType,
      content: content,
      createdAt: DateTime.now(),
      isRead: senderType == 'doctor', // Auto-read if doctor sent
      attachmentUrl: attachmentUrl,
      attachmentType: attachmentType,
      metadata: {},
    );
    
    // Store in cache
    _messagesCache.putIfAbsent(patientId, () => []);
    _messagesCache[patientId]!.add(message);
    
    return message;
  }

  /// Create a voice call log
  Future<VoiceCallLog> createCallLog({
    required int patientId,
    required String initiatedBy, // 'doctor', 'patient'
    required DateTime callStart,
    required int durationSeconds,
    required String status, // 'completed', 'missed', 'declined', 'no_answer'
    String? callNotes,
  }) async {
    final callEnd = callStart.add(Duration(seconds: durationSeconds));

    final callLog = VoiceCallLog(
      id: '${patientId}_call_${DateTime.now().millisecondsSinceEpoch}',
      patientId: patientId,
      initiatedBy: initiatedBy,
      callStart: callStart,
      callEnd: callEnd,
      durationSeconds: durationSeconds,
      status: status,
      callNotes: callNotes ?? '',
      createdAt: DateTime.now(),
    );
    
    // Store in cache
    _callsCache.putIfAbsent(patientId, () => []);
    _callsCache[patientId]!.add(callLog);
    
    return callLog;
  }

  /// Get communication history for a patient
  Future<List<CommunicationMessage>> getCommunicationHistory(
    int patientId, {
    int limitDays = 90,
  }) async {
    final messages = _messagesCache[patientId] ?? [];
    final cutoffDate = DateTime.now().subtract(Duration(days: limitDays));
    
    // Filter by date range and sort by creation time
    final filteredMessages = messages
        .where((m) => m.createdAt.isAfter(cutoffDate))
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    
    return filteredMessages;
  }

  /// Get voice call history for a patient
  Future<List<VoiceCallLog>> getCallHistory(
    int patientId, {
    int limitDays = 90,
  }) async {
    final calls = _callsCache[patientId] ?? [];
    final cutoffDate = DateTime.now().subtract(Duration(days: limitDays));
    
    // Filter by date range and sort by call start time
    final filteredCalls = calls
        .where((c) => c.callStart.isAfter(cutoffDate))
        .toList()
      ..sort((a, b) => a.callStart.compareTo(b.callStart));
    
    return filteredCalls;
  }

  /// Get message count for unread messages
  Future<int> getUnreadMessageCount(int patientId) async {
    final messages = _messagesCache[patientId] ?? [];
    return messages.where((m) => !m.isRead && m.senderType == 'patient').length;
  }

  /// Get statistics on patient communication
  Future<CommunicationStats> getCommunicationStats(
    int patientId,
  ) async {
    final history = await getCommunicationHistory(patientId);
    final callLogs = await getCallHistory(patientId);

    final doctorMessages = history
        .where((m) => m.senderType == 'doctor')
        .toList();
    
    final patientMessages = history
        .where((m) => m.senderType == 'patient')
        .toList();

    final completedCalls = callLogs
        .where((c) => c.status == 'completed')
        .toList();

    final totalCallDuration = completedCalls.isEmpty
        ? 0
        : completedCalls.map((c) => c.durationSeconds).reduce((a, b) => a + b);

    return CommunicationStats(
      totalMessages: history.length,
      doctorMessages: doctorMessages.length,
      patientMessages: patientMessages.length,
      totalCalls: callLogs.length,
      completedCalls: completedCalls.length,
      totalCallDurationSeconds: totalCallDuration,
      lastMessageDate: history.isEmpty ? null : history.last.createdAt,
      lastCallDate: callLogs.isEmpty ? null : callLogs.last.callStart,
      averageResponseTime: _calculateAvgResponseTime(history),
    );
  }

  /// Get threaded conversation view (messages in order)
  Future<List<ConversationThread>> getConversationThreads(
    int patientId,
  ) async {
    final messages = await getCommunicationHistory(patientId);
    final threads = <ConversationThread>[];

    // Group messages by conversation threads (e.g., per day or per visit)
    DateTime? currentDate;
    List<CommunicationMessage> currentThread = [];

    for (final message in messages) {
      final messageDate = message.createdAt;
      final date = DateTime(messageDate.year, messageDate.month, messageDate.day);

      if (currentDate != date && currentThread.isNotEmpty) {
        threads.add(ConversationThread(
          id: '${patientId}_thread_${currentDate}',
          patientId: patientId,
          messages: currentThread,
          startTime: currentThread.first.createdAt,
          endTime: currentThread.last.createdAt,
        ));
        currentThread = [];
      }

      currentDate = date;
      currentThread.add(message);
    }

    if (currentThread.isNotEmpty) {
      threads.add(ConversationThread(
        id: '${patientId}_thread_${currentDate}',
        patientId: patientId,
        messages: currentThread,
        startTime: currentThread.first.createdAt,
        endTime: currentThread.last.createdAt,
      ));
    }

    return threads;
  }

  /// Queue message for offline delivery
  Future<QueuedMessage> queueMessage({
    required int patientId,
    required String messageType,
    required String content,
    String? attachmentUrl,
  }) async {
    return QueuedMessage(
      id: '${patientId}_queued_${DateTime.now().millisecondsSinceEpoch}',
      patientId: patientId,
      messageType: messageType,
      content: content,
      attachmentUrl: attachmentUrl,
      queuedAt: DateTime.now(),
      attempts: 0,
      status: 'queued',
    );
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(List<String> messageIds) async {
    // Update messages across all patients in cache
    for (final patientMessages in _messagesCache.values) {
      for (int i = 0; i < patientMessages.length; i++) {
        if (messageIds.contains(patientMessages[i].id)) {
          // Create a new message with isRead = true
          final oldMsg = patientMessages[i];
          patientMessages[i] = CommunicationMessage(
            id: oldMsg.id,
            patientId: oldMsg.patientId,
            senderType: oldMsg.senderType,
            messageType: oldMsg.messageType,
            content: oldMsg.content,
            createdAt: oldMsg.createdAt,
            isRead: true,
            attachmentUrl: oldMsg.attachmentUrl,
            attachmentType: oldMsg.attachmentType,
            metadata: oldMsg.metadata,
          );
        }
      }
    }
  }
  
  /// Mark all messages from a patient as read
  Future<void> markAllMessagesAsRead(int patientId) async {
    final messages = _messagesCache[patientId];
    if (messages == null) return;
    
    final messageIds = messages
        .where((m) => !m.isRead)
        .map((m) => m.id)
        .toList();
    await markMessagesAsRead(messageIds);
  }
  
  /// Clear communication history for a patient (useful for testing)
  void clearHistory(int patientId) {
    _messagesCache.remove(patientId);
    _callsCache.remove(patientId);
  }
  
  /// Seed demo communication data for a patient
  Future<void> seedDemoData(int patientId, String patientName) async {
    final now = DateTime.now();
    
    // Add some demo messages
    await createMessage(
      patientId: patientId,
      senderType: 'patient',
      messageType: 'text',
      content: 'Hello Doctor, I wanted to follow up on my last visit.',
    );
    
    await createMessage(
      patientId: patientId,
      senderType: 'doctor',
      messageType: 'text',
      content: 'Hello $patientName, how are you feeling today? Any updates on your symptoms?',
    );
    
    await createMessage(
      patientId: patientId,
      senderType: 'patient',
      messageType: 'text',
      content: 'I\'m feeling much better, thank you. The medication seems to be working.',
    );
    
    // Add some demo calls
    await createCallLog(
      patientId: patientId,
      initiatedBy: 'doctor',
      callStart: now.subtract(const Duration(days: 3)),
      durationSeconds: 320,
      status: 'completed',
      callNotes: 'Follow-up call - patient reported improvement',
    );
    
    await createCallLog(
      patientId: patientId,
      initiatedBy: 'patient',
      callStart: now.subtract(const Duration(days: 7)),
      durationSeconds: 0,
      status: 'missed',
      callNotes: 'Patient tried to reach during lunch hours',
    );
  }

  // Helper method
  Duration? _calculateAvgResponseTime(List<CommunicationMessage> messages) {
    if (messages.length < 2) return null;

    var totalResponseTime = Duration.zero;
    int responseCount = 0;

    for (int i = 1; i < messages.length; i++) {
      if (messages[i].senderType != messages[i - 1].senderType) {
        final timeBetween = messages[i].createdAt.difference(messages[i - 1].createdAt);
        totalResponseTime += timeBetween;
        responseCount++;
      }
    }

    if (responseCount == 0) return null;
    return Duration(milliseconds: totalResponseTime.inMilliseconds ~/ responseCount);
  }
}

/// Model for a communication message
class CommunicationMessage {
  const CommunicationMessage({
    required this.id,
    required this.patientId,
    required this.senderType,
    required this.messageType,
    required this.content,
    required this.createdAt,
    required this.isRead,
    this.attachmentUrl,
    this.attachmentType,
    required this.metadata,
  });

  final String id;
  final int patientId;
  final String senderType; // 'doctor', 'patient'
  final String messageType; // 'text', 'audio', 'document', 'video'
  final String content;
  final DateTime createdAt;
  final bool isRead;
  final String? attachmentUrl;
  final String? attachmentType;
  final Map<String, dynamic> metadata;

  bool get isFromDoctor => senderType == 'doctor';
  bool get isFromPatient => senderType == 'patient';
  bool get hasAttachment => attachmentUrl != null && attachmentUrl!.isNotEmpty;

  String get displayTime {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return createdAt.toString().split(' ')[0];
    }
  }

  Color get senderColor => isFromDoctor ? const Color(0xFF6366F1) : const Color(0xFF10B981);
}

/// Model for voice call log
class VoiceCallLog {
  const VoiceCallLog({
    required this.id,
    required this.patientId,
    required this.initiatedBy,
    required this.callStart,
    required this.callEnd,
    required this.durationSeconds,
    required this.status,
    required this.callNotes,
    required this.createdAt,
  });

  final String id;
  final int patientId;
  final String initiatedBy; // 'doctor', 'patient'
  final DateTime callStart;
  final DateTime callEnd;
  final int durationSeconds;
  final String status; // 'completed', 'missed', 'declined', 'no_answer'
  final String callNotes;
  final DateTime createdAt;

  bool get isCompleted => status == 'completed';
  bool get isMissed => status == 'missed';
  bool get isDeclined => status == 'declined';

  String get durationFormatted {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    
    if (minutes == 0) {
      return '$seconds sec';
    } else if (minutes < 60) {
      return '$minutes min ${seconds > 0 ? '$seconds sec' : ''}';
    } else {
      final hours = minutes ~/ 60;
      final remainingMins = minutes % 60;
      return '$hours h ${remainingMins > 0 ? '$remainingMins min' : ''}';
    }
  }

  Color get statusColor => 
      isCompleted ? const Color(0xFF10B981) :
      isMissed ? const Color(0xFFDC2626) :
      isDeclined ? const Color(0xFFF59E0B) :
      const Color(0xFF64748B);

  String get statusLabel =>
      status[0].toUpperCase() + status.substring(1).replaceAll('_', ' ');
}

/// Model for message queue item (offline support)
class QueuedMessage {
  const QueuedMessage({
    required this.id,
    required this.patientId,
    required this.messageType,
    required this.content,
    this.attachmentUrl,
    required this.queuedAt,
    required this.attempts,
    required this.status,
    this.lastAttemptAt,
    this.nextRetryAt,
  });

  final String id;
  final int patientId;
  final String messageType;
  final String content;
  final String? attachmentUrl;
  final DateTime queuedAt;
  final int attempts;
  final String status; // 'queued', 'sending', 'sent', 'failed'
  final DateTime? lastAttemptAt;
  final DateTime? nextRetryAt;

  bool get shouldRetry => 
      attempts < 3 && (nextRetryAt == null || nextRetryAt!.isBefore(DateTime.now()));
}

/// Model for conversation thread (messages grouped by date/visit)
class ConversationThread {
  const ConversationThread({
    required this.id,
    required this.patientId,
    required this.messages,
    required this.startTime,
    required this.endTime,
  });

  final String id;
  final int patientId;
  final List<CommunicationMessage> messages;
  final DateTime startTime;
  final DateTime endTime;

  String get threadDate => startTime.toString().split(' ')[0];
  int get messageCount => messages.length;
  int get unreadCount => messages.where((m) => !m.isRead).length;
}

/// Model for communication statistics
class CommunicationStats {
  const CommunicationStats({
    required this.totalMessages,
    required this.doctorMessages,
    required this.patientMessages,
    required this.totalCalls,
    required this.completedCalls,
    required this.totalCallDurationSeconds,
    this.lastMessageDate,
    this.lastCallDate,
    this.averageResponseTime,
  });

  final int totalMessages;
  final int doctorMessages;
  final int patientMessages;
  final int totalCalls;
  final int completedCalls;
  final int totalCallDurationSeconds;
  final DateTime? lastMessageDate;
  final DateTime? lastCallDate;
  final Duration? averageResponseTime;

  double get doctorMessagePercent => totalMessages == 0 ? 0 : doctorMessages / totalMessages;
  double get callSuccessRate => totalCalls == 0 ? 0 : completedCalls / totalCalls;

  String get avgCallDuration {
    if (completedCalls == 0) return 'N/A';
    final avgSeconds = totalCallDurationSeconds ~/ completedCalls;
    final minutes = avgSeconds ~/ 60;
    final seconds = avgSeconds % 60;
    
    if (minutes == 0) {
      return '$seconds sec';
    } else {
      return '$minutes min ${seconds > 0 ? '$seconds sec' : ''}';
    }
  }

  String get responseTimeFormatted {
    if (averageResponseTime == null) return 'N/A';
    
    final totalMinutes = averageResponseTime!.inMinutes;
    if (totalMinutes < 60) {
      return '$totalMinutes minutes';
    } else if (totalMinutes < 1440) {
      final hours = totalMinutes ~/ 60;
      final mins = totalMinutes % 60;
      return '$hours h ${mins > 0 ? '$mins min' : ''}';
    } else {
      final days = totalMinutes ~/ 1440;
      return '$days days';
    }
  }
}
