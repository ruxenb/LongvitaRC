sealed class ViewState<T> {
  const ViewState();
}

class ViewStateIdle<T> extends ViewState<T> {
  const ViewStateIdle();
}

class ViewStateLoading<T> extends ViewState<T> {
  final String? message;
  const ViewStateLoading([this.message]);
}

class ViewStateSuccess<T> extends ViewState<T> {
  final T data;
  const ViewStateSuccess(this.data);
}

class ViewStateEmpty<T> extends ViewState<T> {
  final String message;
  const ViewStateEmpty({this.message = 'Chưa có dữ liệu'});
}

class ViewStateError<T> extends ViewState<T> {
  final String message;
  final Object? error;
  const ViewStateError(this.message, [this.error]);
}
