import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/pipeline_controller.dart';
import '../providers/pipeline_master_provider.dart';
import '../services/master_data_service.dart';
import '../widgets/pipeline_canvas_page.dart';

class TemplateConfigurationPage extends StatelessWidget {
  const TemplateConfigurationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PipelineController()),
        ChangeNotifierProvider(
          lazy: false,
          create: (ctx) => PipelineMasterProvider(ctx.read<MasterDataService>()),
        ),
      ],
      child: const PipelineCanvasPage(),
    );
  }
}
