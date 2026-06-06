import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/media/media_info.dart';
import '../../../../core/theme/app_styling.dart';
import '../../../../core/theme/app_theme.dart';

class MusicBarWidget extends StatefulWidget {
  final MediaInfo media;
  final VoidCallback onPlayPause;
  final VoidCallback onSkipNext;

  const MusicBarWidget({
    super.key,
    required this.media,
    required this.onPlayPause,
    required this.onSkipNext,
  });

  @override
  State<MusicBarWidget> createState() => _MusicBarWidgetState();
}

class _MusicBarWidgetState extends State<MusicBarWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slideCtrl;
  late final Animation<double> _slideAnim;
  Timer? _hideTimer;
  bool _visible = false;

  static const _hideAfter = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _slideAnim = CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut);
    _syncVisibility(widget.media);
  }

  @override
  void didUpdateWidget(MusicBarWidget old) {
    super.didUpdateWidget(old);
    if (widget.media.hasTrack != old.media.hasTrack ||
        widget.media.isPlaying != old.media.isPlaying ||
        widget.media.title != old.media.title) {
      _syncVisibility(widget.media);
    }
  }

  void _syncVisibility(MediaInfo info) {
    _hideTimer?.cancel();
    if (info.hasTrack) {
      _show();
      if (!info.isPlaying) {
        _hideTimer = Timer(_hideAfter, _hide);
      }
    } else {
      _hideTimer = Timer(_hideAfter, _hide);
    }
  }

  void _show() {
    if (_visible) return;
    setState(() => _visible = true);
    _slideCtrl.forward();
  }

  void _hide() {
    if (!_visible) return;
    _slideCtrl.reverse().then((_) {
      if (mounted) setState(() => _visible = false);
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _slideCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppStyling.textMutedDark : AppStyling.textMutedLight;
    final border = isDark ? AppStyling.borderDark : AppStyling.borderLight;
    final surface = isDark ? AppStyling.surfaceDark : AppStyling.surfaceLight;

    return SizeTransition(
      sizeFactor: _slideAnim,
      axisAlignment: -1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: surface,
          border: Border(top: BorderSide(color: border)),
        ),
        child: Row(
          children: [
            Icon(Icons.music_note_rounded, size: 12, color: textMuted),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.media.title,
                    style: dmSans(size: 11, color: textMuted),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  if (widget.media.artist.isNotEmpty)
                    Text(
                      widget.media.artist,
                      style: dmSans(
                        size: 10,
                        color: textMuted.withValues(alpha: 0.6),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            _MediaButton(
              icon: widget.media.isPlaying
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              color: textMuted,
              onTap: widget.onPlayPause,
            ),
            const SizedBox(width: 2),
            _MediaButton(
              icon: Icons.skip_next_rounded,
              color: textMuted,
              onTap: widget.onSkipNext,
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaButton extends StatefulWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MediaButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_MediaButton> createState() => _MediaButtonState();
}

class _MediaButtonState extends State<_MediaButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: _hovered
                ? widget.color.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Icon(widget.icon, size: 15, color: widget.color),
        ),
      ),
    );
  }
}
