import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../core/app_config.dart';
import '../core/app_settings.dart';
import '../core/theme/planr_design.dart';
import '../core/widgets/planr_background.dart';
import '../core/widgets/planr_card.dart';
import '../core/widgets/planr_scaffold.dart';
import '../l10n/l10n.dart';
import '../providers/auth_provider.dart';
import '../providers/firebase_providers.dart';
import '../widgets/account/delete_account_dialog.dart';
import '../widgets/account/logout_dialog.dart';
import 'blocked_users_screen.dart';
import 'legal_screen.dart';

Future<String> _loadVersion() async {
  final info = await PackageInfo.fromPlatform();
  return '${info.version} (${info.buildNumber})';
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key, this.versionLoader = _loadVersion});

  final Future<String> Function() versionLoader;

  void _open(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _resetPassword(BuildContext context, WidgetRef ref, String email) async {
    final error = await ref.read(authProvider).resetPassword(email: email);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? context.l10n.resetPasswordSent)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final user = ref.watch(firebaseAuthProvider).currentUser;
    final settings = AppSettings.instance;

    return PlanrScaffold(
      title: l10n.settingsTitle,
      variant: PlanrBackgroundVariant.profile,
      child: ListView(
        children: [
          _Section(
            title: l10n.settingsPreferences,
            children: [
              Text(
                l10n.settingsLanguage,
                style: const TextStyle(
                  color: PlanrDesign.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              ValueListenableBuilder<Locale?>(
                valueListenable: settings.locale,
                builder: (context, locale, _) => SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<String>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(value: '', label: Text(l10n.languageSystem)),
                      ButtonSegment(value: 'de', label: Text(l10n.languageGerman)),
                      ButtonSegment(value: 'en', label: Text(l10n.languageEnglish)),
                    ],
                    selected: {locale?.languageCode ?? ''},
                    onSelectionChanged: (value) {
                      final code = value.first;
                      settings.setLanguage(code.isEmpty ? null : code);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.settingsNotifications,
                style: const TextStyle(
                  color: PlanrDesign.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              ValueListenableBuilder<bool>(
                valueListenable: settings.notifyInvites,
                builder: (context, value, _) => SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.notifyInvitations),
                  subtitle: Text(l10n.notifyInvitationsHint),
                  value: value,
                  onChanged: settings.setNotifyInvites,
                ),
              ),
              ValueListenableBuilder<bool>(
                valueListenable: settings.notifyFriendRequests,
                builder: (context, value, _) => SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.notifyFriendRequests),
                  subtitle: Text(l10n.notifyFriendRequestsHint),
                  value: value,
                  onChanged: settings.setNotifyFriendRequests,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Section(
            title: l10n.settingsAccount,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.settingsEmail),
                subtitle: Text(user?.email ?? '-'),
                trailing: Text(
                  user?.emailVerified == true
                      ? l10n.emailVerified
                      : l10n.emailNotVerified,
                  style: TextStyle(
                    color: user?.emailVerified == true
                        ? Colors.green.shade700
                        : Colors.orange.shade800,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (user?.email != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.lock_reset_rounded),
                  title: Text(l10n.resetPassword),
                  subtitle: Text(l10n.resetPasswordHint),
                  onTap: () => _resetPassword(context, ref, user!.email!),
                ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.logout_rounded, color: Colors.red.shade600),
                title: Text(l10n.logOut),
                subtitle: Text(l10n.logOutHint),
                onTap: () => confirmAndLogout(context, ref),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.delete_forever_rounded, color: Colors.red.shade600),
                title: Text(
                  l10n.deleteAccount,
                  style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w800),
                ),
                subtitle: Text(l10n.deleteAccountHint),
                onTap: () => showDeleteAccountDialog(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Section(
            title: l10n.settingsPrivacy,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.block_rounded),
                title: Text(l10n.blockedUsersTitle),
                subtitle: Text(l10n.blockedUsersHint),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _open(context, const BlockedUsersScreen()),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Section(
            title: l10n.settingsHelp,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.policy_rounded),
                title: Text(l10n.termsAndPrivacy),
                subtitle: Text(l10n.termsAndPrivacyHint),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _open(context, const LegalScreen()),
              ),
              if (AppConfig.supportEmail.isNotEmpty)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.support_agent_rounded),
                  title: Text(l10n.supportContact(AppConfig.supportEmail)),
                  trailing: const Icon(Icons.copy_rounded),
                  onTap: () => Clipboard.setData(
                    const ClipboardData(text: AppConfig.supportEmail),
                  ),
                )
              else
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.support_agent_rounded),
                  title: Text(l10n.supportContactMissing),
                ),
              FutureBuilder<String>(
                future: versionLoader(),
                builder: (context, snapshot) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.info_outline_rounded),
                  title: Text(l10n.appVersion),
                  trailing: Text(snapshot.data ?? '-'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return PlanrCard(
      padding: const EdgeInsets.all(18),
      radius: 28,
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: PlanrDesign.ink,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}
