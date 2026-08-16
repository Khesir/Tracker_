import 'package:flutter/material.dart';

/// Scrolls [text] horizontally when it overflows its natural width,
/// looping seamlessly. Falls back to a plain single-line [Text] when the
/// text fits (or before the first layout pass has measured it).
///
/// Shared between the vinyl and bar_ mini-widget card styles so both
/// "now playing" / "listening_" lines scroll identically on overflow.
class MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const MarqueeText({super.key, required this.text, required this.style});

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  double _textWidth = 0;
  double _lineHeight = 12;

  static const double _gap = 36.0;
  static const double _speed = 38.0; // px per second

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void didUpdateWidget(MarqueeText old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) {
      _ctrl.stop();
      _ctrl.reset();
      WidgetsBinding.instance.addPostFrameCallback((_) => _start());
    }
  }

  void _start() {
    if (!mounted) return;
    final tp = TextPainter(
      text: TextSpan(text: widget.text, style: widget.style),
      textDirection: TextDirection.ltr,
    )..layout();
    _textWidth = tp.width;
    _lineHeight = tp.height;
    if (_textWidth <= 0) return;
    _ctrl.duration = Duration(
      milliseconds: ((_textWidth + _gap) / _speed * 1000).round(),
    );
    _ctrl.repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_textWidth == 0) {
      return Text(widget.text, style: widget.style, maxLines: 1);
    }
    return SizedBox(
      height: _lineHeight,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            final offset = _ctrl.value * (_textWidth + _gap);
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: 0,
                  left: -offset,
                  child: Text(widget.text, style: widget.style),
                ),
                Positioned(
                  top: 0,
                  left: _textWidth + _gap - offset,
                  child: Text(widget.text, style: widget.style),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
