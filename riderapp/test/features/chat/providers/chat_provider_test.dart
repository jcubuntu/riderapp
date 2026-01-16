import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:riderapp/features/chat/domain/entities/conversation.dart';
import 'package:riderapp/features/chat/presentation/providers/chat_provider.dart';
import 'package:riderapp/features/chat/presentation/providers/chat_state.dart';

import '../../../helpers/mock_classes.dart';
import '../../../helpers/test_helpers.dart';

void main() {
  late MockChatRepository mockRepository;
  late MockSocketService mockSocketService;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValues();
  });

  setUp(() {
    mockRepository = MockChatRepository();
    mockSocketService = MockSocketService();

    // Setup default socket service stubs
    when(() => mockSocketService.on(any(), any())).thenReturn(null);
    when(() => mockSocketService.off(any(), any())).thenReturn(null);
    when(() => mockSocketService.joinConversation(any())).thenReturn(null);
    when(() => mockSocketService.leaveConversation(any())).thenReturn(null);
    when(() => mockSocketService.markMessagesRead(any())).thenReturn(null);
    when(() => mockSocketService.startTyping(any())).thenReturn(null);
    when(() => mockSocketService.stopTyping(any())).thenReturn(null);
    when(() => mockSocketService.sendMessage(
          conversationId: any(named: 'conversationId'),
          content: any(named: 'content'),
        )).thenReturn(null);
  });

  tearDown(() {
    container.dispose();
  });

  group('ConversationsNotifier', () {
    group('Initial State', () {
      test('should start with ConversationsInitial state', () {
        container = TestHelpers.createChatContainer(
          mockChatRepository: mockRepository,
          mockSocketService: mockSocketService,
        );

        final state = container.read(conversationsProvider);
        expect(state, isA<ConversationsInitial>());
      });
    });

    group('loadConversations', () {
      test('should set ConversationsLoading state when loading starts', () async {
        when(() => mockRepository.getConversations(
              page: any(named: 'page'),
              limit: any(named: 'limit'),
            )).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return TestDataFactory.createPaginatedConversations();
        });

        container = TestHelpers.createChatContainer(
          mockChatRepository: mockRepository,
          mockSocketService: mockSocketService,
        );

        final notifier = container.read(conversationsProvider.notifier);

        // Start loading but don't await
        final loadFuture = notifier.loadConversations();

        // Check loading state immediately
        await container.pump();
        expect(container.read(conversationsProvider), isA<ConversationsLoading>());

        await loadFuture;
      });

      test('should set ConversationsLoaded state with conversations on success', () async {
        final testConversations = [
          TestDataFactory.createConversation(id: 'conv-1', title: 'Conversation 1'),
          TestDataFactory.createConversation(id: 'conv-2', title: 'Conversation 2'),
        ];
        final paginatedResult = TestDataFactory.createPaginatedConversations(
          conversations: testConversations,
          total: 2,
          page: 1,
          totalPages: 1,
        );

        when(() => mockRepository.getConversations(
              page: any(named: 'page'),
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => paginatedResult);

        container = TestHelpers.createChatContainer(
          mockChatRepository: mockRepository,
          mockSocketService: mockSocketService,
        );

        final notifier = container.read(conversationsProvider.notifier);
        await notifier.loadConversations();

        final state = container.read(conversationsProvider);
        expect(state, isA<ConversationsLoaded>());
        final loadedState = state as ConversationsLoaded;
        expect(loadedState.conversations.length, equals(2));
        expect(loadedState.total, equals(2));
      });

      test('should set ConversationsError state on failure', () async {
        when(() => mockRepository.getConversations(
              page: any(named: 'page'),
              limit: any(named: 'limit'),
            )).thenThrow(Exception('Failed to load conversations'));

        container = TestHelpers.createChatContainer(
          mockChatRepository: mockRepository,
          mockSocketService: mockSocketService,
        );

        final notifier = container.read(conversationsProvider.notifier);
        await notifier.loadConversations();

        final state = container.read(conversationsProvider);
        expect(state, isA<ConversationsError>());
      });

      test('should refresh conversations when refresh is true', () async {
        final conversations = [TestDataFactory.createConversation()];

        when(() => mockRepository.getConversations(
              page: any(named: 'page'),
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => TestDataFactory.createPaginatedConversations(
              conversations: conversations,
            ));

        container = TestHelpers.createChatContainer(
          mockChatRepository: mockRepository,
          mockSocketService: mockSocketService,
        );

        final notifier = container.read(conversationsProvider.notifier);

        // Load initial
        await notifier.loadConversations();

        // Refresh
        await notifier.loadConversations(refresh: true);

        verify(() => mockRepository.getConversations(
              page: any(named: 'page'),
              limit: any(named: 'limit'),
            )).called(2);
      });
    });

    group('loadMore', () {
      test('should append new conversations to existing list', () async {
        final firstBatch = [
          TestDataFactory.createConversation(id: 'conv-1'),
        ];
        final secondBatch = [
          TestDataFactory.createConversation(id: 'conv-2'),
        ];

        when(() => mockRepository.getConversations(
              page: 1,
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => TestDataFactory.createPaginatedConversations(
              conversations: firstBatch,
              total: 2,
              page: 1,
              totalPages: 2,
            ));

        when(() => mockRepository.getConversations(
              page: 2,
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => TestDataFactory.createPaginatedConversations(
              conversations: secondBatch,
              total: 2,
              page: 2,
              totalPages: 2,
            ));

        container = TestHelpers.createChatContainer(
          mockChatRepository: mockRepository,
          mockSocketService: mockSocketService,
        );

        final notifier = container.read(conversationsProvider.notifier);

        // Load first page
        await notifier.loadConversations();

        var state = container.read(conversationsProvider) as ConversationsLoaded;
        expect(state.conversations.length, equals(1));
        expect(state.hasMore, isTrue);

        // Load more
        await notifier.loadMore();

        state = container.read(conversationsProvider) as ConversationsLoaded;
        expect(state.conversations.length, equals(2));
      });

      test('should not load more when there is no next page', () async {
        when(() => mockRepository.getConversations(
              page: any(named: 'page'),
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => TestDataFactory.createPaginatedConversations(
              totalPages: 1,
              page: 1,
            ));

        container = TestHelpers.createChatContainer(
          mockChatRepository: mockRepository,
          mockSocketService: mockSocketService,
        );

        final notifier = container.read(conversationsProvider.notifier);
        await notifier.loadConversations();
        await notifier.loadMore();

        // Should only have called getConversations once (initial load)
        verify(() => mockRepository.getConversations(
              page: any(named: 'page'),
              limit: any(named: 'limit'),
            )).called(1);
      });
    });

    group('updateConversation', () {
      test('should update conversation with new last message', () async {
        final conversation = TestDataFactory.createConversation(id: 'conv-1');

        when(() => mockRepository.getConversations(
              page: any(named: 'page'),
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => TestDataFactory.createPaginatedConversations(
              conversations: [conversation],
            ));

        container = TestHelpers.createChatContainer(
          mockChatRepository: mockRepository,
          mockSocketService: mockSocketService,
        );

        final notifier = container.read(conversationsProvider.notifier);
        await notifier.loadConversations();

        final newMessage = TestDataFactory.createMessage(
          id: 'msg-1',
          conversationId: 'conv-1',
          content: 'New message',
        );

        notifier.updateConversation('conv-1', newMessage);

        final state = container.read(conversationsProvider) as ConversationsLoaded;
        expect(state.conversations.first.lastMessage?.content, equals('New message'));
      });

      test('should sort conversations by updated time after update', () async {
        final now = DateTime.now();
        final conversations = [
          TestDataFactory.createConversation(
            id: 'conv-1',
            updatedAt: now.subtract(const Duration(hours: 1)),
          ),
          TestDataFactory.createConversation(
            id: 'conv-2',
            updatedAt: now.subtract(const Duration(hours: 2)),
          ),
        ];

        when(() => mockRepository.getConversations(
              page: any(named: 'page'),
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => TestDataFactory.createPaginatedConversations(
              conversations: conversations,
            ));

        container = TestHelpers.createChatContainer(
          mockChatRepository: mockRepository,
          mockSocketService: mockSocketService,
        );

        final notifier = container.read(conversationsProvider.notifier);
        await notifier.loadConversations();

        // Send message to conv-2, making it the most recent
        final newMessage = TestDataFactory.createMessage(
          id: 'msg-1',
          conversationId: 'conv-2',
          sentAt: now,
        );

        notifier.updateConversation('conv-2', newMessage);

        final state = container.read(conversationsProvider) as ConversationsLoaded;
        expect(state.conversations.first.id, equals('conv-2'));
      });
    });

    group('removeConversation', () {
      test('should remove conversation from the list', () async {
        final conversations = [
          TestDataFactory.createConversation(id: 'conv-1'),
          TestDataFactory.createConversation(id: 'conv-2'),
        ];

        when(() => mockRepository.getConversations(
              page: any(named: 'page'),
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => TestDataFactory.createPaginatedConversations(
              conversations: conversations,
              total: 2,
            ));

        container = TestHelpers.createChatContainer(
          mockChatRepository: mockRepository,
          mockSocketService: mockSocketService,
        );

        final notifier = container.read(conversationsProvider.notifier);
        await notifier.loadConversations();

        notifier.removeConversation('conv-1');

        final state = container.read(conversationsProvider) as ConversationsLoaded;
        expect(state.conversations.length, equals(1));
        expect(state.conversations.first.id, equals('conv-2'));
        expect(state.total, equals(1));
      });
    });
  });

  group('ChatMessagesNotifier', () {
    late String testConversationId;
    late Conversation testConversation;

    setUp(() {
      testConversationId = 'conv-1';
      testConversation = TestDataFactory.createConversation(id: testConversationId);
    });

    group('Initial State and Loading', () {
      test('should load messages on initialization', () async {
        final messages = [TestDataFactory.createMessage()];

        when(() => mockRepository.getConversationById(any()))
            .thenAnswer((_) async => testConversation);
        when(() => mockRepository.getMessages(any(), page: any(named: 'page'), limit: any(named: 'limit')))
            .thenAnswer((_) async => TestDataFactory.createPaginatedMessages(
                  messages: messages,
                ));
        when(() => mockRepository.markAsRead(any())).thenAnswer((_) async {});

        container = TestHelpers.createChatContainer(
          mockChatRepository: mockRepository,
          mockSocketService: mockSocketService,
        );

        // The notifier loads messages in constructor, so wait for it
        await container.pumpAndSettle();

        final state = container.read(chatMessagesProvider(testConversationId));
        expect(state, isA<ChatMessagesLoaded>());
      });

      test('should set ChatMessagesError state on load failure', () async {
        when(() => mockRepository.getConversationById(any()))
            .thenThrow(Exception('Failed to load conversation'));

        container = TestHelpers.createChatContainer(
          mockChatRepository: mockRepository,
          mockSocketService: mockSocketService,
        );

        await container.pumpAndSettle();

        final state = container.read(chatMessagesProvider(testConversationId));
        expect(state, isA<ChatMessagesError>());
      });
    });

    group('loadMore', () {
      test('should prepend older messages to the list', () async {
        final firstBatch = [TestDataFactory.createMessage(id: 'msg-1')];
        final olderBatch = [TestDataFactory.createMessage(id: 'msg-older')];

        when(() => mockRepository.getConversationById(any()))
            .thenAnswer((_) async => testConversation);
        when(() => mockRepository.getMessages(any(), page: 1, limit: any(named: 'limit')))
            .thenAnswer((_) async => TestDataFactory.createPaginatedMessages(
                  messages: firstBatch,
                  page: 1,
                  totalPages: 2,
                ));
        when(() => mockRepository.getMessages(any(), page: 2, limit: any(named: 'limit')))
            .thenAnswer((_) async => TestDataFactory.createPaginatedMessages(
                  messages: olderBatch,
                  page: 2,
                  totalPages: 2,
                ));
        when(() => mockRepository.markAsRead(any())).thenAnswer((_) async {});

        container = TestHelpers.createChatContainer(
          mockChatRepository: mockRepository,
          mockSocketService: mockSocketService,
        );

        await container.pumpAndSettle();

        final notifier = container.read(chatMessagesProvider(testConversationId).notifier);
        await notifier.loadMore();

        final state = container.read(chatMessagesProvider(testConversationId)) as ChatMessagesLoaded;
        expect(state.messages.length, equals(2));
        // Older messages should be at the beginning
        expect(state.messages.first.id, equals('msg-older'));
      });
    });

    group('sendMessage', () {
      test('should add sent message to the list', () async {
        final existingMessages = [TestDataFactory.createMessage(id: 'msg-existing')];
        final sentMessage = TestDataFactory.createMessage(
          id: 'msg-sent',
          content: 'Hello!',
        );

        when(() => mockRepository.getConversationById(any()))
            .thenAnswer((_) async => testConversation);
        when(() => mockRepository.getMessages(any(), page: any(named: 'page'), limit: any(named: 'limit')))
            .thenAnswer((_) async => TestDataFactory.createPaginatedMessages(
                  messages: existingMessages,
                ));
        when(() => mockRepository.markAsRead(any())).thenAnswer((_) async {});
        when(() => mockRepository.sendMessage(
              any(),
              content: any(named: 'content'),
              type: any(named: 'type'),
            )).thenAnswer((_) async => sentMessage);

        container = TestHelpers.createChatContainer(
          mockChatRepository: mockRepository,
          mockSocketService: mockSocketService,
        );

        await container.pumpAndSettle();

        final notifier = container.read(chatMessagesProvider(testConversationId).notifier);
        await notifier.sendMessage('Hello!');

        final state = container.read(chatMessagesProvider(testConversationId)) as ChatMessagesLoaded;
        expect(state.messages.length, equals(2));
        expect(state.messages.last.content, equals('Hello!'));
      });

      test('should not send empty messages', () async {
        when(() => mockRepository.getConversationById(any()))
            .thenAnswer((_) async => testConversation);
        when(() => mockRepository.getMessages(any(), page: any(named: 'page'), limit: any(named: 'limit')))
            .thenAnswer((_) async => TestDataFactory.createPaginatedMessages());
        when(() => mockRepository.markAsRead(any())).thenAnswer((_) async {});

        container = TestHelpers.createChatContainer(
          mockChatRepository: mockRepository,
          mockSocketService: mockSocketService,
        );

        await container.pumpAndSettle();

        final notifier = container.read(chatMessagesProvider(testConversationId).notifier);
        await notifier.sendMessage('   '); // Empty after trim

        verifyNever(() => mockRepository.sendMessage(
              any(),
              content: any(named: 'content'),
              type: any(named: 'type'),
            ));
      });

      test('should set isSending flag during send', () async {
        when(() => mockRepository.getConversationById(any()))
            .thenAnswer((_) async => testConversation);
        when(() => mockRepository.getMessages(any(), page: any(named: 'page'), limit: any(named: 'limit')))
            .thenAnswer((_) async => TestDataFactory.createPaginatedMessages());
        when(() => mockRepository.markAsRead(any())).thenAnswer((_) async {});
        when(() => mockRepository.sendMessage(
              any(),
              content: any(named: 'content'),
              type: any(named: 'type'),
            )).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return TestDataFactory.createMessage();
        });

        container = TestHelpers.createChatContainer(
          mockChatRepository: mockRepository,
          mockSocketService: mockSocketService,
        );

        await container.pumpAndSettle();

        final notifier = container.read(chatMessagesProvider(testConversationId).notifier);
        final sendFuture = notifier.sendMessage('Hello!');
        await container.pump();

        var state = container.read(chatMessagesProvider(testConversationId)) as ChatMessagesLoaded;
        expect(state.isSending, isTrue);

        await sendFuture;

        state = container.read(chatMessagesProvider(testConversationId)) as ChatMessagesLoaded;
        expect(state.isSending, isFalse);
      });

      test('should also emit message via socket for real-time delivery', () async {
        final sentMessage = TestDataFactory.createMessage(content: 'Test message');

        when(() => mockRepository.getConversationById(any()))
            .thenAnswer((_) async => testConversation);
        when(() => mockRepository.getMessages(any(), page: any(named: 'page'), limit: any(named: 'limit')))
            .thenAnswer((_) async => TestDataFactory.createPaginatedMessages());
        when(() => mockRepository.markAsRead(any())).thenAnswer((_) async {});
        when(() => mockRepository.sendMessage(
              any(),
              content: any(named: 'content'),
              type: any(named: 'type'),
            )).thenAnswer((_) async => sentMessage);

        container = TestHelpers.createChatContainer(
          mockChatRepository: mockRepository,
          mockSocketService: mockSocketService,
        );

        await container.pumpAndSettle();

        final notifier = container.read(chatMessagesProvider(testConversationId).notifier);
        await notifier.sendMessage('Test message');

        verify(() => mockSocketService.sendMessage(
              conversationId: testConversationId,
              content: 'Test message',
            )).called(1);
      });
    });

    group('addReceivedMessage', () {
      test('should add received message to the list', () async {
        final existingMessages = [TestDataFactory.createMessage(id: 'msg-1')];

        when(() => mockRepository.getConversationById(any()))
            .thenAnswer((_) async => testConversation);
        when(() => mockRepository.getMessages(any(), page: any(named: 'page'), limit: any(named: 'limit')))
            .thenAnswer((_) async => TestDataFactory.createPaginatedMessages(
                  messages: existingMessages,
                ));
        when(() => mockRepository.markAsRead(any())).thenAnswer((_) async {});

        container = TestHelpers.createChatContainer(
          mockChatRepository: mockRepository,
          mockSocketService: mockSocketService,
        );

        await container.pumpAndSettle();

        final notifier = container.read(chatMessagesProvider(testConversationId).notifier);
        final receivedMessage = TestDataFactory.createMessage(
          id: 'msg-received',
          content: 'Received message',
        );

        notifier.addReceivedMessage(receivedMessage);

        final state = container.read(chatMessagesProvider(testConversationId)) as ChatMessagesLoaded;
        expect(state.messages.length, equals(2));
        expect(state.messages.last.id, equals('msg-received'));
      });

      test('should not add duplicate messages', () async {
        final existingMessage = TestDataFactory.createMessage(id: 'msg-1');

        when(() => mockRepository.getConversationById(any()))
            .thenAnswer((_) async => testConversation);
        when(() => mockRepository.getMessages(any(), page: any(named: 'page'), limit: any(named: 'limit')))
            .thenAnswer((_) async => TestDataFactory.createPaginatedMessages(
                  messages: [existingMessage],
                ));
        when(() => mockRepository.markAsRead(any())).thenAnswer((_) async {});

        container = TestHelpers.createChatContainer(
          mockChatRepository: mockRepository,
          mockSocketService: mockSocketService,
        );

        await container.pumpAndSettle();

        final notifier = container.read(chatMessagesProvider(testConversationId).notifier);

        // Try to add the same message again
        notifier.addReceivedMessage(existingMessage);

        final state = container.read(chatMessagesProvider(testConversationId)) as ChatMessagesLoaded;
        expect(state.messages.length, equals(1));
      });
    });

    group('Socket Integration', () {
      test('should join conversation room on initialization', () async {
        when(() => mockRepository.getConversationById(any()))
            .thenAnswer((_) async => testConversation);
        when(() => mockRepository.getMessages(any(), page: any(named: 'page'), limit: any(named: 'limit')))
            .thenAnswer((_) async => TestDataFactory.createPaginatedMessages());
        when(() => mockRepository.markAsRead(any())).thenAnswer((_) async {});

        container = TestHelpers.createChatContainer(
          mockChatRepository: mockRepository,
          mockSocketService: mockSocketService,
        );

        // Access the provider to trigger initialization
        container.read(chatMessagesProvider(testConversationId));

        await container.pumpAndSettle();

        verify(() => mockSocketService.joinConversation(testConversationId)).called(1);
      });

      test('should mark as read when loading messages', () async {
        when(() => mockRepository.getConversationById(any()))
            .thenAnswer((_) async => testConversation);
        when(() => mockRepository.getMessages(any(), page: any(named: 'page'), limit: any(named: 'limit')))
            .thenAnswer((_) async => TestDataFactory.createPaginatedMessages());
        when(() => mockRepository.markAsRead(any())).thenAnswer((_) async {});

        container = TestHelpers.createChatContainer(
          mockChatRepository: mockRepository,
          mockSocketService: mockSocketService,
        );

        // Trigger the provider
        container.read(chatMessagesProvider(testConversationId));

        await container.pumpAndSettle();

        verify(() => mockRepository.markAsRead(testConversationId)).called(1);
      });
    });
  });

  group('unreadMessagesCountProvider', () {
    test('should return unread count from repository', () async {
      when(() => mockRepository.getUnreadCount()).thenAnswer((_) async => 5);

      container = TestHelpers.createChatContainer(
        mockChatRepository: mockRepository,
        mockSocketService: mockSocketService,
      );

      // Wait for the future to complete
      await container.pumpAndSettle();

      final result = container.read(unreadMessagesCountProvider);
      expect(result.value, equals(5));
    });

    test('should handle error when getting unread count', () async {
      when(() => mockRepository.getUnreadCount())
          .thenThrow(Exception('Failed to get count'));

      container = TestHelpers.createChatContainer(
        mockChatRepository: mockRepository,
        mockSocketService: mockSocketService,
      );

      // Wait for the future to complete
      await container.pumpAndSettle();

      final result = container.read(unreadMessagesCountProvider);
      expect(result.hasError, isTrue);
    });
  });
}
