import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:planner_app/models/public_page.dart';
import 'package:planner_app/providers/managed_public_pages.dart';

void main() {
  late StreamController<List<PublicPage>> owned;
  late StreamController<List<PublicPage>> administered;

  setUp(() {
    owned = StreamController<List<PublicPage>>(sync: true);
    administered = StreamController<List<PublicPage>>(sync: true);
  });

  tearDown(() async {
    await owned.close();
    await administered.close();
  });

  PublicPage page(String id, {int day = 1, bool active = true}) {
    return PublicPage.fromMap({
      'name': id,
      'isActive': active,
      'createdAt': DateTime.utc(2030, 1, day),
    }, id);
  }

  Stream<List<String>> pageIds() {
    return watchManagedPublicPages(
      ownedPages: owned.stream,
      administeredPages: administered.stream,
    ).map((pages) => pages.map((page) => page.id).toList());
  }

  test('waits for both initial snapshots before emitting', () async {
    final values = <List<String>>[];
    final subscription = pageIds().listen(values.add);
    addTearDown(subscription.cancel);

    owned.add([page('owned')]);
    await pumpEventQueue();
    expect(values, isEmpty);

    administered.add([]);
    await pumpEventQueue();
    expect(values, [
      ['owned'],
    ]);
  });

  test('admin-only additions and removals refresh the list', () async {
    final values = <List<String>>[];
    final subscription = pageIds().listen(values.add);
    addTearDown(subscription.cancel);

    owned.add([page('owned')]);
    administered.add([]);
    await pumpEventQueue();

    administered.add([page('admin', day: 2)]);
    await pumpEventQueue();
    expect(values.last, ['admin', 'owned']);

    administered.add([]);
    await pumpEventQueue();
    expect(values.last, ['owned']);
  });

  test('owner-only changes retain the latest administered pages', () async {
    final values = <List<String>>[];
    final subscription = pageIds().listen(values.add);
    addTearDown(subscription.cancel);

    owned.add([]);
    administered.add([page('admin')]);
    await pumpEventQueue();

    owned.add([page('owned', day: 2)]);
    await pumpEventQueue();
    expect(values.last, ['owned', 'admin']);
  });

  test('filters inactive pages, deduplicates and sorts newest first', () async {
    final values = <List<String>>[];
    final subscription = pageIds().listen(values.add);
    addTearDown(subscription.cancel);

    owned.add([
      page('older'),
      page('shared', day: 2),
      page('inactive', day: 4, active: false),
    ]);
    administered.add([
      page('shared', day: 2),
      page('newest', day: 3),
    ]);
    await pumpEventQueue();

    expect(values.last, ['newest', 'shared', 'older']);
  });

  test('forwards errors from either source', () async {
    final errors = <Object>[];
    final subscription = pageIds().listen((_) {}, onError: errors.add);
    addTearDown(subscription.cancel);
    final ownerError = StateError('Owner query failed');
    final adminError = StateError('Admin query failed');

    owned.addError(ownerError);
    administered.addError(adminError);
    await pumpEventQueue();

    expect(errors, [ownerError, adminError]);
  });

  test('cancelling the result cancels both source subscriptions', () async {
    final subscription = pageIds().listen((_) {});
    await pumpEventQueue();
    expect(owned.hasListener, isTrue);
    expect(administered.hasListener, isTrue);

    await subscription.cancel();

    expect(owned.hasListener, isFalse);
    expect(administered.hasListener, isFalse);
  });
}