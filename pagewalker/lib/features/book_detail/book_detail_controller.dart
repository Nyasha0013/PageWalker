import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/user_book.dart';

class BookDetailState {
  final BookStatus status;
  final double rating;

  const BookDetailState({
    required this.status,
    required this.rating,
  });

  BookDetailState copyWith({
    BookStatus? status,
    double? rating,
  }) =>
      BookDetailState(
        status: status ?? this.status,
        rating: rating ?? this.rating,
      );
}

class BookDetailController
    extends StateNotifier<BookDetailState> {
  BookDetailController()
      : super(
          const BookDetailState(
            status: BookStatus.tbr,
            rating: 0,
          ),
        );

  void setStatus(BookStatus status) {
    state = state.copyWith(status: status);
  }

  void setRating(double rating) {
    state = state.copyWith(rating: rating);
  }
}

final bookDetailProvider = StateNotifierProvider.family<
    BookDetailController,
    BookDetailState,
    String>((ref, bookId) {
  return BookDetailController();
});

