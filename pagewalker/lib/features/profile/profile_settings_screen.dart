import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/plus/pagewalker_plus_features.dart';
import '../../core/plus/pagewalker_plus_service.dart';
import '../../core/plus/plus_paywall_sheet.dart';
import '../../core/plus/plus_gate.dart';
import '../../core/config/supabase_config.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/pagewalker_theme_extension.dart';
import '../../core/widgets/themed_background.dart';
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
    final tc = context.pwColors;
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      body: ThemedBackground(
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
                      color: tc.primary,
                    ),
                    title: Text(
                      'Settings',
                      style: AppText.display(22, context: context),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        _PlusSettingsCard(),
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
                                  color: tc.primary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => ref.read(themeProvider.notifier).setLight(),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        decoration: BoxDecoration(
                                          color: ref.watch(themeProvider) == ThemeMode.light
                                              ? tc.primary
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(
                                            color: tc.primary.withValues(alpha: 0.5),
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            const Text('☀️', style: TextStyle(fontSize: 22)),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Light',
                                              style: AppText.bodySemiBold(
                                                12,
                                                color: ref.watch(themeProvider) == ThemeMode.light
                                                    ? Colors.white
                                                    : tc.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => ref.read(themeProvider.notifier).setDark(),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        decoration: BoxDecoration(
                                          color: ref.watch(themeProvider) == ThemeMode.dark
                                              ? tc.primary
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(
                                            color: tc.primary.withValues(alpha: 0.5),
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            const Text('🌙', style: TextStyle(fontSize: 22)),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Dark',
                                              style: AppText.bodySemiBold(
                                                12,
                                                color: ref.watch(themeProvider) == ThemeMode.dark
                                                    ? Colors.white
                                                    : tc.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => ref.read(themeProvider.notifier).setSystem(),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        decoration: BoxDecoration(
                                          color: ref.watch(themeProvider) == ThemeMode.system
                                              ? tc.primary
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(
                                            color: tc.primary.withValues(alpha: 0.5),
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Icon(
                                              Icons.brightness_auto_rounded,
                                              size: 22,
                                              color: ref.watch(themeProvider) == ThemeMode.system
                                                  ? Colors.white
                                                  : tc.textSecondary,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'System',
                                              style: AppText.bodySemiBold(
                                                12,
                                                color: ref.watch(themeProvider) == ThemeMode.system
                                                    ? Colors.white
                                                    : tc.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Choose your theme',
                                style: AppText.bodySemiBold(15, color: tc.primary),
                              ),
                              const SizedBox(height: 12),
                              _buildThemeCard(
                                context: context,
                                ref: ref,
                                type: AppThemeType.classic,
                                name: 'Classic',
                                subtitle: 'Black, Orange & White',
                                description: 'Bold and striking. Perfect for BookTok energy.',
                                previewColors: const [
                                  Color(0xFF0A0A0A),
                                  Color(0xFFFF6B1A),
                                  Color(0xFFFFFFFF),
                                ],
                                emoji: '📙',
                              ),
                              const SizedBox(height: 12),
                              _buildThemeCard(
                                context: context,
                                ref: ref,
                                type: AppThemeType.midnightLibrary,
                                name: 'Midnight Library',
                                subtitle: 'Navy, Gold & Cream',
                                description: 'Dark academia. Mysterious and literary.',
                                previewColors: const [
                                  Color(0xFF0A0A14),
                                  Color(0xFFD4AF37),
                                  Color(0xFFF5F0E8),
                                ],
                                emoji: '🌙',
                              ),
                              const SizedBox(height: 12),
                              _buildThemeCard(
                                context: context,
                                ref: ref,
                                type: AppThemeType.forestRetreat,
                                name: 'Forest Retreat',
                                subtitle: 'Forest Green, Amber & Cream',
                                description: 'Cosy and natural. Cottagecore reader vibes.',
                                previewColors: const [
                                  Color(0xFF080F0A),
                                  Color(0xFFC8861A),
                                  Color(0xFFF0F5EC),
                                ],
                                emoji: '🌿',
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
                                style: AppText.bodySemiBold(15, color: tc.primary),
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
                                style: AppText.bodySemiBold(15, color: tc.primary),
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
                                  color: tc.textMuted,
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
                                  color: tc.primary,
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
                                          color: tc.textSecondary,
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
                                    activeThumbColor: tc.primary,
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
                                          colorScheme: Theme.of(context)
                                              .colorScheme
                                              .copyWith(primary: tc.primary),
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
                                      color: tc.card,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: tc.primary.withValues(alpha: 0.3),
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
                                            color: tc.primary,
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
                                          color: tc.textSecondary,
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
                                    activeThumbColor: tc.primary,
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
                                        color: tc.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _isPublic,
                                onChanged: (v) => setState(() => _isPublic = v),
                                activeThumbColor: tc.primary,
                              ),
                            ],
                          ),
                        ),

                        // SECTION 6 — HOME SCREEN WIDGET
                        GlassCard(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Home Screen Widget',
                                style: AppText.bodySemiBold(
                                  15,
                                  color: tc.primary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add the Pagewalker widget to your home screen to see your current read at a glance.',
                                style: AppText.body(
                                  13,
                                  color: tc.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xE6120800),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: tc.primary.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Pagewalker',
                                      style: AppText.label(
                                        10,
                                        color: tc.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Your current book title',
                                      style: AppText.display(14, context: context),
                                    ),
                                    Text(
                                      'Author name',
                                      style: AppText.body(
                                        11,
                                        color: tc.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    LinearProgressIndicator(
                                      value: 0.65,
                                      backgroundColor: tc.accent.withValues(alpha: 0.25),
                                      valueColor: AlwaysStoppedAnimation(tc.primary),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Page 258 of 400 · 35% left',
                                      style: AppText.body(
                                        10,
                                        color: tc.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'To add: long press your home screen → Widgets → Pagewalker',
                                style: AppText.body(
                                  12,
                                  color: tc.textMuted,
                                ),
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
                                style: AppText.bodySemiBold(15, color: tc.primary),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton(
                                onPressed: () {},
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: tc.primary.withValues(alpha: 0.5),
                                  ),
                                  foregroundColor: tc.primary,
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
                                      color: const Color(0xFFFF4444)
                                          .withValues(alpha: 0.7),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // SECTION 7 — LEGAL
                        GlassCard(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Column(
                            children: [
                              ListTile(
                                title: Text('Privacy Policy', style: AppText.body(15, context: context)),
                                trailing: Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 16,
                                  color: tc.primary,
                                ),
                                onTap: () => context.push('/privacy'),
                                contentPadding: EdgeInsets.zero,
                              ),
                              Divider(color: tc.primary.withValues(alpha: 0.1)),
                              ListTile(
                                title: Text('Terms of Service', style: AppText.body(15, context: context)),
                                trailing: Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 16,
                                  color: tc.primary,
                                ),
                                onTap: () => context.push('/terms'),
                                contentPadding: EdgeInsets.zero,
                              ),
                              Divider(color: tc.primary.withValues(alpha: 0.1)),
                              ListTile(
                                title: Text('Contact Us', style: AppText.body(15, context: context)),
                                subtitle: Text(
                                  Env.contactEmail,
                                  style: AppText.body(12, color: tc.textSecondary, context: context),
                                ),
                                leading: Icon(
                                  Icons.email_rounded,
                                  color: tc.primary,
                                ),
                                onTap: () async {
                                  final uri = Uri(
                                    scheme: 'mailto',
                                    path: Env.contactEmail,
                                    queryParameters: const {
                                      'subject': 'Pagewalker Support',
                                    },
                                  );
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri);
                                  }
                                },
                                contentPadding: EdgeInsets.zero,
                              ),
                              Divider(color: tc.primary.withValues(alpha: 0.1)),
                              ListTile(
                                title: Text('App Version', style: AppText.body(15, context: context)),
                                subtitle: Text(
                                  '© ${Env.copyrightYear} ${Env.appName}',
                                  style: AppText.body(11, color: tc.textMuted, context: context),
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: tc.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: tc.primary.withValues(alpha: 0.3)),
                                  ),
                                  child: FutureBuilder<PackageInfo>(
                                    future: PackageInfo.fromPlatform(),
                                    builder: (context, snapshot) {
                                      final info = snapshot.data;
                                      final label = info == null
                                          ? 'v${Env.appVersion}'
                                          : info.buildNumber.isEmpty
                                              ? 'v${info.version}'
                                              : 'v${info.version} (${info.buildNumber})';
                                      return Text(
                                        label,
                                        style: AppText.bodySemiBold(12, color: tc.primary, context: context),
                                      );
                                    },
                                  ),
                                ),
                                contentPadding: EdgeInsets.zero,
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
            loading: () => Center(
              child: CircularProgressIndicator(color: tc.primary),
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

  Widget _buildThemeCard({
    required BuildContext context,
    required WidgetRef ref,
    required AppThemeType type,
    required String name,
    required String subtitle,
    required String description,
    required List<Color> previewColors,
    required String emoji,
  }) {
    final currentTheme = ref.watch(appThemeProvider);
    final isSelected = currentTheme == type;
    final themeColors = context.pwColors;
    return GestureDetector(
      onTap: () => ref.read(appThemeProvider.notifier).setTheme(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? themeColors.primary.withValues(alpha: 0.1)
              : themeColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? themeColors.primary : themeColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: previewColors[0],
                    ),
                  ),
                  Positioned(
                    right: 0,
                    child: Container(
                      width: 28,
                      height: 56,
                      decoration: BoxDecoration(
                        color: previewColors[1],
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(28),
                          bottomRight: Radius.circular(28),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 4,
                    left: 8,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: previewColors[2],
                        border: Border.all(color: Colors.black12, width: 1),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(
                        name,
                        style: AppText.bodySemiBold(15, context: context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppText.body(12, color: themeColors.primary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: AppText.body(12, color: themeColors.textMuted),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: themeColors.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}

class _PlusSettingsCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tc = context.pwColors;
    final isPlus = ref.watch(pagewalkerPlusProvider).value ?? false;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Pagewalker Plus',
                style: AppText.bodySemiBold(15, color: tc.primary),
              ),
              const SizedBox(width: 8),
              const PlusBadge(),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isPlus
                ? 'You have Plus — mood reads, bingo, wraps, widgets, and unlimited clubs are unlocked.'
                : 'Upgrade for mood reads, reading personality, bingo, home widget, wraps, spin the wheel, and unlimited clubs.',
            style: AppText.body(13, color: tc.textMuted),
          ),
          const SizedBox(height: 12),
          GradientButton(
            label: isPlus ? 'Manage subscription' : 'See Plus benefits',
            width: double.infinity,
            onPressed: () => showPlusPaywall(context),
          ),
          if (isPlus) ...[
            const SizedBox(height: 12),
            Text(
              'Home screen widget',
              style: AppText.bodySemiBold(14, color: tc.primary),
            ),
            const SizedBox(height: 6),
            Text(
              'Long-press your Android home screen → Widgets → Pagewalker. '
              'Shows your current read and progress (updates when you open Library).',
              style: AppText.body(12, color: tc.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

