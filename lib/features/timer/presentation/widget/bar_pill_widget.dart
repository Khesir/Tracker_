import 'package:flutter/material.dart';
import '../../../../core/media/media_info.dart';
import '../../../../core/models/project_model.dart';
import '../../../../core/theme/app_theme.dart';
import 'bar_card_widget.dart';
import 'marquee_text_widget.dart';
import 'project_picker_widget.dart';

// Design tokens — mirrors BarCard's recipe (lib/features/timer/
// presentation/widget/bar_card_widget.dart) so the bar_ card and pill
// share the same "white card over desktop" look.
const _kAccent = Color(0xFF16C172);
const _kInk = Color(0xFF16181D);
const _kMuted = Color(0xFF9AA0AB);
const _kCardBg = Color(0xFFFAFAFA);

const double _kBarPillWidth = 150;
const double _kBarPillLeft = 24;
const double _kBarPillTop = 14;
// Same shadow-clearance reasoning as BarCard (bar_card_widget.dart) — the
// shared BoxShadow recipe needs ~28px sideways / ~50px below the box, or
// the OS window clips it.
const double _kBarPillRight = 28;
const double _kBarPillBottom = 48;

/// The bar_ style's further-minimized "pill" state — matches
/// `trackr_ widget 2.html`'s `.pill` block in full (unlike the vinyl
/// pill, which is trimmed to just time + expand): a passive music
/// status line, the elapsed timer + an expand-to-card button, and the
/// same docked project row the bar_ card uses, which doubles as the
/// project-switcher affordance without needing to expand first.
class BarPill extends StatelessWidget {
  final String elapsed;
  final MediaInfo media;
  final String? projectName;
  final String? activeProjectId;
  final bool pickerOpen;
  final List<ProjectModel> projects;
  final VoidCallback onExpand;
  final VoidCallback onTogglePicker;
  final ValueChanged<ProjectModel> onSelectProject;

  const BarPill({
    super.key,
    required this.elapsed,
    required this.media,
    required this.projectName,
    required this.activeProjectId,
    required this.pickerOpen,
    required this.projects,
    required this.onExpand,
    required this.onTogglePicker,
    required this.onSelectProject,
  });

  @override
  Widget build(BuildContext context) {
    final parts = elapsed.split(':');

    return Padding(
      padding: const EdgeInsets.fromLTRB(_kBarPillLeft, _kBarPillTop, _kBarPillRight, _kBarPillBottom),
      child: Container(
        width: _kBarPillWidth,
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              offset: const Offset(0, 1),
              blurRadius: 1,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.50),
              offset: const Offset(0, 22),
              blurRadius: 46,
              spreadRadius: -18,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              offset: const Offset(0, 8),
              blurRadius: 18,
              spreadRadius: -10,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BarDragArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Passive music status line
                    if (media.hasTrack)
                      MarqueeText(
                        text: 'listening_ ${media.title}',
                        style: spaceMono(size: 9.5, color: _kMuted),
                      )
                    else
                      Text(
                        'not playing',
                        style: spaceMono(size: 9.5, color: _kMuted),
                      ),
                    const SizedBox(height: 6),
                    // Timer + expand-to-card button
                    Row(
                      children: [
                        RichText(
                          text: TextSpan(
                            style: spaceMono(size: 19, weight: FontWeight.w800),
                            children: [
                              TextSpan(text: parts[0], style: const TextStyle(color: _kInk)),
                              const TextSpan(text: ':', style: TextStyle(color: _kMuted, fontWeight: FontWeight.w500)),
                              TextSpan(text: parts[1], style: const TextStyle(color: _kInk)),
                              const TextSpan(text: ':', style: TextStyle(color: _kMuted, fontWeight: FontWeight.w500)),
                              TextSpan(text: parts[2], style: const TextStyle(color: _kAccent)),
                            ],
                          ),
                        ),
                        const Spacer(),
                        BarWinBtn(
                          icon: Icons.open_in_full_rounded,
                          tooltip: 'expand',
                          onTap: onExpand,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Project row — docked at the bottom, acts as the picker
            // toggle. Same component/interaction the bar_ card uses.
            BarProjectRow(
              name: projectName ?? 'no session',
              isOpen: pickerOpen,
              onTap: onTogglePicker,
            ),
            if (pickerOpen) ProjectPicker(
              projects: projects,
              activeProjectId: activeProjectId,
              onSelect: onSelectProject,
            ),
          ],
        ),
      ),
    );
  }
}
