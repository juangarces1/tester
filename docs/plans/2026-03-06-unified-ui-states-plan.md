# Unified UI States Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Create a unified system for UI states (loading, success, error, empty) with reusable widgets, provider mixin, custom overlay notifications, and migrate FuelRed as pilot.

**Architecture:** A `ViewStateMixin` on providers exposes a typed `ViewState` enum. A `StateView` wrapper widget uses `AnimatedSwitcher` to render the correct state widget (shimmer, error card, empty state, or content). An `AppOverlay` system replaces both SnackBar and Fluttertoast with custom floating toasts.

**Tech Stack:** Flutter, Provider, shimmer package (new dep), AnimatedSwitcher, Overlay API

---

### Task 1: Add shimmer dependency

**Files:**
- Modify: `pubspec.yaml:16-44`

**Step 1: Add shimmer to pubspec.yaml**

Add under dependencies (after `flutter_ringtone_player`):

```yaml
  shimmer: ^3.0.0
```

**Step 2: Install**

Run: `flutter pub get`
Expected: Dependencies resolved successfully

**Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "deps: add shimmer package for skeleton loading"
```

---

### Task 2: ViewState enum + ViewStateMixin

**Files:**
- Create: `lib/Components/state/view_state.dart`

**Step 1: Create the file**

```dart
import 'package:flutter/material.dart';

/// Possible UI states for any screen or section.
enum ViewState { loading, content, error, empty }

/// Mixin for ChangeNotifier providers to expose a typed ViewState.
///
/// Usage:
/// ```dart
/// class MyProvider extends ChangeNotifier with ViewStateMixin { ... }
/// ```
mixin ViewStateMixin on ChangeNotifier {
  ViewState _viewState = ViewState.loading;
  String? _errorMessage;

  ViewState get viewState => _viewState;
  String? get errorMessage => _errorMessage;

  void setLoading() {
    _viewState = ViewState.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void setContent() {
    _viewState = ViewState.content;
    _errorMessage = null;
    notifyListeners();
  }

  void setError(String message) {
    _viewState = ViewState.error;
    _errorMessage = message;
    notifyListeners();
  }

  void setEmpty() {
    _viewState = ViewState.empty;
    _errorMessage = null;
    notifyListeners();
  }
}
```

**Step 2: Verify it compiles**

Run: `flutter analyze lib/Components/state/view_state.dart`
Expected: No issues found

**Step 3: Commit**

```bash
git add lib/Components/state/view_state.dart
git commit -m "feat: add ViewState enum and ViewStateMixin"
```

---

### Task 3: EmptyState widget

**Files:**
- Create: `lib/Components/state/empty_state.dart`

**Step 1: Create the widget**

```dart
import 'package:flutter/material.dart';
import 'package:tester/constans.dart';

/// Unified empty state widget. Replaces inline _buildEmptyState() and MyNoContent.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: kNewtextSec.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: kContrateFondoOscuro,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: kNewtextSec, fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

**Step 2: Verify it compiles**

Run: `flutter analyze lib/Components/state/empty_state.dart`
Expected: No issues found

**Step 3: Commit**

```bash
git add lib/Components/state/empty_state.dart
git commit -m "feat: add EmptyState widget"
```

---

### Task 4: ErrorCard widget

**Files:**
- Create: `lib/Components/state/error_card.dart`

**Step 1: Create the widget**

```dart
import 'package:flutter/material.dart';
import 'package:tester/constans.dart';

/// Inline error card with icon, message, and optional retry button.
class ErrorCard extends StatelessWidget {
  const ErrorCard({
    super.key,
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFFF1744).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFFF1744),
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                color: kContrateFondoOscuro,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Reintentar'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFFF1744),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

**Step 2: Verify it compiles**

Run: `flutter analyze lib/Components/state/error_card.dart`
Expected: No issues found

**Step 3: Commit**

```bash
git add lib/Components/state/error_card.dart
git commit -m "feat: add ErrorCard widget"
```

---

### Task 5: MinimalLoader widget

**Files:**
- Create: `lib/Components/state/minimal_loader.dart`

**Step 1: Create the widget**

A subtle animated loader for action-level loading (not full-page). Replaces the heavy GIF+blur `LoaderComponent` for inline use.

```dart
import 'package:flutter/material.dart';
import 'package:tester/constans.dart';

/// Minimal animated loader for action-level loading states.
class MinimalLoader extends StatelessWidget {
  const MinimalLoader({
    super.key,
    this.size = 40,
    this.color = kNewred,
    this.label,
  });

  final double size;
  final Color color;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          if (label != null) ...[
            const SizedBox(height: 12),
            Text(
              label!,
              style: const TextStyle(
                color: kNewtextSec,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
```

**Step 2: Verify it compiles**

Run: `flutter analyze lib/Components/state/minimal_loader.dart`
Expected: No issues found

**Step 3: Commit**

```bash
git add lib/Components/state/minimal_loader.dart
git commit -m "feat: add MinimalLoader widget"
```

---

### Task 6: ShimmerCard and ShimmerList widgets

**Files:**
- Create: `lib/Components/state/shimmer_card.dart`
- Create: `lib/Components/state/shimmer_list.dart`

**Step 1: Create ShimmerCard**

```dart
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tester/constans.dart';

/// A single skeleton card that mimics a content card while loading.
class ShimmerCard extends StatelessWidget {
  const ShimmerCard({super.key, this.height = 100});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Shimmer.fromColors(
        baseColor: kNewborder,
        highlightColor: kNewsurfaceHi,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: kNewborder,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar placeholder
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: kNewsurfaceHi,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Title placeholder
                      Container(
                        height: 14,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: kNewsurfaceHi,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Subtitle placeholder
                      Container(
                        height: 12,
                        width: 150,
                        decoration: BoxDecoration(
                          color: kNewsurfaceHi,
                          borderRadius: BorderRadius.circular(4),
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
    );
  }
}
```

**Step 2: Create ShimmerList**

```dart
import 'package:flutter/material.dart';
import 'package:tester/Components/state/shimmer_card.dart';

/// A column of ShimmerCards to simulate a loading list.
class ShimmerList extends StatelessWidget {
  const ShimmerList({
    super.key,
    this.itemCount = 4,
    this.cardHeight = 100,
  });

  final int itemCount;
  final double cardHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        itemCount,
        (_) => ShimmerCard(height: cardHeight),
      ),
    );
  }
}
```

**Step 3: Verify both compile**

Run: `flutter analyze lib/Components/state/shimmer_card.dart lib/Components/state/shimmer_list.dart`
Expected: No issues found

**Step 4: Commit**

```bash
git add lib/Components/state/shimmer_card.dart lib/Components/state/shimmer_list.dart
git commit -m "feat: add ShimmerCard and ShimmerList skeleton loading widgets"
```

---

### Task 7: StateView wrapper widget

**Files:**
- Create: `lib/Components/state/state_view.dart`

**Step 1: Create the widget**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tester/Components/state/empty_state.dart';
import 'package:tester/Components/state/error_card.dart';
import 'package:tester/Components/state/minimal_loader.dart';
import 'package:tester/Components/state/view_state.dart';

/// Generic wrapper that renders loading/error/empty/content based on
/// the provider's [ViewState].
///
/// Usage:
/// ```dart
/// StateView<MyProvider>(
///   onLoading: () => ShimmerList(),
///   onContent: (prov) => MyContentWidget(prov),
/// )
/// ```
class StateView<T extends ChangeNotifier> extends StatelessWidget {
  const StateView({
    super.key,
    required this.onContent,
    this.onLoading,
    this.onError,
    this.onEmpty,
    this.transitionDuration = const Duration(milliseconds: 250),
  });

  final Widget Function(T provider) onContent;
  final Widget Function()? onLoading;
  final Widget Function(String message, VoidCallback? retry)? onError;
  final Widget Function()? onEmpty;
  final Duration transitionDuration;

  @override
  Widget build(BuildContext context) {
    return Consumer<T>(
      builder: (context, provider, _) {
        // If provider doesn't use ViewStateMixin, just render content
        if (provider is! ViewStateMixin) {
          return onContent(provider);
        }

        final mixin = provider as ViewStateMixin;
        final Widget child;

        switch (mixin.viewState) {
          case ViewState.loading:
            child = KeyedSubtree(
              key: const ValueKey('state_loading'),
              child: onLoading?.call() ?? const MinimalLoader(),
            );
          case ViewState.error:
            child = KeyedSubtree(
              key: const ValueKey('state_error'),
              child: onError?.call(mixin.errorMessage ?? 'Error desconocido', null) ??
                  ErrorCard(message: mixin.errorMessage ?? 'Error desconocido'),
            );
          case ViewState.empty:
            child = KeyedSubtree(
              key: const ValueKey('state_empty'),
              child: onEmpty?.call() ??
                  const EmptyState(
                    icon: Icons.inbox_rounded,
                    title: 'Sin datos',
                  ),
            );
          case ViewState.content:
            child = KeyedSubtree(
              key: const ValueKey('state_content'),
              child: onContent(provider),
            );
        }

        return AnimatedSwitcher(
          duration: transitionDuration,
          child: child,
        );
      },
    );
  }
}
```

**Step 2: Verify it compiles**

Run: `flutter analyze lib/Components/state/state_view.dart`
Expected: No issues found

**Step 3: Commit**

```bash
git add lib/Components/state/state_view.dart
git commit -m "feat: add StateView wrapper widget with AnimatedSwitcher"
```

---

### Task 8: AppOverlay notification system

**Files:**
- Create: `lib/Components/overlay/app_overlay.dart`

**Step 1: Create the overlay system**

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tester/constans.dart';

enum _OverlayLevel { success, error, warning, info }

/// Custom floating toast notification system.
///
/// Usage:
/// ```dart
/// AppOverlay.success(context, 'Despacho autorizado');
/// AppOverlay.error(context, 'Error al conectar');
/// ```
class AppOverlay {
  AppOverlay._();

  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;

  static void success(BuildContext context, String message) =>
      _show(context, message, _OverlayLevel.success);

  static void error(BuildContext context, String message) =>
      _show(context, message, _OverlayLevel.error);

  static void warning(BuildContext context, String message) =>
      _show(context, message, _OverlayLevel.warning);

  static void info(BuildContext context, String message) =>
      _show(context, message, _OverlayLevel.info);

  static void _show(BuildContext context, String message, _OverlayLevel level) {
    _dismiss();

    final overlay = Overlay.of(context);
    final config = _configFor(level);

    _currentEntry = OverlayEntry(
      builder: (ctx) => _OverlayToast(
        message: message,
        icon: config.icon,
        color: config.color,
        onDismiss: _dismiss,
      ),
    );

    overlay.insert(_currentEntry!);
    _dismissTimer = Timer(const Duration(seconds: 3), _dismiss);
  }

  static void _dismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _currentEntry?.remove();
    _currentEntry = null;
  }

  static ({IconData icon, Color color}) _configFor(_OverlayLevel level) {
    return switch (level) {
      _OverlayLevel.success => (
          icon: Icons.check_circle_rounded,
          color: const Color(0xFF00C853),
        ),
      _OverlayLevel.error => (
          icon: Icons.error_rounded,
          color: const Color(0xFFFF1744),
        ),
      _OverlayLevel.warning => (
          icon: Icons.warning_rounded,
          color: const Color(0xFFFF9100),
        ),
      _OverlayLevel.info => (
          icon: Icons.info_rounded,
          color: const Color(0xFF29B6F6),
        ),
    };
  }
}

class _OverlayToast extends StatefulWidget {
  const _OverlayToast({
    required this.message,
    required this.icon,
    required this.color,
    required this.onDismiss,
  });

  final String message;
  final IconData icon;
  final Color color;
  final VoidCallback onDismiss;

  @override
  State<_OverlayToast> createState() => _OverlayToastState();
}

class _OverlayToastState extends State<_OverlayToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Positioned(
      top: topPadding + 8,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: widget.onDismiss,
              onVerticalDragEnd: (_) => widget.onDismiss(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: kNewsurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: widget.color.withValues(alpha: 0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: widget.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(widget.icon, color: widget.color, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: const TextStyle(
                          color: kContrateFondoOscuro,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: kNewtextSec.withValues(alpha: 0.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

**Step 2: Verify it compiles**

Run: `flutter analyze lib/Components/overlay/app_overlay.dart`
Expected: No issues found

**Step 3: Commit**

```bash
git add lib/Components/overlay/app_overlay.dart
git commit -m "feat: add AppOverlay custom floating toast notification system"
```

---

### Task 9: Barrel export file

**Files:**
- Create: `lib/Components/state/state_widgets.dart`

**Step 1: Create barrel export**

```dart
/// Barrel export for all unified state widgets.
export 'view_state.dart';
export 'state_view.dart';
export 'empty_state.dart';
export 'error_card.dart';
export 'minimal_loader.dart';
export 'shimmer_card.dart';
export 'shimmer_list.dart';
```

**Step 2: Commit**

```bash
git add lib/Components/state/state_widgets.dart
git commit -m "feat: add barrel export for state widgets"
```

---

### Task 10: Migrate FuelRedProvider to ViewStateMixin

**Files:**
- Modify: `lib/fuelred/fuelred_provider.dart:21` (class declaration)
- Modify: `lib/fuelred/fuelred_provider.dart:107` (after syncFromRest)
- Modify: `lib/fuelred/fuelred_provider.dart:111-122` (syncFromRest method)

**Step 1: Add mixin to class declaration**

Change line 21 from:
```dart
class FuelRedProvider extends ChangeNotifier {
```
to:
```dart
import 'package:tester/Components/state/state_widgets.dart';

class FuelRedProvider extends ChangeNotifier with ViewStateMixin {
```

(Add the import at the top of the file with the other imports)

**Step 2: Update syncFromRest to set ViewState**

Change the `syncFromRest` method (lines 111-122) to:

```dart
  Future<void> syncFromRest() async {
    try {
      final results = await Future.wait([
        FuelRedApiHelper.getWaitingTransactions(),
        FuelRedApiHelper.getPendingDispatches(),
      ]);
      waitingTransactions = results[0];
      pendingDispatches = results[1];
      if (waitingTransactions.isEmpty && pendingDispatches.isEmpty) {
        setEmpty();
      } else {
        setContent();
      }
      debugPrint(
          '[FuelRedProvider] Sync REST: ${waitingTransactions.length} waiting, '
          '${pendingDispatches.length} pending');
    } catch (e) {
      setError('Error al sincronizar: $e');
      debugPrint('[FuelRedProvider] Sync REST error: $e');
    }
  }
```

**Step 3: Update initialize to set loading at start**

In the `initialize()` method, add `setLoading();` right after `_initialized = true;` (after line 43):

```dart
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    setLoading();
    // ... rest of the method stays the same
```

**Step 4: Update WS listeners to set content when data arrives**

In the `onTransactionWaiting` listener (after `notifyListeners()` on line 56), the mixin's `setContent()` is already called by `notifyListeners()` — but we need to explicitly set content state. Add after line 56:

```dart
    _subs.add(_ws.onTransactionWaiting.listen((data) {
      final newId = data['transaction_id'] as int? ?? 0;
      waitingTransactions.removeWhere((t) => _txId(t) == newId);
      waitingTransactions.insert(0, data);
      if (viewState != ViewState.content) setContent();
      notifyListeners();
      FlutterRingtonePlayer().playNotification();
      debugPrint(
          '[FuelRedProvider] Nueva transaccion esperando: ${data['transaction_id']}');
    }));
```

Do the same for `onDispatchReady` listener — add `if (viewState != ViewState.content) setContent();` before its `notifyListeners()`.

**Step 5: Verify it compiles**

Run: `flutter analyze lib/fuelred/fuelred_provider.dart`
Expected: No issues found

**Step 6: Commit**

```bash
git add lib/fuelred/fuelred_provider.dart
git commit -m "feat: migrate FuelRedProvider to ViewStateMixin"
```

---

### Task 11: Migrate FuelRedPage to use StateView and state widgets

**Files:**
- Modify: `lib/fuelred/fuelred_page.dart`

**Step 1: Replace imports**

Add at the top:
```dart
import 'package:tester/Components/state/state_widgets.dart';
import 'package:tester/Components/overlay/app_overlay.dart';
```

**Step 2: Replace the build method**

Replace the `build` method (lines 14-70) with:

```dart
  @override
  Widget build(BuildContext context) {
    return StateView<FuelRedProvider>(
      onLoading: () => const Padding(
        padding: EdgeInsets.only(top: 80),
        child: ShimmerList(itemCount: 3, cardHeight: 120),
      ),
      onEmpty: () => const EmptyState(
        icon: Icons.local_shipping_outlined,
        title: 'Sin ordenes FuelRed',
        subtitle: 'Cuando un chofer P4S llegue a la estacion\naparecera aqui',
      ),
      onError: (msg, retry) => ErrorCard(
        message: msg,
        onRetry: () => context.read<FuelRedProvider>().syncFromRest(),
      ),
      onContent: (prov) => CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildActionHub(context, prov)),
          if (prov.waitingTransactions.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _buildSectionHeader(
                'Esperando verificacion',
                prov.waitingCount,
                const Color(0xFFFF9100),
              ),
            ),
            SliverList.separated(
              itemCount: prov.waitingTransactions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) =>
                  _buildWaitingCard(context, prov, prov.waitingTransactions[i]),
            ),
          ],
          if (prov.pendingDispatches.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _buildSectionHeader(
                'Despachos autorizados',
                prov.pendingCount,
                const Color(0xFF00E676),
              ),
            ),
            SliverList.separated(
              itemCount: prov.pendingDispatches.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) =>
                  _buildDispatchCard(context, prov, prov.pendingDispatches[i]),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
```

**Step 3: Remove the old `_buildEmptyState` method** (lines 594-622)

Delete the entire `_buildEmptyState()` method — it's now replaced by `EmptyState` widget.

**Step 4: Replace SnackBars in _AuthorizeButton with AppOverlay**

In `_AuthorizeButtonState._authorize()` (lines 1086-1116), replace the three `ScaffoldMessenger.of(context).showSnackBar(...)` calls:

```dart
  Future<void> _authorize() async {
    setState(() => _loading = true);
    try {
      final ok = await widget.prov.authorizeDispatch(
        context: context,
        dispatch: widget.dispatch,
      );
      if (!mounted) return;
      if (ok) {
        AppOverlay.success(context, 'Despacho autorizado — movido a Despachos');
      } else {
        AppOverlay.error(context, 'Error al autorizar despacho');
      }
    } catch (e) {
      if (!mounted) return;
      AppOverlay.error(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
```

**Step 5: Verify it compiles**

Run: `flutter analyze lib/fuelred/fuelred_page.dart`
Expected: No issues found

**Step 6: Commit**

```bash
git add lib/fuelred/fuelred_page.dart
git commit -m "feat: migrate FuelRedPage to StateView, EmptyState, and AppOverlay"
```

---

### Task 12: Modernize _RfidScanSheet phases

**Files:**
- Modify: `lib/fuelred/fuelred_page.dart` (the `_RfidScanSheet` section)

**Step 1: Replace String _phase with enum**

Add a local enum at the top of the file (before `_RfidScanSheet` class, around line 693):

```dart
enum _ScanPhase { idle, scanning, verifying, success, error }
```

**Step 2: Update _RfidScanSheetState**

Change `String _phase = 'idle';` to `_ScanPhase _phase = _ScanPhase.idle;`

Update all comparisons:
- `_phase == 'scanning'` → `_phase == _ScanPhase.scanning`
- `_phase == 'verifying'` → `_phase == _ScanPhase.verifying`
- `_phase == 'error'` → `_phase == _ScanPhase.error`
- `_phase == 'idle'` → `_phase == _ScanPhase.idle`
- `_phase = 'scanning'` → `_phase = _ScanPhase.scanning`
- `_phase = 'error'` → `_phase = _ScanPhase.error`
- `_phase = 'verifying'` → `_phase = _ScanPhase.verifying`
- `_phase = 'success'` → `_phase = _ScanPhase.success`

**Step 3: Wrap _buildScanState in AnimatedSwitcher**

In the `build` method of `_RfidScanSheetState` (around line 891), replace:
```dart
            _buildScanState(),
```
with:
```dart
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _buildScanState(),
            ),
```

**Step 4: Add ValueKey to each phase in _buildScanState**

Update the `_buildScanState()` switch to return widgets with keys:

```dart
  Widget _buildScanState() {
    return switch (_phase) {
      _ScanPhase.scanning => Column(
          key: const ValueKey('scan_scanning'),
          children: [
            // ... existing scanning UI
          ],
        ),
      _ScanPhase.verifying => Column(
          key: const ValueKey('scan_verifying'),
          children: [
            // ... existing verifying UI
          ],
        ),
      _ScanPhase.success => Column(
          key: const ValueKey('scan_success'),
          children: [
            // ... existing success UI
          ],
        ),
      _ScanPhase.error => Column(
          key: const ValueKey('scan_error'),
          children: [
            // ... existing error UI
          ],
        ),
      _ScanPhase.idle => Column(
          key: const ValueKey('scan_idle'),
          children: [
            // ... existing idle UI
          ],
        ),
    };
  }
```

Keep the existing UI content inside each Column — just add the `key` parameter and change the switch syntax.

**Step 5: Update the button condition**

Change:
```dart
if (_phase == 'error' || _phase == 'idle')
```
to:
```dart
if (_phase == _ScanPhase.error || _phase == _ScanPhase.idle)
```

**Step 6: Verify it compiles**

Run: `flutter analyze lib/fuelred/fuelred_page.dart`
Expected: No issues found

**Step 7: Commit**

```bash
git add lib/fuelred/fuelred_page.dart
git commit -m "feat: replace String phases with typed enum + AnimatedSwitcher in RfidScanSheet"
```

---

### Task 13: Manual smoke test

**Step 1: Run the app**

Run: `flutter run`

**Step 2: Verify these scenarios**

1. Open FuelRed tab — should show shimmer loading briefly, then content or empty state
2. If empty: should see the EmptyState widget with truck icon and message
3. If connected: action hub should show normally with WS status
4. Tap a waiting card → bottom sheet opens with NFC scan
5. Watch scan phases transition with smooth fade animation
6. Authorize a dispatch → should see AppOverlay toast slide in from top (not SnackBar)
7. Error scenarios → should see red AppOverlay toast

**Step 3: Final commit if any adjustments needed**

```bash
git add -A
git commit -m "fix: adjustments from smoke testing"
```
