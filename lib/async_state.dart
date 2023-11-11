import 'dart:math';

import 'package:declarative_reactivity_workshop/src/async_value.dart';

import 'src/atom.dart';

final delayed = Atom<AsyncValue<int>>((context) {
  final value = context.mutateSelf((value) {
    if (value?.valueOrNull case final value?) {
      return AsyncLoading(value);
    }

    return value;
  });

  Future.delayed(const Duration(seconds: 2), () {
    context.mutateSelf(
      (_) => AsyncData(Random().nextInt(100)),
    );
  });

  return value ?? const AsyncLoading();
});
