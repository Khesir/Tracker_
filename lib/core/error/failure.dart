library;

sealed class Failure {
  final String message;
  final StackTrace? stackTrace;
  final Object? originalError;

  const Failure({
    required this.message,
    this.stackTrace,
    this.originalError,
  });

  @override
  String toString() => message;
}

class NetworkFailure extends Failure {
  const NetworkFailure({String? message, super.stackTrace, super.originalError})
      : super(message: message ?? 'No internet connection.');
}

class DatabaseFailure extends Failure {
  const DatabaseFailure({String? message, super.stackTrace, super.originalError})
      : super(message: message ?? 'Failed to save data.');
}

class ValidationFailure extends Failure {
  const ValidationFailure(String message, {super.stackTrace, super.originalError})
      : super(message: message);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure({String? message, super.stackTrace, super.originalError})
      : super(message: message ?? 'Resource not found.');
}

class UnknownFailure extends Failure {
  const UnknownFailure({String? message, super.stackTrace, super.originalError})
      : super(message: message ?? 'An unexpected error occurred.');
}
