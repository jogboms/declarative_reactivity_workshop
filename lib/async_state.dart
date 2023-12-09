import 'dart:async';
import 'dart:math';

import 'src/async_atom.dart';

final delayed = FutureAtom((_) {
  return Future.delayed(
    const Duration(seconds: 2),
    () => Random().nextInt(100),
  );
}, name: 'delayed');

final delayedByTen = FutureAtom((context) async {
  return await context.async(delayed) * 10;
}, name: 'delayed-by-ten');

final delayedStream = StreamAtom((context) async* {
  final value = await context.async(delayed);

  await Future.delayed(const Duration(seconds: 2));

  yield value;
}, name: 'delayed-stream');

final delayedStreamByTen = FutureAtom((context) async {
  return await context.async(delayedStream) * 10;
}, name: 'delayed-stream-by-ten');

final delayedStreamCounter = StreamAtom((context) async* {
  yield* _countGenerator().asyncMap(
    (count) async => (await context.async(delayedStream)) + count,
  );
}, name: 'delayed-stream-counter');

final delayedByStream = FutureAtom((context) async {
  await Future.delayed(const Duration(milliseconds: 300));
  return await context.async(delayedStreamCounter);
}, name: 'delayed-by-stream');

Stream<int> _countGenerator() {
  return Stream.periodic(
    const Duration(seconds: 1),
    (count) => count + 1,
  );
}
