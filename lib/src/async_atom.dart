import 'dart:async';

import 'async_value.dart';
import 'atom.dart';

typedef AsyncAtomFactory<T, U> = U Function(AtomContext<AsyncValue<T>> context);

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
