import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:riderapp/features/auth/presentation/providers/auth_provider.dart';
import 'package:riderapp/features/incidents/presentation/providers/incidents_provider.dart';
import 'package:riderapp/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:riderapp/features/chat/presentation/providers/chat_provider.dart';

import 'mock_classes.dart';

/// Test helper utilities for Riverpod provider testing
class TestHelpers {
  /// Create a ProviderContainer with common overrides for testing
  static ProviderContainer createContainer({
    List<Override> overrides = const [],
  }) {
    return ProviderContainer(
      overrides: overrides,
    );
  }

  /// Create a ProviderContainer with mock auth repository
  static ProviderContainer createAuthContainer({
    MockAuthRepository? mockAuthRepository,
    List<Override> additionalOverrides = const [],
  }) {
    final authRepo = mockAuthRepository ?? MockAuthRepository();

    return ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepo),
        ...additionalOverrides,
      ],
    );
  }

  /// Create a ProviderContainer with mock incidents repository
  static ProviderContainer createIncidentsContainer({
    MockIncidentsRepository? mockIncidentsRepository,
    List<Override> additionalOverrides = const [],
  }) {
    final incidentsRepo = mockIncidentsRepository ?? MockIncidentsRepository();

    return ProviderContainer(
      overrides: [
        incidentsRepositoryProvider.overrideWithValue(incidentsRepo),
        ...additionalOverrides,
      ],
    );
  }

  /// Create a ProviderContainer with mock notifications repository
  static ProviderContainer createNotificationsContainer({
    MockNotificationsRepository? mockNotificationsRepository,
    List<Override> additionalOverrides = const [],
  }) {
    final notificationsRepo = mockNotificationsRepository ?? MockNotificationsRepository();

    return ProviderContainer(
      overrides: [
        notificationsRepositoryProvider.overrideWithValue(notificationsRepo),
        ...additionalOverrides,
      ],
    );
  }

  /// Create a ProviderContainer with mock chat repository and socket service
  static ProviderContainer createChatContainer({
    MockChatRepository? mockChatRepository,
    MockSocketService? mockSocketService,
    List<Override> additionalOverrides = const [],
  }) {
    final chatRepo = mockChatRepository ?? MockChatRepository();

    return ProviderContainer(
      overrides: [
        chatRepositoryProvider.overrideWithValue(chatRepo),
        ...additionalOverrides,
      ],
    );
  }
}

/// Extension to help with async state testing
extension ProviderContainerExtension on ProviderContainer {
  /// Wait for provider to settle by pumping the event loop
  Future<void> pump() async {
    await Future<void>.delayed(Duration.zero);
  }

  /// Wait for multiple event loops to process
  Future<void> pumpAndSettle({int iterations = 20, Duration delay = const Duration(milliseconds: 10)}) async {
    for (var i = 0; i < iterations; i++) {
      await Future<void>.delayed(delay);
    }
  }

  /// Wait for a provider state to match a condition
  Future<void> waitForState<T>(
    ProviderBase<T> provider,
    bool Function(T state) condition, {
    Duration timeout = const Duration(seconds: 5),
    Duration checkInterval = const Duration(milliseconds: 50),
  }) async {
    final stopwatch = Stopwatch()..start();
    while (stopwatch.elapsed < timeout) {
      final state = read(provider);
      if (condition(state)) {
        return;
      }
      await Future<void>.delayed(checkInterval);
    }
    throw TimeoutException('Timeout waiting for state condition', timeout);
  }
}

/// TimeoutException for state waiting
class TimeoutException implements Exception {
  final String message;
  final Duration timeout;

  TimeoutException(this.message, this.timeout);

  @override
  String toString() => '$message (after ${timeout.inMilliseconds}ms)';
}
