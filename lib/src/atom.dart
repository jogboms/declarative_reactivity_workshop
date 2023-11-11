import 'package:meta/meta.dart';

typedef VoidCallback = void Function();
typedef ValueCallback<T> = T Function();
typedef AtomFactory<T> = T Function(AtomContext<T> context);
typedef AtomMutation<T> = T Function(T value);
typedef AtomListener<T> = void Function(T? previous, T value);
@optionalTypeArgs
typedef AtomSubscription<T> = ({ValueCallback<T> get, VoidCallback cancel});

/// A context that can be used to interact with [Atom]s.
@optionalTypeArgs
mixin AtomContext<U> {}

@optionalTypeArgs
final class AtomContainer<U> implements AtomContext<U> {
  void dispose() {}
}

/// A [Atom] that can be used to store a value.
@optionalTypeArgs
base class Atom<T> {
  Atom(this.factory, {this.key, this.name});

  @internal
  final AtomFactory<T> factory;

  @internal
  final Object? key;

  @internal
  final String? name;

  @internal
  AtomElement<T> createElement() => AtomElement<T>(this);

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

  late T value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AtomElement && runtimeType == other.runtimeType && atom == other.atom;

  @override
  int get hashCode => atom.hashCode;

  @override
  String toString() => 'AtomElement<${atom.name ?? T}>($hashCode)';
}
