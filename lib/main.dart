import 'package:decard_web/app_state.dart';
import 'package:decard_web/pack_view.dart';
import 'package:decard_web/page_not_found.dart';
import 'package:decard_web/upload_file.dart';
import 'package:flutter/material.dart';
import 'package:routemaster/routemaster.dart';
import 'package:url_strategy/url_strategy.dart';
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
      '/': (route) => NoAnimationPage(child: WebPackList(packInfoManager: appState.packInfoManager)),
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
