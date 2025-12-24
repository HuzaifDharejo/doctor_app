import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ui/screens/add_patient_screen.dart';
import '../../ui/screens/add_prescription_screen.dart';
import '../../ui/screens/add_appointment_screen.dart';
import '../../ui/screens/global_search_screen.dart';

/// Keyboard shortcuts handler for desktop
/// Wraps the app to provide global keyboard shortcuts
/// Only active on desktop platforms (macOS, Windows, Linux, Web)
class KeyboardShortcutsHandler extends ConsumerWidget {
  const KeyboardShortcutsHandler({
    super.key,
    required this.child,
  });

  final Widget child;

  /// Check if keyboard shortcuts should be enabled
  static bool get _shouldEnableShortcuts {
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!_shouldEnableShortcuts) {
      return child;
    }

    return Shortcuts(
      shortcuts: {
        // Ctrl+K / Cmd+K - Global search
        LogicalKeySet(
          defaultTargetPlatform == TargetPlatform.macOS ? LogicalKeyboardKey.meta : LogicalKeyboardKey.control,
          LogicalKeyboardKey.keyK,
        ): const _GlobalSearchIntent(),
        
        // Ctrl+N / Cmd+N - New patient
        LogicalKeySet(
          defaultTargetPlatform == TargetPlatform.macOS ? LogicalKeyboardKey.meta : LogicalKeyboardKey.control,
          LogicalKeyboardKey.keyN,
        ): const _NewPatientIntent(),
        
        // Ctrl+P / Cmd+P - New prescription
        LogicalKeySet(
          defaultTargetPlatform == TargetPlatform.macOS ? LogicalKeyboardKey.meta : LogicalKeyboardKey.control,
          LogicalKeyboardKey.keyP,
        ): const _NewPrescriptionIntent(),
        
        // Ctrl+A / Cmd+A - New appointment
        LogicalKeySet(
          defaultTargetPlatform == TargetPlatform.macOS ? LogicalKeyboardKey.meta : LogicalKeyboardKey.control,
          LogicalKeyboardKey.keyA,
        ): const _NewAppointmentIntent(),
        
        // Ctrl+/ / Cmd+/ - Show shortcuts help
        LogicalKeySet(
          defaultTargetPlatform == TargetPlatform.macOS ? LogicalKeyboardKey.meta : LogicalKeyboardKey.control,
          LogicalKeyboardKey.slash,
        ): const _ShowShortcutsHelpIntent(),
        
        // Escape - Close dialog/go back
        LogicalKeySet(LogicalKeyboardKey.escape): const _CloseDialogIntent(),
        
        // Ctrl+S / Cmd+S - Save current form
        LogicalKeySet(
          defaultTargetPlatform == TargetPlatform.macOS ? LogicalKeyboardKey.meta : LogicalKeyboardKey.control,
          LogicalKeyboardKey.keyS,
        ): const _SaveFormIntent(),
      },
      child: Actions(
        actions: {
          _GlobalSearchIntent: CallbackAction<_GlobalSearchIntent>(
            onInvoke: (_) => _openGlobalSearch(context),
          ),
          _NewPatientIntent: CallbackAction<_NewPatientIntent>(
            onInvoke: (_) => _openNewPatient(context),
          ),
          _NewPrescriptionIntent: CallbackAction<_NewPrescriptionIntent>(
            onInvoke: (_) => _openNewPrescription(context),
          ),
          _NewAppointmentIntent: CallbackAction<_NewAppointmentIntent>(
            onInvoke: (_) => _openNewAppointment(context),
          ),
          _ShowShortcutsHelpIntent: CallbackAction<_ShowShortcutsHelpIntent>(
            onInvoke: (_) => _showShortcutsHelp(context),
          ),
          _CloseDialogIntent: CallbackAction<_CloseDialogIntent>(
            onInvoke: (_) => _closeDialogOrPop(context),
          ),
          _SaveFormIntent: CallbackAction<_SaveFormIntent>(
            onInvoke: (_) => _saveCurrentForm(context),
          ),
        },
        child: FocusScope(
          autofocus: true,
          child: child,
        ),
      ),
    );
  }

  void _openGlobalSearch(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const GlobalSearchScreen()),
    );
  }

  void _openNewPatient(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddPatientScreen()),
    );
  }

  void _openNewPrescription(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddPrescriptionScreen()),
    );
  }

  void _openNewAppointment(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddAppointmentScreen()),
    );
  }

  void _closeDialogOrPop(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  void _saveCurrentForm(BuildContext context) {
    // Try to find and trigger save action in the current form
    // This will be handled by individual forms
    FocusScope.of(context).unfocus(); // Unfocus first
    
    // Try to find a save button or form and trigger it
    // Forms should listen for this or use a GlobalKey
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.showSnackBar(
      const SnackBar(
        content: Text('Use the Save button in the form to save'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showShortcutsHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _ShortcutsHelpDialog(),
    );
  }
}

// Intent classes for shortcuts
class _GlobalSearchIntent extends Intent {
  const _GlobalSearchIntent();
}

class _NewPatientIntent extends Intent {
  const _NewPatientIntent();
}

class _NewPrescriptionIntent extends Intent {
  const _NewPrescriptionIntent();
}

class _NewAppointmentIntent extends Intent {
  const _NewAppointmentIntent();
}

class _ShowShortcutsHelpIntent extends Intent {
  const _ShowShortcutsHelpIntent();
}

class _CloseDialogIntent extends Intent {
  const _CloseDialogIntent();
}

class _SaveFormIntent extends Intent {
  const _SaveFormIntent();
}

/// Shortcuts help dialog
class _ShortcutsHelpDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMac = Theme.of(context).platform == TargetPlatform.macOS;
    final modifier = isMac ? 'Cmd' : 'Ctrl';

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.keyboard_rounded, size: 24),
          SizedBox(width: 12),
          Text('Keyboard Shortcuts'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildShortcutRow(context, '$modifier + K', 'Global Search'),
            const SizedBox(height: 12),
            _buildShortcutRow(context, '$modifier + N', 'New Patient'),
            const SizedBox(height: 12),
            _buildShortcutRow(context, '$modifier + P', 'New Prescription'),
            const SizedBox(height: 12),
            _buildShortcutRow(context, '$modifier + A', 'New Appointment'),
            const SizedBox(height: 12),
            _buildShortcutRow(context, '$modifier + /', 'Show Shortcuts'),
            const SizedBox(height: 12),
            _buildShortcutRow(context, 'Esc', 'Close Dialog / Go Back'),
            const SizedBox(height: 12),
            _buildShortcutRow(context, '$modifier + S', 'Save Form'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildShortcutRow(BuildContext context, String shortcut, String action) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isDark 
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            shortcut,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            action,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}

