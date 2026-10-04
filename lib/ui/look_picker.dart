import 'package:flutter/material.dart';

import 'octo_avatar.dart';
import 'octo_looks.dart';
import 'theme.dart';
import 'tokens.dart';

/// The six looks in a row; the chosen one is ringed.
class LookPicker extends StatelessWidget {
  const LookPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final OctoLook selected;
  final ValueChanged<OctoLook>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = OctoTheme.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final look in OctoLook.values)
            Padding(
              padding: const EdgeInsets.only(right: OctoSpace.sm),
              child: Semantics(
                button: true,
                selected: look == selected,
                label: look.label,
                excludeSemantics: true,
                child: InkResponse(
                  onTap: onChanged == null ? null : () => onChanged!(look),
                  radius: 32,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: look == selected
                            ? colors.accent
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: OctoAvatar(look: look, size: 52),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
