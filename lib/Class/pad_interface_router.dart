/// A última interface aberta recebe os comandos; a anterior volta ao fechar.
class PadInterfaceRouter {
  final List<void Function(String)> _handlers = [];
  void Function() attach(void Function(String) handler) {
    _handlers.add(handler);
    return () => _handlers.remove(handler);
  }

  bool dispatch(String command) {
    if (_handlers.isEmpty || command.isEmpty) return false;
    _handlers.last(command);
    return true;
  }
}
