import 'package:flutter_test/flutter_test.dart';
import 'package:vizualizer/data/models/template_configuration_response_model.dart';
import 'package:vizualizer/presentation/controllers/pipeline_controller.dart';

/// The four supported combinations of template kind × output format.
///
///   Static  + User Defined → 1      Dynamic + UniMailing   → 3
///   Static  + UniMailing   → 2      Dynamic + User Defined → 4
void main() {
  PipelineController controllerFor(String templateType, List<String> formats) {
    return PipelineController()
      ..setSidebarTemplate(
        'T',
        templateId: 1,
        templateType: templateType,
        outputFormats: formats,
      );
  }

  group('PipelineController scenario getters', () {
    test('case 1 — static + user defined', () {
      final c = controllerFor('2', ['User Defined']);
      expect(c.configTemplateType, 1);
      expect(c.isStaticUserDefined, isTrue);
      expect(c.isStaticUniMailing, isFalse);
      expect(c.isPerOutputKeyFlow, isFalse);
    });

    test('case 2 — static + unimailing', () {
      final c = controllerFor('2', ['Unimailing']);
      expect(c.configTemplateType, 2);
      expect(c.isStaticUniMailing, isTrue);
      expect(c.isStaticUserDefined, isFalse);
      expect(c.isPerOutputKeyFlow, isFalse);
    });

    test('case 3 — dynamic + unimailing', () {
      final c = controllerFor('3', ['Unimailing']);
      expect(c.configTemplateType, 3);
      expect(c.isDynamicUniMailing, isTrue);
      expect(c.isDynamicUserDefined, isFalse);
      expect(c.isPerOutputKeyFlow, isTrue);
    });

    test('case 4 — dynamic + user defined', () {
      final c = controllerFor('3', ['User Defined']);
      expect(c.configTemplateType, 4);
      expect(c.isDynamicUserDefined, isTrue);
      expect(c.isDynamicUniMailing, isFalse);
      expect(c.isPerOutputKeyFlow, isTrue);
    });

    test('legacy "1 - Static" / "2 - Dynamic" labels still resolve', () {
      expect(controllerFor('1 - Static', ['User Defined']).configTemplateType, 1);
      expect(controllerFor('1 - Static', ['Unimailing']).configTemplateType, 2);
      expect(controllerFor('2 - Dynamic', ['Unimailing']).configTemplateType, 3);
      expect(controllerFor('2 - Dynamic', ['User Defined']).configTemplateType, 4);
    });

    test('unimailing stays the default when the format is missing', () {
      expect(controllerFor('2', []).configTemplateType, 2);
      expect(controllerFor('2', []).isStaticUniMailing, isTrue);
      expect(controllerFor('3', []).configTemplateType, 3);
      expect(controllerFor('3', []).isDynamicUniMailing, isTrue);
    });

    test('nothing fires before a template is selected', () {
      final c = PipelineController();
      expect(c.isStaticUniMailing, isFalse);
      expect(c.isStaticUserDefined, isFalse);
      expect(c.isDynamicUniMailing, isFalse);
      expect(c.isDynamicUserDefined, isFalse);
      expect(c.isPerOutputKeyFlow, isFalse);
    });
  });

  group('TemplateConfigurationResponseModel.type', () {
    TemplateConfigType typeOf(List<int> templateTypes) =>
        TemplateConfigurationResponseModel.fromJsonData([
          for (final t in templateTypes) {'TemplateType': t, 'DymanicId': 0},
        ]).type;

    test('reads all four TemplateType values', () {
      expect(typeOf([1]), TemplateConfigType.staticUserDefined);
      expect(typeOf([2]), TemplateConfigType.staticUnimailing);
      expect(typeOf([3]), TemplateConfigType.dynamicUnimailing);
      expect(typeOf([4]), TemplateConfigType.dynamicUserDefined);
    });

    test('a single-output-key dynamic config is still dynamic', () {
      final m = TemplateConfigurationResponseModel.fromJsonData([
        {'TemplateType': 4, 'DymanicId': 0},
      ]);
      expect(m.isDynamic, isTrue);
      expect(m.isStatic, isFalse);
    });

    test('falls back to entry count when TemplateType is absent', () {
      final m = TemplateConfigurationResponseModel.fromJsonData([
        {'DymanicId': 0},
        {'DymanicId': 6},
      ]);
      expect(m.type, TemplateConfigType.dynamicUnimailing);
    });
  });
}
