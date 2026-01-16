import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:riderapp/features/incidents/domain/entities/incident.dart';
import 'package:riderapp/features/incidents/data/datasources/incidents_remote_datasource.dart';
import 'package:riderapp/features/incidents/presentation/providers/incidents_provider.dart';
import 'package:riderapp/features/incidents/presentation/providers/incidents_state.dart';

import '../../../helpers/mock_classes.dart';
import '../../../helpers/test_helpers.dart';

void main() {
  late MockIncidentsRepository mockRepository;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValues();
  });

  setUp(() {
    mockRepository = MockIncidentsRepository();
  });

  tearDown(() {
    container.dispose();
  });

  group('IncidentsListNotifier', () {
    group('Initial State', () {
      test('should start with IncidentsListInitial state', () {
        container = TestHelpers.createIncidentsContainer(
          mockIncidentsRepository: mockRepository,
        );

        final state = container.read(incidentsListProvider);
        expect(state, isA<IncidentsListInitial>());
      });
    });

    group('loadIncidents', () {
      test('should set IncidentsListLoading state when loading starts', () async {
        when(() => mockRepository.getIncidents(
              page: any(named: 'page'),
              limit: any(named: 'limit'),
              search: any(named: 'search'),
              category: any(named: 'category'),
              status: any(named: 'status'),
              priority: any(named: 'priority'),
              province: any(named: 'province'),
              assignedTo: any(named: 'assignedTo'),
              reportedBy: any(named: 'reportedBy'),
            )).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return TestDataFactory.createPaginatedIncidents();
        });

        container = TestHelpers.createIncidentsContainer(
          mockIncidentsRepository: mockRepository,
        );

        final notifier = container.read(incidentsListProvider.notifier);

        // Start loading but don't await
        final loadFuture = notifier.loadIncidents();

        // Check loading state immediately
        await container.pump();
        expect(container.read(incidentsListProvider), isA<IncidentsListLoading>());

        await loadFuture;
      });

      test('should set IncidentsListLoaded state with incidents on success', () async {
        final testIncidents = [
          TestDataFactory.createIncident(id: 'incident-1', title: 'Incident 1'),
          TestDataFactory.createIncident(id: 'incident-2', title: 'Incident 2'),
        ];
        final paginatedResult = TestDataFactory.createPaginatedIncidents(
          incidents: testIncidents,
          total: 2,
          page: 1,
          totalPages: 1,
        );

        when(() => mockRepository.getIncidents(
              page: any(named: 'page'),
              limit: any(named: 'limit'),
              search: any(named: 'search'),
              category: any(named: 'category'),
              status: any(named: 'status'),
              priority: any(named: 'priority'),
              province: any(named: 'province'),
              assignedTo: any(named: 'assignedTo'),
              reportedBy: any(named: 'reportedBy'),
            )).thenAnswer((_) async => paginatedResult);

        container = TestHelpers.createIncidentsContainer(
          mockIncidentsRepository: mockRepository,
        );

        final notifier = container.read(incidentsListProvider.notifier);
        await notifier.loadIncidents();

        final state = container.read(incidentsListProvider);
        expect(state, isA<IncidentsListLoaded>());
        final loadedState = state as IncidentsListLoaded;
        expect(loadedState.incidents.length, equals(2));
        expect(loadedState.total, equals(2));
        expect(loadedState.page, equals(1));
      });

      test('should set IncidentsListError state on failure', () async {
        when(() => mockRepository.getIncidents(
              page: any(named: 'page'),
              limit: any(named: 'limit'),
              search: any(named: 'search'),
              category: any(named: 'category'),
              status: any(named: 'status'),
              priority: any(named: 'priority'),
              province: any(named: 'province'),
              assignedTo: any(named: 'assignedTo'),
              reportedBy: any(named: 'reportedBy'),
            )).thenThrow(IncidentsException(message: 'Failed to load incidents'));

        container = TestHelpers.createIncidentsContainer(
          mockIncidentsRepository: mockRepository,
        );

        final notifier = container.read(incidentsListProvider.notifier);
        await notifier.loadIncidents();

        final state = container.read(incidentsListProvider);
        expect(state, isA<IncidentsListError>());
        expect((state as IncidentsListError).message, equals('Failed to load incidents'));
      });

      test('should pass filter parameters to repository', () async {
        when(() => mockRepository.getIncidents(
              page: any(named: 'page'),
              limit: any(named: 'limit'),
              search: any(named: 'search'),
              category: any(named: 'category'),
              status: any(named: 'status'),
              priority: any(named: 'priority'),
              province: any(named: 'province'),
              assignedTo: any(named: 'assignedTo'),
              reportedBy: any(named: 'reportedBy'),
            )).thenAnswer((_) async => TestDataFactory.createPaginatedIncidents());

        container = TestHelpers.createIncidentsContainer(
          mockIncidentsRepository: mockRepository,
        );

        final notifier = container.read(incidentsListProvider.notifier);
        await notifier.loadIncidents(
          search: 'test search',
          category: IncidentCategory.accident,
          status: IncidentStatus.pending,
          priority: IncidentPriority.high,
        );

        verify(() => mockRepository.getIncidents(
              page: 1,
              limit: 10,
              search: 'test search',
              category: IncidentCategory.accident,
              status: IncidentStatus.pending,
              priority: IncidentPriority.high,
              province: null,
              assignedTo: null,
              reportedBy: null,
            )).called(1);
      });
    });

    group('loadMore', () {
      test('should append new incidents to existing list', () async {
        final firstBatch = [
          TestDataFactory.createIncident(id: 'incident-1'),
        ];
        final secondBatch = [
          TestDataFactory.createIncident(id: 'incident-2'),
        ];

        when(() => mockRepository.getIncidents(
              page: 1,
              limit: any(named: 'limit'),
              search: any(named: 'search'),
              category: any(named: 'category'),
              status: any(named: 'status'),
              priority: any(named: 'priority'),
              province: any(named: 'province'),
              assignedTo: any(named: 'assignedTo'),
              reportedBy: any(named: 'reportedBy'),
            )).thenAnswer((_) async => TestDataFactory.createPaginatedIncidents(
              incidents: firstBatch,
              total: 2,
              page: 1,
              totalPages: 2,
            ));

        when(() => mockRepository.getIncidents(
              page: 2,
              limit: any(named: 'limit'),
              search: any(named: 'search'),
              category: any(named: 'category'),
              status: any(named: 'status'),
              priority: any(named: 'priority'),
              province: any(named: 'province'),
              assignedTo: any(named: 'assignedTo'),
              reportedBy: any(named: 'reportedBy'),
            )).thenAnswer((_) async => TestDataFactory.createPaginatedIncidents(
              incidents: secondBatch,
              total: 2,
              page: 2,
              totalPages: 2,
            ));

        container = TestHelpers.createIncidentsContainer(
          mockIncidentsRepository: mockRepository,
        );

        final notifier = container.read(incidentsListProvider.notifier);

        // Load first page
        await notifier.loadIncidents();

        var state = container.read(incidentsListProvider) as IncidentsListLoaded;
        expect(state.incidents.length, equals(1));
        expect(state.hasNextPage, isTrue);

        // Load more
        await notifier.loadMore();

        state = container.read(incidentsListProvider) as IncidentsListLoaded;
        expect(state.incidents.length, equals(2));
        expect(state.incidents[0].id, equals('incident-1'));
        expect(state.incidents[1].id, equals('incident-2'));
      });

      test('should not load more when there is no next page', () async {
        when(() => mockRepository.getIncidents(
              page: any(named: 'page'),
              limit: any(named: 'limit'),
              search: any(named: 'search'),
              category: any(named: 'category'),
              status: any(named: 'status'),
              priority: any(named: 'priority'),
              province: any(named: 'province'),
              assignedTo: any(named: 'assignedTo'),
              reportedBy: any(named: 'reportedBy'),
            )).thenAnswer((_) async => TestDataFactory.createPaginatedIncidents(
              totalPages: 1,
              page: 1,
            ));

        container = TestHelpers.createIncidentsContainer(
          mockIncidentsRepository: mockRepository,
        );

        final notifier = container.read(incidentsListProvider.notifier);
        await notifier.loadIncidents();
        await notifier.loadMore();

        // Should only have called getIncidents once (initial load)
        verify(() => mockRepository.getIncidents(
              page: any(named: 'page'),
              limit: any(named: 'limit'),
              search: any(named: 'search'),
              category: any(named: 'category'),
              status: any(named: 'status'),
              priority: any(named: 'priority'),
              province: any(named: 'province'),
              assignedTo: any(named: 'assignedTo'),
              reportedBy: any(named: 'reportedBy'),
            )).called(1);
      });

      test('should set isLoadingMore flag during pagination', () async {
        when(() => mockRepository.getIncidents(
              page: 1,
              limit: any(named: 'limit'),
              search: any(named: 'search'),
              category: any(named: 'category'),
              status: any(named: 'status'),
              priority: any(named: 'priority'),
              province: any(named: 'province'),
              assignedTo: any(named: 'assignedTo'),
              reportedBy: any(named: 'reportedBy'),
            )).thenAnswer((_) async => TestDataFactory.createPaginatedIncidents(
              totalPages: 2,
              page: 1,
            ));

        when(() => mockRepository.getIncidents(
              page: 2,
              limit: any(named: 'limit'),
              search: any(named: 'search'),
              category: any(named: 'category'),
              status: any(named: 'status'),
              priority: any(named: 'priority'),
              province: any(named: 'province'),
              assignedTo: any(named: 'assignedTo'),
              reportedBy: any(named: 'reportedBy'),
            )).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return TestDataFactory.createPaginatedIncidents(
            totalPages: 2,
            page: 2,
          );
        });

        container = TestHelpers.createIncidentsContainer(
          mockIncidentsRepository: mockRepository,
        );

        final notifier = container.read(incidentsListProvider.notifier);
        await notifier.loadIncidents();

        final loadMoreFuture = notifier.loadMore();
        await container.pump();

        var state = container.read(incidentsListProvider) as IncidentsListLoaded;
        expect(state.isLoadingMore, isTrue);

        await loadMoreFuture;

        state = container.read(incidentsListProvider) as IncidentsListLoaded;
        expect(state.isLoadingMore, isFalse);
      });
    });

    group('applyFilters', () {
      test('should reload incidents with new filters', () async {
        when(() => mockRepository.getIncidents(
              page: any(named: 'page'),
              limit: any(named: 'limit'),
              search: any(named: 'search'),
              category: any(named: 'category'),
              status: any(named: 'status'),
              priority: any(named: 'priority'),
              province: any(named: 'province'),
              assignedTo: any(named: 'assignedTo'),
              reportedBy: any(named: 'reportedBy'),
            )).thenAnswer((_) async => TestDataFactory.createPaginatedIncidents());

        container = TestHelpers.createIncidentsContainer(
          mockIncidentsRepository: mockRepository,
        );

        final notifier = container.read(incidentsListProvider.notifier);

        await notifier.applyFilters(
          category: IncidentCategory.accident,
          status: IncidentStatus.resolved,
        );

        final state = container.read(incidentsListProvider) as IncidentsListLoaded;
        expect(state.filterCategory, equals(IncidentCategory.accident));
        expect(state.filterStatus, equals(IncidentStatus.resolved));
      });
    });

    group('clearFilters', () {
      test('should reload incidents without filters', () async {
        when(() => mockRepository.getIncidents(
              page: any(named: 'page'),
              limit: any(named: 'limit'),
              search: any(named: 'search'),
              category: any(named: 'category'),
              status: any(named: 'status'),
              priority: any(named: 'priority'),
              province: any(named: 'province'),
              assignedTo: any(named: 'assignedTo'),
              reportedBy: any(named: 'reportedBy'),
            )).thenAnswer((_) async => TestDataFactory.createPaginatedIncidents());

        container = TestHelpers.createIncidentsContainer(
          mockIncidentsRepository: mockRepository,
        );

        final notifier = container.read(incidentsListProvider.notifier);

        // Apply filters first
        await notifier.applyFilters(category: IncidentCategory.accident);

        // Clear filters
        await notifier.clearFilters();

        final state = container.read(incidentsListProvider) as IncidentsListLoaded;
        expect(state.filterCategory, isNull);
        expect(state.filterStatus, isNull);
        expect(state.filterPriority, isNull);
      });
    });

    group('updateIncidentInList', () {
      test('should update incident in the list', () async {
        final incident = TestDataFactory.createIncident(
          id: 'incident-1',
          title: 'Original Title',
        );

        when(() => mockRepository.getIncidents(
              page: any(named: 'page'),
              limit: any(named: 'limit'),
              search: any(named: 'search'),
              category: any(named: 'category'),
              status: any(named: 'status'),
              priority: any(named: 'priority'),
              province: any(named: 'province'),
              assignedTo: any(named: 'assignedTo'),
              reportedBy: any(named: 'reportedBy'),
            )).thenAnswer((_) async => TestDataFactory.createPaginatedIncidents(
              incidents: [incident],
            ));

        container = TestHelpers.createIncidentsContainer(
          mockIncidentsRepository: mockRepository,
        );

        final notifier = container.read(incidentsListProvider.notifier);
        await notifier.loadIncidents();

        final updatedIncident = incident.copyWith(title: 'Updated Title');
        notifier.updateIncidentInList(updatedIncident);

        final state = container.read(incidentsListProvider) as IncidentsListLoaded;
        expect(state.incidents.first.title, equals('Updated Title'));
      });
    });

    group('removeIncidentFromList', () {
      test('should remove incident from the list', () async {
        final incidents = [
          TestDataFactory.createIncident(id: 'incident-1'),
          TestDataFactory.createIncident(id: 'incident-2'),
        ];

        when(() => mockRepository.getIncidents(
              page: any(named: 'page'),
              limit: any(named: 'limit'),
              search: any(named: 'search'),
              category: any(named: 'category'),
              status: any(named: 'status'),
              priority: any(named: 'priority'),
              province: any(named: 'province'),
              assignedTo: any(named: 'assignedTo'),
              reportedBy: any(named: 'reportedBy'),
            )).thenAnswer((_) async => TestDataFactory.createPaginatedIncidents(
              incidents: incidents,
              total: 2,
            ));

        container = TestHelpers.createIncidentsContainer(
          mockIncidentsRepository: mockRepository,
        );

        final notifier = container.read(incidentsListProvider.notifier);
        await notifier.loadIncidents();

        notifier.removeIncidentFromList('incident-1');

        final state = container.read(incidentsListProvider) as IncidentsListLoaded;
        expect(state.incidents.length, equals(1));
        expect(state.incidents.first.id, equals('incident-2'));
        expect(state.total, equals(1));
      });
    });

    group('addIncidentToList', () {
      test('should add incident to the beginning of the list', () async {
        final existingIncident = TestDataFactory.createIncident(id: 'incident-1');

        when(() => mockRepository.getIncidents(
              page: any(named: 'page'),
              limit: any(named: 'limit'),
              search: any(named: 'search'),
              category: any(named: 'category'),
              status: any(named: 'status'),
              priority: any(named: 'priority'),
              province: any(named: 'province'),
              assignedTo: any(named: 'assignedTo'),
              reportedBy: any(named: 'reportedBy'),
            )).thenAnswer((_) async => TestDataFactory.createPaginatedIncidents(
              incidents: [existingIncident],
              total: 1,
            ));

        container = TestHelpers.createIncidentsContainer(
          mockIncidentsRepository: mockRepository,
        );

        final notifier = container.read(incidentsListProvider.notifier);
        await notifier.loadIncidents();

        final newIncident = TestDataFactory.createIncident(id: 'incident-new');
        notifier.addIncidentToList(newIncident);

        final state = container.read(incidentsListProvider) as IncidentsListLoaded;
        expect(state.incidents.length, equals(2));
        expect(state.incidents.first.id, equals('incident-new'));
        expect(state.total, equals(2));
      });
    });
  });

  group('myIncidentsListProvider', () {
    test('should call getMyIncidents instead of getIncidents', () async {
      when(() => mockRepository.getMyIncidents(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            search: any(named: 'search'),
            category: any(named: 'category'),
            status: any(named: 'status'),
            priority: any(named: 'priority'),
          )).thenAnswer((_) async => TestDataFactory.createPaginatedIncidents());

      container = TestHelpers.createIncidentsContainer(
        mockIncidentsRepository: mockRepository,
      );

      final notifier = container.read(myIncidentsListProvider.notifier);
      await notifier.loadIncidents();

      verify(() => mockRepository.getMyIncidents(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            search: any(named: 'search'),
            category: any(named: 'category'),
            status: any(named: 'status'),
            priority: any(named: 'priority'),
          )).called(1);

      verifyNever(() => mockRepository.getIncidents(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            search: any(named: 'search'),
            category: any(named: 'category'),
            status: any(named: 'status'),
            priority: any(named: 'priority'),
            province: any(named: 'province'),
            assignedTo: any(named: 'assignedTo'),
            reportedBy: any(named: 'reportedBy'),
          ));
    });
  });

  group('CreateIncidentNotifier', () {
    group('createIncident', () {
      test('should set CreateIncidentSuccess state on successful creation', () async {
        final newIncident = TestDataFactory.createIncident(id: 'new-incident');

        when(() => mockRepository.createIncident(
              title: any(named: 'title'),
              description: any(named: 'description'),
              category: any(named: 'category'),
              priority: any(named: 'priority'),
              locationLat: any(named: 'locationLat'),
              locationLng: any(named: 'locationLng'),
              locationAddress: any(named: 'locationAddress'),
              locationProvince: any(named: 'locationProvince'),
              locationDistrict: any(named: 'locationDistrict'),
              incidentDate: any(named: 'incidentDate'),
              isAnonymous: any(named: 'isAnonymous'),
            )).thenAnswer((_) async => newIncident);

        container = TestHelpers.createIncidentsContainer(
          mockIncidentsRepository: mockRepository,
        );

        final notifier = container.read(createIncidentProvider.notifier);
        await notifier.createIncident(
          title: 'Test Incident',
          description: 'Test Description',
        );

        final state = container.read(createIncidentProvider);
        expect(state, isA<CreateIncidentSuccess>());
        expect((state as CreateIncidentSuccess).incident.id, equals('new-incident'));
        expect(state.isUpdate, isFalse);
      });

      test('should set CreateIncidentError state on failure', () async {
        when(() => mockRepository.createIncident(
              title: any(named: 'title'),
              description: any(named: 'description'),
              category: any(named: 'category'),
              priority: any(named: 'priority'),
              locationLat: any(named: 'locationLat'),
              locationLng: any(named: 'locationLng'),
              locationAddress: any(named: 'locationAddress'),
              locationProvince: any(named: 'locationProvince'),
              locationDistrict: any(named: 'locationDistrict'),
              incidentDate: any(named: 'incidentDate'),
              isAnonymous: any(named: 'isAnonymous'),
            )).thenThrow(IncidentsException(message: 'Creation failed'));

        container = TestHelpers.createIncidentsContainer(
          mockIncidentsRepository: mockRepository,
        );

        final notifier = container.read(createIncidentProvider.notifier);
        await notifier.createIncident(
          title: 'Test Incident',
          description: 'Test Description',
        );

        final state = container.read(createIncidentProvider);
        expect(state, isA<CreateIncidentError>());
        expect((state as CreateIncidentError).message, equals('Creation failed'));
      });
    });

    group('updateIncident', () {
      test('should set CreateIncidentSuccess with isUpdate=true', () async {
        final updatedIncident = TestDataFactory.createIncident(
          id: 'incident-1',
          title: 'Updated Title',
        );

        when(() => mockRepository.updateIncident(
              any(),
              title: any(named: 'title'),
              description: any(named: 'description'),
              category: any(named: 'category'),
              priority: any(named: 'priority'),
              locationLat: any(named: 'locationLat'),
              locationLng: any(named: 'locationLng'),
              locationAddress: any(named: 'locationAddress'),
              locationProvince: any(named: 'locationProvince'),
              locationDistrict: any(named: 'locationDistrict'),
              incidentDate: any(named: 'incidentDate'),
              isAnonymous: any(named: 'isAnonymous'),
            )).thenAnswer((_) async => updatedIncident);

        container = TestHelpers.createIncidentsContainer(
          mockIncidentsRepository: mockRepository,
        );

        final notifier = container.read(createIncidentProvider.notifier);
        await notifier.updateIncident(
          'incident-1',
          title: 'Updated Title',
        );

        final state = container.read(createIncidentProvider);
        expect(state, isA<CreateIncidentSuccess>());
        expect((state as CreateIncidentSuccess).isUpdate, isTrue);
      });
    });

    group('reset', () {
      test('should reset state to CreateIncidentInitial', () async {
        final newIncident = TestDataFactory.createIncident();

        when(() => mockRepository.createIncident(
              title: any(named: 'title'),
              description: any(named: 'description'),
              category: any(named: 'category'),
              priority: any(named: 'priority'),
              locationLat: any(named: 'locationLat'),
              locationLng: any(named: 'locationLng'),
              locationAddress: any(named: 'locationAddress'),
              locationProvince: any(named: 'locationProvince'),
              locationDistrict: any(named: 'locationDistrict'),
              incidentDate: any(named: 'incidentDate'),
              isAnonymous: any(named: 'isAnonymous'),
            )).thenAnswer((_) async => newIncident);

        container = TestHelpers.createIncidentsContainer(
          mockIncidentsRepository: mockRepository,
        );

        final notifier = container.read(createIncidentProvider.notifier);
        await notifier.createIncident(
          title: 'Test',
          description: 'Test',
        );

        expect(container.read(createIncidentProvider), isA<CreateIncidentSuccess>());

        notifier.reset();

        expect(container.read(createIncidentProvider), isA<CreateIncidentInitial>());
      });
    });
  });

  group('IncidentStatsNotifier', () {
    test('should load statistics successfully', () async {
      final stats = TestDataFactory.createIncidentStats();

      when(() => mockRepository.getIncidentStats())
          .thenAnswer((_) async => stats);

      container = TestHelpers.createIncidentsContainer(
        mockIncidentsRepository: mockRepository,
      );

      final notifier = container.read(incidentStatsProvider.notifier);
      await notifier.loadStats();

      final state = container.read(incidentStatsProvider);
      expect(state, isA<IncidentStatsLoaded>());
      expect((state as IncidentStatsLoaded).stats.recentCount.total, equals(10));
    });

    test('should set error state on failure', () async {
      when(() => mockRepository.getIncidentStats())
          .thenThrow(IncidentsException(message: 'Stats failed'));

      container = TestHelpers.createIncidentsContainer(
        mockIncidentsRepository: mockRepository,
      );

      final notifier = container.read(incidentStatsProvider.notifier);
      await notifier.loadStats();

      final state = container.read(incidentStatsProvider);
      expect(state, isA<IncidentStatsError>());
      expect((state as IncidentStatsError).message, equals('Stats failed'));
    });
  });
}
