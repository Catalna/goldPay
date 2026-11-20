import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme/tokens.dart';
import '../constants/copy_id.dart';
import 'demo_badge.dart';

/// Destination highlighted in the persistent bottom bar.
enum AppShellTab { home, history, settings }

/// Shared application frame following modern fintech design:
/// clean warm-cream background, elegant top header, and floating center-scan bottom bar.
class AppShell extends StatelessWidget {
  const AppShell({
    this.title,
    this.titleText,
    required this.child,
    this.subtitle,
    this.currentTab,
    this.leading,
    this.actions,
    this.showDemoBadge = false,
    super.key,
  });

  final Widget? title;
  final String? titleText;
  final Widget child;
  final String? subtitle;
  final AppShellTab? currentTab;
  final Widget? leading;
  final List<Widget>? actions;
  final bool showDemoBadge;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isHome = currentTab == AppShellTab.home;

    return Scaffold(
      backgroundColor: GoldPayTokens.surface,
      body: SafeArea(
        bottom: currentTab != null ? false : true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                GoldPayTokens.pagePadding,
                GoldPayTokens.space12,
                GoldPayTokens.pagePadding,
                GoldPayTokens.space8,
              ),
              child: Row(
                children: [
                  if (leading != null) ...[
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: GoldPayTokens.card,
                        shape: BoxShape.circle,
                        border: Border.all(color: GoldPayTokens.border),
                      ),
                      child: leading,
                    ),
                    const SizedBox(width: GoldPayTokens.space12),
                  ] else if (isHome) ...[
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: GoldPayTokens.card,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: GoldPayTokens.gold.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.person_rounded,
                          color: GoldPayTokens.primaryDark,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: GoldPayTokens.space12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isHome) ...[
                          Text(
                            'WELCOME BACK',
                            style: textTheme.bodySmall?.copyWith(
                              fontSize: 10,
                              height: 12 / 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                              color: GoldPayTokens.inkMuted,
                            ),
                          ),
                          const SizedBox(height: 2),
                        ],
                        Row(
                          children: [
                            Flexible(
                              child:
                                  title ??
                                  Text(
                                    titleText ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: textTheme.titleLarge?.copyWith(
                                      color: GoldPayTokens.ink,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                            ),
                            if (showDemoBadge) ...[
                              const SizedBox(width: GoldPayTokens.space8),
                              const DemoBadge(),
                            ],
                          ],
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: GoldPayTokens.inkMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  ...?actions,
                ],
              ),
            ),
            Expanded(child: child),
            if (currentTab != null) _BottomBar(currentTab: currentTab!),
          ],
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.currentTab});

  final AppShellTab currentTab;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: GoldPayTokens.card,
        border: const Border(
          top: BorderSide(color: GoldPayTokens.border, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: GoldPayTokens.navBarHeight,
        child: Row(
          children: [
            Expanded(
              child: _BottomTab(
                icon: Icons.home_rounded,
                label: CopyId.navHomeTab,
                selected: currentTab == AppShellTab.home,
                onTap: () => context.go('/'),
              ),
            ),
            Expanded(
              child: _BottomTab(
                icon: Icons.receipt_long_rounded,
                label: CopyId.navHistory,
                selected: currentTab == AppShellTab.history,
                onTap: () => context.go('/history'),
              ),
            ),
            SizedBox(
              width: GoldPayTokens.navBarHeight,
              child: _ScanButton(onTap: () => context.push('/scan')),
            ),
            Expanded(
              child: _BottomTab(
                icon: Icons.tune_rounded,
                label: CopyId.navSettingsTab,
                selected: currentTab == AppShellTab.settings,
                onTap: () => context.go('/demo-settings'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomTab extends StatelessWidget {
  const _BottomTab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? GoldPayTokens.primaryDark : GoldPayTokens.inkMuted;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: GoldPayTokens.space4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(
                fontSize: 12,
                color: color,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Floating centre action button: Scan QRIS in prominent forest green.
class _ScanButton extends StatelessWidget {
  const _ScanButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      label: CopyId.navScan,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GoldPayTokens.navScanButtonSize),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: GoldPayTokens.navScanButtonSize,
              height: GoldPayTokens.navScanButtonSize,
              decoration: BoxDecoration(
                color: GoldPayTokens.primaryDark,
                shape: BoxShape.circle,
                border: Border.all(color: GoldPayTokens.card, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: GoldPayTokens.primaryDark.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.qr_code_scanner_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              CopyId.navScanTab,
              style: textTheme.bodySmall?.copyWith(
                fontSize: 11,
                color: GoldPayTokens.primaryDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
