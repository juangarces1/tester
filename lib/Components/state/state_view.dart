import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tester/Components/state/empty_state.dart';
import 'package:tester/Components/state/error_card.dart';
import 'package:tester/Components/state/minimal_loader.dart';
import 'package:tester/Components/state/view_state.dart';

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
