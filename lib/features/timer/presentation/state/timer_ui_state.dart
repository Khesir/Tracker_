import '../../../../core/state/stream_state.dart';
import '../../../../core/models/session_model.dart';
import '../../../../core/media/media_info.dart';

enum TimerStatus { idle, running, paused, stopping }

class TimerUiData {
  final TimerStatus status;
  final Duration elapsed;
  final String? projectId;
  final String? projectName;
  final MediaInfo media;

  const TimerUiData({
    this.status = TimerStatus.idle,
    this.elapsed = Duration.zero,
    this.projectId,
    this.projectName,
    this.media = MediaInfo.none,
  });

  bool get isRunning => status == TimerStatus.running;
  bool get isPaused => status == TimerStatus.paused;

  TimerUiData copyWith({
    TimerStatus? status,
    Duration? elapsed,
    String? projectId,
    String? projectName,
    MediaInfo? media,
    SessionModel? session,
  }) {
    return TimerUiData(
      status: status ?? this.status,
      elapsed: elapsed ?? this.elapsed,
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      media: media ?? this.media,
    );
  }
}

class TimerUiState extends StreamState<TimerUiData> {
  TimerUiState() : super(const TimerUiData());
}
