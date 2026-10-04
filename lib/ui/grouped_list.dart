import 'package:flutter/material.dart';

import 'theme.dart';
import 'tokens.dart';

/// An iOS-settings-style section: a small grey header and plain rows.
class GroupedSection extends StatelessWidget {
  const GroupedSection({
    super.key,
    this.title,
    required this.children,
    this.footer,
  });

  final String? title;
  final List<Widget> children;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    final colors = OctoTheme.of(context);
    final small = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: colors.secondaryLabel);
    return Padding(
      padding: const EdgeInsets.only(top: OctoSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                OctoSpace.lg,
                0,
                OctoSpace.lg,
                OctoSpace.xs,
              ),
              child: Semantics(
                header: true,
                child: Text(title!.toUpperCase(), style: small),
              ),
            ),
          ...children,
          if (footer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                OctoSpace.lg,
                OctoSpace.xs,
                OctoSpace.lg,
                0,
              ),
              child: Text(footer!, style: small),
            ),
        ],
      ),
    );
  }
}
