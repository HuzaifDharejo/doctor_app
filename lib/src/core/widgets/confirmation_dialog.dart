import 'package:flutter/material.dart';

/// A confirmation dialog for dangerous or important actions.
///
/// This widget provides a consistent confirmation UX with:
/// - Clear title and message
/// - Customizable action buttons
/// - Destructive action styling
/// - Optional icon
///
/// Example:
/// ```dart
/// final confirmed = await ConfirmationDialog.show(
///   context: context,
///   title: 'Delete Patient',
///   message: 'Are you sure you want to delete this patient? This action cannot be undone.',
///   confirmText: 'Delete',
///   isDestructive: true,
/// );
/// if (confirmed) {
///   await deletePatient(id);
/// }
/// ```
class ConfirmationDialog extends StatelessWidget {
  /// Creates a confirmation dialog.
  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    this.isDestructive = false,
    this.icon,
  });

  /// The dialog title.
  final String title;

  /// The dialog message explaining the action.
  final String message;

  /// Text for the confirm button.
  final String confirmText;

  /// Text for the cancel button.
  final String cancelText;

  /// Whether the action is destructive (changes button color to red).
  final bool isDestructive;

  /// Optional icon to display above the title.
  final IconData? icon;

  /// Shows a confirmation dialog and returns true if confirmed.
  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDestructive = false,
    IconData? icon,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        isDestructive: isDestructive,
        icon: icon,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIcon = icon ??
        (isDestructive ? Icons.warning_amber_rounded : Icons.help_outline);
    final iconColor = isDestructive
        ? theme.colorScheme.error
        : theme.colorScheme.primary;

    return AlertDialog(
      icon: Icon(
        effectiveIcon,
        size: 48,
        color: iconColor,
      ),
      title: Text(
        title,
        textAlign: TextAlign.center,
      ),
      content: Text(
        message,
        textAlign: TextAlign.center,
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelText),
        ),
        if (isDestructive)
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            child: Text(confirmText),
          )
        else
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmText),
          ),
      ],
    );
  }
}

/// A dialog for confirming deletion with optional details.
///
/// This is a specialized confirmation dialog for delete operations.
class DeleteConfirmationDialog extends StatelessWidget {
  /// Creates a delete confirmation dialog.
  const DeleteConfirmationDialog({
    super.key,
    required this.itemName,
    this.itemType = 'item',
    this.additionalMessage,
  });

  /// The name of the item being deleted.
  final String itemName;

  /// The type of item (e.g., "patient", "appointment").
  final String itemType;

  /// Optional additional message to display.
  final String? additionalMessage;

  /// Shows a delete confirmation dialog and returns true if confirmed.
  static Future<bool> show({
    required BuildContext context,
    required String itemName,
    String itemType = 'item',
    String? additionalMessage,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => DeleteConfirmationDialog(
        itemName: itemName,
        itemType: itemType,
        additionalMessage: additionalMessage,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      icon: Icon(
        Icons.delete_forever,
        size: 48,
        color: theme.colorScheme.error,
      ),
      title: Text(
        'Delete $itemType?',
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Are you sure you want to delete "$itemName"?',
            textAlign: TextAlign.center,
          ),
          if (additionalMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              additionalMessage!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'This action cannot be undone.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}

/// A dialog for confirming logout.
class LogoutConfirmationDialog extends StatelessWidget {
  /// Creates a logout confirmation dialog.
  const LogoutConfirmationDialog({super.key});

  /// Shows a logout confirmation dialog and returns true if confirmed.
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const LogoutConfirmationDialog(),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return ConfirmationDialog(
      icon: Icons.logout,
      title: 'Log Out',
      message:
          'Are you sure you want to log out? You will need to sign in again to access your data.',
      confirmText: 'Log Out',
      cancelText: 'Stay Signed In',
    );
  }
}

/// A dialog for confirming discarding unsaved changes.
class DiscardChangesDialog extends StatelessWidget {
  /// Creates a discard changes dialog.
  const DiscardChangesDialog({super.key});

  /// Shows a discard changes dialog and returns true if user wants to discard.
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const DiscardChangesDialog(),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      icon: Icon(
        Icons.edit_off,
        size: 48,
        color: theme.colorScheme.error,
      ),
      title: const Text(
        'Discard Changes?',
        textAlign: TextAlign.center,
      ),
      content: const Text(
        'You have unsaved changes. Are you sure you want to discard them?',
        textAlign: TextAlign.center,
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Keep Editing'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          child: const Text('Discard'),
        ),
      ],
    );
  }
}

/// A dialog for confirming actions that will send communications.
class SendConfirmationDialog extends StatelessWidget {
  /// Creates a send confirmation dialog.
  const SendConfirmationDialog({
    super.key,
    required this.recipientCount,
    required this.messageType,
  });

  /// The number of recipients.
  final int recipientCount;

  /// The type of message (e.g., "SMS", "email", "notification").
  final String messageType;

  /// Shows a send confirmation dialog and returns true if confirmed.
  static Future<bool> show({
    required BuildContext context,
    required int recipientCount,
    required String messageType,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => SendConfirmationDialog(
        recipientCount: recipientCount,
        messageType: messageType,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recipientText =
        recipientCount == 1 ? '1 recipient' : '$recipientCount recipients';

    return AlertDialog(
      icon: Icon(
        Icons.send,
        size: 48,
        color: theme.colorScheme.primary,
      ),
      title: Text(
        'Send $messageType?',
        textAlign: TextAlign.center,
      ),
      content: Text(
        'This will send a $messageType to $recipientText.',
        textAlign: TextAlign.center,
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Send'),
        ),
      ],
    );
  }
}
