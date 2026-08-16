import 'package:flutter/material.dart';
import '../../../../core/models/project_model.dart';
import '../../../../core/theme/app_styling.dart';
import '../../../../core/theme/app_theme.dart';

/// Simple project picker used to link a note to a project. Pops the chosen
/// [ProjectModel], or null if dismissed. [candidates] should already
/// exclude projects the note is linked to.
class ProjectPickerDialog extends StatelessWidget {
  final List<ProjectModel> candidates;

  const ProjectPickerDialog({super.key, required this.candidates});

  Color _projectColor(ProjectModel p) =>
      Color(int.parse(p.colorHex.replaceFirst('#', '0xFF')));

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppStyling.surfaceDark : AppStyling.bgLight;
    final border = isDark ? AppStyling.borderDark : AppStyling.borderLight;
    final textPrimary = isDark ? AppStyling.textPrimaryDark : AppStyling.textPrimaryLight;
    final textMuted = isDark ? AppStyling.textMutedDark : AppStyling.textMutedLight;

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppStyling.cardRadius),
        side: BorderSide(color: border),
      ),
      child: SizedBox(
        width: 360,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'link_to_project',
                style: spaceMono(size: 13, weight: FontWeight.w700, color: textPrimary),
              ),
              const SizedBox(height: 16),
              if (candidates.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'no other projects to link',
                    style: dmSans(size: 12, color: textMuted),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: candidates.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, i) {
                      final project = candidates[i];
                      return _ProjectRow(
                        project: project,
                        color: _projectColor(project),
                        isDark: isDark,
                        onTap: () => Navigator.of(context).pop(project),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('cancel', style: dmSans(size: 13, color: textMuted)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectRow extends StatefulWidget {
  final ProjectModel project;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _ProjectRow({
    required this.project,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_ProjectRow> createState() => _ProjectRowState();
}

class _ProjectRowState extends State<_ProjectRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        widget.isDark ? AppStyling.textPrimaryDark : AppStyling.textPrimaryLight;
    final border = widget.isDark ? AppStyling.borderDark : AppStyling.borderLight;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered ? widget.color.withValues(alpha: 0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.project.name,
                  style: spaceMono(size: 12.5, weight: FontWeight.w700, color: textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
