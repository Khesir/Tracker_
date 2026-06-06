#include "smtc_plugin.h"

#include <windows.h>
#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Media.Control.h>

#include <chrono>
#include <string>

namespace {

using namespace winrt::Windows::Media::Control;

std::string ToUtf8(const winrt::hstring& s) {
  if (s.empty()) return {};
  int len = WideCharToMultiByte(CP_UTF8, 0, s.c_str(), -1, nullptr, 0,
                                nullptr, nullptr);
  if (len <= 1) return {};
  std::string out(len - 1, '\0');
  WideCharToMultiByte(CP_UTF8, 0, s.c_str(), -1, &out[0], len, nullptr,
                      nullptr);
  return out;
}

// StreamHandler subclass bridges EventChannel listen/cancel to SmtcPlugin.
class SmtcStreamHandler
    : public flutter::StreamHandler<flutter::EncodableValue> {
 public:
  explicit SmtcStreamHandler(SmtcPlugin* plugin) : plugin_(plugin) {}

 protected:
  std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>>
  OnListenInternal(
      const flutter::EncodableValue* /*arguments*/,
      std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>&& events)
      override {
    plugin_->OnListen(std::move(events));
    return nullptr;
  }

  std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>>
  OnCancelInternal(const flutter::EncodableValue* /*arguments*/) override {
    plugin_->OnCancel();
    return nullptr;
  }

 private:
  SmtcPlugin* plugin_;
};

}  // namespace

SmtcPlugin::SmtcPlugin(flutter::BinaryMessenger* messenger) {
  method_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          messenger, "trackr/media",
          &flutter::StandardMethodCodec::GetInstance());

  method_channel_->SetMethodCallHandler(
      [this](const auto& call, auto result) {
        HandleMethodCall(call, std::move(result));
      });

  event_channel_ =
      std::make_unique<flutter::EventChannel<flutter::EncodableValue>>(
          messenger, "trackr/media/events",
          &flutter::StandardMethodCodec::GetInstance());

  event_channel_->SetStreamHandler(
      std::make_unique<SmtcStreamHandler>(this));
}

SmtcPlugin::~SmtcPlugin() {
  StopPollThread();
  std::lock_guard<std::mutex> lock(sink_mutex_);
  delete event_sink_;
  event_sink_ = nullptr;
}

void SmtcPlugin::OnListen(
    std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>&& events) {
  {
    std::lock_guard<std::mutex> lock(sink_mutex_);
    event_sink_ = events.release();
  }
  StartPollThread();
}

void SmtcPlugin::OnCancel() {
  StopPollThread();
  std::lock_guard<std::mutex> lock(sink_mutex_);
  delete event_sink_;
  event_sink_ = nullptr;
}

void SmtcPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const auto& method = call.method_name();

  auto try_control = [&](auto action_fn) {
    std::thread([action_fn]() {
      winrt::init_apartment(winrt::apartment_type::multi_threaded);
      try {
        auto manager =
            GlobalSystemMediaTransportControlsSessionManager::RequestAsync()
                .get();
        auto session = manager.GetCurrentSession();
        if (session) action_fn(session);
      } catch (...) {
      }
    }).detach();
    result->Success();
  };

  if (method == "playPause") {
    try_control([](auto& s) { s.TryTogglePlayPauseAsync().get(); });
  } else if (method == "skipNext") {
    try_control([](auto& s) { s.TrySkipNextAsync().get(); });
  } else if (method == "skipPrevious") {
    try_control([](auto& s) { s.TrySkipPreviousAsync().get(); });
  } else {
    result->NotImplemented();
  }
}

void SmtcPlugin::StartPollThread() {
  stop_flag_ = false;
  poll_thread_ = std::thread([this]() { PollLoop(); });
}

void SmtcPlugin::StopPollThread() {
  stop_flag_ = true;
  if (poll_thread_.joinable()) poll_thread_.join();
}

void SmtcPlugin::PollLoop() {
  winrt::init_apartment(winrt::apartment_type::multi_threaded);

  std::string last_title;
  std::string last_artist;
  bool last_playing = false;
  bool last_has_session = false;

  while (!stop_flag_) {
    try {
      auto manager =
          GlobalSystemMediaTransportControlsSessionManager::RequestAsync()
              .get();
      auto session = manager.GetCurrentSession();

      if (!session) {
        if (last_has_session) {
          std::lock_guard<std::mutex> lock(sink_mutex_);
          if (event_sink_) {
            flutter::EncodableMap map;
            map[flutter::EncodableValue("title")] =
                flutter::EncodableValue(std::string{});
            map[flutter::EncodableValue("artist")] =
                flutter::EncodableValue(std::string{});
            map[flutter::EncodableValue("isPlaying")] =
                flutter::EncodableValue(false);
            event_sink_->Success(flutter::EncodableValue(map));
          }
          last_has_session = false;
          last_title.clear();
          last_artist.clear();
          last_playing = false;
        }
      } else {
        auto props = session.TryGetMediaPropertiesAsync().get();
        auto playback = session.GetPlaybackInfo();

        std::string title = props ? ToUtf8(props.Title()) : std::string{};
        std::string artist = props ? ToUtf8(props.Artist()) : std::string{};
        bool is_playing =
            playback.PlaybackStatus() ==
            GlobalSystemMediaTransportControlsSessionPlaybackStatus::Playing;

        if (!last_has_session || title != last_title ||
            artist != last_artist || is_playing != last_playing) {
          std::lock_guard<std::mutex> lock(sink_mutex_);
          if (event_sink_) {
            flutter::EncodableMap map;
            map[flutter::EncodableValue("title")] =
                flutter::EncodableValue(title);
            map[flutter::EncodableValue("artist")] =
                flutter::EncodableValue(artist);
            map[flutter::EncodableValue("isPlaying")] =
                flutter::EncodableValue(is_playing);
            event_sink_->Success(flutter::EncodableValue(map));
          }
          last_title = title;
          last_artist = artist;
          last_playing = is_playing;
          last_has_session = true;
        }
      }
    } catch (...) {
      // SMTC unavailable or access denied — skip.
    }

    std::this_thread::sleep_for(std::chrono::milliseconds(500));
  }
}
