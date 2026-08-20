import 'package:flutter/material.dart';

/// Layout helpers shared by the web portals.
///
/// The Super Admin and Merchant portals were built desktop-first: their dialogs
/// asked for a fixed 360–440 px box, which overflows a 390 px phone once the
/// dialog's own insets are taken off. These helpers keep the desktop sizing but
/// never exceed what the screen can actually give (user report 18/08).
class Responsive {
  const Responsive._();

  /// Phone-ish width where side navigation collapses.
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 700;

  /// A dialog body width that prefers [preferred] but shrinks to fit.
  /// AlertDialog reserves 40 px of horizontal inset on each side.
  static double dialogWidth(BuildContext context, double preferred) {
    final available = MediaQuery.of(context).size.width - 80;
    return available < preferred ? available.clamp(200.0, preferred) : preferred;
  }

  /// A dialog body height that never pushes past the viewport.
  static double dialogHeight(BuildContext context, double preferred) {
    final available = MediaQuery.of(context).size.height * 0.7;
    return available < preferred ? available : preferred;
  }
}

/// A section header with a trailing action that stacks instead of overflowing.
///
/// `Row(children: [Expanded(header), button])` is fine on a laptop but clips the
/// button on a phone. Below [breakpoint] the action moves onto its own
/// full-width line (user report 18/08: portals not responsive on mobile).
class PageHeaderRow extends StatelessWidget {
  final Widget header;
  final List<Widget> actions;
  final double breakpoint;

  const PageHeaderRow({
    super.key,
    required this.header,
    this.actions = const [],
    this.breakpoint = 640,
  });

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return header;
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth >= breakpoint) {
          return Row(
            children: [
              Expanded(child: header),
              for (final a in actions) ...[const SizedBox(width: 8), a],
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: actions),
          ],
        );
      },
    );
  }
}

/// A [ListTile] whose trailing controls drop below the text on narrow screens.
///
/// `ListTile.trailing` is laid out at its natural width and the title gets
/// whatever is left — so a trailing Row of pill + switch + delete squeezes the
/// title into a one-word-per-line column on a phone (user report 18/08).
/// Above [breakpoint] this behaves exactly like a normal ListTile.
class ResponsiveListTile extends StatelessWidget {
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? contentPadding;
  final bool isThreeLine;
  final double breakpoint;

  const ResponsiveListTile({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.contentPadding,
    this.isThreeLine = false,
    this.breakpoint = 620,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= breakpoint || trailing == null;
        if (wide) {
          return ListTile(
            leading: leading,
            title: title,
            subtitle: subtitle,
            trailing: trailing,
            onTap: onTap,
            contentPadding: contentPadding,
            isThreeLine: isThreeLine,
          );
        }
        return ListTile(
          leading: leading,
          title: title,
          onTap: onTap,
          contentPadding: contentPadding,
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (subtitle != null) subtitle!,
              const SizedBox(height: 6),
              // Horizontal scroll is the safety net: even an unusually wide
              // action row can never overflow the tile.
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: trailing!,
              ),
            ],
          ),
        );
      },
    );
  }
}
