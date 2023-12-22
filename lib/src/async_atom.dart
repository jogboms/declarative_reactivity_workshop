import 'dart:async';

import 'async_value.dart';
import 'atom.dart';

typedef AsyncAtomFactory<T, U> = U Function(AtomContext<AsyncValue<T>> context);
typedef AsyncAtomFamilyFactory<T, U, V> = U Function(AtomContext<AsyncValue<T>> context, V arg);

/// A context that can be used to interact with asynchronous [Atom]s.
extension AsyncAtomContext<U> on AtomContext<U> {
  /// Returns the resolved value of [atom] as a [Future]. It will trigger a rebuild of itself when the [atom] changes.
  Future<T> async<T>(Atom<AsyncValue<T>> atom) async {
    await Future<void>.value();

    final completer = Completer<T>();

    listen(atom, (_, value) {
      if (completer.isCompleted) {
        invalidateSelf();
      } else if (value case final AsyncData<T> data) {
        completer.complete(data.value);
      } else if (value case final AsyncError<T> value) {
        completer.completeError(value.error, value.stackTrace);
      }
    }, fireImmediately: true);

    return completer.future;
  }
}

/// A selector that can be used to select a value from an [AsyncValue].
extension AsyncAtomSelector<T> on Atom<AsyncValue<T>> {
  Atom<AsyncValue<U>> selectAsync<U>(AtomSelector<T, U> selector, {String? key, String? name}) {
    return Atom(
      (context) => context.get(this).when(
            loading: () => const AsyncLoading(),
            refreshing: (value) => AsyncLoading(selector(value)),
            data: (value) => AsyncData(selector(value)),
            error: AsyncError.new,
          ),
      key: key,
      name: name,
    );
  }
}

/// A [Atom] that can be used to represent an asynchronous value.
final class FutureAtom<T> extends Atom<AsyncValue<T>> {
  FutureAtom(AsyncAtomFactory<T, FutureOr<T>> factory, {super.key, super.name})
      : super((context) {
          final value = context.mutateSelf((value) {
            if (value?.valueOrNull case final value?) {
              return AsyncLoading(value);
            }

            return value;
          });

          bool disposed = false;
          context.onDispose(() {
            disposed = true;
          });

          switch (factory(context)) {
            case T value:
              return AsyncData(value);
            case Future<T> future:
              future.then((value) {
                if (disposed) {
                  return;
                }
                context.mutateSelf(
                  (_) => AsyncData(value),
                );
              }).catchError((Object error, StackTrace stackTrace) {
                if (disposed) {
                  return;
                }
                context.mutateSelf(
                  (_) => AsyncError(error, stackTrace),
                );
              });
          }

          return value ?? const AsyncLoading();
        });

  static AtomFamily<U, FutureAtom<T>> family<T, U>(
    AsyncAtomFamilyFactory<T, Future<T>, U> factory, {
    String? name,
  }) {
    return (U arg) => FutureAtom<T>(
          (context) => factory(context, arg),
          key: Object.hash(arg, T, U),
          name: name,
        );
  }
}

/// A [Atom] that can be used to represent a stream of values.
final class StreamAtom<T> extends Atom<AsyncValue<T>> {
  StreamAtom(AsyncAtomFactory<T, Stream<T>> factory, {super.key, super.name})
      : super((context) {
          final value = context.mutateSelf((value) {
            if (value?.valueOrNull case final value?) {
              return AsyncLoading(value);
            }

            return value;
          });

          StreamSubscription<T>? sub;
          context.onDispose(() {
            sub?.cancel();
          });

          sub = factory(context).listen((value) {
            context.mutateSelf(
              (_) => AsyncData(value),
            );
          }, onError: (Object error, StackTrace stackTrace) {
            context.mutateSelf(
              (_) => AsyncError(error, stackTrace),
            );
          }, onDone: () => sub?.cancel());

          return value ?? const AsyncLoading();
        });

  static AtomFamily<U, StreamAtom<T>> family<T, U>(
    AsyncAtomFamilyFactory<T, Stream<T>, U> factory, {
    String? name,
  }) {
    return (U arg) => StreamAtom<T>(
          (context) => factory(context, arg),
          key: Object.hash(arg, T, U),
          name: name,
        );
  }
}
