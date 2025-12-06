import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing form drafts with auto-save functionality
class FormDraftService {
  static const _draftPrefix = 'form_draft_';
  static const _autoSaveInterval = Duration(seconds: 30);

  /// Save a draft for a specific form type
  static Future<void> saveDraft({
    required String formType,
    required Map<String, dynamic> data,
    int? patientId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final draftKey = _getDraftKey(formType, patientId);
    
    final draft = FormDraft(
      formType: formType,
      patientId: patientId,
      data: data,
      savedAt: DateTime.now(),
    );
    
    await prefs.setString(draftKey, jsonEncode(draft.toJson()));
  }

  /// Load a draft for a specific form type
  static Future<FormDraft?> loadDraft({
    required String formType,
    int? patientId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final draftKey = _getDraftKey(formType, patientId);
    
    final draftJson = prefs.getString(draftKey);
    if (draftJson == null) return null;
    
    try {
      final json = jsonDecode(draftJson) as Map<String, dynamic>;
      return FormDraft.fromJson(json);
    } catch (e) {
      // Invalid draft, remove it
      await prefs.remove(draftKey);
      return null;
    }
  }

  /// Clear a draft for a specific form type
  static Future<void> clearDraft({
    required String formType,
    int? patientId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final draftKey = _getDraftKey(formType, patientId);
    await prefs.remove(draftKey);
  }

  /// Check if a draft exists
  static Future<bool> hasDraft({
    required String formType,
    int? patientId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final draftKey = _getDraftKey(formType, patientId);
    return prefs.containsKey(draftKey);
  }

  /// Get all available drafts
  static Future<List<FormDraft>> getAllDrafts() async {
    final prefs = await SharedPreferences.getInstance();
    final drafts = <FormDraft>[];
    
    for (final key in prefs.getKeys()) {
      if (key.startsWith(_draftPrefix)) {
        final draftJson = prefs.getString(key);
        if (draftJson != null) {
          try {
            final json = jsonDecode(draftJson) as Map<String, dynamic>;
            drafts.add(FormDraft.fromJson(json));
          } catch (_) {}
        }
      }
    }
    
    // Sort by saved date, most recent first
    drafts.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return drafts;
  }

  static String _getDraftKey(String formType, int? patientId) {
    if (patientId != null) {
      return '$_draftPrefix${formType}_$patientId';
    }
    return '$_draftPrefix${formType}_new';
  }
}

/// Data class representing a form draft
class FormDraft {
  const FormDraft({
    required this.formType,
    required this.data,
    required this.savedAt,
    this.patientId,
  });

  final String formType;
  final int? patientId;
  final Map<String, dynamic> data;
  final DateTime savedAt;

  Map<String, dynamic> toJson() => {
    'formType': formType,
    'patientId': patientId,
    'data': data,
    'savedAt': savedAt.toIso8601String(),
  };

  factory FormDraft.fromJson(Map<String, dynamic> json) => FormDraft(
    formType: json['formType'] as String,
    patientId: json['patientId'] as int?,
    data: json['data'] as Map<String, dynamic>,
    savedAt: DateTime.parse(json['savedAt'] as String),
  );

  String get formTypeLabel {
    switch (formType) {
      case 'general_consultation':
        return 'General Consultation';
      case 'lab_result':
        return 'Lab Result';
      case 'procedure':
        return 'Medical Procedure';
      case 'pulmonary':
        return 'Pulmonary Evaluation';
      case 'follow_up':
        return 'Follow-up Visit';
      case 'imaging':
        return 'Imaging/Radiology';
      default:
        return formType;
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(savedAt);
    
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${savedAt.day}/${savedAt.month}/${savedAt.year}';
  }
}

/// Mixin that provides auto-save functionality to form screens
mixin AutoSaveFormMixin<T extends StatefulWidget> on State<T> {
  Timer? _autoSaveTimer;
  bool _isDirty = false;
  
  /// Override this to provide the form type
  String get formType;
  
  /// Override this to provide current patient ID
  int? get currentPatientId;
  
  /// Override this to build the draft data
  Map<String, dynamic> buildDraftData();
  
  /// Override this to restore from draft
  void restoreFromDraft(Map<String, dynamic> data);

  void initAutoSave() {
    _autoSaveTimer = Timer.periodic(
      FormDraftService._autoSaveInterval,
      (_) => _autoSave(),
    );
  }

  void disposeAutoSave() {
    _autoSaveTimer?.cancel();
  }

  void markDirty() {
    _isDirty = true;
  }

  Future<void> _autoSave() async {
    if (!_isDirty) return;
    
    await FormDraftService.saveDraft(
      formType: formType,
      patientId: currentPatientId,
      data: buildDraftData(),
    );
    
    _isDirty = false;
  }

  /// Call this to manually save the draft
  Future<void> saveDraft() async {
    await FormDraftService.saveDraft(
      formType: formType,
      patientId: currentPatientId,
      data: buildDraftData(),
    );
  }

  /// Call this when the form is successfully submitted
  Future<void> clearDraftOnSuccess() async {
    await FormDraftService.clearDraft(
      formType: formType,
      patientId: currentPatientId,
    );
  }

  /// Check and offer to restore a draft
  Future<void> checkForDraft() async {
    final draft = await FormDraftService.loadDraft(
      formType: formType,
      patientId: currentPatientId,
    );
    
    if (draft != null && mounted) {
      _showRestoreDraftDialog(draft);
    }
  }

  void _showRestoreDraftDialog(FormDraft draft) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.restore, color: Colors.amber.shade700),
            ),
            const SizedBox(width: 12),
            const Text('Restore Draft?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('A previous draft was found for this form.'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    'Saved ${draft.timeAgo}',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              FormDraftService.clearDraft(
                formType: formType,
                patientId: currentPatientId,
              );
            },
            child: Text(
              'Discard',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              restoreFromDraft(draft.data);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }
}

/// Widget that shows auto-save status
class AutoSaveIndicator extends StatelessWidget {
  const AutoSaveIndicator({
    super.key,
    required this.isSaving,
    required this.lastSaved,
  });

  final bool isSaving;
  final DateTime? lastSaved;

  @override
  Widget build(BuildContext context) {
    if (isSaving) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Saving...',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      );
    }

    if (lastSaved != null) {
      final diff = DateTime.now().difference(lastSaved!);
      String timeText;
      if (diff.inSeconds < 60) {
        timeText = 'Saved';
      } else if (diff.inMinutes < 60) {
        timeText = 'Saved ${diff.inMinutes}m ago';
      } else {
        timeText = 'Saved ${diff.inHours}h ago';
      }

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_done, size: 14, color: Colors.green.shade400),
          const SizedBox(width: 4),
          Text(
            timeText,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}
