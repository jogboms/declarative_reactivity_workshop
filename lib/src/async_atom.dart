import 'dart:async';

import 'async_value.dart';
import 'atom.dart';

typedef AsyncAtomFactory<T, U> = U Function(AtomContext<AsyncValue<T>> context);

/// A context that can be used to interact with asynchronous [Atom]s.
extension AsyncAtomContext<U> on AtomContext<U> {
  /// Returns the resolved value of [atom] as a [Future]. It will trigger a rebuild of itself when the [atom] changes.
  Future<T> async<T>(Atom<AsyncValue<T>> atom) {
    final completer = Completer<T>();

    listen(atom, (_, value) {
      if (completer.isCompleted) {
        invalidateSelf();
      } else if (value case final AsyncData<T> data) {
        completer.complete(data.value);
      }
    }, fireImmediately: true);

    return completer.future;
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
              });
          }

          return value ?? const AsyncLoading();
        });
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
          });

          return value ?? const AsyncLoading();
        });
}
