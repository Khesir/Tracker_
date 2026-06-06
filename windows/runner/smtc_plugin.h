#ifndef RUNNER_SMTC_PLUGIN_H_
#define RUNNER_SMTC_PLUGIN_H_

#include <flutter/binary_messenger.h>
#include <flutter/event_channel.h>
#include <flutter/event_sink.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <atomic>
#include <memory>
#include <mutex>
#include <thread>

// In-runner SMTC plugin — does not extend flutter::Plugin to avoid
// depending on flutter_wrapper_plugin. Lifetime is managed by FlutterWindow.
class SmtcPlugin {
 public:
  explicit SmtcPlugin(flutter::BinaryMessenger* messenger);
  ~SmtcPlugin();

  // Called by the stream handler on listen/cancel.
  void OnListen(
      std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>&& events);
  void OnCancel();

 private:
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  void StartPollThread();
  void StopPollThread();
  void PollLoop();

  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>
      method_channel_;
  std::unique_ptr<flutter::EventChannel<flutter::EncodableValue>>
      event_channel_;

  std::mutex sink_mutex_;
  flutter::EventSink<flutter::EncodableValue>* event_sink_ = nullptr;

  std::thread poll_thread_;
  std::atomic<bool> stop_flag_{false};
};

#endif  // RUNNER_SMTC_PLUGIN_H_
