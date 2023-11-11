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

@optionalTypeArgs
final class AtomContainer<U> implements AtomContext<U> {
  AtomContainer({
    AtomContainer? parent,
  }) : _elements = parent?._elements ?? {};

  final Map<Atom, AtomElement> _elements;

  @override
  T get<T>(
    Atom<T> atom, {
    bool rebuildOnChange = true,
  }) {
    switch (_elements[atom]) {
      case AtomElement<T> element:
        return element.value;
      case _:
        final element = atom.createElement();
        _elements[atom] = element;
        final value = atom.factory(
          AtomContainer(parent: this),
        );
        element.setValue(value);
        return value;
    }
  }

  @override
  AtomSubscription<T> listen<T>(
    Atom<T> atom,
    AtomListener<T> listener, {
    bool fireImmediately = false,
  }) {
    throw UnimplementedError();
  }

  @override
  T mutate<T>(Atom<T> atom, AtomMutation<T> mutator) {
    throw UnimplementedError();
  }

  @override
  @internal
  U? mutateSelf(AtomMutation<U?> mutator) {
    throw UnimplementedError();
  }

  @override
  void invalidate<T>(Atom<T> atom) {}

  @override
  @internal
  void invalidateSelf() {}

  @override
  void onDispose(VoidCallback callback) {}

  void dispose() {}
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

  T? _value;

  T get value {
    if (_value case final value?) {
      return value;
    }

    throw StateError('The value of $atom has not been initialized.');
  }

  T setValue(T value) {
    _value = value;

    return value;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AtomElement && runtimeType == other.runtimeType && atom == other.atom;

  @override
  int get hashCode => atom.hashCode;

  @override
  String toString() => 'AtomElement<${atom.name ?? T}>($hashCode)';
}
