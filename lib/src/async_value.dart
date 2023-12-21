sealed class AsyncValue<T> {
  const AsyncValue();

  T? get valueOrNull {
    return switch (this) {
      AsyncData(:final value) || AsyncLoading(:final value?) => value,
      _ => null,
    };
  }

  U when<U>({
    required U Function() loading,
    required U Function(T value) refreshing,
    required U Function(T value) data,
    required U Function(Object error, StackTrace stackTrace) error,
  }) {
    return switch (this) {
      AsyncData(:final value) => data(value),
      AsyncLoading(:final value) => value == null ? loading() : refreshing(value),
      final AsyncError<T> value => error(value.error, value.stackTrace),
    };
  }
}

class AsyncLoading<T> extends AsyncValue<T> {
  const AsyncLoading([this.value]);

  final T? value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AsyncLoading && runtimeType == other.runtimeType && value == other.value;

  @override
  int get hashCode => value?.hashCode ?? runtimeType.hashCode;

  @override
  String toString() => 'AsyncLoading(${value ?? ''})';
}

class AsyncData<T> extends AsyncValue<T> {
  const AsyncData(this.value);

  final T value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AsyncData && runtimeType == other.runtimeType && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'AsyncData($value)';
}

class AsyncError<T> extends AsyncValue<T> {
  const AsyncError(this.error, this.stackTrace);

  final Object error;
  final StackTrace stackTrace;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AsyncError && runtimeType == other.runtimeType && error == other.error && stackTrace == other.stackTrace;

  @override
  int get hashCode => error.hashCode ^ stackTrace.hashCode;

  @override
  String toString() => 'AsyncError($error, $stackTrace)';
}
