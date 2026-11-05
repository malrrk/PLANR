import 'dart:async';

import '../models/public_page.dart';

Stream<List<PublicPage>> watchManagedPublicPages({
  required Stream<List<PublicPage>> ownedPages,
  required Stream<List<PublicPage>> administeredPages,
}) {
  late StreamController<List<PublicPage>> controller;
  StreamSubscription<List<PublicPage>>? ownedSubscription;
  StreamSubscription<List<PublicPage>>? administeredSubscription;
  List<PublicPage>? latestOwned;
  List<PublicPage>? latestAdministered;
  var completedSources = 0;

  void emit() {
    final owned = latestOwned;
    final administered = latestAdministered;
    if (owned == null || administered == null) return;

    final pagesById = <String, PublicPage>{};
    for (final page in [...owned, ...administered]) {
      if (page.isActive) pagesById[page.id] = page;
    }

    final pages = pagesById.values.toList()
      ..sort((first, second) => second.createdAt.compareTo(first.createdAt));
    controller.add(pages);
  }

  void onDone() {
    completedSources += 1;
    if (completedSources == 2) controller.close();
  }

  controller = StreamController<List<PublicPage>>(
    onListen: () {
      ownedSubscription = ownedPages.listen(
        (pages) {
          latestOwned = pages;
          emit();
        },
        onError: controller.addError,
        onDone: onDone,
      );
      administeredSubscription = administeredPages.listen(
        (pages) {
          latestAdministered = pages;
          emit();
        },
        onError: controller.addError,
        onDone: onDone,
      );
    },
    onPause: () {
      ownedSubscription?.pause();
      administeredSubscription?.pause();
    },
    onResume: () {
      ownedSubscription?.resume();
      administeredSubscription?.resume();
    },
    onCancel: () async {
      await Future.wait([
        if (ownedSubscription != null) ownedSubscription!.cancel(),
        if (administeredSubscription != null)
          administeredSubscription!.cancel(),
      ]);
    },
  );

  return controller.stream;
}