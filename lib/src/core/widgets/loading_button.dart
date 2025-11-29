import 'package:flutter/material.dart';

/// A button that shows a loading indicator while an async operation is in progress.
class LoadingButton extends StatefulWidget {
  const LoadingButton({
    required this.onPressed,
    required this.child,
    super.key,
    this.isLoading = false,
    this.loadingChild,
    this.style,
    this.disabled = false,
  });

  /// Called when the button is pressed.
  /// Can return a Future for automatic loading state management,
  /// or null for manual loading state control.
  final Future<void> Function()? onPressed;

  /// The button's child widget.
  final Widget child;

  /// Whether the button is currently in loading state.
  /// Use this for manual loading state control.
  final bool isLoading;

  /// Optional widget to show while loading.
  /// Defaults to a CircularProgressIndicator.
  final Widget? loadingChild;

  /// The button's style.
  final ButtonStyle? style;

  /// Whether the button is disabled.
  final bool disabled;

  @override
  State<LoadingButton> createState() => _LoadingButtonState();
}

class _LoadingButtonState extends State<LoadingButton> {
  bool _isLoading = false;

  bool get _effectiveLoading => widget.isLoading || _isLoading;

  Future<void> _handlePress() async {
    if (_effectiveLoading || widget.disabled || widget.onPressed == null) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      await widget.onPressed!();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _effectiveLoading || widget.disabled ? null : _handlePress,
      style: widget.style,
      child: _effectiveLoading
          ? widget.loadingChild ?? _defaultLoadingChild(context)
          : widget.child,
    );
  }

  Widget _defaultLoadingChild(BuildContext context) {
    return SizedBox(
      height: 20,
      width: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }
}

/// A text button that shows a loading indicator while an async operation is in progress.
class LoadingTextButton extends StatefulWidget {
  const LoadingTextButton({
    required this.onPressed,
    required this.child,
    super.key,
    this.isLoading = false,
    this.loadingChild,
    this.style,
    this.disabled = false,
  });

  final Future<void> Function()? onPressed;
  final Widget child;
  final bool isLoading;
  final Widget? loadingChild;
  final ButtonStyle? style;
  final bool disabled;

  @override
  State<LoadingTextButton> createState() => _LoadingTextButtonState();
}

class _LoadingTextButtonState extends State<LoadingTextButton> {
  bool _isLoading = false;

  bool get _effectiveLoading => widget.isLoading || _isLoading;

  Future<void> _handlePress() async {
    if (_effectiveLoading || widget.disabled || widget.onPressed == null) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      await widget.onPressed!();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: _effectiveLoading || widget.disabled ? null : _handlePress,
      style: widget.style,
      child: _effectiveLoading
          ? widget.loadingChild ?? _defaultLoadingChild(context)
          : widget.child,
    );
  }

  Widget _defaultLoadingChild(BuildContext context) {
    return SizedBox(
      height: 16,
      width: 16,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

/// An outlined button that shows a loading indicator while an async operation is in progress.
class LoadingOutlinedButton extends StatefulWidget {
  const LoadingOutlinedButton({
    required this.onPressed,
    required this.child,
    super.key,
    this.isLoading = false,
    this.loadingChild,
    this.style,
    this.disabled = false,
  });

  final Future<void> Function()? onPressed;
  final Widget child;
  final bool isLoading;
  final Widget? loadingChild;
  final ButtonStyle? style;
  final bool disabled;

  @override
  State<LoadingOutlinedButton> createState() => _LoadingOutlinedButtonState();
}

class _LoadingOutlinedButtonState extends State<LoadingOutlinedButton> {
  bool _isLoading = false;

  bool get _effectiveLoading => widget.isLoading || _isLoading;

  Future<void> _handlePress() async {
    if (_effectiveLoading || widget.disabled || widget.onPressed == null) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      await widget.onPressed!();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: _effectiveLoading || widget.disabled ? null : _handlePress,
      style: widget.style,
      child: _effectiveLoading
          ? widget.loadingChild ?? _defaultLoadingChild(context)
          : widget.child,
    );
  }

  Widget _defaultLoadingChild(BuildContext context) {
    return SizedBox(
      height: 16,
      width: 16,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

/// An icon button that shows a loading indicator while an async operation is in progress.
class LoadingIconButton extends StatefulWidget {
  const LoadingIconButton({
    required this.onPressed,
    required this.icon,
    super.key,
    this.isLoading = false,
    this.tooltip,
    this.iconSize,
    this.color,
    this.disabled = false,
  });

  final Future<void> Function()? onPressed;
  final Widget icon;
  final bool isLoading;
  final String? tooltip;
  final double? iconSize;
  final Color? color;
  final bool disabled;

  @override
  State<LoadingIconButton> createState() => _LoadingIconButtonState();
}

class _LoadingIconButtonState extends State<LoadingIconButton> {
  bool _isLoading = false;

  bool get _effectiveLoading => widget.isLoading || _isLoading;

  Future<void> _handlePress() async {
    if (_effectiveLoading || widget.disabled || widget.onPressed == null) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      await widget.onPressed!();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _effectiveLoading || widget.disabled ? null : _handlePress,
      icon: _effectiveLoading ? _loadingIndicator(context) : widget.icon,
      tooltip: widget.tooltip,
      iconSize: widget.iconSize,
      color: widget.color,
    );
  }

  Widget _loadingIndicator(BuildContext context) {
    return SizedBox(
      height: widget.iconSize ?? 24,
      width: widget.iconSize ?? 24,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: widget.color ?? Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
