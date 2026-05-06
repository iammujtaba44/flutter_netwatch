import 'package:flutter/widgets.dart';

class NWNavigatorObserver extends NavigatorObserver {
  Route<dynamic>? _currentRoute;

  Route<dynamic>? get currentRoute => _currentRoute;

  String? get currentRouteName => _currentRoute?.settings.name;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _currentRoute = route;
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _currentRoute = previousRoute;
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _currentRoute = newRoute;
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    if (_currentRoute == route) {
      _currentRoute = previousRoute;
    }
  }
}
