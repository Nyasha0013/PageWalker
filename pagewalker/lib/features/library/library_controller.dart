import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/user_book.dart';

final currentTabProvider =
    StateProvider<BookStatus>((ref) => BookStatus.tbr);

