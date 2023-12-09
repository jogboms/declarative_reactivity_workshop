import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import 'atom.dart';

@optionalTypeArgs
mixin AtomWidgetMixin<T extends StatefulWidget> on State<T> {
  @internal
  static AtomWidgetMixin of(BuildContext context) {
    final result = context.getInheritedWidgetOfExactType<_AtomWidgetMixinMarker>();
    assert(result != null, 'No AtomScope found in context');
    return result!.state;
  }

  @internal
  AtomContainer get container;
}

class _AtomWidgetMixinMarker extends InheritedWidget {
  const _AtomWidgetMixinMarker({
    super.key,
    required this.state,
    required super.child,
  });

  final AtomWidgetMixin state;

  @override
  bool updateShouldNotify(_AtomWidgetMixinMarker old) => old.state.container != state.container;
}

extension AtomWidgetContext on BuildContext {
  /// Returns the current value of [atom]. If [rebuildOnChange] is true, it will rebuild itself when the [atom] changes.
  T get<T>(
    Atom<T> atom, {
    bool rebuildOnChange = true,
  }) {
    throw UnimplementedError();
  }

  /// Listens to changes on [atom]. Subscriptions will be automatically cancelled when the widget is rebuilt and/or disposed.
  void listen<T>(Atom<T> atom, AtomListener<T> listener) {
    throw UnimplementedError();
  }

  /// Listens to changes on [atom]. If [fireImmediately] is true, the listener will be called immediately with the current value.
  AtomSubscription<T> listenManual<T>(
    Atom<T> atom,
    AtomListener<T> listener, {
    bool fireImmediately = false,
  }) {
    throw UnimplementedError();
  }

  /// Mutates [atom] with [mutator] and returns the new value.
  void mutate<T>(Atom<T> atom, AtomMutation<T> mutator) {
    throw UnimplementedError();
  }

  /// Invalidates [atom] so that it will rebuild.
  void invalidate<T>(Atom<T> atom) {
    throw UnimplementedError();
  }
}
