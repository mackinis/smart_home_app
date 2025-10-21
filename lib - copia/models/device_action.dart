class DeviceAction {
  final String id;
  final String label;
  final List<ActionParam> params;
  final String commandTemplate;

  const DeviceAction({
    required this.id,
    required this.label,
    required this.params,
    required this.commandTemplate,
  });

  String buildCommand(Map<String, String> values) {
    var cmd = commandTemplate;
    values.forEach((key, value) {
      cmd = cmd.replaceAll('{$key}', value);
    });
    return cmd;
  }
}

class ActionParam {
  final String key;
  final String label;
  final String? regex;
  final bool obscure;

  const ActionParam({
    required this.key,
    required this.label,
    this.regex,
    this.obscure = false,
  });

  bool validate(String input) {
    if (regex == null) return true;
    return RegExp(regex!).hasMatch(input);
  }
}