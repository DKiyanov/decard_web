import 'package:decard_web/app_state.dart';
import 'package:decard_web/home_page.dart';
import 'package:decard_web/own_pack_list.dart';
import 'package:decard_web/pack_view.dart';
import 'package:decard_web/page_not_found.dart';
import 'package:decard_web/upload_file.dart';
import 'package:flutter/material.dart';
import 'package:routemaster/routemaster.dart';
import 'package:url_strategy/url_strategy.dart';
import 'child_list.dart';
import 'pack_editor.dart';
import 'login_email.dart';
import 'login_page.dart';
import 'pack_list.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setPathUrlStrategy();
  await appState.initialization();
  runApp(const DecardWebApp());
}

RouteMap _buildRouteMap(BuildContext context) {
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

      '/view_pack_list': (route) => NoAnimationPage(
        child: WebPackList(packInfoManager: appState.packInfoManager),
      ),

      '/child_list': (route) => const NoAnimationPage(
        child: ChildList(),
      ),

      '/own_pack_list': (route) => const NoAnimationPage(
        child: OwnPackList(),
      ),

      '/upload_file': (route) => const NoAnimationPage(
        child: UploadFile(),
      ),
    },
  );
}

class NoAnimationPage<T> extends TransitionPage<T> {
  const NoAnimationPage({required Widget child})
      : super(
          child: child,
          pushTransition: PageTransition.none,
          popTransition: PageTransition.none,
        );
}

class DecardWebApp extends StatelessWidget {
  final RouteInformationProvider? routeInformationProvider;

  const DecardWebApp({
    Key? key,
    this.routeInformationProvider,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'DecardWebApp',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        platform: TargetPlatform.android,
      ),
      routeInformationParser: const RoutemasterParser(),
      routeInformationProvider: routeInformationProvider,
      routerDelegate: RoutemasterDelegate(
        routesBuilder: (context) {
           return _buildRouteMap(context);
        },
      ),
    );
  }
}
