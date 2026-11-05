import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planner_app/app.dart';
import 'package:planner_app/providers/auth_provider.dart';

/// Counts how many provider containers have been created, so a new value proves the state was rebuilt.
var _containersCreated = 0;
final _containerToken = Provider<int>((ref) => ++_containersCreated);

class _TokenProbe extends ConsumerWidget {
  const _TokenProbe();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Text('token:${ref.watch(_containerToken)}'),
    );
  }
}

String _token(WidgetTester tester) {
  return tester.widget<Text>(find.textContaining('token:')).data!;
}

void main() {
  late StreamController<String?> uids;

  setUp(() {
    uids = StreamController<String?>();
    signUpInProgress.value = false;
  });

  tearDown(() async {
    signUpInProgress.value = false;
    await uids.close();
  });

  Future<void> pumpRoot(WidgetTester tester) async {
    await tester.pumpWidget(
      PlanrRoot(userIds: uids.stream, child: const _TokenProbe()),
    );
  }

  // The first pump delivers the stream event, the second builds the frame it scheduled.
  Future<void> emit(WidgetTester tester, String? uid) async {
    uids.add(uid);
    await tester.pump();
    await tester.pump();
  }

  testWidgets('shows a loading screen until the first auth event', (tester) async {
    await pumpRoot(tester);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.textContaining('token:'), findsNothing);

    await emit(tester, null);

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.textContaining('token:'), findsOneWidget);
  });

  testWidgets('a different user gets fresh state, the same user keeps it', (tester) async {
    await pumpRoot(tester);

    await emit(tester, 'alice');
    final alice = _token(tester);

    await emit(tester, 'alice');
    expect(_token(tester), alice);

    await emit(tester, null);
    final signedOut = _token(tester);
    expect(signedOut, isNot(alice));

    await emit(tester, 'bob');
    expect(_token(tester), isNot(signedOut));
    expect(_token(tester), isNot(alice));
  });

  testWidgets('the switch to the new account waits until sign-up has finished', (tester) async {
    await pumpRoot(tester);

    await emit(tester, null);
    final signedOut = _token(tester);

    signUpInProgress.value = true;
    await emit(tester, 'alice');
    expect(_token(tester), signedOut);

    signUpInProgress.value = false;
    await tester.pump();
    await tester.pump();
    expect(_token(tester), isNot(signedOut));
  });
}
