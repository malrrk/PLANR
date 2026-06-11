import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/planr_design.dart';
import '../core/widgets/planr_background.dart';
import '../core/widgets/planr_button.dart';
import '../core/widgets/planr_card.dart';
import '../core/widgets/planr_scaffold.dart';
import '../core/widgets/planr_text_field.dart';
import '../models/public_page.dart';
import '../providers/public_page_provider.dart';

class ManagePageAdminsScreen extends ConsumerStatefulWidget {
  const ManagePageAdminsScreen({
    super.key,
    required this.pageId,
  });

  final String pageId;

  @override
  ConsumerState<ManagePageAdminsScreen> createState() =>
      _ManagePageAdminsScreenState();
}

class _ManagePageAdminsScreenState
    extends ConsumerState<ManagePageAdminsScreen> {
  final _usernameController = TextEditingController();

  bool _adding = false;
  String? _removingUid;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _addAdmin(PublicPage page) async {
    final username = _usernameController.text.trim();

    if (username.isEmpty) {
      _showSnackBar('Please enter a username.');
      return;
    }

    setState(() {
      _adding = true;
    });

    final error = await ref.read(publicPageServiceProvider).addPageAdminByUsername(
          page: page,
          username: username,
        );

    if (!mounted) return;

    setState(() {
      _adding = false;
    });

    if (error != null) {
      _showSnackBar(error);
      return;
    }

    _usernameController.clear();

    ref.invalidate(publicPageByIdProvider(page.id));
    ref.invalidate(myManagedPublicPagesProvider);

    _showSnackBar('Admin added.');
  }

  Future<void> _removeAdmin({
    required PublicPage page,
    required String adminUid,
  }) async {
    setState(() {
      _removingUid = adminUid;
    });

    final error = await ref.read(publicPageServiceProvider).removePageAdmin(
          page: page,
          adminUid: adminUid,
        );

    if (!mounted) return;

    setState(() {
      _removingUid = null;
    });

    if (error != null) {
      _showSnackBar(error);
      return;
    }

    ref.invalidate(publicPageByIdProvider(page.id));
    ref.invalidate(myManagedPublicPagesProvider);

    _showSnackBar('Admin removed.');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pageAsync = ref.watch(publicPageByIdProvider(widget.pageId));

    return PlanrScaffold(
      title: 'Page Admins',
      variant: PlanrBackgroundVariant.profile,
      resizeToAvoidBottomInset: true,
      child: pageAsync.when(
        data: (page) {
          if (page == null) {
            return const _CenteredAdminMessage(
              icon: Icons.search_off_rounded,
              title: 'Page not found',
              subtitle: 'This public page is no longer available.',
            );
          }

          final adminUids = page.adminUids
              .where((uid) => uid != page.ownerUid)
              .toSet()
              .toList();

          return ListView(
            physics: const BouncingScrollPhysics(),
            children: [
              _AdminIntroCard(page: page),
              const SizedBox(height: 18),
              PlanrCard(
                padding: const EdgeInsets.all(18),
                radius: 30,
                color: PlanrDesign.cardLight.withOpacity(0.88),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionTitle(
                      icon: Icons.person_add_alt_1_rounded,
                      title: 'Add admin',
                      subtitle:
                          'Enter the username of a user who should manage this page.',
                    ),
                    const SizedBox(height: 16),
                    PlanrTextField(
                      controller: _usernameController,
                      label: 'Username',
                      hintText: 'e.g. alec06',
                      prefixIcon: Icons.alternate_email_rounded,
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 16),
                    PlanrButton(
                      label: _adding ? 'Adding...' : 'Add Admin',
                      icon: Icons.add_rounded,
                      isLoading: _adding,
                      onPressed: _adding ? null : () => _addAdmin(page),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _AdminsListCard(
                page: page,
                adminUids: adminUids,
                removingUid: _removingUid,
                onRemoveAdmin: (adminUid) => _removeAdmin(
                  page: page,
                  adminUid: adminUid,
                ),
              ),
              const SizedBox(height: 20),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
        error: (_, _) => const _CenteredAdminMessage(
          icon: Icons.error_outline_rounded,
          title: 'Could not load admins',
          subtitle: 'Please try again in a moment.',
        ),
      ),
    );
  }
}

class _AdminIntroCard extends StatelessWidget {
  const _AdminIntroCard({
    required this.page,
  });

  final PublicPage page;

  @override
  Widget build(BuildContext context) {
    return PlanrCard(
      padding: const EdgeInsets.all(20),
      radius: 30,
      color: PlanrDesign.cardLight.withOpacity(0.88),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: PlanrDesign.accentSoft.withOpacity(0.78),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.92),
              ),
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: PlanrDesign.accentDark,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  page.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: PlanrDesign.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.35,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Admins can edit the page and create public events as this page.',
                  style: TextStyle(
                    color: PlanrDesign.muted,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    height: 1.32,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminsListCard extends StatelessWidget {
  const _AdminsListCard({
    required this.page,
    required this.adminUids,
    required this.removingUid,
    required this.onRemoveAdmin,
  });

  final PublicPage page;
  final List<String> adminUids;
  final String? removingUid;
  final ValueChanged<String> onRemoveAdmin;

  @override
  Widget build(BuildContext context) {
    return PlanrCard(
      padding: const EdgeInsets.all(18),
      radius: 30,
      color: PlanrDesign.cardLight.withOpacity(0.88),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.group_rounded,
            title: 'Current admins',
            subtitle: 'Only the owner can add or remove admins.',
          ),
          const SizedBox(height: 14),
          _OwnerRow(ownerUid: page.ownerUid),
          if (adminUids.isEmpty) ...[
            const SizedBox(height: 14),
            const _NoAdminsNotice(),
          ] else ...[
            const SizedBox(height: 12),
            for (final adminUid in adminUids)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _AdminUserRow(
                  uid: adminUid,
                  isRemoving: removingUid == adminUid,
                  onRemove: () => onRemoveAdmin(adminUid),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _OwnerRow extends StatelessWidget {
  const _OwnerRow({
    required this.ownerUid,
  });

  final String? ownerUid;

  @override
  Widget build(BuildContext context) {
    if (ownerUid == null || ownerUid!.isEmpty) {
      return const _StaticUserRow(
        icon: Icons.person_rounded,
        title: 'Unknown owner',
        subtitle: 'Owner information is missing.',
        badge: 'Owner',
      );
    }

    return _UserProfileRow(
      uid: ownerUid!,
      badge: 'Owner',
      trailing: const Icon(
        Icons.lock_rounded,
        color: PlanrDesign.softMuted,
        size: 20,
      ),
    );
  }
}

class _AdminUserRow extends StatelessWidget {
  const _AdminUserRow({
    required this.uid,
    required this.isRemoving,
    required this.onRemove,
  });

  final String uid;
  final bool isRemoving;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return _UserProfileRow(
      uid: uid,
      badge: 'Admin',
      trailing: Material(
        color: PlanrDesign.accentSoft.withOpacity(0.72),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: isRemoving ? null : onRemove,
          customBorder: const CircleBorder(),
          child: Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            child: isRemoving
                ? const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(
                    Icons.close_rounded,
                    color: PlanrDesign.accentDark,
                    size: 21,
                  ),
          ),
        ),
      ),
    );
  }
}

class _UserProfileRow extends StatelessWidget {
  const _UserProfileRow({
    required this.uid,
    required this.badge,
    required this.trailing,
  });

  final String uid;
  final String badge;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const _StaticUserRow(
            icon: Icons.person_rounded,
            title: 'Loading user...',
            subtitle: '',
            badge: '',
          );
        }

        final data = snapshot.data!.data();
        final displayName = data?['displayName'] as String? ?? 'Unknown user';
        final username = data?['username'] as String? ?? '';
        final photoUrl = data?['photoUrl'] as String?;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: PlanrDesign.cardLight.withOpacity(0.76),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          child: Row(
            children: [
              _UserAvatar(
                displayName: displayName,
                photoUrl: photoUrl,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: PlanrDesign.ink,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (badge.isNotEmpty) ...[
                          const SizedBox(width: 7),
                          _SmallRolePill(label: badge),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      username.isEmpty ? uid : '@$username',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: PlanrDesign.muted,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              trailing,
            ],
          ),
        );
      },
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({
    required this.displayName,
    required this.photoUrl,
  });

  final String displayName;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final trimmedPhoto = photoUrl?.trim();
    final initial = displayName.trim().isEmpty
        ? '?'
        : displayName.trim().characters.first.toUpperCase();

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: PlanrDesign.accentSoft.withOpacity(0.75),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: Colors.white.withOpacity(0.9),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: trimmedPhoto != null && trimmedPhoto.isNotEmpty
          ? Image.network(
              trimmedPhoto,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _AvatarInitial(initial: initial),
            )
          : _AvatarInitial(initial: initial),
    );
  }
}

class _AvatarInitial extends StatelessWidget {
  const _AvatarInitial({
    required this.initial,
  });

  final String initial;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          color: PlanrDesign.accentDark,
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _StaticUserRow extends StatelessWidget {
  const _StaticUserRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PlanrDesign.cardLight.withOpacity(0.76),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withOpacity(0.9),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: PlanrDesign.accentSoft.withOpacity(0.75),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(
              icon,
              color: PlanrDesign.accentDark,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: PlanrDesign.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: PlanrDesign.muted,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (badge.isNotEmpty) _SmallRolePill(label: badge),
        ],
      ),
    );
  }
}

class _SmallRolePill extends StatelessWidget {
  const _SmallRolePill({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: PlanrDesign.accentSoft.withOpacity(0.78),
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: PlanrDesign.accentDark,
          fontSize: 11,
          height: 1,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _NoAdminsNotice extends StatelessWidget {
  const _NoAdminsNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PlanrDesign.cardLight.withOpacity(0.76),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withOpacity(0.9),
        ),
      ),
      child: const Text(
        'No additional admins yet. Add someone by username above.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: PlanrDesign.muted,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          height: 1.35,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: PlanrDesign.accentSoft.withOpacity(0.72),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.88),
            ),
          ),
          child: Icon(
            icon,
            color: PlanrDesign.accentDark,
            size: 21,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: PlanrDesign.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.25,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: PlanrDesign.muted,
                  fontSize: 12.6,
                  fontWeight: FontWeight.w700,
                  height: 1.28,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CenteredAdminMessage extends StatelessWidget {
  const _CenteredAdminMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PlanrDesign.pagePadding),
        child: PlanrCard(
          padding: const EdgeInsets.all(24),
          radius: 30,
          color: PlanrDesign.cardLight.withOpacity(0.88),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: PlanrDesign.accentDark,
                size: 36,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: PlanrDesign.ink,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: PlanrDesign.muted,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}