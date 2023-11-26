import 'package:decard_web/app_state.dart';
import 'package:decard_web/pack_view.dart';
import 'package:decard_web/upload_file.dart';
import 'package:flutter/material.dart';
import 'package:routemaster/routemaster.dart';
import 'package:url_strategy/url_strategy.dart';
import 'audiobooks_page.dart';
import 'book_card.dart';
import 'book_page.dart';
import 'category_page.dart';
import 'login_email.dart';
import 'login_page.dart';
import 'models.dart';
import 'pack_list.dart';
import 'page_scaffold.dart';
import 'search_page.dart';

final booksDatabase = BooksDatabase();

void main() async {
  setPathUrlStrategy();
  await appState.initialization();
  runApp(const BookStoreApp());
}

bool _isValidCategory(String? category) {
  return BookCategory.values.any(
    (e) => e.queryParam == category,
  );
}

bool _isValidBookId(String? id) {
  return booksDatabase.books.any((book) => book.id == id);
}

RouteMap _buildRouteMap(BuildContext context) {
  return RouteMap(
    onUnknownRoute: (path) {
      return NoAnimationPage(
        child: PageScaffold(
          title: 'Page not found',
          body: Center(
            child: Text(
              "Couldn't find page '$path'",
              style: Theme.of(context).textTheme.displaySmall,
            ),
          ),
        ),
      );
    },
    routes: {
      //'/': (route) => const NoAnimationPage(child: ShopHome()),
      '/': (route) => NoAnimationPage(child: PackList(packInfoManager: appState.packInfoManager)),
      '/pack/:id': (route) => NoAnimationPage(child: PackView(
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

      '/book/:id': (route) => _isValidBookId(route.pathParameters['id'])
          ? NoAnimationPage(child: BookPage(id: route.pathParameters['id']!))
          : const NotFound(),
      '/category/:category': (route) =>
          _isValidCategory(route.pathParameters['category'])
              ? NoAnimationPage(
                  child: CategoryPage(
                    category: BookCategory.values.firstWhere(
                      (e) => e.queryParam == route.pathParameters['category'],
                    ),
                  ),
                )
              : const NotFound(),
      '/category/:category/book/:id': (route) => _isValidCategory(
                  route.pathParameters['category']) &&
              _isValidBookId(route.pathParameters['id'])
          ? NoAnimationPage(child: BookPage(id: route.pathParameters['id']!))
          : const NotFound(),
      '/audiobooks': (route) => TabPage(
            child: const AudiobookPage(),
            paths: const ['all', 'picks'],
            pageBuilder: (child) => NoAnimationPage(child: child),
          ),
      '/audiobooks/all': (route) => const NoAnimationPage(
            child: AudiobookListPage(mode: 'all'),
          ),
      '/audiobooks/picks': (route) => const NoAnimationPage(
            child: AudiobookListPage(mode: 'picks'),
          ),
      '/audiobooks/book/:id': (route) =>
          _isValidBookId(route.pathParameters['id'])
              ? NoAnimationPage(
                  child: BookPage(id: route.pathParameters['id']!),
                )
              : const NotFound(),
      '/search': (route) => NoAnimationPage(
              child: SearchPage(
            query: route.queryParameters['query'] ?? '',
            sortOrder: SortOrder.values.firstWhere(
              (e) => e.queryParam == route.queryParameters['sort'],
              orElse: () => SortOrder.name,
            ),
          )),
      '/view_pack_list': (route) => NoAnimationPage(
        child: PackList(packInfoManager: appState.packInfoManager),
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

class BookStoreApp extends StatelessWidget {
  final RouteInformationProvider? routeInformationProvider;

  const BookStoreApp({
    Key? key,
    this.routeInformationProvider,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Dashazon',
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

class ShopHome extends StatelessWidget {
  const ShopHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: "Dash's book shop",
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "All of Dash's lovely books...",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Wrap(
            children: [
              for (final book in booksDatabase.books) BookCard(book: book),
            ],
          ),
        ],
      ),
    );
  }
}
