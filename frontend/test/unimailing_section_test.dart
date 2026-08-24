import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vizualizer/data/models/pipeline_models.dart';
import 'package:vizualizer/presentation/controllers/pipeline_controller.dart';
import 'package:vizualizer/presentation/widgets/pipeline/nodes/output_node_body.dart';

/// Static + User Defined reuses UniMailingSection's CUSTOM COLUMNS block but
/// must not show the 7 UNIMAILING FIELDS rows above it.
void main() {
  PipelineNode sourceNode() => PipelineNode(
        id: 'n1',
        type: NodeType.db,
        name: 'CUST_MASTER',
        position: Offset.zero,
        typeId: '1',
        cols: ['CUST_ID', 'EMAIL'],
        selectedCols: ['CUST_ID', 'EMAIL'],
      );

  Future<void> pump(WidgetTester tester, {required bool showMandatory}) async {
    final ctrl = PipelineController();
    final node = sourceNode();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: UniMailingSection(
              ctrl: ctrl,
              sourceNodes: [node],
              showMandatoryFields: showMandatory,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('shows the 7 UniMailing fields by default (case 2)',
      (tester) async {
    await pump(tester, showMandatory: true);
    expect(find.text('UNIMAILING FIELDS'), findsOneWidget);
    expect(find.text('Mail To'), findsOneWidget);
    expect(find.text('Barcode'), findsOneWidget);
    expect(find.text('CUSTOM COLUMNS (Column 1–Column 50)'), findsOneWidget);
  });

  testWidgets('hides them for Static + User Defined (case 1)', (tester) async {
    await pump(tester, showMandatory: false);
    expect(find.text('UNIMAILING FIELDS'), findsNothing);
    expect(find.text('Mail To'), findsNothing);
    expect(find.text('Barcode'), findsNothing);
    // …but the custom columns block, its tip and Add button still render.
    expect(find.text('CUSTOM COLUMNS (Column 1–Column 50)'), findsOneWidget);
    expect(find.text('Tip: tap a Column name to rename it.'), findsOneWidget);
    expect(find.text('Add Column 2'), findsOneWidget);
    expect(find.text('Column 1'), findsWidgets);
  });
}
