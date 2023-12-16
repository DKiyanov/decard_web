import 'package:decard_web/app_state.dart';
import 'package:decard_web/home_page.dart';
import 'package:decard_web/pack_view.dart';
import 'package:decard_web/page_not_found.dart';
import 'package:decard_web/showcase_out.dart';
import 'package:decard_web/upload_file.dart';
import 'package:flutter/material.dart';
import 'package:routemaster/routemaster.dart';
import 'package:url_strategy/url_strategy.dart';
import 'pack_editor/pack_editor.dart';
import 'login_email.dart';
import 'login_page.dart';
import 'pack_list.dart';
import 'package:simple_events/simple_events.dart' as event;

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
          cardController: appState.cardController,
          packId: int.parse(route.pathParameters['id']!)
      )),

      '/login': (route) => NoAnimationPage(
            child: LoginPage(
              redirectTo: route.queryParameters['redirectTo'],
            ),
          ),

      '/login/login_email': (route) => NoAnimationPage(
        child: LoginEmail(
          connect: appState.serverConnect,
          onLoginOk: (context){
            Routemaster.of(context).push(route.queryParameters['redirectTo']??'/');
          },
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
            paths: const [HomePage.tabShowcase, HomePage.tabChildren, HomePage.tabPossessions],
            pageBuilder: (child) => NoAnimationPage(child: child),
          );
        }

        return NoAnimationPage(child: WebPackList(packInfoManager: appState.packInfoManager));
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

      '/pack_editor': (route) {
        return TabPage(
          child: const PackEditor(),
          paths: const [PackEditor.tabHead, PackEditor.tabStyles, PackEditor.tabCards, PackEditor.tabSources],
          pageBuilder: (child) => NoAnimationPage(child: child),
        );
      },

      '/pack_editor/${PackEditor.tabHead}': (route) {
        return const NoAnimationPage(
          child: PackEditorTabView(tabKey : PackEditor.tabHead),
        );
      },

      '/pack_editor/${PackEditor.tabStyles}': (route) {
        return const NoAnimationPage(
          child: PackEditorTabView(tabKey : PackEditor.tabStyles),
        );
      },

      '/pack_editor/${PackEditor.tabCards}': (route) {
        return const NoAnimationPage(
          child: PackEditorTabView(tabKey : PackEditor.tabCards),
        );
      },

      '/pack_editor/${PackEditor.tabSources}': (route) {
        return const NoAnimationPage(
          child: PackEditorTabView(tabKey : PackEditor.tabSources),
        );
      },

      '/pack/:id': (route) => NoAnimationPage(child: PackView(
          cardController: appState.cardController,
          packId: int.parse(route.pathParameters['id']!)
      )),

      '/upload_file': (route) => const NoAnimationPage(
        child: UploadFile(),
      ),
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
    );
  }
}
