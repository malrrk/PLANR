import 'package:flutter/material.dart';

import '../core/app_config.dart';
import '../core/theme/planr_design.dart';
import '../core/widgets/planr_background.dart';
import '../core/widgets/planr_scaffold.dart';

/// Plain-language terms and privacy summary. Have it reviewed before publishing.
class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key});

  static const List<(String, String)> _sections = [
    (
      'Community rules',
      'PLANR is for real plans with real people. Do not post spam, harassment, hate, '
          'sexual or violent content, or anything illegal. You are responsible for what you '
          'post. We may remove content and suspend accounts that break these rules. '
          'You can report any event, page, story, message or profile, and block any user.',
    ),
    (
      'What we collect',
      'Your email address, display name, username and optional bio and photos. The events, '
          'stories, messages, invites, friends and pages you create or join. Reports and '
          'blocks you make. We use this only to run the app.',
    ),
    (
      'Who can see it',
      'Your profile, events you make public and public pages are visible to other signed-in '
          'users. Private events and event chats are visible to the people invited or going. '
          'Stories are shown to your friends in the app.',
    ),
    (
      'Where it is stored',
      'Your data is stored with Google Firebase (authentication, database and file storage). '
          'We do not sell your data.',
    ),
    (
      'Your choices',
      'You can edit your profile at any time and delete your account in the app under '
          'Profile > Delete account. Deleting your account removes your profile, your events, '
          'stories and friendships. Messages you sent in other people\'s events may be removed '
          'too.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return PlanrScaffold(
      title: 'Terms & Privacy',
      variant: PlanrBackgroundVariant.profile,
      child: ListView(
        children: [
          for (final (title, body) in _sections) ...[
            Text(
              title,
              style: const TextStyle(
                color: PlanrDesign.ink,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              style: const TextStyle(
                color: PlanrDesign.muted,
                fontSize: 14.5,
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
          ],
          if (AppConfig.supportEmail.isNotEmpty)
            Text(
              'Questions or reports: ${AppConfig.supportEmail}',
              style: const TextStyle(
                color: PlanrDesign.ink,
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
