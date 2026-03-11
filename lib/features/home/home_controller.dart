import 'package:flutter_riverpod/flutter_riverpod.dart';

final greetingNameProvider =
    StateProvider<String>((ref) => 'Reader');

