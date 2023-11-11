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

class AtomScope extends StatefulWidget {
  const AtomScope({super.key, required this.child});

  final Widget child;

  @override
  State<AtomScope> createState() => _AtomScopeState();
}

class _AtomScopeState extends State<AtomScope> with AtomWidgetMixin {
  @override
  late final container = AtomContainer();

  @override
  void dispose() {
    container.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AtomWidgetMixinMarker(
      key: ObjectKey(container),
      state: this,
      child: widget.child,
    );
  }
}

class AtomBuilder extends StatefulWidget {
  const AtomBuilder({super.key, required this.builder});

  final WidgetBuilder builder;

  @override
  State<AtomBuilder> createState() => _AtomBuilderState();
}

class _AtomBuilderState extends State<AtomBuilder> {
  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) => widget.builder(context),
    );
  }
}

extension AtomWidgetContext on BuildContext {
  /// Returns the current value of [atom]. If [rebuildOnChange] is true, it will rebuild itself when the [atom] changes.
  T get<T>(
    Atom<T> atom, {
    bool rebuildOnChange = true,
  }) {
    return AtomWidgetMixin.of(this).container.get(
          atom,
          rebuildOnChange: rebuildOnChange,
        );
  }

  /// Listens to changes on [atom]. Subscriptions will be automatically cancelled when the widget is rebuilt and/or disposed.
  void listen<T>(Atom<T> atom, AtomListener<T> listener) {
    listenManual(atom, listener, fireImmediately: false);
  }

  /// Listens to changes on [atom]. If [fireImmediately] is true, the listener will be called immediately with the current value.
  AtomSubscription<T> listenManual<T>(
    Atom<T> atom,
    AtomListener<T> listener, {
    bool fireImmediately = false,
  }) =>
      AtomWidgetMixin.of(this).container.listen(atom, listener, fireImmediately: fireImmediately);

  /// Mutates [atom] with [mutator] and returns the new value.
  void mutate<T>(Atom<T> atom, AtomMutation<T> mutator) => AtomWidgetMixin.of(this).container.mutate<T>(atom, mutator);

  /// Invalidates [atom] so that it will rebuild.
  void invalidate<T>(Atom<T> atom) => AtomWidgetMixin.of(this).container.invalidate(atom);
}
