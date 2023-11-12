import 'dart:async';
import 'dart:math';

import 'src/async_atom.dart';

final delayed = FutureAtom((_) {
  return Future.delayed(
    const Duration(seconds: 2),
    () => Random().nextInt(100),
  );
});

final delayedByTen = FutureAtom((context) async {
  return await context.async(delayed) * 10;
});

final delayedStream = StreamAtom((context) async* {
  final value = await context.async(delayed);

  await Future.delayed(const Duration(seconds: 2));

  yield value;
});

final delayedStreamByTen = FutureAtom((context) async {
  return await context.async(delayedStream) * 10;
});

final delayedStreamCounter = StreamAtom((context) async* {
  yield* _countGenerator().asyncMap(
    (count) async => (await context.async(delayedStream)) + count,
  );
});

Stream<int> _countGenerator() {
  return Stream.periodic(
    const Duration(seconds: 1),
    (count) => count + 1,
  );
}
