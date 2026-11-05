import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/planr_design.dart';
import '../core/widgets/planr_background.dart';
import '../core/widgets/planr_button.dart';
import '../core/widgets/planr_card.dart';
import '../core/widgets/planr_scaffold.dart';
import '../models/public_page.dart';
import '../providers/public_page_provider.dart';
import 'create_public_page_screen.dart';
import 'public_page_screen.dart';
import 'edit_public_page_screen.dart';

class ManagedPublicPagesScreen extends ConsumerWidget {
  const ManagedPublicPagesScreen({super.key});

  void _openCreatePage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const CreatePublicPageScreen(),
      ),
    );
  }

  void _openPage(BuildContext context, PublicPage page) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PublicPageScreen(pageId: page.id),
      ),
    );
  }

  void _openEditPage(BuildContext context, PublicPage page) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditPublicPageScreen(page: page),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pagesAsync = ref.watch(myManagedPublicPagesProvider);

    return PlanrScaffold(
      title: 'Public Pages',
      variant: PlanrBackgroundVariant.profile,
      child: pagesAsync.when(
        data: (pages) {
          if (pages.isEmpty) {
            return ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                _ManagedPagesIntroCard(
                  onCreatePage: () => _openCreatePage(context),
                ),
                const SizedBox(height: 18),
                PlanrCard(
                  padding: const EdgeInsets.all(22),
                  radius: 30,
                  color: PlanrDesign.cardLight.withValues(alpha: 0.88),
                  child: Column(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: PlanrDesign.accentSoft.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Icon(
                          Icons.storefront_rounded,
                          color: PlanrDesign.accentDark,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'No public pages yet',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: PlanrDesign.ink,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.35,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Create a page for a group, venue or organization to host public events.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: PlanrDesign.muted,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 18),
                      PlanrButton(
                        label: 'Create Page',
                        icon: Icons.add_rounded,
                        onPressed: () => _openCreatePage(context),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          return ListView(
            physics: const BouncingScrollPhysics(),
            children: [
              _ManagedPagesIntroCard(
                onCreatePage: () => _openCreatePage(context),
              ),
              const SizedBox(height: 18),
              _SectionHeader(
                title: 'Managed pages',
                subtitle:
                    '${pages.length} ${pages.length == 1 ? 'page' : 'pages'} you can use as organizers.',
              ),
              const SizedBox(height: 14),
              for (final page in pages)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ManagedPageCard(
                    page: page,
                    onTap: () => _openPage(context, page),
                    onEdit: () => _openEditPage(context, page),
                  ),
                ),
              const SizedBox(height: 20),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
        error: (_, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(PlanrDesign.pagePadding),
            child: PlanrCard(
              padding: const EdgeInsets.all(22),
              radius: 30,
              color: PlanrDesign.cardLight.withValues(alpha: 0.88),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    color: PlanrDesign.accentDark,
                    size: 34,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Pages could not load',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: PlanrDesign.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Something went wrong while loading your public pages.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
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
        ),
      ),
    );
  }
}

class _ManagedPagesIntroCard extends StatelessWidget {
  const _ManagedPagesIntroCard({
    required this.onCreatePage,
  });

  final VoidCallback onCreatePage;

  @override
  Widget build(BuildContext context) {
    return PlanrCard(
      padding: const EdgeInsets.all(20),
      radius: 30,
      color: PlanrDesign.cardLight.withValues(alpha: 0.88),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: PlanrDesign.accentSoft.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.92),
              ),
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: PlanrDesign.accentDark,
              size: 27,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Host as a page',
                  style: TextStyle(
                    color: PlanrDesign.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.35,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Manage public pages for clubs, groups, venues or organizations.',
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
          const SizedBox(width: 12),
          Material(
            color: PlanrDesign.accent,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onCreatePage,
              customBorder: const CircleBorder(),
              child: Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 25,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ManagedPageCard extends StatelessWidget {
  const _ManagedPageCard({
    required this.page,
    required this.onTap,
    required this.onEdit,
  });

  final PublicPage page;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  bool get _isOwner {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return uid != null && page.ownerUid == uid;
  }

  String get _roleLabel => _isOwner ? 'Owner' : 'Admin';

  String _categoryLabel(String category) {
    final normalized = category.trim().toLowerCase();

    return switch (normalized) {
      'club' => 'Club',
      'bar' => 'Bar',
      'venue' => 'Venue',
      'organization' => 'Organization',
      'collective' => 'Collective',
      'student_group' => 'Student Group',
      _ => 'Page',
    };
  }

  @override
  Widget build(BuildContext context) {
    final photoUrl = page.photoUrl?.trim();
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;
    final initial = page.name.trim().isEmpty
        ? '?'
        : page.name.trim().characters.first.toUpperCase();

    return PlanrCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      radius: 28,
      color: PlanrDesign.cardLight.withValues(alpha: 0.88),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: PlanrDesign.accentSoft.withValues(alpha: 0.76),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.92),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: hasPhoto
                ? Image.network(
                    photoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _PageInitial(initial: initial),
                  )
                : _PageInitial(initial: initial),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: SizedBox(
              height: 66,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _RolePill(label: _roleLabel),
                      const SizedBox(width: 7),
                      _CategoryMiniText(label: _categoryLabel(page.category)),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    page.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: PlanrDesign.ink,
                      fontSize: 17.5,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.45,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      if (page.displayHandle.isNotEmpty) ...[
                        Flexible(
                          child: Text(
                            page.displayHandle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: PlanrDesign.muted,
                              fontSize: 12.5,
                              height: 1,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Icon(
                        Icons.group_rounded,
                        size: 14,
                        color: PlanrDesign.softMuted.withValues(alpha: 0.85),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${page.followerCount}',
                        style: TextStyle(
                          color: PlanrDesign.softMuted.withValues(alpha: 0.95),
                          fontSize: 12.5,
                          height: 1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Icon(
                        Icons.event_rounded,
                        size: 14,
                        color: PlanrDesign.softMuted.withValues(alpha: 0.85),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${page.eventCount}',
                        style: TextStyle(
                          color: PlanrDesign.softMuted.withValues(alpha: 0.95),
                          fontSize: 12.5,
                          height: 1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Material(
                color: PlanrDesign.accentSoft.withValues(alpha: 0.72),
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: onEdit,
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.edit_rounded,
                      color: PlanrDesign.accentDark,
                      size: 19,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Icon(
                Icons.chevron_right_rounded,
                color: PlanrDesign.softMuted,
                size: 24,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PageInitial extends StatelessWidget {
  const _PageInitial({
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
          fontSize: 25,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  const _RolePill({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: PlanrDesign.accentSoft.withValues(alpha: 0.78),
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

class _CategoryMiniText extends StatelessWidget {
  const _CategoryMiniText({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: PlanrDesign.softMuted,
          fontSize: 11.5,
          height: 1,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: PlanrDesign.sectionTitleStyle.copyWith(
                  fontSize: 26,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: PlanrDesign.muted,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}