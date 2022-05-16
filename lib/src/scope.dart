import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flow_builder/flow_builder.dart';

import 'route.dart';
import 'settings.dart';

/// The scope of a wizard page.
///
/// Each page is enclosed by a `WizardScope` widget.
class WizardScope extends StatefulWidget {
  const WizardScope({
    Key? key,
    required int index,
    required WizardRoute route,
    required List<String> routes,
  })  : _index = index,
        _route = route,
        _routes = routes,
        super(key: key);

  final int _index;
  final WizardRoute _route;
  final List<String> _routes;

  @override
  State<WizardScope> createState() => WizardScopeState();
}

/// The state of a `WizardScope`, accessed via `Wizard.of(context)`.
class WizardScopeState extends State<WizardScope> {
  /// Arguments passed from the previous page.
  ///
  /// ```dart
  /// final something = Wizard.of(context).arguments as Something;
  /// ```
  Object? get arguments => ModalRoute.of(context)?.settings.arguments;

  /// Requests the wizard to show the first page.
  ///
  /// ```dart
  /// onPressed: Wizard.of(context).home
  /// ```
  void home() {
    final routes = _getRoutes();
    assert(routes.length > 1,
        '`Wizard.home()` called from the first route ${routes.last.name}');

    _updateRoutes((state) {
      final copy = List<WizardRouteSettings>.of(state);
      return copy..replaceRange(1, routes.length, []);
    });
  }

  /// Requests the wizard to show the previous page. Optionally, `result` can be
  /// returned to the previous page.
  ///
  /// ```dart
  /// onPressed: Wizard.of(context).back
  /// ```
  void back<T extends Object?>([T? result]) {
    final routes = _getRoutes();
    assert(routes.length > 1,
        '`Wizard.back()` called from the first route ${routes.last.name}');

    // go back to a specific route, or pick the previous route on the list
    final previous = widget._route.onBack?.call(routes.last);
    if (previous != null) {
      assert(widget._routes.contains(previous),
          '`Wizard.routes` is missing route \'$previous\'.');
    }

    final start = previous != null
        ? routes.lastIndexWhere((settings) => settings.name == previous) + 1
        : routes.length - 1;

    _updateRoutes((state) {
      final copy = List<WizardRouteSettings>.of(state);
      copy[start].result.complete(result);
      return copy..replaceRange(start, routes.length, []);
    });
  }

  /// Requests the wizard to show the next page. Optionally, `arguments` can be
  /// passed to the next page.
  ///
  /// ```dart
  /// onPressed: Wizard.of(context).next
  /// ```
  Future<T?> next<T extends Object?>({Object? arguments}) {
    final routes = _getRoutes();
    assert(routes.isNotEmpty, routes.length.toString());

    final previous = routes.last.copyWith(arguments: arguments);

    // advance to a specific route
    String? onNext() => widget._route.onNext?.call(previous);

    // pick the next route on the list
    String nextRoute() {
      final index = widget._routes.indexOf(previous.name!);
      assert(index < widget._routes.length - 1,
          '`Wizard.next()` called from the last route ${previous.name}.');
      return widget._routes[index + 1];
    }

    final next = WizardRouteSettings<T?>(
      name: onNext() ?? nextRoute(),
      arguments: arguments,
    );

    assert(widget._routes.contains(next.name),
        '`Wizard.routes` is missing route \'${next.name}\'.');

    _updateRoutes((state) {
      final copy = List<WizardRouteSettings>.of(state);
      return copy..add(next);
    });

    return next.result.future;
  }

  List<WizardRouteSettings> _getRoutes() =>
      context.flow<List<WizardRouteSettings>>().state;

  void _updateRoutes(
    List<WizardRouteSettings> Function(List<WizardRouteSettings>) callback,
  ) {
    context.flow<List<WizardRouteSettings>>().update(callback);
  }

  /// Returns `false` if the wizard page is the first page.
  bool get hasPrevious => widget._index > 0;

  /// Returns `false` if the wizard page is the last page.
  bool get hasNext => widget._index < widget._routes.length - 1;

  @override
  Widget build(BuildContext context) => Builder(builder: widget._route.builder);
}