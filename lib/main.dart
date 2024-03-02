import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:decard_web/app_state.dart';
import 'package:decard_web/home_page.dart';
import 'package:decard_web/pack_view.dart';
import 'package:decard_web/page_not_found.dart';
import 'package:decard_web/regulator_editor/regulator_cardset_page.dart';
import 'package:decard_web/regulator_editor/regulator_param_page.dart';
import 'package:decard_web/showcase_out.dart';

import 'package:flutter/material.dart';
import 'package:routemaster/routemaster.dart';
import 'package:url_strategy/url_strategy.dart';
import 'child_results_report.dart';
import 'child_statistics.dart';
import 'pack_editor/pack_editor.dart';
import 'login_page.dart';
import 'package:simple_events/simple_events.dart' as event;

// for access to http sources was configured:
// android\app\src\main\res\xml\network_security_config.xml
// it for debug only needs

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setPathUrlStrategy();
  await appState.initialization();
  runApp(const DecardWebApp());
}

RouteMap _buildRouteMapOut(BuildContext context) {
  return RouteMap(
    onUnknownRoute: (path) {
      return const NoAnimationPage(
        child: PageNotFound(),
      );
    },

    routes: {
      '/': (route) {
        return const NoAnimationPage(child: ShowcaseOut());
      },

      '/pack/:id': (route) => NoAnimationPage(child: PackView(
        packId: int.parse(route.pathParameters['id']!)
      )),

      '/login': (route) => NoAnimationPage(
        child: LoginPage(
          redirectTo: route.queryParameters['redirectTo'],
        ),
      ),

    },
  );
}

RouteMap _buildRouteMapIn(BuildContext context) {
  return RouteMap(
    onUnknownRoute: (path) {
      return const NoAnimationPage(
        child: PageNotFound(),
      );
    },

    routes: {
      '/': (route) {
         if (appState.serverConnect.isLoggedIn) {
          return TabPage(
            child: const HomePage(),
            paths: const [HomePage.tabShowcase, HomePage.tabChildren, HomePage.tabPossessions, HomePage.tabMenu],
            pageBuilder: (child) => NoAnimationPage(child: child),
          );
        }

        return const NoAnimationPage(child: ShowcaseOut() );
      },

      '/${HomePage.tabShowcase}': (route) {
        return const NoAnimationPage(
          child: HomePageTabView(tabKey : HomePage.tabShowcase),
        );
      },

      '/${HomePage.tabChildren}': (route) {
        return const NoAnimationPage(
          child: HomePageTabView(tabKey : HomePage.tabChildren),
        );
      },

      '/${HomePage.tabPossessions}': (route) {
        return const NoAnimationPage(
          child: HomePageTabView(tabKey : HomePage.tabPossessions),
        );
      },

      '/${HomePage.tabMenu}': (route) {
        return const NoAnimationPage(
          child: HomePageTabView(tabKey : HomePage.tabMenu),
        );
      },

      '/pack_editor/:id': (route) => NoAnimationPage(child: PackEditor(
          packId: int.parse(route.pathParameters['id']!)
      )),

      '/pack/:id': (route) => NoAnimationPage(child: PackView(
        packId: int.parse(route.pathParameters['id']!),
        cardKey: route.queryParameters['cardKey'],
      )),

      '/child_tune': (route) => NoAnimationPage(child: RegulatorParamsPage(
        childID : route.queryParameters['id']!,
      )),

      '/child_pack_tune': (route) => NoAnimationPage(child: RegulatorCardSetPage(
          childID : route.queryParameters['id']!,
          packId  : route.queryParameters['packId']!,
      )),

      '/child_stat': (route) => NoAnimationPage(child: ChildStatistics(
        childID : route.queryParameters['id']!,
      )),

      '/child_results': (route) => NoAnimationPage(child: ChildResultsReport(
        childID    : route.queryParameters['id']!,
        reportMode : ChildResultsReportMode.values.firstWhereOrNull((element) => element.name == route.queryParameters['mode'])??ChildResultsReportMode.allResults,
      )),
    },
  );
}

RouteMap _buildRouteMap(BuildContext context) {
  if (appState.serverConnect.isLoggedIn) {
    return _buildRouteMapIn(context);
  }
  return _buildRouteMapOut(context);
}

class NoAnimationPage<T> extends TransitionPage<T> {
  const NoAnimationPage({required Widget child})
      : super(
          child: child,
          pushTransition: PageTransition.none,
          popTransition: PageTransition.none,
        );
}

class DecardWebApp extends StatefulWidget {
  final RouteInformationProvider? routeInformationProvider;

  const DecardWebApp({
    Key? key,
    this.routeInformationProvider,
  }) : super(key: key);

  @override
  State<DecardWebApp> createState() => _DecardWebAppState();
}

class _DecardWebAppState extends State<DecardWebApp> {
  event.Listener? onLoggedInChangeListener;

  @override
  void initState() {
    super.initState();
    onLoggedInChangeListener = appState.serverConnect.onLoggedInChange.subscribe((listener, data) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    onLoggedInChangeListener?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(

      title: 'DecardWebApp',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        platform: TargetPlatform.android,
      ),
      routeInformationParser: const RoutemasterParser(),
      routeInformationProvider: widget.routeInformationProvider,
      routerDelegate: RoutemasterDelegate(
        routesBuilder: (context) {
           return _buildRouteMap(context);
        },
      ),
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {PointerDeviceKind.mouse, PointerDeviceKind.touch, PointerDeviceKind.stylus, PointerDeviceKind.unknown},
      ),
    );
  }
}
