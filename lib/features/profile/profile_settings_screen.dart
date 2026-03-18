import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/supabase_config.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/dynamic_sky_background.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../data/models/profile.dart';
import '../../data/repositories/profile_repository.dart';
import 'profile_controller.dart';

class ProfileSettingsScreen extends ConsumerStatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  ConsumerState<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends ConsumerState<ProfileSettingsScreen> {
  final _repo = ProfileRepository();

  final _displayNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _ageController = TextEditingController();
  final _locationController = TextEditingController();
  final _favouriteGenreController = TextEditingController();
  final _readingGoalController = TextEditingController();
  final _instagramController = TextEditingController();
  final _facebookController = TextEditingController();

  bool _isPublic = true;
  bool _saving = false;
  bool _seeded = false;

  bool _notificationsEnabled = false;
  bool _streakWarnings = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadNotificationPrefs();
  }

  Future<void> _loadNotificationPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
      _streakWarnings = prefs.getBool('streak_warnings') ?? true;
      final hour = prefs.getInt('notifications_hour') ?? 20;
      final minute = prefs.getInt('notifications_minute') ?? 0;
      _reminderTime = TimeOfDay(hour: hour, minute: minute);
    });
  }

  Future<void> _saveNotificationPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
    await prefs.setBool('streak_warnings', _streakWarnings);
    await prefs.setInt('notifications_hour', _reminderTime.hour);
    await prefs.setInt('notifications_minute', _reminderTime.minute);
  }

  String _getReminderMessage() {
    return "Pick up your book for a few minutes — future you will thank you.";
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _ageController.dispose();
    _locationController.dispose();
    _favouriteGenreController.dispose();
    _readingGoalController.dispose();
    _instagramController.dispose();
    _facebookController.dispose();
    super.dispose();
  }

  void _seedFromProfile(Profile profile) {
    if (_seeded) return;
    _seeded = true;
    _displayNameController.text = profile.displayName;
    _usernameController.text = profile.username;
    _bioController.text = profile.bio ?? '';
    _ageController.text = profile.age?.toString() ?? '';
    _locationController.text = profile.location ?? '';
    _favouriteGenreController.text = profile.favouriteGenre ?? '';
    _readingGoalController.text = (profile.readingGoal).toString();
    _instagramController.text = profile.instagramHandle ?? '';
    _facebookController.text = profile.facebookName ?? '';
    _isPublic = profile.isPublic;
  }

  Future<void> _saveChanges(Profile? existing) async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return;

    final username = _usernameController.text.trim().toLowerCase().replaceAll(' ', '');
    final readingGoal = int.tryParse(_readingGoalController.text.trim()) ?? 12;
    final age = int.tryParse(_ageController.text.trim());

    setState(() => _saving = true);
    try {
      final updated = Profile(
        id: existing?.id ?? user.id,
        username: username,
        displayName: _displayNameController.text.trim(),
        avatarUrl: existing?.avatarUrl,
        bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
        age: age,
        location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        instagramHandle: _instagramController.text.trim().isEmpty ? null : _instagramController.text.trim(),
        facebookName: _facebookController.text.trim().isEmpty ? null : _facebookController.text.trim(),
        favouriteGenre: _favouriteGenreController.text.trim().isEmpty ? null : _favouriteGenreController.text.trim(),
        readingGoal: readingGoal,
        isPublic: _isPublic,
        createdAt: existing?.createdAt ?? DateTime.now(),
      );

      await _repo.updateProfile(updated);
      ref.invalidate(profileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      body: DynamicSkyBackground(
        child: SafeArea(
          child: profileAsync.when(
            data: (profile) {
              if (profile != null) _seedFromProfile(profile);
              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    leading: IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: AppColors.orangePrimary,
                    ),
                    title: Text(
                      'Settings',
                      style: AppText.display(22, context: context),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        // SECTION 1 — APPEARANCE
                        GlassCard(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Appearance',
                                style: AppText.bodySemiBold(
                                  15,
                                  color: AppColors.orangePrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => ref.read(themeProvider.notifier).setDark(),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        decoration: BoxDecoration(
                                          color: ref.watch(themeProvider) == ThemeMode.dark
                                              ? AppColors.orangePrimary
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(
                                            color: AppColors.orangePrimary.withOpacity(0.5),
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            const Text('🌙', style: TextStyle(fontSize: 24)),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Dark',
                                              style: AppText.bodySemiBold(
                                                13,
                                                color: ref.watch(themeProvider) == ThemeMode.dark
                                                    ? Colors.white
                                                    : (isDark
                                                        ? AppColors.darkTextSecondary
                                                        : AppColors.lightTextSecondary),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => ref.read(themeProvider.notifier).setLight(),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        decoration: BoxDecoration(
                                          color: ref.watch(themeProvider) == ThemeMode.light
                                              ? AppColors.orangePrimary
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(
                                            color: AppColors.orangePrimary.withOpacity(0.5),
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            const Text('☀️', style: TextStyle(fontSize: 24)),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Light',
                                              style: AppText.bodySemiBold(
                                                13,
                                                color: ref.watch(themeProvider) == ThemeMode.light
                                                    ? Colors.white
                                                    : (isDark
                                                        ? AppColors.darkTextSecondary
                                                        : AppColors.lightTextSecondary),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // SECTION 2 — PERSONAL INFO
                        GlassCard(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Personal Info',
                                style: AppText.bodySemiBold(15, color: AppColors.orangePrimary),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _displayNameController,
                                decoration: const InputDecoration(labelText: 'Display Name'),
                                style: AppText.body(14, context: context),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _usernameController,
                                decoration: const InputDecoration(labelText: 'Username'),
                                style: AppText.body(14, context: context),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _bioController,
                                maxLines: 3,
                                maxLength: 150,
                                decoration: const InputDecoration(labelText: 'Bio'),
                                style: AppText.body(14, context: context),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _ageController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Age (optional)'),
                                style: AppText.body(14, context: context),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _locationController,
                                decoration: const InputDecoration(labelText: 'Location (optional)'),
                                style: AppText.body(14, context: context),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _favouriteGenreController,
                                decoration: const InputDecoration(labelText: 'Favourite Genre (optional)'),
                                style: AppText.body(14, context: context),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _readingGoalController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Reading Goal (books/year)'),
                                style: AppText.body(14, context: context),
                              ),
                            ],
                          ),
                        ),

                        // SECTION 3 — SOCIAL LINKS
                        GlassCard(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Social Links',
                                style: AppText.bodySemiBold(15, color: AppColors.orangePrimary),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _instagramController,
                                decoration: const InputDecoration(
                                  labelText: 'Instagram Handle',
                                  prefixIcon: Icon(Icons.camera_alt_rounded, size: 18),
                                ),
                                style: AppText.body(14, context: context),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _facebookController,
                                decoration: const InputDecoration(
                                  labelText: 'Facebook Name',
                                  prefixIcon: Icon(Icons.facebook_rounded, size: 18),
                                ),
                                style: AppText.body(14, context: context),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Add your socials so other Pagewalker readers can connect with you!',
                                style: AppText.body(
                                  12,
                                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // SECTION 4 — NOTIFICATIONS
                        GlassCard(
                          padding: const EdgeInsets.all(16),
                          margin:
                              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Notifications',
                                style: AppText.bodySemiBold(
                                  15,
                                  color: AppColors.orangePrimary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Daily Reading Reminder',
                                        style: AppText.bodySemiBold(14, context: context),
                                      ),
                                      Text(
                                        'Get nudged to read every day',
                                        style: AppText.body(
                                          12,
                                          color: AppColors.darkTextSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Switch(
                                    value: _notificationsEnabled,
                                    onChanged: (val) async {
                                      setState(() => _notificationsEnabled = val);
                                      await _saveNotificationPrefs();
                                      if (val) {
                                        await NotificationService().requestPermission();
                                        await NotificationService().scheduleDailyReminder(
                                          time: _reminderTime,
                                          message: _getReminderMessage(),
                                        );
                                      } else {
                                        await NotificationService().cancelAll();
                                      }
                                    },
                                    activeColor: AppColors.orangePrimary,
                                  ),
                                ],
                              ),
                              if (_notificationsEnabled) ...[
                                const SizedBox(height: 12),
                                GestureDetector(
                                  onTap: () async {
                                    final picked = await showTimePicker(
                                      context: context,
                                      initialTime: _reminderTime,
                                      builder: (context, child) => Theme(
                                        data: Theme.of(context).copyWith(
                                          colorScheme: const ColorScheme.dark(
                                            primary: AppColors.orangePrimary,
                                          ),
                                        ),
                                        child: child!,
                                      ),
                                    );
                                    if (picked != null) {
                                      setState(() => _reminderTime = picked);
                                      await _saveNotificationPrefs();
                                      await NotificationService().scheduleDailyReminder(
                                        time: picked,
                                        message: _getReminderMessage(),
                                      );
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.darkCard,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.orangePrimary.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Reminder time',
                                          style: AppText.body(14, context: context),
                                        ),
                                        Text(
                                          _formatTime(_reminderTime),
                                          style: AppText.bodySemiBold(
                                            14,
                                            color: AppColors.orangePrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Streak Warnings',
                                        style: AppText.bodySemiBold(14, context: context),
                                      ),
                                      Text(
                                        'Alert when streak is at risk',
                                        style: AppText.body(
                                          12,
                                          color: AppColors.darkTextSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Switch(
                                    value: _streakWarnings,
                                    onChanged: (val) async {
                                      setState(() => _streakWarnings = val);
                                      await _saveNotificationPrefs();
                                    },
                                    activeColor: AppColors.orangePrimary,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // SECTION 5 — PRIVACY
                        GlassCard(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Public Profile',
                                      style: AppText.bodySemiBold(14, context: context),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Allow other readers to find and follow you',
                                      style: AppText.body(
                                        12,
                                        color: isDark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.lightTextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _isPublic,
                                onChanged: (v) => setState(() => _isPublic = v),
                                activeColor: AppColors.orangePrimary,
                              ),
                            ],
                          ),
                        ),

                        // SECTION 6 — ACCOUNT
                        GlassCard(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Account',
                                style: AppText.bodySemiBold(15, color: AppColors.orangePrimary),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton(
                                onPressed: () {},
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: AppColors.orangePrimary.withOpacity(0.5),
                                  ),
                                  foregroundColor: AppColors.orangePrimary,
                                ),
                                child: const Text('Change Password'),
                              ),
                              const SizedBox(height: 10),
                              OutlinedButton(
                                onPressed: () async {
                                  await SupabaseConfig.client.auth.signOut();
                                  if (context.mounted) context.go('/auth/login');
                                },
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFFFF4444)),
                                  foregroundColor: const Color(0xFFFF4444),
                                ),
                                child: const Text('Sign Out'),
                              ),
                              const SizedBox(height: 10),
                              GestureDetector(
                                onTap: () {},
                                child: Center(
                                  child: Text(
                                    'Delete Account',
                                    style: AppText.body(
                                      12,
                                      color: const Color(0xFFFF4444).withOpacity(0.7),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          child: GradientButton(
                            label: 'Save Changes',
                            width: double.infinity,
                            isLoading: _saving,
                            onPressed: _saving ? null : () => _saveChanges(profile),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.orangePrimary),
            ),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Failed to load settings: $e',
                  style: AppText.body(14, context: context),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

