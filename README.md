# Declarative Reactivity Workshop

This workshop will help you understand how to implement a declarative reactivity system similar
to [Riverpod](https://riverpod.dev/docs/introduction/getting_started).

This is a common pattern in the web development space with examples
like [MobX](https://mobx.js.org/the-gist-of-mobx.html), [Solid-js's Signals](https://www.solidjs.com/guides/reactivity), [Vue's Composition
API](https://vuejs.org/guide/introduction.html), [React's Recoil-js](https://recoiljs.org/docs/introduction/core-concepts)
and more recently [Svelte's Runes](https://svelte.dev/blog/runes).

This is a very simplified version of a reactivity system with a couple of missing features. Most-notable a robust 
error handling system. But it will help you understand how a basic reactivity system works internally.

This workshop is also not meant to teach you how to use Riverpod, it is actually only mentioned as a more robust
implementation with a familiar API but rather how to implement a similar system from scratch without all the bells and
whistles.

## What is reactivity?

Reactivity is a programming paradigm that focuses on how data flows through an application. A reactive system will
automatically update when data changes.

This is in contrast to the imperative style, which requires the developer to manually update the UI when data changes.

In the case of being declarative, you are tasked with describing what you want the data to look like when a change
occurs and the details of when this happens and how it happens is handled automatically by the framework.

## Why is declarative reactivity important?

Declarative reactivity is important because it allows us to focus on what we want our system to look like, rather
than how we want our system to behave. This allows us to write code that is easier to understand, test, and maintain.

## What makes a declarative reactive system?

### Declarative

We should only be able to mutate only our state and not the state of other objects.

### Reactive

We should be able to subscribe to changes in other reactive objects and be notified when they
occur.

### Composable

We should be able to combine multiple reactive objects into a single reactive object.

### Performant

We should be able to update our state without causing unnecessary re-renders.

### Predictable

We should be able to predict how our state will change when we mutate it.

### Testable

We should be able to test our state without having to mock out the entire system.

## How does it actually work?

Its important again to understand that declarative reactivity is not a new concept. It has been around for a long
time in the form of the Observer Pattern. The Observer Pattern is a design pattern that allows objects to subscribe
to changes in other objects. This is useful when you want to be notified of changes in an object, but don't want to
have to poll for changes.

The Observer Pattern is a good starting point for understanding how declarative reactivity works, but it has some
limitations in its raw form especially when it comes to self-clean up and potential memory leaks. We would be
addressing some of these in our implementation.

## What does it look like in code?

### Riverpod

```dart

final countProvider = StateProvider((ref) => 0);

class Counter extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final count = useProvider(countProvider).state;

    useEffect(() {
      final timer = Timer.periodic(Duration(seconds: 1), (_) {
        context
            .read(countProvider)
            .state++;
      });

      return timer.cancel;
    }, []);

    return Text('Count: $count');
  }
}
```

### Solid-js

```jsx
import { createSignal, createEffect } from "solid-js";

function Counter() {
  const [count, setCount] = createSignal(0);

  setInterval(() => setCount(count() + 1), 1000);
  
  createEffect(() => console.log(count()));

  return <p>Count: {count()}</p>;
}
```

### Vue

```vue
<script setup>
import { ref, watch } from 'vue'

const count = ref(0)

setInterval(() => count.value++, 1000)

watch(count, () => console.log(count.value))
</script>

<template>
  <p>Count: {{ count }}</p>
</template>
```

### Svelte

```svelte
<script>
   let count = $state(0);

   setInterval(() => count += 1, 1000);
  
   $effect(() => console.log(count));
</script>

<p>Count: {count}</p>
```

## What we will be building

```dart

final count = Atom((_) => 0);

void main() {
  final container = AtomContainer();

  Timer.periodic(const Duration(seconds: 1), (_) {
    container.mutate(count, (value) => value + 1);
  });

  container.listen(count, (_, value) {
    print(value);
  });
}

```

## Lets Begin!

You can follow along by checking out the commits.

A live flutter demo can also be accessed on [Dartpad](https://dartpad.dev/?id=5aa877b61eb9fccd904c325f2757a05a). 
