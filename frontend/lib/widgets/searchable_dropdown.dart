import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Styled dropdown that opens an anchored overlay below the field,
/// matching the pattern used in SourceConfigurationPage.
class SearchableDropdownField extends StatefulWidget {
  final String? value;
  final String hint;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final bool enabled;
  final double height;

  const SearchableDropdownField({
    super.key,
    required this.items,
    required this.onChanged,
    this.value,
    this.hint = '— Select —',
    this.enabled = true,
    this.height = 34,
  });

  @override
  State<SearchableDropdownField> createState() =>
      _SearchableDropdownFieldState();
}

class _SearchableDropdownFieldState extends State<SearchableDropdownField> {
  final _layerLink = LayerLink();
  OverlayEntry? _overlay;

  bool get _isOpen => _overlay != null;

  void _toggle() {
    if (_isOpen) {
      _close();
    } else {
      _open();
    }
  }

  void _open() {
    final renderBox = context.findRenderObject() as RenderBox?;
    final width = renderBox?.size.width ?? 200.0;

    _overlay = OverlayEntry(
      builder: (_) => _SearchDropdownOverlay(
        layerLink: _layerLink,
        items: widget.items,
        current: widget.value,
        dropdownWidth: width,
        triggerHeight: widget.height,
        onDismiss: _close,
        onSelect: (item) {
          _close();
          widget.onChanged(item);
        },
      ),
    );
    Overlay.of(context).insert(_overlay!);
    setState(() {});
  }

  void _close() {
    _overlay?.remove();
    _overlay = null;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = widget.value != null && widget.items.contains(widget.value);
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: widget.enabled ? _toggle : null,
        child: Opacity(
          opacity: widget.enabled ? 1.0 : 0.5,
          child: Container(
            height: widget.height,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: _isOpen ? AppColors.violet : AppColors.border2,
                width: _isOpen ? 1.5 : 1.0,
              ),
              color: AppColors.surface2,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    hasValue ? widget.value! : widget.hint,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: hasValue ? AppColors.text : AppColors.textMuted,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: _isOpen ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: AppColors.textDim,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Overlay widget ────────────────────────────────────────────────────────────

class _SearchDropdownOverlay extends StatefulWidget {
  final LayerLink layerLink;
  final List<String> items;
  final String? current;
  final double dropdownWidth;
  final double triggerHeight;
  final VoidCallback onDismiss;
  final ValueChanged<String> onSelect;

  const _SearchDropdownOverlay({
    required this.layerLink,
    required this.items,
    required this.current,
    required this.dropdownWidth,
    required this.triggerHeight,
    required this.onDismiss,
    required this.onSelect,
  });

  @override
  State<_SearchDropdownOverlay> createState() => _SearchDropdownOverlayState();
}

class _SearchDropdownOverlayState extends State<_SearchDropdownOverlay> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<String> get _filtered {
    if (_query.isEmpty) return widget.items;
    final q = _query.toLowerCase();
    return widget.items.where((s) => s.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Stack(
      children: [
        // Tap outside → dismiss
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onDismiss,
            behavior: HitTestBehavior.translucent,
            child: const SizedBox.expand(),
          ),
        ),

        // Dropdown card anchored below trigger
        CompositedTransformFollower(
          link: widget.layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, widget.triggerHeight + 4),
          child: Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(10),
              color: AppColors.surface,
              child: Container(
                width: widget.dropdownWidth,
                constraints: const BoxConstraints(maxHeight: 280),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Search field ──
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: TextField(
                        controller: _searchCtrl,
                        autofocus: true,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.text,
                        ),
                        onChanged: (v) => setState(() => _query = v),
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          hintStyle: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            size: 14,
                            color: AppColors.textDim,
                          ),
                          suffixIcon: _query.isNotEmpty
                              ? IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    size: 13,
                                  ),
                                  color: AppColors.textDim,
                                  onPressed: () => setState(() {
                                    _searchCtrl.clear();
                                    _query = '';
                                  }),
                                )
                              : null,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 7,
                          ),
                          filled: true,
                          fillColor: AppColors.surface2,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(7),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(7),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(7),
                            borderSide: const BorderSide(
                              color: AppColors.violet,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.border),

                    // ── Item list ──
                    Flexible(
                      child: widget.items.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: Text(
                                'No items available',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            )
                          : filtered.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: Text(
                                'No results found',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => const Divider(
                                height: 1,
                                color: AppColors.border,
                              ),
                              itemBuilder: (_, i) {
                                final item = filtered[i];
                                final isCurrent = item == widget.current;
                                return InkWell(
                                  onTap: () => widget.onSelect(item),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 9,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isCurrent
                                              ? Icons.radio_button_checked
                                              : Icons.radio_button_unchecked,
                                          size: 16,
                                          color: isCurrent
                                              ? AppColors.violet
                                              : AppColors.textDim,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            item,
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              color: isCurrent
                                                  ? AppColors.violet
                                                  : AppColors.text,
                                              fontWeight: isCurrent
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
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
