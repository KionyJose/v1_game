import 'package:flutter/material.dart';

/// Permite que grupos de ações definam sua ordem horizontal no Pad.
class PadDirectionIntent extends Intent {
  final TraversalDirection direction;
  const PadDirectionIntent(this.direction);
}
