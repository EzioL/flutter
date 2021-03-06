// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Verify that a BottomSheet can be rebuilt with ScaffoldFeatureController.setState()', (WidgetTester tester) async {
    final GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();
    PersistentBottomSheetController<Null> bottomSheet;
    int buildCount = 0;

    await tester.pumpWidget(new MaterialApp(
      home: new Scaffold(
        key: scaffoldKey,
        body: const Center(child: const Text('body'))
      )
    ));

    bottomSheet = scaffoldKey.currentState.showBottomSheet<Null>((_) {
      return new Builder(
        builder: (BuildContext context) {
          buildCount += 1;
          return new Container(height: 200.0);
        }
      );
    });

    await tester.pump();
    expect(buildCount, equals(1));

    bottomSheet.setState(() { });
    await tester.pump();
    expect(buildCount, equals(2));
  });

  testWidgets('Verify that a scrollable BottomSheet can be dismissed', (WidgetTester tester) async {
    final GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();

    await tester.pumpWidget(new MaterialApp(
      home: new Scaffold(
        key: scaffoldKey,
        body: const Center(child: const Text('body'))
      )
    ));

    scaffoldKey.currentState.showBottomSheet<Null>((BuildContext context) {
      return new ListView(
        shrinkWrap: true,
        primary: false,
        children: <Widget>[
          new Container(height: 100.0, child: const Text('One')),
          new Container(height: 100.0, child: const Text('Two')),
          new Container(height: 100.0, child: const Text('Three')),
        ],
      );
    });

    await tester.pumpAndSettle();

    expect(find.text('Two'), findsOneWidget);

    await tester.drag(find.text('Two'), const Offset(0.0, 400.0));
    await tester.pumpAndSettle();

    expect(find.text('Two'), findsNothing);
  });

  testWidgets('showBottomSheet()', (WidgetTester tester) async {
    final GlobalKey key = new GlobalKey();
    await tester.pumpWidget(new MaterialApp(
      home: new Scaffold(
        body: new Placeholder(key: key),
      )
    ));

    int buildCount = 0;
    showBottomSheet<Null>(
      context: key.currentContext,
      builder: (BuildContext context) {
        return new Builder(
          builder: (BuildContext context) {
            buildCount += 1;
            return new Container(height: 200.0);
          }
        );
      },
    );
    await tester.pump();
    expect(buildCount, equals(1));
  });

  testWidgets('Scaffold removes top MediaQuery padding', (WidgetTester tester) async {
    BuildContext scaffoldContext;
    BuildContext bottomSheetContext;

    await tester.pumpWidget(new MaterialApp(
      home: new MediaQuery(
        data: const MediaQueryData(
          padding: const EdgeInsets.all(50.0),
        ),
        child: new Scaffold(
          resizeToAvoidBottomPadding: false,
          body: new Builder(
            builder: (BuildContext context) {
              scaffoldContext = context;
              return new Container();
            }
          ),
        ),
      )
    ));

    await tester.pump();

    showBottomSheet<Null>(
      context: scaffoldContext,
      builder: (BuildContext context) {
        bottomSheetContext = context;
        return new Container();
      },
    );

    await tester.pump();

    expect(
      MediaQuery.of(bottomSheetContext).padding,
      const EdgeInsets.only(
        bottom: 50.0,
        left: 50.0,
        right: 50.0,
      ),
    );
  });

  testWidgets('Scaffold.bottomSheet', (WidgetTester tester) async {
    final Key bottomSheetKey = new UniqueKey();

    await tester.pumpWidget(
      new MaterialApp(
        home: new Scaffold(
          body: const Placeholder(),
          bottomSheet: new Container(
            key: bottomSheetKey,
            alignment: Alignment.center,
            height: 200.0,
            child: new Builder(
              builder: (BuildContext context) {
                return new RaisedButton(
                  child: const Text('showModalBottomSheet'),
                  onPressed: () {
                    showModalBottomSheet<void>(
                      context: context,
                      builder: (BuildContext context) => const Text('modal bottom sheet'),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );

    expect(find.text('showModalBottomSheet'), findsOneWidget);
    expect(tester.getSize(find.byKey(bottomSheetKey)), const Size(800.0, 200.0));
    expect(tester.getTopLeft(find.byKey(bottomSheetKey)), const Offset(0.0, 400.0));

    // Show the modal bottomSheet
    await tester.tap(find.text('showModalBottomSheet'));
    await tester.pumpAndSettle();
    expect(find.text('modal bottom sheet'), findsOneWidget);

    // Dismiss the modal bottomSheet
    await tester.tap(find.text('modal bottom sheet'));
    await tester.pumpAndSettle();
    expect(find.text('modal bottom sheet'), findsNothing);
    expect(find.text('showModalBottomSheet'), findsOneWidget);

    // Remove the persistent bottomSheet
    await tester.pumpWidget(
      new MaterialApp(
        home: const Scaffold(
          bottomSheet: null,
          body: const Placeholder(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('showModalBottomSheet'), findsNothing);
    expect(find.byKey(bottomSheetKey), findsNothing);
  });
}
