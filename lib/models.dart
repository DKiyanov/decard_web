class Book {
  final String id;
  final String title;
  final String description;
  final DateTime releaseDate;
  final List<BookCategory> categories;
  final bool isStaffPick;

  Book({
    required this.id,
    required this.title,
    required this.description,
    required this.releaseDate,
    required this.categories,
    required this.isStaffPick,
  });
}

enum BookCategory {
  fiction,
  nonFiction,
}

extension BookCategoryExtension on BookCategory {
  String get displayName {
    switch (this) {
      case BookCategory.fiction:
        return 'Fiction';
      case BookCategory.nonFiction:
        return 'Non-fiction';
    }
  }

  String get queryParam {
    switch (this) {
      case BookCategory.fiction:
        return 'fiction';
      case BookCategory.nonFiction:
        return 'nonfiction';
    }
  }
}

class BooksDatabase {
  final Iterable<Book> books = List.unmodifiable([
    Book(
      id: '1',
      title: 'Hummingbirds for Dummies',
      description: "Find out all about Hummingbirds, and how awesome they are.",
      releaseDate: DateTime(1985, 3, 23),
      categories: [BookCategory.nonFiction],
      isStaffPick: true,
    ),
    Book(
      id: '2',
      title: "Of Hummingbirds And Men",
      description: "blah blah blha",
      releaseDate: DateTime(1923, 1, 1),
      categories: [BookCategory.fiction],
      isStaffPick: false,
    ),
    Book(
      id: '3',
      title: "Gone With The Hummingbirds",
      description:
          "Set in the American South, this book tells the story of Dash O'Bird, the strong-willed daughter...",
      releaseDate: DateTime(1936, 6, 30),
      categories: [BookCategory.fiction],
      isStaffPick: false,
    ),
    Book(
      id: '4',
      title: "Harry Potter and the Chamber of Hummingbirds",
      description: "Wizard and Hummingbirds! What more could you want?",
      releaseDate: DateTime(1998, 7, 2),
      categories: [BookCategory.fiction],
      isStaffPick: true,
    ),
  ]);
}
