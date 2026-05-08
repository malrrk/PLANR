import 'package:flutter/material.dart';

import '../theme/planr_design.dart';
import 'planr_background.dart';

class PlanrScaffold extends StatelessWidget {
  const PlanrScaffold({
    super.key,
    required this.child,
    this.variant = PlanrBackgroundVariant.plain,
    this.title,
    this.actions,
    this.showBackButton = true,
    this.padding = const EdgeInsets.fromLTRB(
      PlanrDesign.pagePadding,
      14,
      PlanrDesign.pagePadding,
      24,
    ),
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.resizeToAvoidBottomInset,
  });

  final Widget child;
  final PlanrBackgroundVariant variant;
  final String? title;
  final List<Widget>? actions;
  final bool showBackButton;
  final EdgeInsets padding;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final bool? resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    return PlanrBackground(
      variant: variant,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        bottomNavigationBar: bottomNavigationBar,
        floatingActionButton: floatingActionButton,
        appBar: title == null && actions == null
            ? null
            : AppBar(
                title: title == null
                    ? null
                    : Text(
                        title!,
                        style: const TextStyle(
                          color: PlanrDesign.ink,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                        ),
                      ),
                centerTitle: false,
                backgroundColor: Colors.transparent,
                foregroundColor: PlanrDesign.ink,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
                leading: showBackButton
                    ? IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 20,
                          color: PlanrDesign.ink,
                        ),
                      )
                    : null,
                actions: actions,
              ),
        body: SafeArea(
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}