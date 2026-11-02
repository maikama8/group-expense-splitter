enum SplitMode { equal, custom }

extension SplitModeLabel on SplitMode {
  String get label => switch (this) {
        SplitMode.equal => 'Equal',
        SplitMode.custom => 'Custom',
      };
}
