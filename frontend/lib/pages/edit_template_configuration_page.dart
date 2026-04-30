import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/pipeline_controller.dart';
import '../providers/pipeline_master_provider.dart';
import '../services/master_data_service.dart';
import '../widgets/edit_pipeline_canvas_page.dart';

class EditTemplateConfigurationPage extends StatelessWidget {
  const EditTemplateConfigurationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PipelineController(templateMode: 'edit')),
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
