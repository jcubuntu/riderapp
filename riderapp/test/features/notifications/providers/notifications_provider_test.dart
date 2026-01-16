import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:riderapp/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:riderapp/features/notifications/presentation/providers/notifications_state.dart';

import '../../../helpers/mock_classes.dart';
import '../../../helpers/test_helpers.dart';

void main() {
  late MockNotificationsRepository mockRepository;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValues();
  });

  setUp(() {
    mockRepository = MockNotificationsRepository();
  });

  tearDown(() {
    container.dispose();
  });

  group('NotificationsNotifier', () {
    group('Initial State', () {
      test('should start with NotificationsInitial state', () {
        container = TestHelpers.createNotificationsContainer(
          mockNotificationsRepository: mockRepository,
        );

        final state = container.read(notificationsProvider);
        expect(state, isA<NotificationsInitial>());
      });
    });

    group('loadNotifications', () {
      test('should set NotificationsLoading state when loading starts', () async {
        when(() => mockRepository.getNotifications(
              page: any(named: 'page'),
              limit: any(named: 'limit'),
            )).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return TestDataFactory.createPaginatedNotifications();
        });

        container = TestHelpers.createNotificationsContainer(
          mockNotificationsRepository: mockRepository,
        );

        final notifier = container.read(notificationsProvider.notifier);

        // Start loading but don't await
        final loadFuture = notifier.loadNotifications();

        // Check loading state immediately
        await container.pump();
        expect(container.read(notificationsProvider), isA<NotificationsLoading>());

        await loadFuture;
      });

      test('should set NotificationsLoaded state with notifications on success', () async {
        final testNotifications = [
          TestDataFactory.createNotification(id: 'notif-1', title: 'Notification 1'),
          TestDataFactory.createNotification(id: 'notif-2', title: 'Notification 2'),
        ];
        final paginatedResult = TestDataFactory.createPaginatedNotifications(
          notifications: testNotifications,
          total: 2,
          page: 1,
          totalPages: 1,
          unreadCount: 1,
        );

        when(() => mockRepository.getNotifications(
              page: any(named: 'page'),
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => paginatedResult);

        container = TestHelpers.createNotificationsContainer(
          mockNotificationsRepository: mockRepository,
        );

        final notifier = container.read(notificationsProvider.notifier);
        await notifier.loadNotifications();

        final state = container.read(notificationsProvider);
        expect(state, isA<NotificationsLoaded>());
        final loadedState = state as NotificationsLoaded;
        expect(loadedState.notifications.length, equals(2));
        expect(loadedState.total, equals(2));
        expect(loadedState.unreadCount, equals(1));
      });

      test('should set NotificationsError state on failure', () async {
        when(() => mockRepository.getNotifications(
              page: any(named: 'page'),
              limit: any(named: 'limit'),
            )).thenThrow(Exception('Failed to load notifications'));

        container = TestHelpers.createNotificationsContainer(
          mockNotificationsRepository: mockRepository,
        );

        final notifier = container.read(notificationsProvider.notifier);
        await notifier.loadNotifications();

        final state = container.read(notificationsProvider);
        expect(state, isA<NotificationsError>());
      });

      test('should refresh notifications when refresh is true', () async {
        final notifications = [TestDataFactory.createNotification()];

        when(() => mockRepository.getNotifications(
              page: any(named: 'page'),
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => TestDataFactory.createPaginatedNotifications(
              notifications: notifications,
            ));

        container = TestHelpers.createNotificationsContainer(
          mockNotificationsRepository: mockRepository,
        );

        final notifier = container.read(notificationsProvider.notifier);

        // Load initial
        await notifier.loadNotifications();

        // Refresh
        await notifier.loadNotifications(refresh: true);

        verify(() => mockRepository.getNotifications(
              page: any(named: 'page'),
              limit: any(named: 'limit'),
            )).called(2);
      });
    });

    group('loadMore', () {
      test('should append new notifications to existing list', () async {
        final firstBatch = [
          TestDataFactory.createNotification(id: 'notif-1'),
        ];
        final secondBatch = [
          TestDataFactory.createNotification(id: 'notif-2'),
        ];

        when(() => mockRepository.getNotifications(
              page: 1,
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => TestDataFactory.createPaginatedNotifications(
              notifications: firstBatch,
              total: 2,
              page: 1,
              totalPages: 2,
            ));

        when(() => mockRepository.getNotifications(
              page: 2,
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => TestDataFactory.createPaginatedNotifications(
              notifications: secondBatch,
              total: 2,
              page: 2,
              totalPages: 2,
            ));

        container = TestHelpers.createNotificationsContainer(
          mockNotificationsRepository: mockRepository,
        );

        final notifier = container.read(notificationsProvider.notifier);

        // Load first page
        await notifier.loadNotifications();

        var state = container.read(notificationsProvider) as NotificationsLoaded;
        expect(state.notifications.length, equals(1));
        expect(state.hasMore, isTrue);

        // Load more
        await notifier.loadMore();

        state = container.read(notificationsProvider) as NotificationsLoaded;
        expect(state.notifications.length, equals(2));
        expect(state.notifications[0].id, equals('notif-1'));
        expect(state.notifications[1].id, equals('notif-2'));
      });

      test('should not load more when there is no next page', () async {
        when(() => mockRepository.getNotifications(
              page: any(named: 'page'),
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => TestDataFactory.createPaginatedNotifications(
              totalPages: 1,
              page: 1,
            ));

        container = TestHelpers.createNotificationsContainer(
          mockNotificationsRepository: mockRepository,
        );

        final notifier = container.read(notificationsProvider.notifier);
        await notifier.loadNotifications();
        await notifier.loadMore();

        // Should only have called getNotifications once (initial load)
        verify(() => mockRepository.getNotifications(
              page: any(named: 'page'),
              limit: any(named: 'limit'),
            )).called(1);
      });

      test('should set isLoadingMore flag during pagination', () async {
        when(() => mockRepository.getNotifications(
              page: 1,
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => TestDataFactory.createPaginatedNotifications(
              totalPages: 2,
              page: 1,
            ));

        when(() => mockRepository.getNotifications(
              page: 2,
              limit: any(named: 'limit'),
            )).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return TestDataFactory.createPaginatedNotifications(
            totalPages: 2,
            page: 2,
          );
        });

        container = TestHelpers.createNotificationsContainer(
          mockNotificationsRepository: mockRepository,
        );

        final notifier = container.read(notificationsProvider.notifier);
        await notifier.loadNotifications();

        final loadMoreFuture = notifier.loadMore();
        await container.pump();

        var state = container.read(notificationsProvider) as NotificationsLoaded;
        expect(state.isLoadingMore, isTrue);

        await loadMoreFuture;

        state = container.read(notificationsProvider) as NotificationsLoaded;
        expect(state.isLoadingMore, isFalse);
      });
    });

    group('markAsRead', () {
      test('should optimistically update notification as read', () async {
        final unreadNotification = TestDataFactory.createNotification(
          id: 'notif-1',
          isRead: false,
        );

        when(() => mockRepository.getNotifications(
              page: any(named: 'page'),
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => TestDataFactory.createPaginatedNotifications(
              notifications: [unreadNotification],
              unreadCount: 1,
            ));

        when(() => mockRepository.markAsRead(any()))
            .thenAnswer((_) async {});

        container = TestHelpers.createNotificationsContainer(
          mockNotificationsRepository: mockRepository,
        );

        final notifier = container.read(notificationsProvider.notifier);
        await notifier.loadNotifications();

        await notifier.markAsRead('notif-1');

        final state = container.read(notificationsProvider) as NotificationsLoaded;
        expect(state.notifications.first.isRead, isTrue);
        expect(state.unreadCount, equals(0));
      });

      test('should revert on API failure', () async {
        final unreadNotification = TestDataFactory.createNotification(
          id: 'notif-1',
          isRead: false,
        );

        when(() => mockRepository.getNotifications(
              page: any(named: 'page'),
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => TestDataFactory.createPaginatedNotifications(
              notifications: [unreadNotification],
              unreadCount: 1,
            ));

        when(() => mockRepository.markAsRead(any()))
            .thenThrow(Exception('API Error'));

        container = TestHelpers.createNotificationsContainer(
          mockNotificationsRepository: mockRepository,
        );

        final notifier = container.read(notificationsProvider.notifier);
        await notifier.loadNotifications();

        await notifier.markAsRead('notif-1');

        // State should be reverted
        final state = container.read(notificationsProvider) as NotificationsLoaded;
        expect(state.notifications.first.isRead, isFalse);
        expect(state.unreadCount, equals(1));
      });

      test('should call repository markAsRead with correct id', () async {
        final notification = TestDataFactory.createNotification(
          id: 'notif-1',
          isRead: false,
        );

        when(() => mockRepository.getNotifications(
              page: any(named: 'page'),
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => TestDataFactory.createPaginatedNotifications(
              notifications: [notification],
              unreadCount: 1,
            ));

        when(() => mockRepository.markAsRead(any()))
            .thenAnswer((_) async {});

        container = TestHelpers.createNotificationsContainer(
          mockNotificationsRepository: mockRepository,
        );

        final notifier = container.read(notificationsProvider.notifier);
        await notifier.loadNotifications();

        await notifier.markAsRead('notif-1');

        verify(() => mockRepository.markAsRead('notif-1')).called(1);
      });
    });

    group('markAllAsRead', () {
      test('should mark all notifications as read', () async {
        final notifications = [
          TestDataFactory.createNotification(id: 'notif-1', isRead: false),
          TestDataFactory.createNotification(id: 'notif-2', isRead: false),
        ];

        when(() => mockRepository.getNotifications(
              page: any(named: 'page'),
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => TestDataFactory.createPaginatedNotifications(
              notifications: notifications,
              unreadCount: 2,
            ));

        when(() => mockRepository.markAllAsRead())
            .thenAnswer((_) async {});

        container = TestHelpers.createNotificationsContainer(
          mockNotificationsRepository: mockRepository,
        );

        final notifier = container.read(notificationsProvider.notifier);
        await notifier.loadNotifications();

        await notifier.markAllAsRead();

        final state = container.read(notificationsProvider) as NotificationsLoaded;
        expect(state.notifications.every((n) => n.isRead), isTrue);
        expect(state.unreadCount, equals(0));
      });

      test('should not call API when there are no unread notifications', () async {
        final notifications = [
          TestDataFactory.createNotification(id: 'notif-1', isRead: true),
        ];

        when(() => mockRepository.getNotifications(
              page: any(named: 'page'),
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => TestDataFactory.createPaginatedNotifications(
              notifications: notifications,
              unreadCount: 0,
            ));

        container = TestHelpers.createNotificationsContainer(
          mockNotificationsRepository: mockRepository,
        );

        final notifier = container.read(notificationsProvider.notifier);
        await notifier.loadNotifications();

        await notifier.markAllAsRead();

        verifyNever(() => mockRepository.markAllAsRead());
      });

      test('should set isMarkingAllRead flag during operation', () async {
        final notifications = [
          TestDataFactory.createNotification(id: 'notif-1', isRead: false),
        ];

        when(() => mockRepository.getNotifications(
              page: any(named: 'page'),
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => TestDataFactory.createPaginatedNotifications(
              notifications: notifications,
              unreadCount: 1,
            ));

        when(() => mockRepository.markAllAsRead()).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
        });

        container = TestHelpers.createNotificationsContainer(
          mockNotificationsRepository: mockRepository,
        );

        final notifier = container.read(notificationsProvider.notifier);
        await notifier.loadNotifications();

        final markAllFuture = notifier.markAllAsRead();
        await container.pump();

        var state = container.read(notificationsProvider) as NotificationsLoaded;
        expect(state.isMarkingAllRead, isTrue);

        await markAllFuture;

        state = container.read(notificationsProvider) as NotificationsLoaded;
        expect(state.isMarkingAllRead, isFalse);
      });
    });

    group('deleteNotification', () {
      test('should remove notification from list', () async {
        final notifications = [
          TestDataFactory.createNotification(id: 'notif-1'),
          TestDataFactory.createNotification(id: 'notif-2'),
        ];

        when(() => mockRepository.getNotifications(
              page: any(named: 'page'),
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => TestDataFactory.createPaginatedNotifications(
              notifications: notifications,
              total: 2,
            ));

        when(() => mockRepository.deleteNotification(any()))
            .thenAnswer((_) async {});

        container = TestHelpers.createNotificationsContainer(
          mockNotificationsRepository: mockRepository,
        );

        final notifier = container.read(notificationsProvider.notifier);
        await notifier.loadNotifications();

        await notifier.deleteNotification('notif-1');

        final state = container.read(notificationsProvider) as NotificationsLoaded;
        expect(state.notifications.length, equals(1));
        expect(state.notifications.first.id, equals('notif-2'));
        expect(state.total, equals(1));
      });

      test('should update unread count when deleting unread notification', () async {
        final unreadNotification = TestDataFactory.createNotification(
          id: 'notif-1',
          isRead: false,
        );

        when(() => mockRepository.getNotifications(
              page: any(named: 'page'),
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => TestDataFactory.createPaginatedNotifications(
              notifications: [unreadNotification],
              unreadCount: 1,
            ));

        when(() => mockRepository.deleteNotification(any()))
            .thenAnswer((_) async {});

        container = TestHelpers.createNotificationsContainer(
          mockNotificationsRepository: mockRepository,
        );

        final notifier = container.read(notificationsProvider.notifier);
        await notifier.loadNotifications();

        await notifier.deleteNotification('notif-1');

        final state = container.read(notificationsProvider) as NotificationsLoaded;
        expect(state.unreadCount, equals(0));
      });

      test('should set deletingId flag during deletion', () async {
        final notification = TestDataFactory.createNotification(id: 'notif-1');

        when(() => mockRepository.getNotifications(
              page: any(named: 'page'),
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => TestDataFactory.createPaginatedNotifications(
              notifications: [notification],
            ));

        when(() => mockRepository.deleteNotification(any())).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
        });

        container = TestHelpers.createNotificationsContainer(
          mockNotificationsRepository: mockRepository,
        );

        final notifier = container.read(notificationsProvider.notifier);
        await notifier.loadNotifications();

        final deleteFuture = notifier.deleteNotification('notif-1');
        await container.pump();

        var state = container.read(notificationsProvider) as NotificationsLoaded;
        expect(state.deletingId, equals('notif-1'));

        await deleteFuture;

        state = container.read(notificationsProvider) as NotificationsLoaded;
        expect(state.deletingId, isNull);
      });
    });

    group('clearAllNotifications', () {
      test('should clear all notifications', () async {
        final notifications = [
          TestDataFactory.createNotification(id: 'notif-1'),
          TestDataFactory.createNotification(id: 'notif-2'),
        ];

        when(() => mockRepository.getNotifications(
              page: any(named: 'page'),
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => TestDataFactory.createPaginatedNotifications(
              notifications: notifications,
              total: 2,
              unreadCount: 1,
            ));

        when(() => mockRepository.clearAllNotifications())
            .thenAnswer((_) async {});

        container = TestHelpers.createNotificationsContainer(
          mockNotificationsRepository: mockRepository,
        );

        final notifier = container.read(notificationsProvider.notifier);
        await notifier.loadNotifications();

        await notifier.clearAllNotifications();

        final state = container.read(notificationsProvider) as NotificationsLoaded;
        expect(state.notifications, isEmpty);
        expect(state.total, equals(0));
        expect(state.unreadCount, equals(0));
      });

      test('should not call API when list is empty', () async {
        when(() => mockRepository.getNotifications(
              page: any(named: 'page'),
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => TestDataFactory.createPaginatedNotifications(
              notifications: [],
              total: 0,
            ));

        container = TestHelpers.createNotificationsContainer(
          mockNotificationsRepository: mockRepository,
        );

        final notifier = container.read(notificationsProvider.notifier);
        await notifier.loadNotifications();

        await notifier.clearAllNotifications();

        verifyNever(() => mockRepository.clearAllNotifications());
      });
    });

    group('refresh', () {
      test('should call loadNotifications with refresh=true', () async {
        when(() => mockRepository.getNotifications(
              page: any(named: 'page'),
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => TestDataFactory.createPaginatedNotifications());

        container = TestHelpers.createNotificationsContainer(
          mockNotificationsRepository: mockRepository,
        );

        final notifier = container.read(notificationsProvider.notifier);
        await notifier.refresh();

        verify(() => mockRepository.getNotifications(
              page: any(named: 'page'),
              limit: any(named: 'limit'),
            )).called(1);
      });
    });
  });

  group('unreadNotificationsCountProvider', () {
    test('should return unread count from repository', () async {
      when(() => mockRepository.getUnreadCount()).thenAnswer((_) async => 5);

      container = TestHelpers.createNotificationsContainer(
        mockNotificationsRepository: mockRepository,
      );

      // Access the provider to trigger loading
      container.read(unreadNotificationsCountProvider);

      // Wait for the future to complete
      await container.pumpAndSettle();

      final result = container.read(unreadNotificationsCountProvider);
      expect(result.value, equals(5));
    });

    test('should handle error when getting unread count', () async {
      when(() => mockRepository.getUnreadCount())
          .thenThrow(Exception('Failed to get count'));

      container = TestHelpers.createNotificationsContainer(
        mockNotificationsRepository: mockRepository,
      );

      // Wait for the future to complete
      await container.pumpAndSettle();

      final result = container.read(unreadNotificationsCountProvider);
      expect(result.hasError, isTrue);
    });
  });
}
