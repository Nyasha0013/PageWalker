import 'package:flutter_riverpod/flutter_riverpod.dart';

final likedReviewsProvider =
    StateProvider<Set<String>>((ref) => <String>{});

