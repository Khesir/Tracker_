import 'dart:io';

/// Prevents multiple app instances from opening the same Hive cache
/// concurrently (which crashes with a PathAccessException lock error).
///
/// Implemented via a loopback TCP socket: the first instance binds the
/// port and acts as the lock holder; later instances fail to bind, ping
/// the holder to bring its window to front, then exit.
class SingleInstanceService {
  static const _lockPort = 51823;

  ServerSocket? _server;
  void Function()? onSecondInstanceLaunched;

  Future<bool> acquire() async {
    try {
      _server = await ServerSocket.bind(InternetAddress.loopbackIPv4, _lockPort);
      _server!.listen((socket) {
        onSecondInstanceLaunched?.call();
        socket.destroy();
      });
      return true;
    } on SocketException {
      await _notifyPrimaryInstance();
      return false;
    }
  }

  Future<void> _notifyPrimaryInstance() async {
    try {
      final socket = await Socket.connect(InternetAddress.loopbackIPv4, _lockPort);
      socket.destroy();
    } on SocketException {
      // Primary instance is unreachable; nothing more we can do here.
    }
  }
}
