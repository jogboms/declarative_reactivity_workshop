import 'dart:async';

import 'async_value.dart';
import 'atom.dart';

typedef AsyncAtomFactory<T, U> = U Function(AtomContext<AsyncValue<T>> context);

extension AsyncAtomContext<U> on AtomContext<U> {
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

final class FutureAtom<T> extends Atom<AsyncValue<T>> {
  FutureAtom(AsyncAtomFactory<T, FutureOr<T>> factory, {super.key, super.name})
      : super((context) {
          final value = context.mutateSelf((value) {
            if (value?.valueOrNull case final value?) {
              return AsyncLoading(value);
            }

            return value;
          });

          switch (factory(context)) {
            case T value:
              return AsyncData(value);
            case Future<T> future:
              future.then((value) {
                context.mutateSelf(
                  (_) => AsyncData(value),
                );
              });
          }

          return value ?? const AsyncLoading();
        });
}
