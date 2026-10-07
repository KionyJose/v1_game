/// A última interface aberta recebe os comandos; a anterior volta ao fechar.
class PadInterfaceRouter {
  final List<({void Function(String) handler, bool Function()? acceptsCommand})>
      _handlers = [];
  void Function() attach(void Function(String) handler,
      {bool Function()? acceptsCommand}) {
    final entry = (handler: handler, acceptsCommand: acceptsCommand);
    _handlers.add(entry);
    return () => _handlers.remove(entry);
  }

  bool dispatch(String command) {
    if (_handlers.isEmpty || command.isEmpty) return false;
    for (final entry in _handlers.reversed) {
      if (!(entry.acceptsCommand?.call() ?? true)) continue;
      entry.handler(command);
      return true;
    }
    return false;
  }
}
