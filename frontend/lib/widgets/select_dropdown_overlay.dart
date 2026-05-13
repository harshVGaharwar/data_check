import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

typedef SelectItem = ({int id, String label});

class SelectDropdownOverlay extends StatefulWidget {
  final LayerLink layerLink;
  final List<SelectItem> items;
  final int? selectedId;
  final double dropdownWidth;
  final String searchHint;
  final VoidCallback onDismiss;
  final void Function(int id, String label) onSelect;

  const SelectDropdownOverlay({
    super.key,
    required this.layerLink,
    required this.items,
    required this.selectedId,
    required this.dropdownWidth,
    required this.searchHint,
    required this.onDismiss,
    required this.onSelect,
  });

  @override
  State<SelectDropdownOverlay> createState() => _SelectDropdownOverlayState();
}

class _SelectDropdownOverlayState extends State<SelectDropdownOverlay> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<SelectItem> get _filtered {
    if (_query.isEmpty) return widget.items;
    final q = _query.toLowerCase();
    return widget.items.where((i) => i.label.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onDismiss,
            behavior: HitTestBehavior.translucent,
            child: const SizedBox.expand(),
          ),
        ),
        CompositedTransformFollower(
          link: widget.layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 46),
          child: Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              color: AppColors.surface,
              child: Container(
                width: widget.dropdownWidth,
                constraints: const BoxConstraints(maxHeight: 320),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: TextField(
                        controller: _searchCtrl,
                        autofocus: true,
                        style: const TextStyle(fontSize: 13, color: AppColors.text),
                        onChanged: (v) => setState(() => _query = v),
                        decoration: InputDecoration(
                          hintText: widget.searchHint,
                          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                          prefixIcon: const Icon(Icons.search, size: 16, color: AppColors.textDim),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          filled: true,
                          fillColor: AppColors.surface2,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.violet, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    Flexible(
                      child: _filtered.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'No results found',
                                style: TextStyle(fontSize: 12, color: AppColors.textDim),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: _filtered.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1, color: AppColors.border),
                              itemBuilder: (_, i) {
                                final item = _filtered[i];
                                final isSel = widget.selectedId == item.id;
                                return InkWell(
                                  onTap: () => widget.onSelect(item.id, item.label),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isSel
                                              ? Icons.radio_button_checked
                                              : Icons.radio_button_unchecked,
                                          size: 18,
                                          color: isSel ? AppColors.violet : AppColors.textDim,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            item.label,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: isSel
                                                  ? FontWeight.w600
                                                  : FontWeight.w400,
                                              color: isSel ? AppColors.violet : AppColors.text,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
