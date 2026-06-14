import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vizualizer/presentation/controllers/pipeline_controller.dart';
import 'package:vizualizer/data/models/pipeline_models.dart';
import 'package:vizualizer/presentation/providers/pipeline_master_provider.dart';
import 'package:vizualizer/data/services/master_data_service.dart';
import 'package:vizualizer/presentation/pages/pipeline/edit_pipeline_canvas_page.dart';
class EditTemplateConfigurationPage extends StatelessWidget {
  const EditTemplateConfigurationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PipelineController(templateMode: TemplateMode.edit)),
        ChangeNotifierProvider(
          lazy: false,
          create: (ctx) =>
              PipelineMasterProvider(ctx.read<MasterDataService>()),
        ),
      ],
      child: const EditPipelineCanvasPage(),
    );
  }
}
