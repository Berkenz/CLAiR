import 'package:flutter_riverpod/flutter_riverpod.dart';

final mainShellTabProvider = StateProvider<int>((ref) => 0);

/// Which segment the Library tab should show: 0 = History, 1 = Saved.
/// Set before switching to the Library tab to open a specific segment.
final librarySegmentProvider = StateProvider<int>((ref) => 0);
