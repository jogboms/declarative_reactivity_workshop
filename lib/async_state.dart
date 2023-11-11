import 'dart:math';

import 'src/async_atom.dart';

final delayed = FutureAtom((_) {
  return Future.delayed(
    const Duration(seconds: 2),
    () => Random().nextInt(100),
  );
});
