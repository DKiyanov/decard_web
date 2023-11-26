import 'app_state.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:routemaster/routemaster.dart';

class PageScaffold extends StatefulWidget {
  final String title;
  final Widget body;
  final String? searchQuery;

  const PageScaffold({
    Key? key,
    required this.title,
    required this.body,
    this.searchQuery,
  }) : super(key: key);

  @override
  State<PageScaffold> createState() => _PageScaffoldState();
}

class _PageScaffoldState extends State<PageScaffold> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _updateSearchQuery();
  }

  @override
  void didUpdateWidget(covariant PageScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateSearchQuery();
  }

  void _updateSearchQuery() {
    if (widget.searchQuery != null) {
      _searchController.text = widget.searchQuery!;
    }
  }

  void _search() {
    Routemaster.of(context).push(
      '/search',
      queryParameters: {'query': _searchController.text},
    );
  }

  @override
  Widget build(BuildContext context) {
    final routemaster = Routemaster.of(context);
    final canGoBack = routemaster.history.canGoBack;
    final canGoForward = routemaster.history.canGoForward;

    return LayoutBuilder(builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 600;

      return Scaffold(
        drawer: isMobile
            ? Drawer(
                child: Container(
                  color: const Color(0xFF232f3e),
                  child: ListView(
                    children: _buildNavBarChildren(inDrawer: true),
                  ),
                ),
              )
            : null,
        appBar: PreferredSize(
          preferredSize: const Size(double.infinity, 70),
          child: isMobile
              ? AppBar(
                  automaticallyImplyLeading: isMobile,
                  title: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Image.asset(
                      'assets/logo.png',
                      width: 200,
                    ),
                  ),
                )
              : AppBar(
                  automaticallyImplyLeading: isMobile,
                  title: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      children: [
                        SizedBox(
                          height: 200,
                          child: Image.asset(
                            'assets/logo.png',
                            width: 200,
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(widget.title),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
        body: Column(
          children: [
            Container(
              color: const Color(0xFF232f3e),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 20),
                  SizedBox(
                    width: 40,
                    child: InkWell(
                      onTap:
                          canGoBack ? () => routemaster.history.back() : null,
                      child: Icon(
                        Icons.arrow_back_ios,
                        color: canGoBack
                            ? Colors.white
                            : Colors.white.withAlpha(30),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: canGoForward
                        ? () => routemaster.history.forward()
                        : null,
                    child: SizedBox(
                      width: 40,
                      child: Icon(
                        Icons.arrow_forward_ios,
                        color: canGoForward
                            ? Colors.white
                            : Colors.white.withAlpha(30),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Container(
                            width: 300,
                            padding: const EdgeInsets.all(16),
                            child: CupertinoTextField(
                              controller: _searchController,
                              onSubmitted: (_) => _search(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: _search,
                          child: const Text('Search'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  if (appState.serverConnect.isLoggedIn)
                    Text(
                      'Hello, ${appState.serverConnect.user!.username}!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  else
                    InkWell(
                      onTap: () {
                        Routemaster.of(context).push(
                          '/login',
                          queryParameters: {
                            'redirectTo': RouteData.of(context).fullPath,
                          },
                        );
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Log in',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 20),
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  if (!isMobile)
                    Container(
                      width: 200,
                      color: const Color(0xFF232f3e),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: _buildNavBarChildren(inDrawer: false),
                      ),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (ModalRoute.of(context)?.canPop == true)
                          const CupertinoNavigationBarBackButton(),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: widget.body,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  List<Widget> _buildNavBarChildren({required bool inDrawer}) {
    return [
      NavigationLink(
        title: 'Fiction',
        path: '/category/fiction',
        inDrawer: inDrawer,
      ),
      NavigationLink(
        title: 'Non-fiction',
        path: '/category/nonfiction',
        inDrawer: inDrawer,
      ),
      NavigationLink(
        title: 'Audiobooks',
        path: '/audiobooks',
        inDrawer: inDrawer,
      ),
      NavigationLink(
        title: 'View pack list',
        path: '/view_pack_list',
        inDrawer: inDrawer,
      ),
      if (appState.serverConnect.isLoggedIn) ...[
        NavigationLink(
          title: 'Upload new file',
          path: '/upload_file',
          inDrawer: inDrawer,
        ),

      ],
    ];
  }
}

class NavigationLink extends StatelessWidget {
  final String title;
  final String path;
  final bool inDrawer;

  const NavigationLink({
    Key? key,
    required this.title,
    required this.path,
    required this.inDrawer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentPath = RouteData.of(context).fullPath;
    final isCurrent = currentPath.startsWith(path);

    return Container(
      color: isCurrent ? const Color(0xff068597) : Colors.transparent,
      child: InkWell(
        onTap: () {
          if (inDrawer) {
            Navigator.pop(context);
          }

          Routemaster.of(context).push(path);
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            title,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
