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

  @override
  T get<T>(
    Atom<T> atom, {
    bool rebuildOnChange = true,
  }) {
    return _resolve(atom, track: rebuildOnChange).value;
  }

  @override
  AtomSubscription<T> listen<T>(
    Atom<T> atom,
    AtomListener<T> listener, {
    bool fireImmediately = false,
  }) {
    final element = _resolve(atom);
    final cancel = element._addListener(listener);

    if (fireImmediately) {
      listener(null, element.value);
    }

    return (
      get: () => element.value,
      cancel: cancel,
    );
  }

  @override
  T mutate<T>(Atom<T> atom, AtomMutation<T> mutator) {
    final element = _resolve(atom);
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
  void invalidateSelf() => _owner?._invalidate();

  @override
  void onDispose(VoidCallback callback) {}

  void dispose() {}

  AtomElement<T> _resolve<T>(
    Atom<T> atom, {
    bool track = false,
  }) {
    switch (_binding._elements[atom]) {
      case AtomElement<T> element:
        if (track) {
          _owner?._dependsOn(element);
        }
        return element;
      case _:
        final element = atom.createElement();
        final container = AtomContainer(owner: element, parent: this);

        _binding._elements[atom] = element.._container = container;

        if (track) {
          _owner?._dependsOn(element);
        }

        return element.._mount();
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

  AtomContainer<T>? _container;
  T? _value;

  T get value {
    if (_value case final value?) {
      return value;
    }

    throw StateError('The value of $atom has not been initialized.');
  }

  T setValue(T value) {
    if (_value != value) {
      final previous = _value;
      _value = value;

      for (final listener in _listeners) {
        listener(previous, value);
      }
      for (final dependent in _dependents) {
        dependent._invalidate();
      }
    }

    return value;
  }

  void _mount() {
    if (_container case final container?) {
      setValue(atom.factory(container));
    }
  }

  void _invalidate() {
    _mount();
  }

  VoidCallback _addListener(AtomListener<T> listener) {
    _listeners.add(listener);
    return () => _listeners.remove(listener);
  }

  void _dependsOn(AtomElement element) => element._dependents.add(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AtomElement && runtimeType == other.runtimeType && atom == other.atom;

  @override
  int get hashCode => atom.hashCode;

  @override
  String toString() => 'AtomElement<${atom.name ?? T}>($hashCode)';
}
