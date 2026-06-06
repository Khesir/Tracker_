#include "smtc_plugin.h"

#include <windows.h>
#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Foundation.Collections.h>
#include <winrt/Windows.Media.Control.h>
#include <winrt/Windows.Storage.Streams.h>

#include <algorithm>
#include <chrono>
#include <string>
#include <vector>

namespace {

using namespace winrt::Windows::Media::Control;
using namespace winrt::Windows::Storage::Streams;

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

GlobalSystemMediaTransportControlsSession FindSpotifySession(
    GlobalSystemMediaTransportControlsSessionManager const& manager) {
  for (auto const& session : manager.GetSessions()) {
    std::string id = ToUtf8(session.SourceAppUserModelId());
    std::string lower = id;
    std::transform(lower.begin(), lower.end(), lower.begin(),
                   [](unsigned char c) { return static_cast<char>(::tolower(c)); });
    if (lower.find("spotify") != std::string::npos) {
      return session;
    }
  }
  return {nullptr};
}

std::vector<uint8_t> ReadThumbnailBytes(
    GlobalSystemMediaTransportControlsSessionMediaProperties const& props) {
  try {
    auto ref = props.Thumbnail();
    if (!ref) return {};
    auto stream = ref.OpenReadAsync().get();
    auto size = static_cast<uint32_t>(stream.Size());
    if (size == 0 || size > 5 * 1024 * 1024) return {};
    DataReader reader(stream);
    reader.LoadAsync(size).get();
    std::vector<uint8_t> bytes(size);
    reader.ReadBytes(bytes);
    reader.DetachStream();
    return bytes;
  } catch (...) {
    return {};
  }
}

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
        auto session = FindSpotifySession(manager);
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
  std::vector<uint8_t> last_art;
  int miss_count = 0;
  static constexpr int kMissThreshold = 3;

  while (!stop_flag_) {
    try {
      auto manager =
          GlobalSystemMediaTransportControlsSessionManager::RequestAsync()
              .get();
      auto session = FindSpotifySession(manager);

      if (!session) {
        if (last_has_session) {
          ++miss_count;
          if (miss_count >= kMissThreshold) {
            std::lock_guard<std::mutex> lock(sink_mutex_);
            if (event_sink_) {
              flutter::EncodableMap map;
              map[flutter::EncodableValue("title")] =
                  flutter::EncodableValue(std::string{});
              map[flutter::EncodableValue("artist")] =
                  flutter::EncodableValue(std::string{});
              map[flutter::EncodableValue("isPlaying")] =
                  flutter::EncodableValue(false);
              map[flutter::EncodableValue("albumArtBytes")] =
                  flutter::EncodableValue(std::vector<uint8_t>{});
              event_sink_->Success(flutter::EncodableValue(map));
            }
            last_has_session = false;
            last_title.clear();
            last_artist.clear();
            last_playing = false;
            last_art.clear();
            miss_count = 0;
          }
        }
      } else {
        miss_count = 0;
        auto props = session.TryGetMediaPropertiesAsync().get();
        auto playback = session.GetPlaybackInfo();

        std::string title = props ? ToUtf8(props.Title()) : std::string{};
        std::string artist = props ? ToUtf8(props.Artist()) : std::string{};
        bool is_playing =
            playback.PlaybackStatus() ==
            GlobalSystemMediaTransportControlsSessionPlaybackStatus::Playing;

        if (props && title != last_title) {
          last_art = ReadThumbnailBytes(props);
        }

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
            map[flutter::EncodableValue("albumArtBytes")] =
                flutter::EncodableValue(last_art);
            event_sink_->Success(flutter::EncodableValue(map));
          }
          last_title = title;
          last_artist = artist;
          last_playing = is_playing;
          last_has_session = true;
        }
      }
    } catch (...) {
    }

    std::this_thread::sleep_for(std::chrono::milliseconds(500));
  }
}
