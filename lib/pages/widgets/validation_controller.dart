import 'dart:async';

import 'package:flutter/material.dart';

enum ValidationStatus {
  idle,
  validating,
  valid,
  invalid,
}

class ValidationState {
  final ValidationStatus status;
  final String? error;

  const ValidationState._(this.status, this.error);

  const ValidationState.idle() : this._(ValidationStatus.idle, null);
  const ValidationState.validating() : this._(ValidationStatus.validating, null);
  const ValidationState.valid() : this._(ValidationStatus.valid, null);
  const ValidationState.invalid(String error) : this._(ValidationStatus.invalid, error);

  bool get isValid => status == ValidationStatus.valid;
  bool get isValidating => status == ValidationStatus.validating;
  bool get hasError => status == ValidationStatus.invalid;
}

class ValidationController extends ChangeNotifier {
  ValidationController({
    this.validator,
    this.debounceDuration = Duration.zero,
  });

  final FutureOr<String?> Function(String value)? validator;
  final Duration debounceDuration;

  Timer? _debounce;
  int _validationId = 0;

  ValidationState _state = const ValidationState.idle();
  ValidationState get state => _state;

  void _setState(ValidationState state) {
    _state = state;
    notifyListeners();
  }

  void validate(String value) {
    _debounce?.cancel();

    if (validator == null) {
      _setState(const ValidationState.valid());
      return;
    }

    _setState(const ValidationState.validating());
    _debounce = Timer(debounceDuration, () async {
      final int currentId = ++_validationId;

      final FutureOr<String?> result = validator!(value);

      if (result is String?) {
        // sync result
        _setState(result == null ? const ValidationState.valid() : ValidationState.invalid(result));
        return;
      }

      // async result
      final String? asyncResult = await result;

      if (currentId != _validationId) return;
      _setState(asyncResult == null ? const ValidationState.valid() : ValidationState.invalid(asyncResult));
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
