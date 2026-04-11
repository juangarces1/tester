import 'package:flutter/material.dart';

enum ViewState { loading, content, error, empty }

mixin ViewStateMixin on ChangeNotifier {
  ViewState _viewState = ViewState.loading;
  String? _errorMessage;

  ViewState get viewState => _viewState;
  String? get errorMessage => _errorMessage;

  void setLoading() {
    _viewState = ViewState.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void setContent() {
    _viewState = ViewState.content;
    _errorMessage = null;
    notifyListeners();
  }

  void setError(String message) {
    _viewState = ViewState.error;
    _errorMessage = message;
    notifyListeners();
  }

  void setEmpty() {
    _viewState = ViewState.empty;
    _errorMessage = null;
    notifyListeners();
  }
}
