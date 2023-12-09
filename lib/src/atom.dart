import 'dart:async';

import 'package:meta/meta.dart';

typedef VoidCallback = void Function();
typedef ValueCallback<T> = T Function();
typedef AtomFactory<T> = T Function(AtomContext<T> context);
typedef AtomFamily<U, V extends Atom> = V Function(U arg);
typedef AtomFamilyFactory<T, U> = T Function(AtomContext ref, U arg);
typedef AtomMutation<T> = T Function(T value);
typedef AtomSelector<T, U> = U Function(T value);
typedef AtomListener<T> = void Function(T? previous, T value);
@optionalTypeArgs
typedef AtomSubscription<T> = ({ValueCallback<T> get, VoidCallback cancel});

/// A context that can be used to interact with [Atom]s.
@optionalTypeArgs
mixin AtomContext<U> {
  /// Returns the current value of [atom]. If [rebuildOnChange] is true, it will rebuild itself when the [atom] changes.
  T get<T>(
    Atom<T> atom, {
    bool rebuildOnChange = true,
  });

  /// Listens to changes on [atom]. If [fireImmediately] is true, the listener will be called immediately with the current value.
  AtomSubscription<T> listen<T>(
    Atom<T> atom,
    AtomListener<T> listener, {
    bool fireImmediately = false,
  });

  /// Mutates [atom] with [mutator] and returns the new value.
  @protected
  T mutate<T>(Atom<T> atom, AtomMutation<T> mutator);

  /// Mutates itself and returns the new value.
  U? mutateSelf(AtomMutation<U?> mutator);

  /// Invalidates [atom] so that it will rebuild.
  @protected
  void invalidate<T>(Atom<T> atom);

  /// Invalidates itself so that it will rebuild.
  void invalidateSelf();

  /// Registers a [callback] to be called when the [Atom] is invalidated or disposed.
  void onDispose(VoidCallback callback);
}

@internal
final class AtomBinding {
  AtomBinding._({
    Map<Atom, AtomElement>? elements,
  }) : _elements = elements ?? {};

  final Map<Atom, AtomElement> _elements;

  void dispose() {
    _elements.clear();
  }
}

@optionalTypeArgs
final class AtomContainer<U> implements AtomContext<U> {
  AtomContainer({
    AtomElement<U>? owner,
    AtomContainer? parent,
  })  : _owner = owner,
        _binding = parent?._binding ?? AtomBinding._();

  final AtomElement<U>? _owner;
  final AtomBinding _binding;

  VoidCallback? _disposeCallback;

  @override
  T get<T>(
    Atom<T> atom, {
    bool rebuildOnChange = true,
  }) {
    return _resolve(atom, mount: true, track: rebuildOnChange).value;
  }

  @override
  AtomSubscription<T> listen<T>(
    Atom<T> atom,
    AtomListener<T> listener, {
    bool fireImmediately = false,
  }) {
    final element = _resolve(atom);
    final cancel = element._addListener(listener);
    _owner?._subscriptionCallback += cancel;

    switch ((fireImmediately, element._state)) {
      case (true, AtomElementState.idle):
        element._mount();
        listener(null, element.value);
      case (false, AtomElementState.idle):
        element._mount();
      case (true, _):
        listener(null, element.value);
      case _:
        break;
    }

    return (
      get: () => element.value,
      cancel: cancel,
    );
  }

  @override
  T mutate<T>(Atom<T> atom, AtomMutation<T> mutator) {
    final element = _resolve(atom, mount: true);
    return element.setValue(mutator(element.value));
  }

  @override
  @internal
  U? mutateSelf(AtomMutation<U?> mutator) {
    if (_owner case final element?) {
      if (mutator(element._value) case final value?) {
        return element.setValue(value);
      }
    }

    return null;
  }

  @override
  void invalidate<T>(Atom<T> atom) => _binding._elements[atom]?._invalidate();

  @override
  @internal
  void invalidateSelf() {
    if (_owner case final element?) {
      element._invalidate(schedule: true);
      scheduleMicrotask(element._maybeMount);
    }
  }

  @override
  void onDispose(VoidCallback callback) {
    if (_owner case final element?) {
      element._disposeCallback += callback;
    } else {
      _disposeCallback += callback;
    }
  }

  void dispose() {
    if (_owner case final element?) {
      element._dispose();
    } else {
      for (final element in _binding._elements.values) {
        element._dispose();
      }
      _binding.dispose();
    }

    final previousCallback = _disposeCallback;
    _disposeCallback = null;
    previousCallback?.call();
  }

  AtomElement<T> _resolve<T>(
    Atom<T> atom, {
    bool mount = false,
    bool track = false,
  }) {
    switch (_binding._elements[atom]) {
      case AtomElement<T> element:
        _owner?._attachDependency(element, track: track);
        return element;
      case _:
        final element = atom.createElement();
        final container = AtomContainer(owner: element, parent: this);

        _binding._elements[atom] = element.._container = container;
        _owner?._attachDependency(element, track: track);

        if (mount) {
          element._mount();
        }

        return element;
    }
  }
}

/// A [Atom] that can be used to store a value.
@optionalTypeArgs
base class Atom<T> {
  Atom(this.factory, {this.key, this.name});

  /// Creates a new [Atom] with the given [factory] that receives a single argument.
  static AtomFamily<U, Atom<T>> family<T, U>(
    AtomFamilyFactory<T, U> factory, {
    String? name,
  }) {
    return (U arg) => Atom(
          (context) => factory(context, arg),
          key: Object.hash(arg, T, U),
          name: name,
        );
  }

  @internal
  final AtomFactory<T> factory;

  @internal
  final Object? key;

  @internal
  final String? name;

  @internal
  AtomElement<T> createElement() => AtomElement<T>(this);

  Atom<U> select<U>(AtomSelector<T, U> selector, {String? key, String? name}) {
    return Atom(
      (context) => selector(context.get(this)),
      key: key,
      name: name,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Atom && runtimeType == other.runtimeType && key == other.key;

  @override
  int get hashCode => key != null ? Object.hash(key, T) : identityHashCode(this);

  @override
  String toString() => 'Atom<${name ?? T}>($hashCode)';
}

@internal
enum AtomElementState {
  /// The atom has never been mounted.
  idle,

  /// The atom is being mounted.
  mounting,

  /// The atom has been mounted at least once.
  active,

  /// The atom needs a remount.
  stale,

  /// The atom has been disposed.
  disposed,
}

@optionalTypeArgs
@internal
class AtomElement<T> {
  AtomElement(this.atom);

  final Atom<T> atom;
  final Set<AtomListener<T>> _listeners = {};
  final Set<AtomElement> _dependents = {};
  final Set<AtomElement> _dependencies = {};

  bool get isActive => _listeners.isNotEmpty || _dependents.isNotEmpty;

  AtomContainer<T>? _container;
  VoidCallback? _subscriptionCallback;
  VoidCallback? _disposeCallback;
  AtomElementState? _state = AtomElementState.idle;
  T? _value;

  T get value {
    if (_state == AtomElementState.stale) {
      _mount();
    }
    if (_value case final value?) {
      return value;
    }

    throw StateError('The value of $atom has not been initialized.');
  }

  T setValue(T value) {
    if (_state == AtomElementState.idle) {
      return _value = value;
    }

    if (_value != value) {
      final previous = _value;
      _value = value;

      for (final listener in _listeners.toList(growable: false)) {
        listener(previous, value);
      }
      for (final dependent in _dependents) {
        dependent._invalidate(schedule: true);
      }
      for (final dependent in _dependents.toList(growable: false)) {
        dependent._maybeMount();
      }
    }

    return value;
  }

  void _mount() {
    if (_container case final container?) {
      _detachDependencies();
      setValue(atom.factory(container));
      _state = AtomElementState.active;
    }
  }

  void _maybeMount() {
    switch (_state) {
      case AtomElementState.stale when _value != null && isActive:
        _mount();
      case AtomElementState.disposed:
        _state = null;
      case _:
        break;
    }
  }

  void _invalidate({bool schedule = false}) {
    switch (_state) {
      case AtomElementState.active:
        _state = AtomElementState.stale;
      case _:
        return;
    }

    _runDispose();

    if (!schedule) {
      return _maybeMount();
    }

    for (final dependent in _dependents) {
      dependent._invalidate(schedule: true);
    }
  }

  VoidCallback _addListener(AtomListener<T> listener) {
    _listeners.add(listener);
    return () => _listeners.remove(listener);
  }

  void _attachDependency(AtomElement element, {bool track = false}) {
    if (track) {
      element._dependents.add(this);
    }
    _dependencies.add(element);
  }

  void _detachDependencies() {
    for (final element in _dependencies.toList(growable: false)) {
      element._dependents.remove(this);
    }

    final previousCallback = _subscriptionCallback;
    _subscriptionCallback = null;
    previousCallback?.call();
  }

  void _runDispose() {
    final previousCallback = _disposeCallback;
    _disposeCallback = null;
    previousCallback?.call();
  }

  void _dispose() {
    _runDispose();
    _detachDependencies();
    _state = AtomElementState.disposed;
    _value = null;
    _container = null;
    _listeners.clear();
    _dependents.clear();
    _dependencies.clear();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AtomElement && runtimeType == other.runtimeType && atom == other.atom;

  @override
  int get hashCode => atom.hashCode;

  @override
  String toString() => 'AtomElement<${atom.name ?? T}>($hashCode)';
}

extension on VoidCallback? {
  VoidCallback operator +(VoidCallback other) => () {
        this?.call();
        other();
      };
}

class AtomGraphNode {
  const AtomGraphNode(this.id, this.source, this.data);

  final String id;
  final bool source;
  final Object? data;

  @override
  bool operator ==(Object other) => other is AtomGraphNode && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => '<$id($source): $data>';
}

typedef AtomGraph = Map<AtomGraphNode, List<AtomGraphNode>>;

extension AtomGraphBuilder<U> on AtomContainer<U> {
  void _addEdgeTo(AtomGraph graph, AtomGraphNode source, AtomGraphNode destination) {
    graph.update(
      source,
      (value) => value..add(destination),
      ifAbsent: () => [destination],
    );
  }

  AtomGraphNode _nodeFor(AtomElement element) {
    return AtomGraphNode(
      element.atom.name ?? element.atom.toString(),
      element._dependencies.isEmpty,
      element._value,
    );
  }

  AtomGraph graph() {
    final graph = <AtomGraphNode, List<AtomGraphNode>>{};
    const node = AtomGraphNode('container', true, null);
    for (final element in _binding._elements.values) {
      final edgeNode = _nodeFor(element);
      if (element._dependencies.isEmpty) {
        _addEdgeTo(graph, node, edgeNode);
      } else {
        for (final dep in element._dependencies) {
          _addEdgeTo(graph, _nodeFor(dep), edgeNode);
        }
      }
    }
    return graph;
  }
}
