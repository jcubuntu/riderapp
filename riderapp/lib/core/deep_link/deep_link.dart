// Deep link handling module for RiderApp
//
// This module provides functionality for handling deep links from notifications
// and navigating to the appropriate screens in the app.
//
// Usage:
// ```dart
// // In your notification handler:
// ref.handleNotificationTap({
//   'type': 'chat',
//   'targetId': '123',
// });
//
// // Or use the notifier directly:
// ref.read(deepLinkNotifierProvider.notifier).handleDeepLink(
//   type: DeepLinkType.incident,
//   targetId: '456',
// );
// ```

export 'deep_link_handler.dart';
export 'deep_link_provider.dart';
export 'deep_link_state.dart';
