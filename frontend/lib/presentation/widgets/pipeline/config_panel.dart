// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:vizualizer/core/theme/app_theme.dart';
// import 'package:vizualizer/data/models/pipeline_models.dart';
// import 'package:vizualizer/presentation/controllers/pipeline_controller.dart';
// import 'package:vizualizer/presentation/providers/pipeline_master_provider.dart';
// import 'package:vizualizer/presentation/widgets/common/searchable_dropdown.dart';

// /// Shows a confirmation dialog before deleting a pipeline node.
// ///
// /// In Dynamic UniMailing mode the dialog warns that the entire canvas for the
// /// active key will be cleared, and on confirm calls [clearCanvasForCurrentKey]
// /// instead of a single-node delete.
// Future<void> confirmDeleteNode(
//   BuildContext ctx,
//   PipelineController ctrl,
//   String id,
//   String name,
//   NodeType nodeType,
// ) async {
//   final dialogTitle = nodeType == NodeType.output
//       ? 'Delete Output Node?'
//       : nodeType == NodeType.join
//       ? 'Delete Join Node?'
//       : 'Delete Source?';
//   final nodeLabel = nodeType == NodeType.output
//       ? 'Output'
//       : nodeType == NodeType.join
//       ? 'Join'
//       : 'Source';

//   if (ctrl.isAnyUniMailing) {
//     final keyName = ctrl.selectedOutputKey.isNotEmpty
//         ? ctrl.selectedOutputKey
//         : null;
//     final nodeName = name.isNotEmpty ? name : nodeLabel;
//     final ok = await showDialog<bool>(
//       context: ctx,
//       barrierDismissible: false,
//       builder: (dialogCtx) => Center(
//         child: Material(
//           color: Colors.transparent,
//           child: Container(
//             width: 400,
//             decoration: BoxDecoration(
//               color: AppColors.surface,
//               borderRadius: BorderRadius.circular(20),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withValues(alpha: 0.20),
//                   blurRadius: 32,
//                   offset: const Offset(0, 10),
//                 ),
//               ],
//             ),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 // ── Top banner ──
//                 Container(
//                   width: double.infinity,
//                   padding: const EdgeInsets.symmetric(vertical: 28),
//                   decoration: BoxDecoration(
//                     color: AppColors.red.withValues(alpha: 0.06),
//                     borderRadius: const BorderRadius.vertical(
//                       top: Radius.circular(20),
//                     ),
//                   ),
//                   child: Column(
//                     children: [
//                       Container(
//                         width: 56,
//                         height: 56,
//                         decoration: BoxDecoration(
//                           shape: BoxShape.circle,
//                           color: AppColors.red.withValues(alpha: 0.14),
//                         ),
//                         child: const Icon(
//                           Icons.delete_outline_rounded,
//                           size: 26,
//                           color: AppColors.red,
//                         ),
//                       ),
//                       const SizedBox(height: 12),
//                       Text(
//                         dialogTitle,
//                         style: const TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.w700,
//                           color: AppColors.red,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),

//                 // ── Body ──
//                 Padding(
//                   padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // ── Warning box with amber left accent ──
//                       ClipRRect(
//                         borderRadius: BorderRadius.circular(10),
//                         child: Stack(
//                           children: [
//                             Container(
//                               width: double.infinity,
//                               padding: const EdgeInsets.fromLTRB(
//                                 14,
//                                 12,
//                                 14,
//                                 12,
//                               ),
//                               decoration: BoxDecoration(
//                                 color: AppColors.amberDim,
//                                 borderRadius: BorderRadius.circular(10),
//                                 border: Border.all(
//                                   color: AppColors.amber.withValues(
//                                     alpha: 0.25,
//                                   ),
//                                 ),
//                               ),
//                               child: Row(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   const Icon(
//                                     Icons.warning_amber_rounded,
//                                     size: 16,
//                                     color: AppColors.amber,
//                                   ),
//                                   const SizedBox(width: 10),
//                                   Expanded(
//                                     child: Column(
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.start,
//                                       children: [
//                                         const Text(
//                                           'This action cannot be undone',
//                                           style: TextStyle(
//                                             fontSize: 13,
//                                             fontWeight: FontWeight.w700,
//                                             color: AppColors.text,
//                                           ),
//                                         ),
//                                         const SizedBox(height: 3),
//                                         RichText(
//                                           text: TextSpan(
//                                             style: const TextStyle(
//                                               fontSize: 12,
//                                               color: AppColors.textDim,
//                                               height: 1.5,
//                                             ),
//                                             children: [
//                                               TextSpan(
//                                                 text:
//                                                     'Deleting $nodeName will clear the ',
//                                               ),
//                                               const TextSpan(
//                                                 text: 'entire canvas',
//                                                 style: TextStyle(
//                                                   fontWeight: FontWeight.w700,
//                                                   color: AppColors.text,
//                                                 ),
//                                               ),
//                                               TextSpan(
//                                                 text: keyName != null
//                                                     ? ' for $keyName.'
//                                                     : ' for this configuration.',
//                                               ),
//                                             ],
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                             Positioned(
//                               left: 0,
//                               top: 0,
//                               bottom: 0,
//                               child: Container(
//                                 width: 4,
//                                 color: AppColors.amber,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       const SizedBox(height: 14),

//                       // ── What will be cleared ──
//                       Container(
//                         width: double.infinity,
//                         padding: const EdgeInsets.all(14),
//                         decoration: BoxDecoration(
//                           color: AppColors.bg,
//                           borderRadius: BorderRadius.circular(10),
//                           border: Border.all(color: AppColors.border),
//                         ),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             const Text(
//                               'WHAT WILL BE CLEARED',
//                               style: TextStyle(
//                                 fontSize: 10,
//                                 fontWeight: FontWeight.w700,
//                                 color: AppColors.textMuted,
//                                 letterSpacing: 0.6,
//                               ),
//                             ),
//                             const SizedBox(height: 10),
//                             _clearItem('Source body & file settings'),
//                             const SizedBox(height: 6),
//                             _clearItem('Join conditions & mappings'),
//                             const SizedBox(height: 6),
//                             _clearItem('Output selection & field mappings'),
//                           ],
//                         ),
//                       ),
//                       const SizedBox(height: 14),

//                       // ── Footer text ──
//                       RichText(
//                         text: TextSpan(
//                           style: const TextStyle(
//                             fontSize: 12,
//                             color: AppColors.textDim,
//                             height: 1.5,
//                           ),
//                           children: [
//                             const TextSpan(text: 'You will need to '),
//                             const TextSpan(
//                               text: 'reconfigure all settings',
//                               style: TextStyle(
//                                 fontWeight: FontWeight.w700,
//                                 color: AppColors.text,
//                               ),
//                             ),
//                             TextSpan(
//                               text: ctrl.isDynamicUniMailing
//                                   ? ' for this key again.'
//                                   : ctrl.isStaticUniMailing
//                                   ? ' for this UniMailing configuration again.'
//                                   : ' for this configuration again.',
//                             ),
//                           ],
//                         ),
//                       ),
//                       const SizedBox(height: 18),

//                       // ── Buttons ──
//                       Row(
//                         children: [
//                           Expanded(
//                             child: OutlinedButton.icon(
//                               onPressed: () =>
//                                   Navigator.of(dialogCtx).pop(false),
//                               icon: const Icon(
//                                 Icons.arrow_back_rounded,
//                                 size: 14,
//                               ),
//                               label: const Text(
//                                 'Cancel',
//                                 style: TextStyle(fontWeight: FontWeight.w600),
//                               ),
//                               style: OutlinedButton.styleFrom(
//                                 foregroundColor: AppColors.text,
//                                 side: const BorderSide(
//                                   color: AppColors.border2,
//                                 ),
//                                 padding: const EdgeInsets.symmetric(
//                                   vertical: 13,
//                                 ),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(10),
//                                 ),
//                               ),
//                             ),
//                           ),
//                           const SizedBox(width: 10),
//                           Expanded(
//                             child: ElevatedButton.icon(
//                               onPressed: () =>
//                                   Navigator.of(dialogCtx).pop(true),
//                               icon: const Icon(
//                                 Icons.delete_outline_rounded,
//                                 size: 15,
//                               ),
//                               label: const Text(
//                                 'Yes, delete',
//                                 style: TextStyle(fontWeight: FontWeight.w700),
//                               ),
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: AppColors.red,
//                                 foregroundColor: Colors.white,
//                                 elevation: 0,
//                                 padding: const EdgeInsets.symmetric(
//                                   vertical: 13,
//                                 ),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(10),
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//     if (ok == true && ctx.mounted) ctrl.clearCanvasForCurrentKey();
//     return;
//   }

//   final ok = await showDialog<bool>(
//     context: ctx,
//     barrierDismissible: false,
//     builder: (dialogCtx) => AlertDialog(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//       titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
//       contentPadding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
//       actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
//       title: Row(
//         children: [
//           const Icon(
//             Icons.delete_outline_rounded,
//             color: AppColors.red,
//             size: 20,
//           ),
//           const SizedBox(width: 8),
//           Text(
//             dialogTitle,
//             style: const TextStyle(
//               fontSize: 15,
//               fontWeight: FontWeight.w700,
//               color: AppColors.red,
//             ),
//           ),
//         ],
//       ),
//       content: RichText(
//         text: TextSpan(
//           style: const TextStyle(
//             fontSize: 13,
//             color: AppColors.text,
//             height: 1.5,
//           ),
//           children: [
//             const TextSpan(text: 'Are you sure you want to delete '),
//             TextSpan(
//               text: name,
//               style: const TextStyle(fontWeight: FontWeight.w700),
//             ),
//             const TextSpan(text: '? All connected edges will also be removed.'),
//           ],
//         ),
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.of(dialogCtx).pop(false),
//           child: const Text('Cancel'),
//         ),
//         ElevatedButton(
//           onPressed: () => Navigator.of(dialogCtx).pop(true),
//           style: ElevatedButton.styleFrom(
//             backgroundColor: AppColors.red,
//             foregroundColor: Colors.white,
//             elevation: 0,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(8),
//             ),
//           ),
//           child: const Text(
//             'Delete',
//             style: TextStyle(fontWeight: FontWeight.w700),
//           ),
//         ),
//       ],
//     ),
//   );
//   if (ok == true && ctx.mounted) ctrl.deleteNode(id);
// }

// /// Shows a confirmation dialog before editing a confirmed node in UniMailing mode.
// /// Warns that the entire canvas for the current key will be cleared, then calls
// /// [clearCanvasForCurrentKey] on confirm.
// Future<void> confirmEditNode(
//   BuildContext ctx,
//   PipelineController ctrl,
//   String name,
//   NodeType nodeType,
// ) async {
//   final dialogTitle = nodeType == NodeType.output
//       ? 'Edit Output Node?'
//       : nodeType == NodeType.join
//       ? 'Edit Join Node?'
//       : 'Edit Source?';
//   final nodeLabel = nodeType == NodeType.output
//       ? 'Output'
//       : nodeType == NodeType.join
//       ? 'Join'
//       : 'Source';

//   final keyName = ctrl.selectedOutputKey.isNotEmpty
//       ? ctrl.selectedOutputKey
//       : null;
//   final nodeName = name.isNotEmpty ? name : nodeLabel;

//   final ok = await showDialog<bool>(
//     context: ctx,
//     barrierDismissible: false,
//     builder: (dialogCtx) => Center(
//       child: Material(
//         color: Colors.transparent,
//         child: Container(
//           width: 400,
//           decoration: BoxDecoration(
//             color: AppColors.surface,
//             borderRadius: BorderRadius.circular(20),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withValues(alpha: 0.20),
//                 blurRadius: 32,
//                 offset: const Offset(0, 10),
//               ),
//             ],
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               // ── Top banner ──
//               Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.symmetric(vertical: 28),
//                 decoration: BoxDecoration(
//                   color: AppColors.red.withValues(alpha: 0.06),
//                   borderRadius: const BorderRadius.vertical(
//                     top: Radius.circular(20),
//                   ),
//                 ),
//                 child: Column(
//                   children: [
//                     Container(
//                       width: 56,
//                       height: 56,
//                       decoration: BoxDecoration(
//                         shape: BoxShape.circle,
//                         color: AppColors.red.withValues(alpha: 0.14),
//                       ),
//                       child: const Icon(
//                         Icons.edit_rounded,
//                         size: 26,
//                         color: AppColors.red,
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     Text(
//                       dialogTitle,
//                       style: const TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.w700,
//                         color: AppColors.red,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//               // ── Body ──
//               Padding(
//                 padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // ── Warning box ──
//                     ClipRRect(
//                       borderRadius: BorderRadius.circular(10),
//                       child: Stack(
//                         children: [
//                           Container(
//                             width: double.infinity,
//                             padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
//                             decoration: BoxDecoration(
//                               color: AppColors.amberDim,
//                               borderRadius: BorderRadius.circular(10),
//                               border: Border.all(
//                                 color: AppColors.amber.withValues(alpha: 0.25),
//                               ),
//                             ),
//                             child: Row(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 const Icon(
//                                   Icons.warning_amber_rounded,
//                                   size: 16,
//                                   color: AppColors.amber,
//                                 ),
//                                 const SizedBox(width: 10),
//                                 Expanded(
//                                   child: Column(
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                     children: [
//                                       const Text(
//                                         'This action cannot be undone',
//                                         style: TextStyle(
//                                           fontSize: 13,
//                                           fontWeight: FontWeight.w700,
//                                           color: AppColors.text,
//                                         ),
//                                       ),
//                                       const SizedBox(height: 3),
//                                       RichText(
//                                         text: TextSpan(
//                                           style: const TextStyle(
//                                             fontSize: 12,
//                                             color: AppColors.textDim,
//                                             height: 1.5,
//                                           ),
//                                           children: [
//                                             TextSpan(
//                                               text:
//                                                   'Editing $nodeName will clear the ',
//                                             ),
//                                             const TextSpan(
//                                               text: 'entire canvas',
//                                               style: TextStyle(
//                                                 fontWeight: FontWeight.w700,
//                                                 color: AppColors.text,
//                                               ),
//                                             ),
//                                             TextSpan(
//                                               text: keyName != null
//                                                   ? ' for $keyName.'
//                                                   : ' for this configuration.',
//                                             ),
//                                           ],
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           Positioned(
//                             left: 0,
//                             top: 0,
//                             bottom: 0,
//                             child: Container(width: 4, color: AppColors.amber),
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 14),

//                     // ── What will be cleared ──
//                     Container(
//                       width: double.infinity,
//                       padding: const EdgeInsets.all(14),
//                       decoration: BoxDecoration(
//                         color: AppColors.bg,
//                         borderRadius: BorderRadius.circular(10),
//                         border: Border.all(color: AppColors.border),
//                       ),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const Text(
//                             'WHAT WILL BE CLEARED',
//                             style: TextStyle(
//                               fontSize: 10,
//                               fontWeight: FontWeight.w700,
//                               color: AppColors.textMuted,
//                               letterSpacing: 0.6,
//                             ),
//                           ),
//                           const SizedBox(height: 10),
//                           _clearItem('Source body & file settings'),
//                           const SizedBox(height: 6),
//                           _clearItem('Join conditions & mappings'),
//                           const SizedBox(height: 6),
//                           _clearItem('Output selection & field mappings'),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 14),

//                     // ── Footer ──
//                     RichText(
//                       text: TextSpan(
//                         style: const TextStyle(
//                           fontSize: 12,
//                           color: AppColors.textDim,
//                           height: 1.5,
//                         ),
//                         children: [
//                           const TextSpan(text: 'You will need to '),
//                           const TextSpan(
//                             text: 'reconfigure all settings',
//                             style: TextStyle(
//                               fontWeight: FontWeight.w700,
//                               color: AppColors.text,
//                             ),
//                           ),
//                           TextSpan(
//                             text: ctrl.isDynamicUniMailing
//                                 ? ' for this key again.'
//                                 : ctrl.isStaticUniMailing
//                                 ? ' for this UniMailing configuration again.'
//                                 : ' for this configuration again.',
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 18),

//                     // ── Buttons ──
//                     Row(
//                       children: [
//                         Expanded(
//                           child: OutlinedButton.icon(
//                             onPressed: () => Navigator.of(dialogCtx).pop(false),
//                             icon: const Icon(
//                               Icons.arrow_back_rounded,
//                               size: 14,
//                             ),
//                             label: const Text(
//                               'Cancel',
//                               style: TextStyle(fontWeight: FontWeight.w600),
//                             ),
//                             style: OutlinedButton.styleFrom(
//                               foregroundColor: AppColors.text,
//                               side: const BorderSide(color: AppColors.border2),
//                               padding: const EdgeInsets.symmetric(vertical: 13),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(10),
//                               ),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 10),
//                         Expanded(
//                           child: ElevatedButton.icon(
//                             onPressed: () => Navigator.of(dialogCtx).pop(true),
//                             icon: const Icon(Icons.edit_rounded, size: 15),
//                             label: const Text(
//                               'Yes, clear',
//                               style: TextStyle(fontWeight: FontWeight.w700),
//                             ),
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: AppColors.red,
//                               foregroundColor: Colors.white,
//                               elevation: 0,
//                               padding: const EdgeInsets.symmetric(vertical: 13),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(10),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     ),
//   );
//   if (ok == true && ctx.mounted) ctrl.clearCanvasForCurrentKey();
// }

// Widget _clearItem(String text) => Row(
//   children: [
//     const Icon(Icons.close_rounded, size: 14, color: AppColors.red),
//     const SizedBox(width: 8),
//     Text(
//       text,
//       style: const TextStyle(
//         fontSize: 12,
//         color: AppColors.text,
//         fontWeight: FontWeight.w500,
//       ),
//     ),
//   ],
// );

// class ConfigPanel extends StatefulWidget {
//   const ConfigPanel({super.key});

//   @override
//   State<ConfigPanel> createState() => _ConfigPanelState();
// }

// class _ConfigPanelState extends State<ConfigPanel>
//     with TickerProviderStateMixin {
//   late final AnimationController _pulse;
//   late final Animation<double> _anim;

//   // Track which node is open so we reset state on switch
//   String? _prevNodeId;

//   // True only after the user explicitly changes the separator dropdown
//   bool _sepAcknowledged = false;

//   // Persistent controller for the source-name field so typing doesn't lose focus
//   final TextEditingController _nameCtrl = TextEditingController();

//   int _lastCanvasVersion = 0;

//   @override
//   void initState() {
//     super.initState();
//     _pulse = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 900),
//     )..repeat(reverse: true);
//     _anim = Tween<double>(
//       begin: 0.0,
//       end: 1.0,
//     ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
//   }

//   @override
//   void dispose() {
//     _pulse.dispose();
//     _nameCtrl.dispose();
//     super.dispose();
//   }

//   // ── Returns 0-4 depending on what the user should fill next ──
//   // Non-manual : 0=sourceName  1=queryFile   2=columnFile  3=outputFormat  4=configBtn
//   // Manual     : 0=sourceName  1=separator   2=columnFile  3=outputFormat  4=configBtn
//   int _computeStep(PipelineNode node) {
//     if (node.confirmState == NodeConfirmState.confirmed) return -1;
//     if (node.name.trim().isEmpty) return 0;
//     final isManual = node.type == NodeType.manual;
//     if (isManual) {
//       if (!_sepAcknowledged) return 1; // separator
//       if (node.fileName == null) return 2; // column file
//       if (node.selectedCols.isEmpty) return 3; // output format
//       return 4; // config button
//     } else {
//       if (node.queryFileName == null) return 1; // query file
//       if (node.fileName == null) return 2; // column file
//       if (node.selectedCols.isEmpty) return 3; // output format
//       return 4; // config button
//     }
//   }

//   // ── Wraps [child] with a pulsing glow border only when [forStep] is active ──
//   Widget _hl(
//     int forStep,
//     int activeStep,
//     Widget child, {
//     Color color = AppColors.blue,
//     bool borderOnly = false,
//   }) {
//     // Always wrap in AnimatedBuilder + Container with a BoxDecoration so the
//     // widget tree structure stays constant as `step` changes.
//     // KEY: decoration must never be null — Container adds/removes an internal
//     // DecoratedBox when decoration flips null↔non-null, which remounts the
//     // child and kills TextField focus.  Use alpha=0 for the inactive state.
//     return AnimatedBuilder(
//       animation: _anim,
//       child:
//           child, // passed as AnimatedBuilder.child so it isn't rebuilt every frame
//       builder: (_, builtChild) {
//         final isActive = forStep == activeStep;
//         final t = isActive ? _anim.value : 0.0;
//         return Container(
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(10),
//             border: Border.all(
//               color: color.withValues(alpha: t * 0.65),
//               width: 1.5,
//             ),
//             color: borderOnly ? null : color.withValues(alpha: t * 0.05),
//             boxShadow: t > 0.1 && !borderOnly
//                 ? [
//                     BoxShadow(
//                       color: color.withValues(alpha: t * 0.18),
//                       blurRadius: 6,
//                       spreadRadius: 2,
//                     ),
//                   ]
//                 : null,
//           ),
//           child: builtChild,
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<PipelineController>(
//       builder: (context, ctrl, _) {
//         final node = ctrl.selectedNodeId != null
//             ? ctrl.findNode(ctrl.selectedNodeId!)
//             : null;

//         // ── Detect canvas clear → reset all local state ──
//         if (ctrl.canvasVersion != _lastCanvasVersion) {
//           WidgetsBinding.instance.addPostFrameCallback((_) {
//             if (!mounted) return;
//             _nameCtrl.clear();
//             setState(() {
//               _lastCanvasVersion = ctrl.canvasVersion;
//               _prevNodeId = null;
//               _sepAcknowledged = false;
//             });
//           });
//         }

//         // ── Detect node switch → reset state and sync name controller ──
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           if (!mounted) return;
//           final newId = ctrl.selectedNodeId;
//           if (newId != _prevNodeId) {
//             final newNode = newId != null ? ctrl.findNode(newId) : null;
//             _nameCtrl.text = newNode?.name ?? '';
//             setState(() {
//               _prevNodeId = newId;
//               _sepAcknowledged = newNode?.separator.isNotEmpty ?? false;
//             });
//           }
//         });

//         return Container(
//           width: 260,
//           color: AppColors.surface,
//           child: Column(
//             children: [
//               // Header
//               Container(
//                 padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
//                 decoration: const BoxDecoration(
//                   border: Border(bottom: BorderSide(color: AppColors.border)),
//                 ),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Expanded(
//                       child: Text(
//                         node != null
//                             ? 'Configure: ${node.name}'
//                             : 'Configure Node',
//                         style: const TextStyle(
//                           color: AppColors.text,
//                           fontSize: 13,
//                           fontWeight: FontWeight.w700,
//                         ),
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ),
//                     if (node != null)
//                       InkWell(
//                         onTap: () => ctrl.selectNode(null),
//                         child: const Icon(
//                           Icons.close,
//                           color: AppColors.textDim,
//                           size: 16,
//                         ),
//                       ),
//                   ],
//                 ),
//               ),

//               // Body
//               Expanded(
//                 child: node == null
//                     ? const Center(
//                         child: Text(
//                           'Click a node to configure',
//                           style: TextStyle(
//                             color: AppColors.textDim,
//                             fontSize: 12,
//                           ),
//                         ),
//                       )
//                     : _buildConfig(context, ctrl, node),
//               ),

//               // Delete button
//               if (node != null && node.type.isSource)
//                 Padding(
//                   padding: const EdgeInsets.all(14),
//                   child: InkWell(
//                     onTap: () => confirmDeleteNode(
//                       context,
//                       ctrl,
//                       node.id,
//                       node.name,
//                       node.type,
//                     ),
//                     child: Container(
//                       width: double.infinity,
//                       padding: const EdgeInsets.symmetric(vertical: 10),
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(8),
//                         border: Border.all(
//                           color: AppColors.red.withValues(alpha: 0.3),
//                         ),
//                       ),
//                       child: const Center(
//                         child: Text(
//                           '🗑 Delete Node',
//                           style: TextStyle(
//                             color: AppColors.red,
//                             fontSize: 12,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildConfig(
//     BuildContext context,
//     PipelineController ctrl,
//     PipelineNode node,
//   ) {
//     if (!node.type.isSource) {
//       return const Center(
//         child: Text(
//           'Use node card controls',
//           style: TextStyle(color: AppColors.textDim, fontSize: 11),
//         ),
//       );
//     }

//     final isLocked = node.confirmState == NodeConfirmState.confirmed;
//     final isManual = node.type == NodeType.manual;
//     final step = _computeStep(node);
//     final separators = [
//       'Comma (,)',
//       'Pipe (|)',
//       'Tab (\\t)',
//       'Semicolon (;)',
//       'Colon (:)',
//       'Tilde (~)',
//       'Caret (^)',
//       'Hash (#)',
//       'Space ( )',
//     ];

//     return ListView(
//       padding: const EdgeInsets.all(14),
//       children: [
//         // ── Source Type (API-driven dropdown) ──
//         const Text('Source Type *', style: AppTextStyles.fieldLabel),
//         const SizedBox(height: 4),
//         _SourceTypeDropdown(node: node, ctrl: ctrl, isLocked: isLocked),
//         const SizedBox(height: 14),

//         // ── Source Name ── (step 0)
//         const Text('Source Name *', style: AppTextStyles.fieldLabel),
//         const SizedBox(height: 4),
//         _hl(
//           0,
//           step,
//           TextFormField(
//             controller: _nameCtrl,
//             readOnly: isLocked,
//             onChanged: isLocked ? null : (v) => ctrl.updateNodeName(node.id, v),
//             style: TextStyle(
//               color: isLocked ? AppColors.textDim : AppColors.text,
//               fontSize: 12.5,
//             ),
//             decoration: _inputDecor(locked: isLocked).copyWith(
//               hintText: 'e.g. Customer_Data',
//               hintStyle: const TextStyle(
//                 color: AppColors.textMuted,
//                 fontSize: 12,
//               ),
//             ),
//           ),
//           borderOnly: true,
//         ),
//         const SizedBox(height: 14),

//         // ── Separator (Manual only) ── (step 1 for manual)
//         if (isManual) ...[
//           const Text('File Separator *', style: AppTextStyles.fieldLabel),
//           const SizedBox(height: 4),
//           _hl(
//             1,
//             step,
//             SearchableDropdownField(
//               value: _sepToLabel(node.separator, separators),
//               hint: '— Select Separator —',
//               items: separators,
//               enabled: !isLocked,
//               onChanged: (v) {
//                 if (v != null) {
//                   final sep = v.contains('\\t')
//                       ? '\t'
//                       : v.contains(',')
//                       ? ','
//                       : v.contains('|')
//                       ? '|'
//                       : v.contains(';')
//                       ? ';'
//                       : v.contains(':')
//                       ? ':'
//                       : v.contains('~')
//                       ? '~'
//                       : v.contains('^')
//                       ? '^'
//                       : v.contains('#')
//                       ? '#'
//                       : ' ';
//                   _onSeparatorChanged(context, ctrl, node, sep);
//                 }
//               },
//             ),
//             borderOnly: true,
//           ),
//           const SizedBox(height: 14),
//         ],

//         // ── Non-manual: Query File Upload ── (step 1 for non-manual)
//         if (!isManual) ...[
//           const Text('Upload Query File', style: AppTextStyles.fieldLabel),
//           const SizedBox(height: 4),
//           _hl(
//             1,
//             step,
//             _uploadButton(
//               icon: Icons.description_outlined,
//               label: 'Upload Query File (.txt)',
//               isLocked: isLocked,
//               onTap: isLocked
//                   ? null
//                   : () async {
//                       final messenger = ScaffoldMessenger.of(context);
//                       final result = await FilePicker.platform.pickFiles(
//                         type: FileType.custom,
//                         allowedExtensions: ['txt'],
//                         withData: true,
//                       );
//                       if (result != null && result.files.single.bytes != null) {
//                         final fileName = result.files.single.name;
//                         final ext = fileName.contains('.')
//                             ? fileName.split('.').last.toLowerCase()
//                             : '';
//                         if (ext != 'txt') {
//                           messenger.showSnackBar(
//                             const SnackBar(
//                               content: Text(
//                                 'Invalid file type: only .txt files are allowed for query upload.',
//                               ),
//                               backgroundColor: Colors.red,
//                             ),
//                           );
//                           return;
//                         }
//                         final queryBytes = result.files.single.bytes!;
//                         final queryText = utf8.decode(
//                           queryBytes,
//                           allowMalformed: true,
//                         );
//                         if (!_isValidQueryFile(queryText)) {
//                           messenger.showSnackBar(
//                             const SnackBar(
//                               content: Text(
//                                 'Invalid file: the query file must contain a valid SQL query (e.g. starting with SELECT, WITH, INSERT, etc.). Column/CSV files are not allowed here.',
//                               ),
//                               backgroundColor: Colors.red,
//                             ),
//                           );
//                           return;
//                         }
//                         ctrl.setQueryFile(
//                           node.id,
//                           fileName,
//                           bytes: queryBytes.toList(),
//                         );
//                         messenger.showSnackBar(
//                           SnackBar(
//                             content: Text('Query file loaded: $fileName'),
//                             backgroundColor: AppColors.green,
//                           ),
//                         );
//                       }
//                     },
//             ),
//             borderOnly: true,
//           ),
//           if (node.queryFileName != null) ...[
//             const SizedBox(height: 4),
//             _fileInfoBar(node.queryFileName!, null, AppColors.blue),
//           ],
//           const SizedBox(height: 14),
//         ],

//         // ── Column File Upload ── (step 2)
//         Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Upload Column File (.csv / .txt) *',
//               style: AppTextStyles.fieldLabel,
//             ),
//             const SizedBox(height: 4),
//             _hl(
//               2,
//               step,
//               _uploadButton(
//                 icon: Icons.upload_file_rounded,
//                 label: 'Upload Column File (.csv / .txt)',
//                 isLocked: isLocked,
//                 onTap: isLocked
//                     ? null
//                     : () async {
//                         final messenger = ScaffoldMessenger.of(context);
//                         final result = await FilePicker.platform.pickFiles(
//                           type: FileType.custom,
//                           allowedExtensions: ['csv', 'txt'],
//                           withData: true,
//                         );
//                         if (result == null ||
//                             result.files.single.bytes == null) {
//                           return;
//                         }
//                         final bytes = result.files.single.bytes!;
//                         final fileName = result.files.single.name;
//                         final text = utf8.decode(bytes, allowMalformed: true);
//                         final lines = text
//                             .split('\n')
//                             .where((l) => l.trim().isNotEmpty)
//                             .toList();
//                         if (lines.isEmpty) return;
//                         final firstLine = lines.first;
//                         // For manual nodes, use the separator already chosen by
//                         // the user; for others, auto-detect from file content.
//                         String sep;
//                         if (isManual && node.separator.isNotEmpty) {
//                           sep = node.separator;
//                           // Only reject if the file clearly uses a DIFFERENT
//                           // separator. A single-column file has no separator
//                           // in the first line at all — that is valid.
//                           const knownSeps = [
//                             ',',
//                             '\t',
//                             '|',
//                             ';',
//                             ':',
//                             '~',
//                             '^',
//                             '#',
//                           ];
//                           final usesOtherSep = knownSeps.any(
//                             (s) => s != sep && firstLine.contains(s),
//                           );
//                           if (!firstLine.contains(sep) && usesOtherSep) {
//                             final sepLabel = _sepNames[sep] ?? sep;
//                             messenger.showSnackBar(
//                               SnackBar(
//                                 content: Text(
//                                   'The uploaded file does not contain the selected separator "$sepLabel". Please select the correct separator or upload a matching file.',
//                                 ),
//                                 backgroundColor: Colors.red,
//                               ),
//                             );
//                             return;
//                           }
//                         } else {
//                           sep = ',';
//                           if ('\t'.allMatches(firstLine).isNotEmpty) {
//                             sep = '\t';
//                           } else if ('|'.allMatches(firstLine).isNotEmpty) {
//                             sep = '|';
//                           } else if (';'.allMatches(firstLine).isNotEmpty) {
//                             sep = ';';
//                           } else if (':'.allMatches(firstLine).isNotEmpty) {
//                             sep = ':';
//                           } else if ('~'.allMatches(firstLine).isNotEmpty) {
//                             sep = '~';
//                           } else if ('^'.allMatches(firstLine).isNotEmpty) {
//                             sep = '^';
//                           } else if ('#'.allMatches(firstLine).isNotEmpty) {
//                             sep = '#';
//                           } else if (' '.allMatches(firstLine).isNotEmpty) {
//                             sep = ' ';
//                           }
//                         }
//                         final cols = firstLine
//                             .split(sep)
//                             .map((c) => c.trim().replaceAll('"', '').trim())
//                             .where((c) => c.isNotEmpty)
//                             .toList();
//                         if (cols.isEmpty) return;
//                         // Reject if the file is actually a SQL query file
//                         if (_isValidQueryFile(text)) {
//                           messenger.showSnackBar(
//                             const SnackBar(
//                               content: Text(
//                                 'Invalid file: this looks like a SQL query file. Please upload a column file (.csv / .txt with column headers).',
//                               ),
//                               backgroundColor: Colors.red,
//                             ),
//                           );
//                           return;
//                         }
//                         if (!_isValidColumnHeaders(cols)) {
//                           messenger.showSnackBar(
//                             const SnackBar(
//                               content: Text(
//                                 'Invalid file: the first row must contain column headers, not raw data or unstructured text.',
//                               ),
//                               backgroundColor: Colors.red,
//                             ),
//                           );
//                           return;
//                         }
//                         final rows = <Map<String, dynamic>>[];
//                         for (int i = 1; i < lines.length; i++) {
//                           final vals = lines[i]
//                               .split(sep)
//                               .map((v) => v.trim().replaceAll('"', '').trim())
//                               .toList();
//                           final row = <String, dynamic>{};
//                           for (int j = 0; j < cols.length; j++) {
//                             row[cols[j]] = j < vals.length ? vals[j] : '';
//                           }
//                           rows.add(row);
//                         }
//                         ctrl.setNodeColumns(
//                           node.id,
//                           cols,
//                           rows,
//                           fileName,
//                           bytes: bytes.toList(),
//                         );
//                         ctrl.updateNodeSeparator(node.id, sep);
//                         messenger.showSnackBar(
//                           SnackBar(
//                             content: Text(
//                               '${cols.length} columns, ${rows.length} rows extracted from $fileName',
//                             ),
//                             backgroundColor: AppColors.green,
//                           ),
//                         );
//                       },
//               ),
//               borderOnly: true,
//             ),
//             if (node.fileName != null) ...[
//               const SizedBox(height: 4),
//               _fileInfoBar(
//                 node.fileName!,
//                 '${node.cols.length} cols',
//                 AppColors.green,
//               ),
//             ],
//           ],
//         ),
//         const SizedBox(height: 14),

//         const SizedBox(height: 20),

//         // ── Confirm / Edit button ──
//         _ConfirmSection(node: node, ctrl: ctrl),

//         const SizedBox(height: 8),
//       ],
//     );
//   }

//   /// Returns true if the extracted column headers look like real column names.
//   /// Rejects: all-numeric headers, single long unstructured string, or headers
//   /// that are sentences (contain multiple spaces / punctuation).
//   bool _isValidColumnHeaders(List<String> cols) {
//     if (cols.isEmpty) return false;
//     // Every token must not be a plain integer/float
//     final allNumeric = cols.every((c) => double.tryParse(c) != null);
//     if (allNumeric) return false;
//     // If there is only one "column" and it looks like a sentence/paragraph
//     if (cols.length == 1 && cols.first.length > 60) return false;
//     // A column name should not contain sentence-level punctuation like '.' mid-word
//     // or be a multi-word natural-language sentence (more than 5 space-separated words)
//     final looksLikeSentence = cols.any((c) {
//       final wordCount = c.trim().split(RegExp(r'\s+')).length;
//       return wordCount > 5;
//     });
//     if (looksLikeSentence) return false;
//     return true;
//   }

//   /// Returns true if the text content looks like a SQL query.
//   bool _isValidQueryFile(String text) {
//     final trimmed = text.trim();
//     if (trimmed.isEmpty) return false;
//     final upper = trimmed.toUpperCase();
//     const sqlKeywords = [
//       'SELECT',
//       'WITH',
//       'INSERT',
//       'UPDATE',
//       'DELETE',
//       'CREATE',
//       'MERGE',
//       'CALL',
//       'EXEC',
//     ];
//     return sqlKeywords.any((kw) => upper.startsWith(kw));
//   }

//   static const _sepNames = {
//     ',': 'Comma (,)',
//     '|': 'Pipe (|)',
//     '\t': 'Tab (\\t)',
//     ';': 'Semicolon (;)',
//     ':': 'Colon (:)',
//     '~': 'Tilde (~)',
//     '^': 'Caret (^)',
//     '#': 'Hash (#)',
//     ' ': 'Space ( )',
//   };

//   /// Called when user changes the separator dropdown.
//   /// If a file is already uploaded, re-parses it with the new separator.
//   void _onSeparatorChanged(
//     BuildContext context,
//     PipelineController ctrl,
//     PipelineNode node,
//     String sep,
//   ) {
//     final messenger = ScaffoldMessenger.of(context);
//     final sepLabel = _sepNames[sep] ?? sep;

//     if (node.columnFileBytes == null) {
//       ctrl.updateNodeSeparator(node.id, sep);
//       setState(() => _sepAcknowledged = true);
//       return;
//     }

//     // File already uploaded — validate new separator against existing file
//     final text = utf8.decode(node.columnFileBytes!, allowMalformed: true);
//     final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
//     if (lines.isEmpty) {
//       ctrl.updateNodeSeparator(node.id, sep);
//       setState(() => _sepAcknowledged = true);
//       return;
//     }

//     final firstLine = lines.first;
//     // Only clear the file if it clearly uses a DIFFERENT separator.
//     // A single-column file has no separator in the first line — keep it.
//     const knownSeps = [',', '\t', '|', ';', ':', '~', '^', '#'];
//     final usesOtherSep = knownSeps.any(
//       (s) => s != sep && firstLine.contains(s),
//     );
//     if (!firstLine.contains(sep) && usesOtherSep) {
//       // Separator doesn't match current file — update separator and clear
//       // the file so user can re-upload with the correct separator.
//       ctrl.updateNodeSeparator(node.id, sep);
//       ctrl.clearNodeColumnFile(node.id);
//       setState(() => _sepAcknowledged = true);
//       messenger.showSnackBar(
//         SnackBar(
//           content: Text(
//             'Separator changed to "$sepLabel". Previous file cleared — please re-upload a file with "$sepLabel" separator.',
//           ),
//           backgroundColor: Colors.orange,
//         ),
//       );
//       return;
//     }

//     // Re-parse columns and rows with new separator
//     final cols = firstLine
//         .split(sep)
//         .map((c) => c.trim().replaceAll('"', '').trim())
//         .where((c) => c.isNotEmpty)
//         .toList();
//     if (cols.isEmpty) return;

//     final rows = <Map<String, dynamic>>[];
//     for (int i = 1; i < lines.length; i++) {
//       final vals = lines[i]
//           .split(sep)
//           .map((v) => v.trim().replaceAll('"', '').trim())
//           .toList();
//       final row = <String, dynamic>{};
//       for (int j = 0; j < cols.length; j++) {
//         row[cols[j]] = j < vals.length ? vals[j] : '';
//       }
//       rows.add(row);
//     }

//     ctrl.updateNodeSeparator(node.id, sep);
//     ctrl.setNodeColumns(
//       node.id,
//       cols,
//       rows,
//       node.fileName!,
//       bytes: node.columnFileBytes!,
//     );
//     setState(() => _sepAcknowledged = true);

//     messenger.showSnackBar(
//       SnackBar(
//         content: Text(
//           'File re-parsed with "$sepLabel": ${cols.length} columns found.',
//         ),
//         backgroundColor: AppColors.green,
//       ),
//     );
//   }

//   /// Map separator char → display label for the dropdown value.
//   /// Returns null when sep is empty so the dropdown shows its hint text.
//   String? _sepToLabel(String sep, List<String> separators) {
//     if (sep.isEmpty) return null;
//     const map = {
//       ',': 'Comma (,)',
//       '|': 'Pipe (|)',
//       '\t': 'Tab (\\t)',
//       ';': 'Semicolon (;)',
//       ':': 'Colon (:)',
//       '~': 'Tilde (~)',
//       '^': 'Caret (^)',
//       '#': 'Hash (#)',
//       ' ': 'Space ( )',
//     };
//     final label = map[sep];
//     return (label != null && separators.contains(label)) ? label : null;
//   }

//   InputDecoration _inputDecor({bool locked = false}) {
//     return InputDecoration(
//       contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(7),
//         borderSide: const BorderSide(color: AppColors.border2),
//       ),
//       enabledBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(7),
//         borderSide: const BorderSide(color: AppColors.border2),
//       ),
//       focusedBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(7),
//         borderSide: BorderSide(
//           color: locked ? AppColors.border2 : AppColors.blue,
//         ),
//       ),
//       filled: true,
//       fillColor: locked
//           ? AppColors.surface2.withValues(alpha: 0.6)
//           : AppColors.surface2,
//       suffixIcon: locked
//           ? const Icon(
//               Icons.lock_outline_rounded,
//               size: 13,
//               color: AppColors.textMuted,
//             )
//           : null,
//     );
//   }

//   Widget _uploadButton({
//     required IconData icon,
//     required String label,
//     required Function()? onTap,
//     bool isLocked = false,
//   }) {
//     return Opacity(
//       opacity: isLocked ? 0.5 : 1.0,
//       child: InkWell(
//         onTap: onTap,
//         child: Container(
//           width: double.infinity,
//           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(8),
//             border: Border.all(
//               color: AppColors.border2,
//               width: 1.5,
//               style: BorderStyle.solid,
//             ),
//           ),
//           child: Row(
//             children: [
//               Icon(
//                 isLocked ? Icons.lock_outline_rounded : icon,
//                 color: AppColors.textDim,
//                 size: 16,
//               ),
//               const SizedBox(width: 8),
//               Text(
//                 label,
//                 style: const TextStyle(
//                   color: AppColors.textDim,
//                   fontSize: 12,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _fileInfoBar(String text, String? badge, Color color) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(6),
//         color: color.withValues(alpha: 0.08),
//         border: Border.all(color: color.withValues(alpha: 0.2)),
//       ),
//       child: Row(
//         children: [
//           Icon(Icons.check_circle_outline, color: color, size: 14),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Text(text, style: TextStyle(color: color, fontSize: 11)),
//           ),
//           if (badge != null)
//             Text(
//               badge,
//               style: TextStyle(
//                 color: color,
//                 fontSize: 11,
//                 fontWeight: FontWeight.w700,
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }

// // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// // CONFIRM SECTION
// // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// class _ConfirmSection extends StatelessWidget {
//   final PipelineNode node;
//   final PipelineController ctrl;
//   const _ConfirmSection({required this.node, required this.ctrl});

//   String? _validate() {
//     final isManual = node.type == NodeType.manual;
//     if (node.name.trim().isEmpty) return 'Source Name is required.';
//     if (node.sourceTypeValue.isEmpty) return 'Source Type is required.';
//     if (isManual) {
//       if (node.fileName == null) return 'Upload Column File is required.';
//     } else {
//       if (node.queryFileName == null) return 'Upload Query File is required.';
//       if (node.fileName == null) return 'Upload Column File is required.';
//     }
//     return null;
//   }

//   @override
//   Widget build(BuildContext context) {
//     final state = node.confirmState;
//     final isConfirmed = state == NodeConfirmState.confirmed;
//     final isEditing = state == NodeConfirmState.editing;
//     final isReady = _validate() == null;

//     if (isConfirmed) {
//       // ── Confirmed state ──
//       return Column(
//         children: [
//           // Container(
//           //   width: double.infinity,
//           //   padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
//           //   decoration: BoxDecoration(
//           //     borderRadius: BorderRadius.circular(8),
//           //     color: AppColors.green.withValues(alpha: 0.1),
//           //     border: Border.all(color: AppColors.green.withValues(alpha: 0.3)),
//           //   ),
//           //   child: const Row(
//           //     mainAxisAlignment: MainAxisAlignment.center,
//           //     children: [
//           //       Icon(
//           //         Icons.check_circle_rounded,
//           //         color: AppColors.green,
//           //         size: 16,
//           //       ),
//           //       SizedBox(width: 8),
//           //       Text(
//           //         'Confirmed',
//           //         style: TextStyle(
//           //           color: AppColors.green,
//           //           fontSize: 12,
//           //           fontWeight: FontWeight.w700,
//           //         ),
//           //       ),
//           //     ],
//           //   ),
//           // ),
//           // const SizedBox(height: 8),
//           InkWell(
//             onTap: () async {
//               if (ctrl.isAnyUniMailing) {
//                 await confirmEditNode(context, ctrl, node.name, node.type);
//               } else {
//                 ctrl.editNode(node.id);
//               }
//             },
//             child: Container(
//               width: double.infinity,
//               padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(
//                   color: AppColors.amber.withValues(alpha: 0.4),
//                 ),
//                 color: AppColors.amber.withValues(alpha: 0.07),
//               ),
//               child: const Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(Icons.edit_rounded, color: AppColors.amber, size: 14),
//                   SizedBox(width: 8),
//                   Text(
//                     'Edit',
//                     style: TextStyle(
//                       color: AppColors.amber,
//                       fontSize: 12,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       );
//     }

//     // ── Not configured / Editing state ──
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         if (isEditing) ...[
//           Container(
//             width: double.infinity,
//             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
//             margin: const EdgeInsets.only(bottom: 10),
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(7),
//               color: AppColors.amber.withValues(alpha: 0.08),
//               border: Border.all(color: AppColors.amber.withValues(alpha: 0.3)),
//             ),
//             child: const Row(
//               children: [
//                 Icon(Icons.edit_rounded, color: AppColors.amber, size: 13),
//                 SizedBox(width: 6),
//                 Text(
//                   'Editing — re-confirm when done',
//                   style: TextStyle(color: AppColors.amber, fontSize: 11),
//                 ),
//               ],
//             ),
//           ),
//         ],
//         InkWell(
//           onTap: () {
//             final error = _validate();
//             if (error != null) {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(content: Text(error), backgroundColor: Colors.red),
//               );
//               return;
//             }
//             ctrl.confirmNode(node.id);
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: Text('${node.name} confirmed successfully.'),
//                 backgroundColor: AppColors.green,
//               ),
//             );
//           },
//           child: AnimatedContainer(
//             duration: const Duration(milliseconds: 300),
//             width: double.infinity,
//             padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(8),
//               color: isReady
//                   ? AppColors.blue
//                   : AppColors.border.withValues(alpha: 0.5),
//               border: Border.all(
//                 color: isReady ? AppColors.blue : AppColors.border2,
//                 width: isReady ? 2.0 : 1.0,
//               ),
//               boxShadow: isReady
//                   ? [
//                       BoxShadow(
//                         color: AppColors.blue.withValues(alpha: 0.35),
//                         blurRadius: 10,
//                         spreadRadius: 1,
//                         offset: const Offset(0, 3),
//                       ),
//                     ]
//                   : null,
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(
//                   Icons.check_rounded,
//                   color: isReady ? Colors.white : AppColors.textMuted,
//                   size: 15,
//                 ),
//                 const SizedBox(width: 8),
//                 Text(
//                   'Configure',
//                   style: TextStyle(
//                     color: isReady ? Colors.white : AppColors.textMuted,
//                     fontSize: 12,
//                     fontWeight: FontWeight.w700,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }

// // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// // SOURCE TYPE DROPDOWN
// // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// class _SourceTypeDropdown extends StatelessWidget {
//   final PipelineNode node;
//   final PipelineController ctrl;
//   final bool isLocked;
//   const _SourceTypeDropdown({
//     required this.node,
//     required this.ctrl,
//     this.isLocked = false,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final master = context.watch<PipelineMasterProvider>();
//     return Opacity(
//       opacity: isLocked ? 0.55 : 1.0,
//       child: IgnorePointer(
//         ignoring: isLocked,
//         child: _buildDropdown(context, master),
//       ),
//     );
//   }

//   Widget _buildDropdown(BuildContext context, PipelineMasterProvider master) {
//     if (master.loading) {
//       return Container(
//         width: double.infinity,
//         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(7),
//           border: Border.all(color: AppColors.border2),
//           color: AppColors.surface2,
//         ),
//         child: const Row(
//           children: [
//             SizedBox(
//               width: 12,
//               height: 12,
//               child: CircularProgressIndicator(
//                 strokeWidth: 1.5,
//                 color: AppColors.textDim,
//               ),
//             ),
//             SizedBox(width: 8),
//             Text(
//               'Loading...',
//               style: TextStyle(color: AppColors.textMuted, fontSize: 12),
//             ),
//           ],
//         ),
//       );
//     }

//     if (master.sourceTypes.isEmpty) {
//       // Fallback: show node type label read-only
//       return Container(
//         width: double.infinity,
//         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(7),
//           border: Border.all(color: AppColors.border2),
//           color: AppColors.surface2,
//         ),
//         child: Row(
//           children: [
//             Icon(node.type.icon, color: node.type.color, size: 14),
//             const SizedBox(width: 8),
//             Text(
//               node.type.label,
//               style: const TextStyle(color: AppColors.text, fontSize: 12),
//             ),
//           ],
//         ),
//       );
//     }

//     final matchedItem = node.sourceTypeId > 0
//         ? master.sourceTypes.where((i) => i.id == node.sourceTypeId).firstOrNull
//         : null;

//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(7),
//         border: Border.all(color: AppColors.blue.withValues(alpha: 0.3)),
//         color: AppColors.blue.withValues(alpha: 0.05),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(4),
//               color: AppColors.blue.withValues(alpha: 0.12),
//               border: Border.all(color: AppColors.blue.withValues(alpha: 0.25)),
//             ),
//             child: Text(
//               matchedItem?.sourceValue ?? node.sourceTypeValue,
//               style: const TextStyle(
//                 color: AppColors.blue,
//                 fontSize: 9,
//                 fontWeight: FontWeight.w700,
//                 fontFamily: 'monospace',
//               ),
//             ),
//           ),
//           const SizedBox(width: 8),
//           // Expanded(
//           //   child: Text(
//           //     matchedItem?.sourceName ?? node.sourceTypeName,
//           //     style: const TextStyle(
//           //       color: AppColors.text,
//           //       fontSize: 12,
//           //       fontWeight: FontWeight.w500,
//           //     ),
//           //   ),
//           // ),
//           const Icon(Icons.lock_outline, size: 12, color: AppColors.textDim),
//         ],
//       ),
//     );
//   }
// }

// // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// // STATUS BAR (same as HTML .statusbar)
// // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// CONFIG PANEL

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:vizualizer/core/theme/app_theme.dart';
import 'package:vizualizer/data/models/pipeline_models.dart';
import 'package:vizualizer/presentation/controllers/pipeline_controller.dart';
import 'package:vizualizer/presentation/providers/pipeline_master_provider.dart';
import 'package:vizualizer/presentation/widgets/common/searchable_dropdown.dart';

/// Shows a confirmation dialog before deleting a pipeline node, then routes
/// to the appropriate focused-delete controller method based on [nodeType]:
/// source → [PipelineController.deleteSourceNode], join →
/// [PipelineController.deleteJoinAndOutput], output →
/// [PipelineController.deleteOutputOnly]. Sources never trigger a whole-canvas
/// wipe — they're the foundation of the pipeline.
Future<void> confirmDeleteNode(
  BuildContext ctx,
  PipelineController ctrl,
  String id,
  String name,
  NodeType nodeType,
) async {
  final dialogTitle = nodeType == NodeType.output
      ? 'Delete Output Node?'
      : nodeType == NodeType.join
      ? 'Delete Join Node?'
      : 'Delete Source?';
  final nodeLabel = nodeType == NodeType.output
      ? 'Output'
      : nodeType == NodeType.join
      ? 'Join'
      : 'Source';

  final ok = await _showFocusedDeleteDialog(
    ctx: ctx,
    title: dialogTitle,
    nodeName: name.isNotEmpty ? name : nodeLabel,
    nodeType: nodeType,
  );
  if (ok != true || !ctx.mounted) return;
  switch (nodeType) {
    case NodeType.join:
      ctrl.deleteJoinAndOutput(id);
      break;
    case NodeType.output:
      ctrl.deleteOutputOnly(id);
      break;
    default:
      ctrl.deleteSourceNode(id);
  }
}

/// Lightweight per-node-type confirm dialog. Honest about scope: source delete
/// removes only the source (and the now-stale output preview); join removes
/// join + output; output removes only the output. Never claims to clear the
/// whole canvas.
Future<bool?> _showFocusedDeleteDialog({
  required BuildContext ctx,
  required String title,
  required String nodeName,
  required NodeType nodeType,
}) {
  final impact = nodeType == NodeType.join
      ? 'The Join node and its Output Preview will be removed. Source nodes stay on the canvas.'
      : nodeType == NodeType.output
      ? 'Only the Output Preview will be removed. Sources and the Join node stay.'
      : 'Only this source will be removed. Other sources stay. The Output Preview will be cleared since it depends on this source.';
  return showDialog<bool>(
    context: ctx,
    barrierDismissible: false,
    builder: (dialogCtx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      title: Row(
        children: [
          const Icon(
            Icons.delete_outline_rounded,
            color: AppColors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.red,
              ),
            ),
          ),
        ],
      ),
      content: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.text,
            height: 1.5,
          ),
          children: [
            const TextSpan(text: 'Delete '),
            TextSpan(
              text: nodeName,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const TextSpan(text: '?\n\n'),
            TextSpan(
              text: impact,
              style: const TextStyle(color: AppColors.textDim, fontSize: 12),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogCtx).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(dialogCtx).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.red,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Delete',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

/// Confirms a source-file replacement that would invalidate downstream
/// configuration (join mappings referencing this source, the output preview,
/// and the active output key's saved snapshot). Returns true if the user
/// agrees and the cascade reset has been applied; false to abort the upload.
///
/// Other source nodes are preserved — only the downstream of the changed
/// source is reset.
Future<bool> confirmReplaceSourceFile(
  BuildContext ctx,
  PipelineController ctrl,
  String sourceId,
  String sourceName,
) async {
  if (!ctrl.hasDownstreamConfigForSource(sourceId)) return true;
  final displayName = sourceName.isNotEmpty ? sourceName : 'this source';
  final ok = await showDialog<bool>(
    context: ctx,
    barrierDismissible: false,
    builder: (dialogCtx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      title: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.amber,
            size: 20,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Replace source file?',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.amber,
              ),
            ),
          ),
        ],
      ),
      content: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.text,
            height: 1.5,
          ),
          children: [
            const TextSpan(text: 'Changing the file for '),
            TextSpan(
              text: displayName,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const TextSpan(
              text:
                  ' will reset its join mappings and the Output Preview because its columns may change. Other source nodes will stay on the canvas.',
              style: TextStyle(color: AppColors.textDim, fontSize: 12),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogCtx).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(dialogCtx).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.amber,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Replace',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
  if (ok != true) return false;
  ctrl.cascadeResetForSourceChange(sourceId);
  return true;
}

class ConfigPanel extends StatefulWidget {
  const ConfigPanel({super.key});

  @override
  State<ConfigPanel> createState() => _ConfigPanelState();
}

class _ConfigPanelState extends State<ConfigPanel>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _anim;

  // Track which node is open so we reset state on switch
  String? _prevNodeId;

  // True only after the user explicitly changes the separator dropdown
  bool _sepAcknowledged = false;

  // Persistent controller for the source-name field so typing doesn't lose focus
  final TextEditingController _nameCtrl = TextEditingController();

  int _lastCanvasVersion = 0;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulse.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  // ── Returns 0-4 depending on what the user should fill next ──
  // Non-manual : 0=sourceName  1=queryFile   2=columnFile  3=outputFormat  4=configBtn
  // Manual     : 0=sourceName  1=separator   2=columnFile  3=outputFormat  4=configBtn
  int _computeStep(PipelineNode node) {
    if (node.confirmState == NodeConfirmState.confirmed) return -1;
    if (node.name.trim().isEmpty) return 0;
    final isManual = node.type == NodeType.manual;
    if (isManual) {
      if (!_sepAcknowledged) return 1; // separator
      if (node.fileName == null) return 2; // column file
      if (node.selectedCols.isEmpty) return 3; // output format
      return 4; // config button
    } else {
      if (node.queryFileName == null) return 1; // query file
      if (node.fileName == null) return 2; // column file
      if (node.selectedCols.isEmpty) return 3; // output format
      return 4; // config button
    }
  }

  // ── Wraps [child] with a pulsing glow border only when [forStep] is active ──
  Widget _hl(
    int forStep,
    int activeStep,
    Widget child, {
    Color color = AppColors.blue,
    bool borderOnly = false,
  }) {
    // Always wrap in AnimatedBuilder + Container with a BoxDecoration so the
    // widget tree structure stays constant as `step` changes.
    // KEY: decoration must never be null — Container adds/removes an internal
    // DecoratedBox when decoration flips null↔non-null, which remounts the
    // child and kills TextField focus.  Use alpha=0 for the inactive state.
    return AnimatedBuilder(
      animation: _anim,
      child:
          child, // passed as AnimatedBuilder.child so it isn't rebuilt every frame
      builder: (_, builtChild) {
        final isActive = forStep == activeStep;
        final t = isActive ? _anim.value : 0.0;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: color.withValues(alpha: t * 0.65),
              width: 1.5,
            ),
            color: borderOnly ? null : color.withValues(alpha: t * 0.05),
            boxShadow: t > 0.1 && !borderOnly
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: t * 0.18),
                      blurRadius: 6,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: builtChild,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PipelineController>(
      builder: (context, ctrl, _) {
        final node = ctrl.selectedNodeId != null
            ? ctrl.findNode(ctrl.selectedNodeId!)
            : null;

        // ── Detect canvas clear → reset all local state ──
        if (ctrl.canvasVersion != _lastCanvasVersion) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _nameCtrl.clear();
            setState(() {
              _lastCanvasVersion = ctrl.canvasVersion;
              _prevNodeId = null;
              _sepAcknowledged = false;
            });
          });
        }

        // ── Detect node switch → reset state and sync name controller ──
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final newId = ctrl.selectedNodeId;
          if (newId != _prevNodeId) {
            final newNode = newId != null ? ctrl.findNode(newId) : null;
            _nameCtrl.text = newNode?.name ?? '';
            setState(() {
              _prevNodeId = newId;
              _sepAcknowledged = newNode?.separator.isNotEmpty ?? false;
            });
          }
        });

        return Container(
          width: 260,
          color: AppColors.surface,
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        node != null
                            ? 'Configure: ${node.name}'
                            : 'Configure Node',
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (node != null)
                      InkWell(
                        onTap: () => ctrl.selectNode(null),
                        child: const Icon(
                          Icons.close,
                          color: AppColors.textDim,
                          size: 16,
                        ),
                      ),
                  ],
                ),
              ),

              // Body
              Expanded(
                child: node == null
                    ? const Center(
                        child: Text(
                          'Click a node to configure',
                          style: TextStyle(
                            color: AppColors.textDim,
                            fontSize: 12,
                          ),
                        ),
                      )
                    : _buildConfig(context, ctrl, node),
              ),

              // Delete button
              if (node != null && node.type.isSource)
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: InkWell(
                    onTap: () => confirmDeleteNode(
                      context,
                      ctrl,
                      node.id,
                      node.name,
                      node.type,
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.red.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          '🗑 Delete Node',
                          style: TextStyle(
                            color: AppColors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConfig(
    BuildContext context,
    PipelineController ctrl,
    PipelineNode node,
  ) {
    if (!node.type.isSource) {
      return const Center(
        child: Text(
          'Use node card controls',
          style: TextStyle(color: AppColors.textDim, fontSize: 11),
        ),
      );
    }

    final isLocked = node.confirmState == NodeConfirmState.confirmed;
    final isManual = node.type == NodeType.manual;
    final step = _computeStep(node);
    final separators = [
      'Comma (,)',
      'Pipe (|)',
      'Tab (\\t)',
      'Semicolon (;)',
      'Colon (:)',
      'Tilde (~)',
      'Caret (^)',
      'Hash (#)',
      'Space ( )',
    ];

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        // ── Source Type (API-driven dropdown) ──
        const Text('Source Type *', style: AppTextStyles.fieldLabel),
        const SizedBox(height: 4),
        _SourceTypeDropdown(node: node, ctrl: ctrl, isLocked: isLocked),
        const SizedBox(height: 14),

        // ── Source Name ── (step 0)
        const Text('Source Name *', style: AppTextStyles.fieldLabel),
        const SizedBox(height: 4),
        _hl(
          0,
          step,
          TextFormField(
            controller: _nameCtrl,
            readOnly: isLocked,
            onChanged: isLocked ? null : (v) => ctrl.updateNodeName(node.id, v),
            style: TextStyle(
              color: isLocked ? AppColors.textDim : AppColors.text,
              fontSize: 12.5,
            ),
            decoration: _inputDecor(locked: isLocked).copyWith(
              hintText: 'e.g. Customer_Data',
              hintStyle: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
          ),
          borderOnly: true,
        ),
        const SizedBox(height: 14),

        // ── Separator (Manual only) ── (step 1 for manual)
        if (isManual) ...[
          const Text('File Separator *', style: AppTextStyles.fieldLabel),
          const SizedBox(height: 4),
          _hl(
            1,
            step,
            SearchableDropdownField(
              value: _sepToLabel(node.separator, separators),
              hint: '— Select Separator —',
              items: separators,
              enabled: !isLocked,
              onChanged: (v) {
                if (v != null) {
                  final sep = v.contains('\\t')
                      ? '\t'
                      : v.contains(',')
                      ? ','
                      : v.contains('|')
                      ? '|'
                      : v.contains(';')
                      ? ';'
                      : v.contains(':')
                      ? ':'
                      : v.contains('~')
                      ? '~'
                      : v.contains('^')
                      ? '^'
                      : v.contains('#')
                      ? '#'
                      : ' ';
                  _onSeparatorChanged(context, ctrl, node, sep);
                }
              },
            ),
            borderOnly: true,
          ),
          const SizedBox(height: 14),
        ],

        // ── Non-manual: Query File Upload ── (step 1 for non-manual)
        if (!isManual) ...[
          const Text('Upload Query File', style: AppTextStyles.fieldLabel),
          const SizedBox(height: 4),
          _hl(
            1,
            step,
            _uploadButton(
              icon: Icons.description_outlined,
              label: 'Upload Query File (.txt)',
              isLocked: isLocked,
              onTap: isLocked
                  ? null
                  : () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['txt'],
                        withData: true,
                      );
                      if (result != null && result.files.single.bytes != null) {
                        final fileName = result.files.single.name;
                        final ext = fileName.contains('.')
                            ? fileName.split('.').last.toLowerCase()
                            : '';
                        if (ext != 'txt') {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Invalid file type: only .txt files are allowed for query upload.',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        final queryBytes = result.files.single.bytes!;
                        final queryText = utf8.decode(
                          queryBytes,
                          allowMalformed: true,
                        );
                        if (!_isValidQueryFile(queryText)) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Invalid file: the query file must contain a valid SQL query (e.g. starting with SELECT, WITH, INSERT, etc.). Column/CSV files are not allowed here.',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        // Replacing an existing query file may yield different
                        // columns — gate the apply behind a consent that wipes
                        // downstream config first.
                        if (node.queryFileName != null && context.mounted) {
                          final proceed = await confirmReplaceSourceFile(
                            context,
                            ctrl,
                            node.id,
                            node.name,
                          );
                          if (!proceed) return;
                        }
                        ctrl.setQueryFile(
                          node.id,
                          fileName,
                          bytes: queryBytes.toList(),
                        );
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('Query file loaded: $fileName'),
                            backgroundColor: AppColors.green,
                          ),
                        );
                      }
                    },
            ),
            borderOnly: true,
          ),
          if (node.queryFileName != null) ...[
            const SizedBox(height: 4),
            _fileInfoBar(node.queryFileName!, null, AppColors.blue),
          ],
          const SizedBox(height: 14),
        ],

        // ── Column File Upload ── (step 2)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Upload Column File (.csv / .txt) *',
              style: AppTextStyles.fieldLabel,
            ),
            const SizedBox(height: 4),
            _hl(
              2,
              step,
              _uploadButton(
                icon: Icons.upload_file_rounded,
                label: 'Upload Column File (.csv / .txt)',
                isLocked: isLocked,
                onTap: isLocked
                    ? null
                    : () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['csv', 'txt'],
                          withData: true,
                        );
                        if (result == null ||
                            result.files.single.bytes == null) {
                          return;
                        }
                        final bytes = result.files.single.bytes!;
                        final fileName = result.files.single.name;
                        final text = utf8.decode(bytes, allowMalformed: true);
                        final lines = text
                            .split('\n')
                            .where((l) => l.trim().isNotEmpty)
                            .toList();
                        if (lines.isEmpty) return;
                        final firstLine = lines.first;
                        // For manual nodes, use the separator already chosen by
                        // the user; for others, auto-detect from file content.
                        String sep;
                        if (isManual && node.separator.isNotEmpty) {
                          sep = node.separator;
                          // Only reject if the file clearly uses a DIFFERENT
                          // separator. A single-column file has no separator
                          // in the first line at all — that is valid.
                          const knownSeps = [
                            ',',
                            '\t',
                            '|',
                            ';',
                            ':',
                            '~',
                            '^',
                            '#',
                          ];
                          final usesOtherSep = knownSeps.any(
                            (s) => s != sep && firstLine.contains(s),
                          );
                          if (!firstLine.contains(sep) && usesOtherSep) {
                            final sepLabel = _sepNames[sep] ?? sep;
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  'The uploaded file does not contain the selected separator "$sepLabel". Please select the correct separator or upload a matching file.',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                        } else {
                          sep = ',';
                          if ('\t'.allMatches(firstLine).isNotEmpty) {
                            sep = '\t';
                          } else if ('|'.allMatches(firstLine).isNotEmpty) {
                            sep = '|';
                          } else if (';'.allMatches(firstLine).isNotEmpty) {
                            sep = ';';
                          } else if (':'.allMatches(firstLine).isNotEmpty) {
                            sep = ':';
                          } else if ('~'.allMatches(firstLine).isNotEmpty) {
                            sep = '~';
                          } else if ('^'.allMatches(firstLine).isNotEmpty) {
                            sep = '^';
                          } else if ('#'.allMatches(firstLine).isNotEmpty) {
                            sep = '#';
                          } else if (' '.allMatches(firstLine).isNotEmpty) {
                            sep = ' ';
                          }
                        }
                        final cols = firstLine
                            .split(sep)
                            .map((c) => c.trim().replaceAll('"', '').trim())
                            .where((c) => c.isNotEmpty)
                            .toList();
                        if (cols.isEmpty) return;
                        // Reject if the file is actually a SQL query file
                        if (_isValidQueryFile(text)) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Invalid file: this looks like a SQL query file. Please upload a column file (.csv / .txt with column headers).',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        if (!_isValidColumnHeaders(cols)) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Invalid file: the first row must contain column headers, not raw data or unstructured text.',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        final rows = <Map<String, dynamic>>[];
                        for (int i = 1; i < lines.length; i++) {
                          final vals = lines[i]
                              .split(sep)
                              .map((v) => v.trim().replaceAll('"', '').trim())
                              .toList();
                          final row = <String, dynamic>{};
                          for (int j = 0; j < cols.length; j++) {
                            row[cols[j]] = j < vals.length ? vals[j] : '';
                          }
                          rows.add(row);
                        }
                        // Replacing an existing column file is what actually
                        // changes the source's column list — gate the apply
                        // behind a downstream-reset consent dialog.
                        if (node.fileName != null && context.mounted) {
                          final proceed = await confirmReplaceSourceFile(
                            context,
                            ctrl,
                            node.id,
                            node.name,
                          );
                          if (!proceed) return;
                        }
                        ctrl.setNodeColumns(
                          node.id,
                          cols,
                          rows,
                          fileName,
                          bytes: bytes.toList(),
                        );
                        ctrl.updateNodeSeparator(node.id, sep);
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              '${cols.length} columns, ${rows.length} rows extracted from $fileName',
                            ),
                            backgroundColor: AppColors.green,
                          ),
                        );
                      },
              ),
              borderOnly: true,
            ),
            if (node.fileName != null) ...[
              const SizedBox(height: 4),
              _fileInfoBar(
                node.fileName!,
                '${node.cols.length} cols',
                AppColors.green,
              ),
            ],
          ],
        ),
        const SizedBox(height: 14),

        const SizedBox(height: 20),

        // ── Confirm / Edit button ──
        _ConfirmSection(node: node, ctrl: ctrl),

        const SizedBox(height: 8),
      ],
    );
  }

  /// Returns true if the extracted column headers look like real column names.
  /// Rejects: all-numeric headers, single long unstructured string, or headers
  /// that are sentences (contain multiple spaces / punctuation).
  bool _isValidColumnHeaders(List<String> cols) {
    if (cols.isEmpty) return false;
    // Every token must not be a plain integer/float
    final allNumeric = cols.every((c) => double.tryParse(c) != null);
    if (allNumeric) return false;
    // If there is only one "column" and it looks like a sentence/paragraph
    if (cols.length == 1 && cols.first.length > 60) return false;
    // A column name should not contain sentence-level punctuation like '.' mid-word
    // or be a multi-word natural-language sentence (more than 5 space-separated words)
    final looksLikeSentence = cols.any((c) {
      final wordCount = c.trim().split(RegExp(r'\s+')).length;
      return wordCount > 5;
    });
    if (looksLikeSentence) return false;
    return true;
  }

  /// Returns true if the text content looks like a SQL query.
  bool _isValidQueryFile(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;
    final upper = trimmed.toUpperCase();
    const sqlKeywords = [
      'SELECT',
      'WITH',
      'INSERT',
      'UPDATE',
      'DELETE',
      'CREATE',
      'MERGE',
      'CALL',
      'EXEC',
    ];
    return sqlKeywords.any((kw) => upper.startsWith(kw));
  }

  static const _sepNames = {
    ',': 'Comma (,)',
    '|': 'Pipe (|)',
    '\t': 'Tab (\\t)',
    ';': 'Semicolon (;)',
    ':': 'Colon (:)',
    '~': 'Tilde (~)',
    '^': 'Caret (^)',
    '#': 'Hash (#)',
    ' ': 'Space ( )',
  };

  /// Called when user changes the separator dropdown.
  /// If a file is already uploaded, re-parses it with the new separator.
  Future<void> _onSeparatorChanged(
    BuildContext context,
    PipelineController ctrl,
    PipelineNode node,
    String sep,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final sepLabel = _sepNames[sep] ?? sep;

    if (node.columnFileBytes == null) {
      ctrl.updateNodeSeparator(node.id, sep);
      setState(() => _sepAcknowledged = true);
      return;
    }

    // File already uploaded — validate new separator against existing file
    final text = utf8.decode(node.columnFileBytes!, allowMalformed: true);
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) {
      ctrl.updateNodeSeparator(node.id, sep);
      setState(() => _sepAcknowledged = true);
      return;
    }

    final firstLine = lines.first;
    // Only clear the file if it clearly uses a DIFFERENT separator.
    // A single-column file has no separator in the first line — keep it.
    const knownSeps = [',', '\t', '|', ';', ':', '~', '^', '#'];
    final usesOtherSep = knownSeps.any(
      (s) => s != sep && firstLine.contains(s),
    );
    if (!firstLine.contains(sep) && usesOtherSep) {
      // Separator doesn't match current file — update separator and clear
      // the file so user can re-upload with the correct separator.
      ctrl.updateNodeSeparator(node.id, sep);
      ctrl.clearNodeColumnFile(node.id);
      setState(() => _sepAcknowledged = true);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Separator changed to "$sepLabel". Previous file cleared — please re-upload a file with "$sepLabel" separator.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Re-parse columns and rows with new separator
    final cols = firstLine
        .split(sep)
        .map((c) => c.trim().replaceAll('"', '').trim())
        .where((c) => c.isNotEmpty)
        .toList();
    if (cols.isEmpty) return;

    final rows = <Map<String, dynamic>>[];
    for (int i = 1; i < lines.length; i++) {
      final vals = lines[i]
          .split(sep)
          .map((v) => v.trim().replaceAll('"', '').trim())
          .toList();
      final row = <String, dynamic>{};
      for (int j = 0; j < cols.length; j++) {
        row[cols[j]] = j < vals.length ? vals[j] : '';
      }
      rows.add(row);
    }

    // Re-parsing with a different separator can change the column list, so
    // gate the apply with a downstream-reset consent just like a fresh upload.
    if (context.mounted) {
      final proceed = await confirmReplaceSourceFile(
        context,
        ctrl,
        node.id,
        node.name,
      );
      if (!proceed) return;
    }
    ctrl.updateNodeSeparator(node.id, sep);
    ctrl.setNodeColumns(
      node.id,
      cols,
      rows,
      node.fileName!,
      bytes: node.columnFileBytes!,
    );
    if (!mounted) return;
    setState(() => _sepAcknowledged = true);

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'File re-parsed with "$sepLabel": ${cols.length} columns found.',
        ),
        backgroundColor: AppColors.green,
      ),
    );
  }

  /// Map separator char → display label for the dropdown value.
  /// Returns null when sep is empty so the dropdown shows its hint text.
  String? _sepToLabel(String sep, List<String> separators) {
    if (sep.isEmpty) return null;
    const map = {
      ',': 'Comma (,)',
      '|': 'Pipe (|)',
      '\t': 'Tab (\\t)',
      ';': 'Semicolon (;)',
      ':': 'Colon (:)',
      '~': 'Tilde (~)',
      '^': 'Caret (^)',
      '#': 'Hash (#)',
      ' ': 'Space ( )',
    };
    final label = map[sep];
    return (label != null && separators.contains(label)) ? label : null;
  }

  InputDecoration _inputDecor({bool locked = false}) {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
        borderSide: const BorderSide(color: AppColors.border2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
        borderSide: const BorderSide(color: AppColors.border2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
        borderSide: BorderSide(
          color: locked ? AppColors.border2 : AppColors.blue,
        ),
      ),
      filled: true,
      fillColor: locked
          ? AppColors.surface2.withValues(alpha: 0.6)
          : AppColors.surface2,
      suffixIcon: locked
          ? const Icon(
              Icons.lock_outline_rounded,
              size: 13,
              color: AppColors.textMuted,
            )
          : null,
    );
  }

  Widget _uploadButton({
    required IconData icon,
    required String label,
    required Function()? onTap,
    bool isLocked = false,
  }) {
    return Opacity(
      opacity: isLocked ? 0.5 : 1.0,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.border2,
              width: 1.5,
              style: BorderStyle.solid,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isLocked ? Icons.lock_outline_rounded : icon,
                color: AppColors.textDim,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textDim,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fileInfoBar(String text, String? badge, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: color, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: color, fontSize: 11)),
          ),
          if (badge != null)
            Text(
              badge,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// CONFIRM SECTION
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _ConfirmSection extends StatelessWidget {
  final PipelineNode node;
  final PipelineController ctrl;
  const _ConfirmSection({required this.node, required this.ctrl});

  String? _validate() {
    final isManual = node.type == NodeType.manual;
    if (node.name.trim().isEmpty) return 'Source Name is required.';
    if (node.typeId.isEmpty) return 'Source Type is required.';
    if (isManual) {
      if (node.fileName == null) return 'Upload Column File is required.';
    } else {
      if (node.queryFileName == null) return 'Upload Query File is required.';
      if (node.fileName == null) return 'Upload Column File is required.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final state = node.confirmState;
    final isConfirmed = state == NodeConfirmState.confirmed;
    final isEditing = state == NodeConfirmState.editing;
    final isReady = _validate() == null;

    if (isConfirmed) {
      // ── Confirmed state ──
      return Column(
        children: [
          // Container(
          //   width: double.infinity,
          //   padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          //   decoration: BoxDecoration(
          //     borderRadius: BorderRadius.circular(8),
          //     color: AppColors.green.withValues(alpha: 0.1),
          //     border: Border.all(color: AppColors.green.withValues(alpha: 0.3)),
          //   ),
          //   child: const Row(
          //     mainAxisAlignment: MainAxisAlignment.center,
          //     children: [
          //       Icon(
          //         Icons.check_circle_rounded,
          //         color: AppColors.green,
          //         size: 16,
          //       ),
          //       SizedBox(width: 8),
          //       Text(
          //         'Confirmed',
          //         style: TextStyle(
          //           color: AppColors.green,
          //           fontSize: 12,
          //           fontWeight: FontWeight.w700,
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
          // const SizedBox(height: 8),
          InkWell(
            onTap: () => ctrl.editNode(node.id),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.amber.withValues(alpha: 0.4),
                ),
                color: AppColors.amber.withValues(alpha: 0.07),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.edit_rounded, color: AppColors.amber, size: 14),
                  SizedBox(width: 8),
                  Text(
                    'Edit',
                    style: TextStyle(
                      color: AppColors.amber,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // ── Not configured / Editing state ──
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isEditing) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              color: AppColors.amber.withValues(alpha: 0.08),
              border: Border.all(color: AppColors.amber.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.edit_rounded, color: AppColors.amber, size: 13),
                SizedBox(width: 6),
                Text(
                  'Editing — re-confirm when done',
                  style: TextStyle(color: AppColors.amber, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
        InkWell(
          onTap: () {
            final error = _validate();
            if (error != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(error), backgroundColor: Colors.red),
              );
              return;
            }
            ctrl.confirmNode(node.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${node.name} confirmed successfully.'),
                backgroundColor: AppColors.green,
              ),
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: isReady
                  ? AppColors.blue
                  : AppColors.border.withValues(alpha: 0.5),
              border: Border.all(
                color: isReady ? AppColors.blue : AppColors.border2,
                width: isReady ? 2.0 : 1.0,
              ),
              boxShadow: isReady
                  ? [
                      BoxShadow(
                        color: AppColors.blue.withValues(alpha: 0.35),
                        blurRadius: 10,
                        spreadRadius: 1,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_rounded,
                  color: isReady ? Colors.white : AppColors.textMuted,
                  size: 15,
                ),
                const SizedBox(width: 8),
                Text(
                  'Configure',
                  style: TextStyle(
                    color: isReady ? Colors.white : AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// SOURCE TYPE DROPDOWN
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _SourceTypeDropdown extends StatelessWidget {
  final PipelineNode node;
  final PipelineController ctrl;
  final bool isLocked;
  const _SourceTypeDropdown({
    required this.node,
    required this.ctrl,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    final master = context.watch<PipelineMasterProvider>();
    return Opacity(
      opacity: isLocked ? 0.55 : 1.0,
      child: IgnorePointer(
        ignoring: isLocked,
        child: _buildDropdown(context, master),
      ),
    );
  }

  Widget _buildDropdown(BuildContext context, PipelineMasterProvider master) {
    if (master.loading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: AppColors.border2),
          color: AppColors.surface2,
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: AppColors.textDim,
              ),
            ),
            SizedBox(width: 8),
            Text(
              'Loading...',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
      );
    }

    if (master.sourceTypes.isEmpty) {
      // Fallback: show node type label read-only
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: AppColors.border2),
          color: AppColors.surface2,
        ),
        child: Row(
          children: [
            Icon(node.type.icon, color: node.type.color, size: 14),
            const SizedBox(width: 8),
            Text(
              node.type.label,
              style: const TextStyle(color: AppColors.text, fontSize: 12),
            ),
          ],
        ),
      );
    }

    final matchedItem = node.sourceTypeId > 0
        ? master.sourceTypes.where((i) => i.id == node.sourceTypeId).firstOrNull
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: AppColors.blue.withValues(alpha: 0.3)),
        color: AppColors.blue.withValues(alpha: 0.05),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: AppColors.blue.withValues(alpha: 0.12),
              border: Border.all(color: AppColors.blue.withValues(alpha: 0.25)),
            ),
            child: Text(
              matchedItem?.sourceValue ?? node.sourceTypeValue,
              style: const TextStyle(
                color: AppColors.blue,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Expanded(
          //   child: Text(
          //     matchedItem?.sourceName ?? node.sourceTypeName,
          //     style: const TextStyle(
          //       color: AppColors.text,
          //       fontSize: 12,
          //       fontWeight: FontWeight.w500,
          //     ),
          //   ),
          // ),
          const Icon(Icons.lock_outline, size: 12, color: AppColors.textDim),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// STATUS BAR (same as HTML .statusbar)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:vizualizer/core/theme/app_theme.dart';
// import 'package:vizualizer/data/models/pipeline_models.dart';
// import 'package:vizualizer/presentation/controllers/pipeline_controller.dart';
// import 'package:vizualizer/presentation/providers/pipeline_master_provider.dart';
// import 'package:vizualizer/presentation/widgets/common/searchable_dropdown.dart';

// /// Shows a confirmation dialog before deleting a pipeline node.
// ///
// /// In Dynamic UniMailing mode the dialog warns that the entire canvas for the
// /// active key will be cleared, and on confirm calls [clearCanvasForCurrentKey]
// /// instead of a single-node delete.
// Future<void> confirmDeleteNode(
//   BuildContext ctx,
//   PipelineController ctrl,
//   String id,
//   String name,
//   NodeType nodeType,
// ) async {
//   final dialogTitle = nodeType == NodeType.output
//       ? 'Delete Output Node?'
//       : nodeType == NodeType.join
//           ? 'Delete Join Node?'
//           : 'Delete Source?';
//   final nodeLabel = nodeType == NodeType.output
//       ? 'Output'
//       : nodeType == NodeType.join
//           ? 'Join'
//           : 'Source';

//   if (ctrl.isAnyUniMailing) {
//     final keyName =
//         ctrl.selectedOutputKey.isNotEmpty ? ctrl.selectedOutputKey : null;
//     final nodeName = name.isNotEmpty ? name : nodeLabel;
//     final ok = await showDialog<bool>(
//       context: ctx,
//       barrierDismissible: false,
//       builder: (dialogCtx) => Center(
//         child: Material(
//           color: Colors.transparent,
//           child: Container(
//             width: 400,
//             decoration: BoxDecoration(
//               color: AppColors.surface,
//               borderRadius: BorderRadius.circular(20),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withValues(alpha: 0.20),
//                   blurRadius: 32,
//                   offset: const Offset(0, 10),
//                 ),
//               ],
//             ),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 // ── Top banner ──
//                 Container(
//                   width: double.infinity,
//                   padding: const EdgeInsets.symmetric(vertical: 28),
//                   decoration: BoxDecoration(
//                     color: AppColors.red.withValues(alpha: 0.06),
//                     borderRadius: const BorderRadius.vertical(
//                       top: Radius.circular(20),
//                     ),
//                   ),
//                   child: Column(
//                     children: [
//                       Container(
//                         width: 56,
//                         height: 56,
//                         decoration: BoxDecoration(
//                           shape: BoxShape.circle,
//                           color: AppColors.red.withValues(alpha: 0.14),
//                         ),
//                         child: const Icon(
//                           Icons.delete_outline_rounded,
//                           size: 26,
//                           color: AppColors.red,
//                         ),
//                       ),
//                       const SizedBox(height: 12),
//                       Text(
//                         dialogTitle,
//                         style: const TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.w700,
//                           color: AppColors.red,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),

//                 // ── Body ──
//                 Padding(
//                   padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // ── Warning box with amber left accent ──
//                       ClipRRect(
//                         borderRadius: BorderRadius.circular(10),
//                         child: Stack(
//                           children: [
//                             Container(
//                               width: double.infinity,
//                               padding: const EdgeInsets.fromLTRB(
//                                 14,
//                                 12,
//                                 14,
//                                 12,
//                               ),
//                               decoration: BoxDecoration(
//                                 color: AppColors.amberDim,
//                                 borderRadius: BorderRadius.circular(10),
//                                 border: Border.all(
//                                   color: AppColors.amber.withValues(
//                                     alpha: 0.25,
//                                   ),
//                                 ),
//                               ),
//                               child: Row(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   const Icon(
//                                     Icons.warning_amber_rounded,
//                                     size: 16,
//                                     color: AppColors.amber,
//                                   ),
//                                   const SizedBox(width: 10),
//                                   Expanded(
//                                     child: Column(
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.start,
//                                       children: [
//                                         const Text(
//                                           'This action cannot be undone',
//                                           style: TextStyle(
//                                             fontSize: 13,
//                                             fontWeight: FontWeight.w700,
//                                             color: AppColors.text,
//                                           ),
//                                         ),
//                                         const SizedBox(height: 3),
//                                         RichText(
//                                           text: TextSpan(
//                                             style: const TextStyle(
//                                               fontSize: 12,
//                                               color: AppColors.textDim,
//                                               height: 1.5,
//                                             ),
//                                             children: [
//                                               TextSpan(
//                                                 text:
//                                                     'Deleting $nodeName will clear the ',
//                                               ),
//                                               const TextSpan(
//                                                 text: 'entire canvas',
//                                                 style: TextStyle(
//                                                   fontWeight: FontWeight.w700,
//                                                   color: AppColors.text,
//                                                 ),
//                                               ),
//                                               TextSpan(
//                                                 text: keyName != null
//                                                     ? ' for $keyName.'
//                                                     : ' for this configuration.',
//                                               ),
//                                             ],
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                             Positioned(
//                               left: 0,
//                               top: 0,
//                               bottom: 0,
//                               child: Container(
//                                 width: 4,
//                                 color: AppColors.amber,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       const SizedBox(height: 14),

//                       // ── What will be cleared ──
//                       Container(
//                         width: double.infinity,
//                         padding: const EdgeInsets.all(14),
//                         decoration: BoxDecoration(
//                           color: AppColors.bg,
//                           borderRadius: BorderRadius.circular(10),
//                           border: Border.all(color: AppColors.border),
//                         ),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             const Text(
//                               'WHAT WILL BE CLEARED',
//                               style: TextStyle(
//                                 fontSize: 10,
//                                 fontWeight: FontWeight.w700,
//                                 color: AppColors.textMuted,
//                                 letterSpacing: 0.6,
//                               ),
//                             ),
//                             const SizedBox(height: 10),
//                             _clearItem('Source body & file settings'),
//                             const SizedBox(height: 6),
//                             _clearItem('Join conditions & mappings'),
//                             const SizedBox(height: 6),
//                             _clearItem('Output selection & field mappings'),
//                           ],
//                         ),
//                       ),
//                       const SizedBox(height: 14),

//                       // ── Footer text ──
//                       RichText(
//                         text: TextSpan(
//                           style: const TextStyle(
//                             fontSize: 12,
//                             color: AppColors.textDim,
//                             height: 1.5,
//                           ),
//                           children: [
//                             const TextSpan(text: 'You will need to '),
//                             const TextSpan(
//                               text: 'reconfigure all settings',
//                               style: TextStyle(
//                                 fontWeight: FontWeight.w700,
//                                 color: AppColors.text,
//                               ),
//                             ),
//                             TextSpan(
//                               text: ctrl.isDynamicUniMailing
//                                   ? ' for this key again.'
//                                   : ctrl.isStaticUniMailing
//                                       ? ' for this UniMailing configuration again.'
//                                       : ' for this configuration again.',
//                             ),
//                           ],
//                         ),
//                       ),
//                       const SizedBox(height: 18),

//                       // ── Buttons ──
//                       Row(
//                         children: [
//                           Expanded(
//                             child: OutlinedButton.icon(
//                               onPressed: () =>
//                                   Navigator.of(dialogCtx).pop(false),
//                               icon: const Icon(
//                                 Icons.arrow_back_rounded,
//                                 size: 14,
//                               ),
//                               label: const Text(
//                                 'Cancel',
//                                 style: TextStyle(fontWeight: FontWeight.w600),
//                               ),
//                               style: OutlinedButton.styleFrom(
//                                 foregroundColor: AppColors.text,
//                                 side: const BorderSide(
//                                   color: AppColors.border2,
//                                 ),
//                                 padding: const EdgeInsets.symmetric(
//                                   vertical: 13,
//                                 ),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(10),
//                                 ),
//                               ),
//                             ),
//                           ),
//                           const SizedBox(width: 10),
//                           Expanded(
//                             child: ElevatedButton.icon(
//                               onPressed: () =>
//                                   Navigator.of(dialogCtx).pop(true),
//                               icon: const Icon(
//                                 Icons.delete_outline_rounded,
//                                 size: 15,
//                               ),
//                               label: const Text(
//                                 'Yes, delete',
//                                 style: TextStyle(fontWeight: FontWeight.w700),
//                               ),
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: AppColors.red,
//                                 foregroundColor: Colors.white,
//                                 elevation: 0,
//                                 padding: const EdgeInsets.symmetric(
//                                   vertical: 13,
//                                 ),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(10),
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//     if (ok == true && ctx.mounted) ctrl.clearCanvasForCurrentKey();
//     return;
//   }

//   final ok = await showDialog<bool>(
//     context: ctx,
//     barrierDismissible: false,
//     builder: (dialogCtx) => AlertDialog(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//       titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
//       contentPadding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
//       actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
//       title: Row(
//         children: [
//           const Icon(
//             Icons.delete_outline_rounded,
//             color: AppColors.red,
//             size: 20,
//           ),
//           const SizedBox(width: 8),
//           Text(
//             dialogTitle,
//             style: const TextStyle(
//               fontSize: 15,
//               fontWeight: FontWeight.w700,
//               color: AppColors.red,
//             ),
//           ),
//         ],
//       ),
//       content: RichText(
//         text: TextSpan(
//           style: const TextStyle(
//             fontSize: 13,
//             color: AppColors.text,
//             height: 1.5,
//           ),
//           children: [
//             const TextSpan(text: 'Are you sure you want to delete '),
//             TextSpan(
//               text: name,
//               style: const TextStyle(fontWeight: FontWeight.w700),
//             ),
//             const TextSpan(text: '? All connected edges will also be removed.'),
//           ],
//         ),
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.of(dialogCtx).pop(false),
//           child: const Text('Cancel'),
//         ),
//         ElevatedButton(
//           onPressed: () => Navigator.of(dialogCtx).pop(true),
//           style: ElevatedButton.styleFrom(
//             backgroundColor: AppColors.red,
//             foregroundColor: Colors.white,
//             elevation: 0,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(8),
//             ),
//           ),
//           child: const Text(
//             'Delete',
//             style: TextStyle(fontWeight: FontWeight.w700),
//           ),
//         ),
//       ],
//     ),
//   );
//   if (ok == true && ctx.mounted) ctrl.deleteNode(id);
// }

// /// Shows a confirmation dialog before editing a confirmed node in UniMailing mode.
// /// Warns that the entire canvas for the current key will be cleared, then calls
// /// [clearCanvasForCurrentKey] on confirm.
// Future<void> confirmEditNode(
//   BuildContext ctx,
//   PipelineController ctrl,
//   String name,
//   NodeType nodeType,
// ) async {
//   final dialogTitle = nodeType == NodeType.output
//       ? 'Edit Output Node?'
//       : nodeType == NodeType.join
//           ? 'Edit Join Node?'
//           : 'Edit Source?';
//   final nodeLabel = nodeType == NodeType.output
//       ? 'Output'
//       : nodeType == NodeType.join
//           ? 'Join'
//           : 'Source';

//   final keyName =
//       ctrl.selectedOutputKey.isNotEmpty ? ctrl.selectedOutputKey : null;
//   final nodeName = name.isNotEmpty ? name : nodeLabel;

//   final ok = await showDialog<bool>(
//     context: ctx,
//     barrierDismissible: false,
//     builder: (dialogCtx) => Center(
//       child: Material(
//         color: Colors.transparent,
//         child: Container(
//           width: 400,
//           decoration: BoxDecoration(
//             color: AppColors.surface,
//             borderRadius: BorderRadius.circular(20),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withValues(alpha: 0.20),
//                 blurRadius: 32,
//                 offset: const Offset(0, 10),
//               ),
//             ],
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               // ── Top banner ──
//               Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.symmetric(vertical: 28),
//                 decoration: BoxDecoration(
//                   color: AppColors.red.withValues(alpha: 0.06),
//                   borderRadius: const BorderRadius.vertical(
//                     top: Radius.circular(20),
//                   ),
//                 ),
//                 child: Column(
//                   children: [
//                     Container(
//                       width: 56,
//                       height: 56,
//                       decoration: BoxDecoration(
//                         shape: BoxShape.circle,
//                         color: AppColors.red.withValues(alpha: 0.14),
//                       ),
//                       child: const Icon(
//                         Icons.edit_rounded,
//                         size: 26,
//                         color: AppColors.red,
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     Text(
//                       dialogTitle,
//                       style: const TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.w700,
//                         color: AppColors.red,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//               // ── Body ──
//               Padding(
//                 padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // ── Warning box ──
//                     ClipRRect(
//                       borderRadius: BorderRadius.circular(10),
//                       child: Stack(
//                         children: [
//                           Container(
//                             width: double.infinity,
//                             padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
//                             decoration: BoxDecoration(
//                               color: AppColors.amberDim,
//                               borderRadius: BorderRadius.circular(10),
//                               border: Border.all(
//                                 color: AppColors.amber.withValues(alpha: 0.25),
//                               ),
//                             ),
//                             child: Row(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 const Icon(
//                                   Icons.warning_amber_rounded,
//                                   size: 16,
//                                   color: AppColors.amber,
//                                 ),
//                                 const SizedBox(width: 10),
//                                 Expanded(
//                                   child: Column(
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                     children: [
//                                       const Text(
//                                         'This action cannot be undone',
//                                         style: TextStyle(
//                                           fontSize: 13,
//                                           fontWeight: FontWeight.w700,
//                                           color: AppColors.text,
//                                         ),
//                                       ),
//                                       const SizedBox(height: 3),
//                                       RichText(
//                                         text: TextSpan(
//                                           style: const TextStyle(
//                                             fontSize: 12,
//                                             color: AppColors.textDim,
//                                             height: 1.5,
//                                           ),
//                                           children: [
//                                             TextSpan(
//                                               text:
//                                                   'Editing $nodeName will clear the ',
//                                             ),
//                                             const TextSpan(
//                                               text: 'entire canvas',
//                                               style: TextStyle(
//                                                 fontWeight: FontWeight.w700,
//                                                 color: AppColors.text,
//                                               ),
//                                             ),
//                                             TextSpan(
//                                               text: keyName != null
//                                                   ? ' for $keyName.'
//                                                   : ' for this configuration.',
//                                             ),
//                                           ],
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           Positioned(
//                             left: 0,
//                             top: 0,
//                             bottom: 0,
//                             child: Container(
//                               width: 4,
//                               color: AppColors.amber,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 14),

//                     // ── What will be cleared ──
//                     Container(
//                       width: double.infinity,
//                       padding: const EdgeInsets.all(14),
//                       decoration: BoxDecoration(
//                         color: AppColors.bg,
//                         borderRadius: BorderRadius.circular(10),
//                         border: Border.all(color: AppColors.border),
//                       ),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const Text(
//                             'WHAT WILL BE CLEARED',
//                             style: TextStyle(
//                               fontSize: 10,
//                               fontWeight: FontWeight.w700,
//                               color: AppColors.textMuted,
//                               letterSpacing: 0.6,
//                             ),
//                           ),
//                           const SizedBox(height: 10),
//                           _clearItem('Source body & file settings'),
//                           const SizedBox(height: 6),
//                           _clearItem('Join conditions & mappings'),
//                           const SizedBox(height: 6),
//                           _clearItem('Output selection & field mappings'),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 14),

//                     // ── Footer ──
//                     RichText(
//                       text: TextSpan(
//                         style: const TextStyle(
//                           fontSize: 12,
//                           color: AppColors.textDim,
//                           height: 1.5,
//                         ),
//                         children: [
//                           const TextSpan(text: 'You will need to '),
//                           const TextSpan(
//                             text: 'reconfigure all settings',
//                             style: TextStyle(
//                               fontWeight: FontWeight.w700,
//                               color: AppColors.text,
//                             ),
//                           ),
//                           TextSpan(
//                             text: ctrl.isDynamicUniMailing
//                                 ? ' for this key again.'
//                                 : ctrl.isStaticUniMailing
//                                     ? ' for this UniMailing configuration again.'
//                                     : ' for this configuration again.',
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 18),

//                     // ── Buttons ──
//                     Row(
//                       children: [
//                         Expanded(
//                           child: OutlinedButton.icon(
//                             onPressed: () => Navigator.of(dialogCtx).pop(false),
//                             icon: const Icon(
//                               Icons.arrow_back_rounded,
//                               size: 14,
//                             ),
//                             label: const Text(
//                               'Cancel',
//                               style: TextStyle(fontWeight: FontWeight.w600),
//                             ),
//                             style: OutlinedButton.styleFrom(
//                               foregroundColor: AppColors.text,
//                               side: const BorderSide(
//                                 color: AppColors.border2,
//                               ),
//                               padding: const EdgeInsets.symmetric(
//                                 vertical: 13,
//                               ),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(10),
//                               ),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 10),
//                         Expanded(
//                           child: ElevatedButton.icon(
//                             onPressed: () => Navigator.of(dialogCtx).pop(true),
//                             icon: const Icon(
//                               Icons.edit_rounded,
//                               size: 15,
//                             ),
//                             label: const Text(
//                               'Yes, clear',
//                               style: TextStyle(fontWeight: FontWeight.w700),
//                             ),
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: AppColors.red,
//                               foregroundColor: Colors.white,
//                               elevation: 0,
//                               padding: const EdgeInsets.symmetric(
//                                 vertical: 13,
//                               ),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(10),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     ),
//   );
//   if (ok == true && ctx.mounted) ctrl.clearCanvasForCurrentKey();
// }

// Widget _clearItem(String text) => Row(
//       children: [
//         const Icon(Icons.close_rounded, size: 14, color: AppColors.red),
//         const SizedBox(width: 8),
//         Text(
//           text,
//           style: const TextStyle(
//             fontSize: 12,
//             color: AppColors.text,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//       ],
//     );

// class ConfigPanel extends StatefulWidget {
//   const ConfigPanel({super.key});

//   @override
//   State<ConfigPanel> createState() => _ConfigPanelState();
// }

// class _ConfigPanelState extends State<ConfigPanel>
//     with TickerProviderStateMixin {
//   late final AnimationController _pulse;
//   late final Animation<double> _anim;

//   // Track which node is open so we reset state on switch
//   String? _prevNodeId;

//   // True only after the user explicitly changes the separator dropdown
//   bool _sepAcknowledged = false;

//   // Persistent controller for the source-name field so typing doesn't lose focus
//   final TextEditingController _nameCtrl = TextEditingController();

//   int _lastCanvasVersion = 0;

//   @override
//   void initState() {
//     super.initState();
//     _pulse = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 900),
//     )..repeat(reverse: true);
//     _anim = Tween<double>(
//       begin: 0.0,
//       end: 1.0,
//     ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
//   }

//   @override
//   void dispose() {
//     _pulse.dispose();
//     _nameCtrl.dispose();
//     super.dispose();
//   }

//   // ── Returns 0-4 depending on what the user should fill next ──
//   // Non-manual : 0=sourceName  1=queryFile   2=columnFile  3=outputFormat  4=configBtn
//   // Manual     : 0=sourceName  1=separator   2=columnFile  3=outputFormat  4=configBtn
//   int _computeStep(PipelineNode node) {
//     if (node.confirmState == NodeConfirmState.confirmed) return -1;
//     if (node.name.trim().isEmpty) return 0;
//     final isManual = node.type == NodeType.manual;
//     if (isManual) {
//       if (!_sepAcknowledged) return 1; // separator
//       if (node.fileName == null) return 2; // column file
//       if (node.selectedCols.isEmpty) return 3; // output format
//       return 4; // config button
//     } else {
//       if (node.queryFileName == null) return 1; // query file
//       if (node.fileName == null) return 2; // column file
//       if (node.selectedCols.isEmpty) return 3; // output format
//       return 4; // config button
//     }
//   }

//   // ── Wraps [child] with a pulsing glow border only when [forStep] is active ──
//   Widget _hl(
//     int forStep,
//     int activeStep,
//     Widget child, {
//     Color color = AppColors.blue,
//     bool borderOnly = false,
//   }) {
//     // Always wrap in AnimatedBuilder + Container with a BoxDecoration so the
//     // widget tree structure stays constant as `step` changes.
//     // KEY: decoration must never be null — Container adds/removes an internal
//     // DecoratedBox when decoration flips null↔non-null, which remounts the
//     // child and kills TextField focus.  Use alpha=0 for the inactive state.
//     return AnimatedBuilder(
//       animation: _anim,
//       child:
//           child, // passed as AnimatedBuilder.child so it isn't rebuilt every frame
//       builder: (_, builtChild) {
//         final isActive = forStep == activeStep;
//         final t = isActive ? _anim.value : 0.0;
//         return Container(
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(10),
//             border: Border.all(
//               color: color.withValues(alpha: t * 0.65),
//               width: 1.5,
//             ),
//             color: borderOnly ? null : color.withValues(alpha: t * 0.05),
//             boxShadow: t > 0.1 && !borderOnly
//                 ? [
//                     BoxShadow(
//                       color: color.withValues(alpha: t * 0.18),
//                       blurRadius: 6,
//                       spreadRadius: 2,
//                     ),
//                   ]
//                 : null,
//           ),
//           child: builtChild,
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<PipelineController>(
//       builder: (context, ctrl, _) {
//         final node = ctrl.selectedNodeId != null
//             ? ctrl.findNode(ctrl.selectedNodeId!)
//             : null;

//         // ── Detect canvas clear → reset all local state ──
//         if (ctrl.canvasVersion != _lastCanvasVersion) {
//           WidgetsBinding.instance.addPostFrameCallback((_) {
//             if (!mounted) return;
//             _nameCtrl.clear();
//             setState(() {
//               _lastCanvasVersion = ctrl.canvasVersion;
//               _prevNodeId = null;
//               _sepAcknowledged = false;
//             });
//           });
//         }

//         // ── Detect node switch → reset state and sync name controller ──
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           if (!mounted) return;
//           final newId = ctrl.selectedNodeId;
//           if (newId != _prevNodeId) {
//             final newNode = newId != null ? ctrl.findNode(newId) : null;
//             _nameCtrl.text = newNode?.name ?? '';
//             setState(() {
//               _prevNodeId = newId;
//               _sepAcknowledged = newNode?.separator.isNotEmpty ?? false;
//             });
//           }
//         });

//         return Container(
//           width: 260,
//           color: AppColors.surface,
//           child: Column(
//             children: [
//               // Header
//               Container(
//                 padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
//                 decoration: const BoxDecoration(
//                   border: Border(bottom: BorderSide(color: AppColors.border)),
//                 ),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Expanded(
//                       child: Text(
//                         node != null
//                             ? 'Configure: ${node.name}'
//                             : 'Configure Node',
//                         style: const TextStyle(
//                           color: AppColors.text,
//                           fontSize: 13,
//                           fontWeight: FontWeight.w700,
//                         ),
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ),
//                     if (node != null)
//                       InkWell(
//                         onTap: () => ctrl.selectNode(null),
//                         child: const Icon(
//                           Icons.close,
//                           color: AppColors.textDim,
//                           size: 16,
//                         ),
//                       ),
//                   ],
//                 ),
//               ),

//               // Body
//               Expanded(
//                 child: node == null
//                     ? const Center(
//                         child: Text(
//                           'Click a node to configure',
//                           style: TextStyle(
//                             color: AppColors.textDim,
//                             fontSize: 12,
//                           ),
//                         ),
//                       )
//                     : _buildConfig(context, ctrl, node),
//               ),

//               // Delete button
//               if (node != null && node.type.isSource)
//                 Padding(
//                   padding: const EdgeInsets.all(14),
//                   child: InkWell(
//                     onTap: () => confirmDeleteNode(
//                         context, ctrl, node.id, node.name, node.type),
//                     child: Container(
//                       width: double.infinity,
//                       padding: const EdgeInsets.symmetric(vertical: 10),
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(8),
//                         border: Border.all(
//                           color: AppColors.red.withValues(alpha: 0.3),
//                         ),
//                       ),
//                       child: const Center(
//                         child: Text(
//                           '🗑 Delete Node',
//                           style: TextStyle(
//                             color: AppColors.red,
//                             fontSize: 12,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildConfig(
//     BuildContext context,
//     PipelineController ctrl,
//     PipelineNode node,
//   ) {
//     if (!node.type.isSource) {
//       return const Center(
//         child: Text(
//           'Use node card controls',
//           style: TextStyle(color: AppColors.textDim, fontSize: 11),
//         ),
//       );
//     }

//     final isLocked = node.confirmState == NodeConfirmState.confirmed;
//     final isManual = node.type == NodeType.manual;
//     final step = _computeStep(node);
//     final separators = [
//       'Comma (,)',
//       'Pipe (|)',
//       'Tab (\\t)',
//       'Semicolon (;)',
//       'Colon (:)',
//       'Tilde (~)',
//       'Caret (^)',
//       'Hash (#)',
//       'Space ( )',
//     ];

//     return ListView(
//       padding: const EdgeInsets.all(14),
//       children: [
//         // ── Source Type (API-driven dropdown) ──
//         const Text('Source Type *', style: AppTextStyles.fieldLabel),
//         const SizedBox(height: 4),
//         _SourceTypeDropdown(node: node, ctrl: ctrl, isLocked: isLocked),
//         const SizedBox(height: 14),

//         // ── Source Name ── (step 0)
//         const Text('Source Name *', style: AppTextStyles.fieldLabel),
//         const SizedBox(height: 4),
//         _hl(
//           0,
//           step,
//           TextFormField(
//             controller: _nameCtrl,
//             readOnly: isLocked,
//             onChanged: isLocked ? null : (v) => ctrl.updateNodeName(node.id, v),
//             style: TextStyle(
//               color: isLocked ? AppColors.textDim : AppColors.text,
//               fontSize: 12.5,
//             ),
//             decoration: _inputDecor(locked: isLocked).copyWith(
//               hintText: 'e.g. Customer_Data',
//               hintStyle: const TextStyle(
//                 color: AppColors.textMuted,
//                 fontSize: 12,
//               ),
//             ),
//           ),
//           borderOnly: true,
//         ),
//         const SizedBox(height: 14),

//         // ── Separator (Manual only) ── (step 1 for manual)
//         if (isManual) ...[
//           const Text('File Separator *', style: AppTextStyles.fieldLabel),
//           const SizedBox(height: 4),
//           _hl(
//             1,
//             step,
//             SearchableDropdownField(
//               value: _sepToLabel(node.separator, separators),
//               hint: '— Select Separator —',
//               items: separators,
//               enabled: !isLocked,
//               onChanged: (v) {
//                 if (v != null) {
//                   final sep = v.contains('\\t')
//                       ? '\t'
//                       : v.contains(',')
//                           ? ','
//                           : v.contains('|')
//                               ? '|'
//                               : v.contains(';')
//                                   ? ';'
//                                   : v.contains(':')
//                                       ? ':'
//                                       : v.contains('~')
//                                           ? '~'
//                                           : v.contains('^')
//                                               ? '^'
//                                               : v.contains('#')
//                                                   ? '#'
//                                                   : ' ';
//                   _onSeparatorChanged(context, ctrl, node, sep);
//                 }
//               },
//             ),
//             borderOnly: true,
//           ),
//           const SizedBox(height: 14),
//         ],

//         // ── Non-manual: Query File Upload ── (step 1 for non-manual)
//         if (!isManual) ...[
//           const Text('Upload Query File', style: AppTextStyles.fieldLabel),
//           const SizedBox(height: 4),
//           _hl(
//             1,
//             step,
//             _uploadButton(
//               icon: Icons.description_outlined,
//               label: 'Upload Query File (.txt)',
//               isLocked: isLocked,
//               onTap: isLocked
//                   ? null
//                   : () async {
//                       final messenger = ScaffoldMessenger.of(context);
//                       final result = await FilePicker.platform.pickFiles(
//                         type: FileType.custom,
//                         allowedExtensions: ['txt'],
//                         withData: true,
//                       );
//                       if (result != null && result.files.single.bytes != null) {
//                         final fileName = result.files.single.name;
//                         final ext = fileName.contains('.')
//                             ? fileName.split('.').last.toLowerCase()
//                             : '';
//                         if (ext != 'txt') {
//                           messenger.showSnackBar(
//                             const SnackBar(
//                               content: Text(
//                                 'Invalid file type: only .txt files are allowed for query upload.',
//                               ),
//                               backgroundColor: Colors.red,
//                             ),
//                           );
//                           return;
//                         }
//                         final queryBytes = result.files.single.bytes!;
//                         final queryText = utf8.decode(
//                           queryBytes,
//                           allowMalformed: true,
//                         );
//                         if (!_isValidQueryFile(queryText)) {
//                           messenger.showSnackBar(
//                             const SnackBar(
//                               content: Text(
//                                 'Invalid file: the query file must contain a valid SQL query (e.g. starting with SELECT, WITH, INSERT, etc.). Column/CSV files are not allowed here.',
//                               ),
//                               backgroundColor: Colors.red,
//                             ),
//                           );
//                           return;
//                         }
//                         ctrl.setQueryFile(
//                           node.id,
//                           fileName,
//                           bytes: queryBytes.toList(),
//                         );
//                         messenger.showSnackBar(
//                           SnackBar(
//                             content: Text('Query file loaded: $fileName'),
//                             backgroundColor: AppColors.green,
//                           ),
//                         );
//                       }
//                     },
//             ),
//             borderOnly: true,
//           ),
//           if (node.queryFileName != null) ...[
//             const SizedBox(height: 4),
//             _fileInfoBar(node.queryFileName!, null, AppColors.blue),
//           ],
//           const SizedBox(height: 14),
//         ],

//         // ── Column File Upload ── (step 2)
//         Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Upload Column File (.csv / .txt) *',
//               style: AppTextStyles.fieldLabel,
//             ),
//             const SizedBox(height: 4),
//             _hl(
//               2,
//               step,
//               _uploadButton(
//                 icon: Icons.upload_file_rounded,
//                 label: 'Upload Column File (.csv / .txt)',
//                 isLocked: isLocked,
//                 onTap: isLocked
//                     ? null
//                     : () async {
//                         final messenger = ScaffoldMessenger.of(context);
//                         final result = await FilePicker.platform.pickFiles(
//                           type: FileType.custom,
//                           allowedExtensions: ['csv', 'txt'],
//                           withData: true,
//                         );
//                         if (result == null ||
//                             result.files.single.bytes == null) {
//                           return;
//                         }
//                         final bytes = result.files.single.bytes!;
//                         final fileName = result.files.single.name;
//                         final text = utf8.decode(bytes, allowMalformed: true);
//                         final lines = text
//                             .split('\n')
//                             .where((l) => l.trim().isNotEmpty)
//                             .toList();
//                         if (lines.isEmpty) return;
//                         final firstLine = lines.first;
//                         // For manual nodes, use the separator already chosen by
//                         // the user; for others, auto-detect from file content.
//                         String sep;
//                         if (isManual && node.separator.isNotEmpty) {
//                           sep = node.separator;
//                           // Only reject if the file clearly uses a DIFFERENT
//                           // separator. A single-column file has no separator
//                           // in the first line at all — that is valid.
//                           const knownSeps = [
//                             ',',
//                             '\t',
//                             '|',
//                             ';',
//                             ':',
//                             '~',
//                             '^',
//                             '#',
//                           ];
//                           final usesOtherSep = knownSeps.any(
//                             (s) => s != sep && firstLine.contains(s),
//                           );
//                           if (!firstLine.contains(sep) && usesOtherSep) {
//                             final sepLabel = _sepNames[sep] ?? sep;
//                             messenger.showSnackBar(
//                               SnackBar(
//                                 content: Text(
//                                   'The uploaded file does not contain the selected separator "$sepLabel". Please select the correct separator or upload a matching file.',
//                                 ),
//                                 backgroundColor: Colors.red,
//                               ),
//                             );
//                             return;
//                           }
//                         } else {
//                           sep = ',';
//                           if ('\t'.allMatches(firstLine).isNotEmpty) {
//                             sep = '\t';
//                           } else if ('|'.allMatches(firstLine).isNotEmpty) {
//                             sep = '|';
//                           } else if (';'.allMatches(firstLine).isNotEmpty) {
//                             sep = ';';
//                           } else if (':'.allMatches(firstLine).isNotEmpty) {
//                             sep = ':';
//                           } else if ('~'.allMatches(firstLine).isNotEmpty) {
//                             sep = '~';
//                           } else if ('^'.allMatches(firstLine).isNotEmpty) {
//                             sep = '^';
//                           } else if ('#'.allMatches(firstLine).isNotEmpty) {
//                             sep = '#';
//                           } else if (' '.allMatches(firstLine).isNotEmpty) {
//                             sep = ' ';
//                           }
//                         }
//                         final cols = firstLine
//                             .split(sep)
//                             .map((c) => c.trim().replaceAll('"', '').trim())
//                             .where((c) => c.isNotEmpty)
//                             .toList();
//                         if (cols.isEmpty) return;
//                         // Reject if the file is actually a SQL query file
//                         if (_isValidQueryFile(text)) {
//                           messenger.showSnackBar(
//                             const SnackBar(
//                               content: Text(
//                                 'Invalid file: this looks like a SQL query file. Please upload a column file (.csv / .txt with column headers).',
//                               ),
//                               backgroundColor: Colors.red,
//                             ),
//                           );
//                           return;
//                         }
//                         if (!_isValidColumnHeaders(cols)) {
//                           messenger.showSnackBar(
//                             const SnackBar(
//                               content: Text(
//                                 'Invalid file: the first row must contain column headers, not raw data or unstructured text.',
//                               ),
//                               backgroundColor: Colors.red,
//                             ),
//                           );
//                           return;
//                         }
//                         final rows = <Map<String, dynamic>>[];
//                         for (int i = 1; i < lines.length; i++) {
//                           final vals = lines[i]
//                               .split(sep)
//                               .map((v) => v.trim().replaceAll('"', '').trim())
//                               .toList();
//                           final row = <String, dynamic>{};
//                           for (int j = 0; j < cols.length; j++) {
//                             row[cols[j]] = j < vals.length ? vals[j] : '';
//                           }
//                           rows.add(row);
//                         }
//                         ctrl.setNodeColumns(
//                           node.id,
//                           cols,
//                           rows,
//                           fileName,
//                           bytes: bytes.toList(),
//                         );
//                         ctrl.updateNodeSeparator(node.id, sep);
//                         messenger.showSnackBar(
//                           SnackBar(
//                             content: Text(
//                               '${cols.length} columns, ${rows.length} rows extracted from $fileName',
//                             ),
//                             backgroundColor: AppColors.green,
//                           ),
//                         );
//                       },
//               ),
//               borderOnly: true,
//             ),
//             if (node.fileName != null) ...[
//               const SizedBox(height: 4),
//               _fileInfoBar(
//                 node.fileName!,
//                 '${node.cols.length} cols',
//                 AppColors.green,
//               ),
//             ],
//           ],
//         ),
//         const SizedBox(height: 14),

//         const SizedBox(height: 20),

//         // ── Confirm / Edit button ──
//         _ConfirmSection(node: node, ctrl: ctrl),

//         const SizedBox(height: 8),
//       ],
//     );
//   }

//   /// Returns true if the extracted column headers look like real column names.
//   /// Rejects: all-numeric headers, single long unstructured string, or headers
//   /// that are sentences (contain multiple spaces / punctuation).
//   bool _isValidColumnHeaders(List<String> cols) {
//     if (cols.isEmpty) return false;
//     // Every token must not be a plain integer/float
//     final allNumeric = cols.every((c) => double.tryParse(c) != null);
//     if (allNumeric) return false;
//     // If there is only one "column" and it looks like a sentence/paragraph
//     if (cols.length == 1 && cols.first.length > 60) return false;
//     // A column name should not contain sentence-level punctuation like '.' mid-word
//     // or be a multi-word natural-language sentence (more than 5 space-separated words)
//     final looksLikeSentence = cols.any((c) {
//       final wordCount = c.trim().split(RegExp(r'\s+')).length;
//       return wordCount > 5;
//     });
//     if (looksLikeSentence) return false;
//     return true;
//   }

//   /// Returns true if the text content looks like a SQL query.
//   bool _isValidQueryFile(String text) {
//     final trimmed = text.trim();
//     if (trimmed.isEmpty) return false;
//     final upper = trimmed.toUpperCase();
//     const sqlKeywords = [
//       'SELECT',
//       'WITH',
//       'INSERT',
//       'UPDATE',
//       'DELETE',
//       'CREATE',
//       'MERGE',
//       'CALL',
//       'EXEC',
//     ];
//     return sqlKeywords.any((kw) => upper.startsWith(kw));
//   }

//   static const _sepNames = {
//     ',': 'Comma (,)',
//     '|': 'Pipe (|)',
//     '\t': 'Tab (\\t)',
//     ';': 'Semicolon (;)',
//     ':': 'Colon (:)',
//     '~': 'Tilde (~)',
//     '^': 'Caret (^)',
//     '#': 'Hash (#)',
//     ' ': 'Space ( )',
//   };

//   /// Called when user changes the separator dropdown.
//   /// If a file is already uploaded, re-parses it with the new separator.
//   void _onSeparatorChanged(
//     BuildContext context,
//     PipelineController ctrl,
//     PipelineNode node,
//     String sep,
//   ) {
//     final messenger = ScaffoldMessenger.of(context);
//     final sepLabel = _sepNames[sep] ?? sep;

//     if (node.columnFileBytes == null) {
//       ctrl.updateNodeSeparator(node.id, sep);
//       setState(() => _sepAcknowledged = true);
//       return;
//     }

//     // File already uploaded — validate new separator against existing file
//     final text = utf8.decode(node.columnFileBytes!, allowMalformed: true);
//     final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
//     if (lines.isEmpty) {
//       ctrl.updateNodeSeparator(node.id, sep);
//       setState(() => _sepAcknowledged = true);
//       return;
//     }

//     final firstLine = lines.first;
//     // Only clear the file if it clearly uses a DIFFERENT separator.
//     // A single-column file has no separator in the first line — keep it.
//     const knownSeps = [',', '\t', '|', ';', ':', '~', '^', '#'];
//     final usesOtherSep = knownSeps.any(
//       (s) => s != sep && firstLine.contains(s),
//     );
//     if (!firstLine.contains(sep) && usesOtherSep) {
//       // Separator doesn't match current file — update separator and clear
//       // the file so user can re-upload with the correct separator.
//       ctrl.updateNodeSeparator(node.id, sep);
//       ctrl.clearNodeColumnFile(node.id);
//       setState(() => _sepAcknowledged = true);
//       messenger.showSnackBar(
//         SnackBar(
//           content: Text(
//             'Separator changed to "$sepLabel". Previous file cleared — please re-upload a file with "$sepLabel" separator.',
//           ),
//           backgroundColor: Colors.orange,
//         ),
//       );
//       return;
//     }

//     // Re-parse columns and rows with new separator
//     final cols = firstLine
//         .split(sep)
//         .map((c) => c.trim().replaceAll('"', '').trim())
//         .where((c) => c.isNotEmpty)
//         .toList();
//     if (cols.isEmpty) return;

//     final rows = <Map<String, dynamic>>[];
//     for (int i = 1; i < lines.length; i++) {
//       final vals = lines[i]
//           .split(sep)
//           .map((v) => v.trim().replaceAll('"', '').trim())
//           .toList();
//       final row = <String, dynamic>{};
//       for (int j = 0; j < cols.length; j++) {
//         row[cols[j]] = j < vals.length ? vals[j] : '';
//       }
//       rows.add(row);
//     }

//     ctrl.updateNodeSeparator(node.id, sep);
//     ctrl.setNodeColumns(
//       node.id,
//       cols,
//       rows,
//       node.fileName!,
//       bytes: node.columnFileBytes!,
//     );
//     setState(() => _sepAcknowledged = true);

//     messenger.showSnackBar(
//       SnackBar(
//         content: Text(
//           'File re-parsed with "$sepLabel": ${cols.length} columns found.',
//         ),
//         backgroundColor: AppColors.green,
//       ),
//     );
//   }

//   /// Map separator char → display label for the dropdown value.
//   /// Returns null when sep is empty so the dropdown shows its hint text.
//   String? _sepToLabel(String sep, List<String> separators) {
//     if (sep.isEmpty) return null;
//     const map = {
//       ',': 'Comma (,)',
//       '|': 'Pipe (|)',
//       '\t': 'Tab (\\t)',
//       ';': 'Semicolon (;)',
//       ':': 'Colon (:)',
//       '~': 'Tilde (~)',
//       '^': 'Caret (^)',
//       '#': 'Hash (#)',
//       ' ': 'Space ( )',
//     };
//     final label = map[sep];
//     return (label != null && separators.contains(label)) ? label : null;
//   }

//   InputDecoration _inputDecor({bool locked = false}) {
//     return InputDecoration(
//       contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(7),
//         borderSide: const BorderSide(color: AppColors.border2),
//       ),
//       enabledBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(7),
//         borderSide: const BorderSide(color: AppColors.border2),
//       ),
//       focusedBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(7),
//         borderSide: BorderSide(
//           color: locked ? AppColors.border2 : AppColors.blue,
//         ),
//       ),
//       filled: true,
//       fillColor: locked
//           ? AppColors.surface2.withValues(alpha: 0.6)
//           : AppColors.surface2,
//       suffixIcon: locked
//           ? const Icon(
//               Icons.lock_outline_rounded,
//               size: 13,
//               color: AppColors.textMuted,
//             )
//           : null,
//     );
//   }

//   Widget _uploadButton({
//     required IconData icon,
//     required String label,
//     required Function()? onTap,
//     bool isLocked = false,
//   }) {
//     return Opacity(
//       opacity: isLocked ? 0.5 : 1.0,
//       child: InkWell(
//         onTap: onTap,
//         child: Container(
//           width: double.infinity,
//           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(8),
//             border: Border.all(
//               color: AppColors.border2,
//               width: 1.5,
//               style: BorderStyle.solid,
//             ),
//           ),
//           child: Row(
//             children: [
//               Icon(
//                 isLocked ? Icons.lock_outline_rounded : icon,
//                 color: AppColors.textDim,
//                 size: 16,
//               ),
//               const SizedBox(width: 8),
//               Text(
//                 label,
//                 style: const TextStyle(
//                   color: AppColors.textDim,
//                   fontSize: 12,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _fileInfoBar(String text, String? badge, Color color) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(6),
//         color: color.withValues(alpha: 0.08),
//         border: Border.all(color: color.withValues(alpha: 0.2)),
//       ),
//       child: Row(
//         children: [
//           Icon(Icons.check_circle_outline, color: color, size: 14),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Text(text, style: TextStyle(color: color, fontSize: 11)),
//           ),
//           if (badge != null)
//             Text(
//               badge,
//               style: TextStyle(
//                 color: color,
//                 fontSize: 11,
//                 fontWeight: FontWeight.w700,
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }

// // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// // CONFIRM SECTION
// // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// class _ConfirmSection extends StatelessWidget {
//   final PipelineNode node;
//   final PipelineController ctrl;
//   const _ConfirmSection({required this.node, required this.ctrl});

//   String? _validate() {
//     print("name: '${node.name}'");
//     print("sourceTypeValue: '${node.sourceTypeValue}'");
//     print("queryFileName: '${node.queryFileName}'");
//     print("fileName: '${node.fileName}'");
//     print("node.type: '${node.type}'");
//     final isManual = node.type == NodeType.manual;
//     if (node.name.trim().isEmpty) return 'Source Name is required.';
//     if (node.sourceTypeId.toString() == '') return 'Source Type is required.';
//     if (isManual) {
//       if (node.fileName == null) return 'Upload Column File is required.';
//     } else {
//       if (node.queryFileName == null) return 'Upload Query File is required.';
//       if (node.fileName == null) return 'Upload Column File is required.';
//     }
//     return null;
//   }

//   @override
//   Widget build(BuildContext context) {
//     final state = node.confirmState;
//     final isConfirmed = state == NodeConfirmState.confirmed;
//     final isEditing = state == NodeConfirmState.editing;
//     final isReady = _validate() == null;

//     if (isConfirmed) {
//       // ── Confirmed state ──
//       return Column(
//         children: [
//           // Container(
//           //   width: double.infinity,
//           //   padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
//           //   decoration: BoxDecoration(
//           //     borderRadius: BorderRadius.circular(8),
//           //     color: AppColors.green.withValues(alpha: 0.1),
//           //     border: Border.all(color: AppColors.green.withValues(alpha: 0.3)),
//           //   ),
//           //   child: const Row(
//           //     mainAxisAlignment: MainAxisAlignment.center,
//           //     children: [
//           //       Icon(
//           //         Icons.check_circle_rounded,
//           //         color: AppColors.green,
//           //         size: 16,
//           //       ),
//           //       SizedBox(width: 8),
//           //       Text(
//           //         'Confirmed',
//           //         style: TextStyle(
//           //           color: AppColors.green,
//           //           fontSize: 12,
//           //           fontWeight: FontWeight.w700,
//           //         ),
//           //       ),
//           //     ],
//           //   ),
//           // ),
//           // const SizedBox(height: 8),
//           InkWell(
//             onTap: () async {
//               if (ctrl.isAnyUniMailing) {
//                 await confirmEditNode(context, ctrl, node.name, node.type);
//               } else {
//                 ctrl.editNode(node.id);
//               }
//             },
//             child: Container(
//               width: double.infinity,
//               padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(
//                   color: AppColors.amber.withValues(alpha: 0.4),
//                 ),
//                 color: AppColors.amber.withValues(alpha: 0.07),
//               ),
//               child: const Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(Icons.edit_rounded, color: AppColors.amber, size: 14),
//                   SizedBox(width: 8),
//                   Text(
//                     'Edit',
//                     style: TextStyle(
//                       color: AppColors.amber,
//                       fontSize: 12,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       );
//     }

//     // ── Not configured / Editing state ──
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         if (isEditing) ...[
//           Container(
//             width: double.infinity,
//             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
//             margin: const EdgeInsets.only(bottom: 10),
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(7),
//               color: AppColors.amber.withValues(alpha: 0.08),
//               border: Border.all(color: AppColors.amber.withValues(alpha: 0.3)),
//             ),
//             child: const Row(
//               children: [
//                 Icon(Icons.edit_rounded, color: AppColors.amber, size: 13),
//                 SizedBox(width: 6),
//                 Text(
//                   'Editing — re-confirm when done',
//                   style: TextStyle(color: AppColors.amber, fontSize: 11),
//                 ),
//               ],
//             ),
//           ),
//         ],
//         InkWell(
//           onTap: () {
//             final error = _validate();
//             if (error != null) {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(content: Text(error), backgroundColor: Colors.red),
//               );
//               return;
//             }
//             ctrl.confirmNode(node.id);
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: Text('${node.name} confirmed successfully.'),
//                 backgroundColor: AppColors.green,
//               ),
//             );
//           },
//           child: AnimatedContainer(
//             duration: const Duration(milliseconds: 300),
//             width: double.infinity,
//             padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(8),
//               color: isReady
//                   ? AppColors.blue
//                   : AppColors.border.withValues(alpha: 0.5),
//               border: Border.all(
//                 color: isReady ? AppColors.blue : AppColors.border2,
//                 width: isReady ? 2.0 : 1.0,
//               ),
//               boxShadow: isReady
//                   ? [
//                       BoxShadow(
//                         color: AppColors.blue.withValues(alpha: 0.35),
//                         blurRadius: 10,
//                         spreadRadius: 1,
//                         offset: const Offset(0, 3),
//                       ),
//                     ]
//                   : null,
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(
//                   Icons.check_rounded,
//                   color: isReady ? Colors.white : AppColors.textMuted,
//                   size: 15,
//                 ),
//                 const SizedBox(width: 8),
//                 Text(
//                   'Configure',
//                   style: TextStyle(
//                     color: isReady ? Colors.white : AppColors.textMuted,
//                     fontSize: 12,
//                     fontWeight: FontWeight.w700,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }

// // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// // SOURCE TYPE DROPDOWN
// // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// class _SourceTypeDropdown extends StatelessWidget {
//   final PipelineNode node;
//   final PipelineController ctrl;
//   final bool isLocked;
//   const _SourceTypeDropdown({
//     required this.node,
//     required this.ctrl,
//     this.isLocked = false,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final master = context.watch<PipelineMasterProvider>();
//     return Opacity(
//       opacity: isLocked ? 0.55 : 1.0,
//       child: IgnorePointer(
//         ignoring: isLocked,
//         child: _buildDropdown(context, master),
//       ),
//     );
//   }

//   Widget _buildDropdown(BuildContext context, PipelineMasterProvider master) {
//     if (master.loading) {
//       return Container(
//         width: double.infinity,
//         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(7),
//           border: Border.all(color: AppColors.border2),
//           color: AppColors.surface2,
//         ),
//         child: const Row(
//           children: [
//             SizedBox(
//               width: 12,
//               height: 12,
//               child: CircularProgressIndicator(
//                 strokeWidth: 1.5,
//                 color: AppColors.textDim,
//               ),
//             ),
//             SizedBox(width: 8),
//             Text(
//               'Loading...',
//               style: TextStyle(color: AppColors.textMuted, fontSize: 12),
//             ),
//           ],
//         ),
//       );
//     }

//     if (master.sourceTypes.isEmpty) {
//       // Fallback: show node type label read-only
//       return Container(
//         width: double.infinity,
//         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(7),
//           border: Border.all(color: AppColors.border2),
//           color: AppColors.surface2,
//         ),
//         child: Row(
//           children: [
//             Icon(node.type.icon, color: node.type.color, size: 14),
//             const SizedBox(width: 8),
//             Text(
//               node.type.label,
//               style: const TextStyle(color: AppColors.text, fontSize: 12),
//             ),
//           ],
//         ),
//       );
//     }

//     final matchedItem = node.sourceTypeId > 0
//         ? master.sourceTypes.where((i) => i.id == node.sourceTypeId).firstOrNull
//         : null;

//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(7),
//         border: Border.all(color: AppColors.blue.withValues(alpha: 0.3)),
//         color: AppColors.blue.withValues(alpha: 0.05),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(4),
//               color: AppColors.blue.withValues(alpha: 0.12),
//               border: Border.all(color: AppColors.blue.withValues(alpha: 0.25)),
//             ),
//             child: Text(
//               matchedItem?.sourceValue ?? node.sourceTypeValue,
//               style: const TextStyle(
//                 color: AppColors.blue,
//                 fontSize: 9,
//                 fontWeight: FontWeight.w700,
//                 fontFamily: 'monospace',
//               ),
//             ),
//           ),
//           const SizedBox(width: 8),
//           // Expanded(
//           //   child: Text(
//           //     matchedItem?.sourceName ?? node.sourceTypeName,
//           //     style: const TextStyle(
//           //       color: AppColors.text,
//           //       fontSize: 12,
//           //       fontWeight: FontWeight.w500,
//           //     ),
//           //   ),
//           // ),
//           const Icon(Icons.lock_outline, size: 12, color: AppColors.textDim),
//         ],
//       ),
//     );
//   }
// }

// // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// // STATUS BAR (same as HTML .statusbar)
// // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
