import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/profile.dart';
import '../../data/repositories/profile_repository.dart';

final profileProvider =
    FutureProvider<Profile?>((ref) async {
  final repo = ProfileRepository();
  return repo.getCurrentProfile();
});

