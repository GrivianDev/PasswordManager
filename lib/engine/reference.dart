/// Small generic container class that is useful for updating values across multiple objects that don't know
/// each other. Example use case is reassigning File objects.
class Reference<T> {
  T _t;

  Reference({required T value}) : _t = value;

  set assign(T value) => _t = value;
  T get value => _t;
}