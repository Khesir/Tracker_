import 'package:flutter/material.dart';
import '../../../../core/models/project_model.dart';
import '../../../../core/theme/app_styling.dart';
import '../../../../core/theme/app_theme.dart';

const _kColors = [
  '#22C55E', '#4AACCC', '#1D9E75', '#F59E0B',
  '#EF4444', '#8B5CF6', '#EC4899', '#F97316',
  '#06B6D4', '#84CC16', '#A78BFA', '#FB923C',
];

class ProjectFormDialog extends StatefulWidget {
  final ProjectModel? existing;

  const ProjectFormDialog({super.key, this.existing});

  @override
  State<ProjectFormDialog> createState() => _ProjectFormDialogState();
}

class _ProjectFormDialogState extends State<ProjectFormDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _targetCtrl;
  late String _selectedColor;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _targetCtrl = TextEditingController(
      text: widget.existing?.targetMinutes != null
          ? (widget.existing!.targetMinutes! / 60).toStringAsFixed(1)
          : '',
    );
    _selectedColor = widget.existing?.colorHex ?? _kColors.first;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    final targetHours = double.tryParse(_targetCtrl.text.trim());
    final targetMinutes = targetHours != null ? (targetHours * 60).round() : null;

    setState(() => _submitting = true);
    Navigator.of(context).pop((
      name: name,
      colorHex: _selectedColor,
      targetMinutes: targetMinutes,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppStyling.surfaceDark : AppStyling.bgLight;
    final border = isDark ? AppStyling.borderDark : AppStyling.borderLight;
    final textPrimary = isDark ? AppStyling.textPrimaryDark : AppStyling.textPrimaryLight;
    final textMuted = isDark ? AppStyling.textMutedDark : AppStyling.textMutedLight;
    final accent = isDark ? AppStyling.accentPrimaryDark : AppStyling.accentLight;

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppStyling.cardRadius),
        side: BorderSide(color: border),
      ),
      child: SizedBox(
        width: 420,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.existing == null ? 'new_project' : 'edit_project',
                style: spaceMono(size: 13, weight: FontWeight.w700, color: textPrimary),
              ),
              const SizedBox(height: 20),
              _Label(text: 'name_', isDark: isDark),
              const SizedBox(height: 6),
              _Field(
                controller: _nameCtrl,
                hint: 'design sprint',
                isDark: isDark,
                autofocus: true,
                onSubmit: (_) => _submit(),
              ),
              const SizedBox(height: 16),
              _Label(text: 'target_hours_ (optional)', isDark: isDark),
              const SizedBox(height: 6),
              _Field(
                controller: _targetCtrl,
                hint: '4.0',
                isDark: isDark,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onSubmit: (_) => _submit(),
              ),
              const SizedBox(height: 4),
              Text(
                'tracked per day, resets at midnight_',
                style: dmSans(size: 10, color: textMuted),
              ),
              const SizedBox(height: 16),
              _Label(text: 'color_', isDark: isDark),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _kColors.map((hex) {
                  final color = Color(int.parse(hex.replaceFirst('#', '0xFF')));
                  final selected = _selectedColor == hex;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = hex),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: selected
                            ? Border.all(color: textPrimary, width: 2)
                            : null,
                        boxShadow: selected
                            ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6)]
                            : null,
                      ),
                      child: selected
                          ? Icon(Icons.check, size: 14, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _DialogButton(
                    label: 'cancel_',
                    isDark: isDark,
                    onTap: () => Navigator.of(context).pop(),
                    color: textMuted,
                  ),
                  const SizedBox(width: 8),
                  _DialogButton(
                    label: widget.existing == null ? 'create_' : 'save_',
                    isDark: isDark,
                    onTap: _submitting ? null : _submit,
                    color: accent,
                    filled: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  final bool isDark;
  const _Label({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark ? AppStyling.textMutedDark : AppStyling.textMutedLight;
    return Text(text, style: spaceMono(size: 10, color: textMuted));
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool isDark;
  final bool autofocus;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onSubmit;

  const _Field({
    required this.controller,
    required this.hint,
    required this.isDark,
    this.autofocus = false,
    this.keyboardType,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final border = isDark ? AppStyling.borderDark : AppStyling.borderLight;
    final textPrimary = isDark ? AppStyling.textPrimaryDark : AppStyling.textPrimaryLight;
    final textMuted = isDark ? AppStyling.textMutedDark : AppStyling.textMutedLight;
    final surface = isDark ? AppStyling.bgDark : AppStyling.surfaceLight;

    return TextField(
      controller: controller,
      autofocus: autofocus,
      keyboardType: keyboardType,
      onSubmitted: onSubmit,
      style: dmSans(size: 13, color: textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: dmSans(size: 13, color: textMuted),
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark ? AppStyling.accentPrimaryDark : AppStyling.accentLight,
          ),
        ),
      ),
    );
  }
}

class _DialogButton extends StatefulWidget {
  final String label;
  final bool isDark;
  final VoidCallback? onTap;
  final Color color;
  final bool filled;

  const _DialogButton({
    required this.label,
    required this.isDark,
    required this.onTap,
    required this.color,
    this.filled = false,
  });

  @override
  State<_DialogButton> createState() => _DialogButtonState();
}

class _DialogButtonState extends State<_DialogButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.filled
        ? (widget.onTap == null
            ? widget.color.withValues(alpha: 0.4)
            : (_hovered ? widget.color.withValues(alpha: 0.85) : widget.color))
        : (_hovered
            ? widget.color.withValues(alpha: 0.08)
            : Colors.transparent);

    return MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            widget.label,
            style: spaceMono(
              size: 11,
              color: widget.filled ? Colors.white : widget.color,
            ),
          ),
        ),
      ),
    );
  }
}
