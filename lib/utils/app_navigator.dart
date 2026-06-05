import 'package:flutter/widgets.dart';

/// Global navigator key so context-free services (e.g. [NotificationService])
/// can navigate in response to notification taps. Attached to the root
/// `MaterialApp` in `lib/main.dart`.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
