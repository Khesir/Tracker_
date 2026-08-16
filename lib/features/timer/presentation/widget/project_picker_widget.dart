import 'package:flutter/material.dart';
import '../../../../core/models/project_model.dart';
import '../../../../core/theme/app_theme.dart';

const _kAccent = Color(0xFF16C172);
const _kInk = Color(0xFF16181D);
const _kMuted = Color(0xFF9AA0AB);
const _kLine = Color(0xFFE9EAEE);

/// Inline, resize-based project list panel used by both the vinyl and
/// bar_ mini-widget card styles when their project picker is open.
class ProjectPicker extends StatelessWidget {
  final List<ProjectModel> projects;
  final String? activeProjectId;
  final ValueChanged<ProjectModel> onSelect;

  const ProjectPicker({
    super.key,
    required this.projects,
    required this.activeProjectId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(height: 1, color: _kLine),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 140),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 5),
            shrinkWrap: true,
            itemCount: projects.length,
            itemBuilder: (_, i) {
              final p = projects[i];
              final isActive = p.id == activeProjectId;
              return ProjectRow(
                project: p,
                isActive: isActive,
                onTap: () => onSelect(p),
              );
            },
          ),
        ),
      ],
    );
  }
}

class ProjectRow extends StatefulWidget {
  final ProjectModel project;
  final bool isActive;
  final VoidCallback onTap;

  const ProjectRow({
    super.key,
    required this.project,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<ProjectRow> createState() => _ProjectRowState();
}

class _ProjectRowState extends State<ProjectRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = Color(
      int.parse('FF${widget.project.colorHex.replaceFirst('#', '')}', radix: 16),
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          color: _hovered
              ? Colors.black.withValues(alpha: 0.04)
              : Colors.transparent,
          child: Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  widget.project.name,
                  style: spaceMono(
                    size: 9,
                    color: widget.isActive ? _kInk : _kMuted,
                    weight: widget.isActive ? FontWeight.w700 : FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.isActive)
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: _kAccent,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
