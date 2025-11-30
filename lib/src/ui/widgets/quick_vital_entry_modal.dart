import 'package:flutter/material.dart';
import 'quick_vital_entry_form.dart';

/// Quick Vital Entry Modal Dialog
/// Shows the quick vital entry form in a bottom sheet for quick access during visits
class QuickVitalEntryModal {
  /// Show quick vital entry as a bottom sheet
  static Future<void> showAsBottomSheet({
    required BuildContext context,
    required int patientId,
    required String patientName,
    VoidCallback? onSaved,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => QuickVitalEntryForm(
          patientId: patientId,
          patientName: patientName,
          onSaved: onSaved,
        ),
      ),
    );
  }

  /// Show quick vital entry as a full-screen dialog
  static Future<void> showAsFullScreen({
    required BuildContext context,
    required int patientId,
    required String patientName,
    VoidCallback? onSaved,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Quick Vital Entry'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: QuickVitalEntryForm(
            patientId: patientId,
            patientName: patientName,
            onSaved: () {
              onSaved?.call();
              Navigator.pop(context);
            },
          ),
        ),
      ),
    );
  }

  /// Show as a responsive dialog (mobile=bottom sheet, tablet=dialog)
  static Future<void> showAdaptive({
    required BuildContext context,
    required int patientId,
    required String patientName,
    VoidCallback? onSaved,
  }) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    if (isMobile) {
      return showAsBottomSheet(
        context: context,
        patientId: patientId,
        patientName: patientName,
        onSaved: onSaved,
      );
    } else {
      return showDialog<void>(
        context: context,
        builder: (context) => Dialog(
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Quick Vital Entry'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: QuickVitalEntryForm(
              patientId: patientId,
              patientName: patientName,
              onSaved: () {
                onSaved?.call();
                Navigator.pop(context);
              },
            ),
          ),
        ),
      );
    }
  }
}
