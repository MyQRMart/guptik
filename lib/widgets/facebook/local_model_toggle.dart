import 'package:flutter/material.dart';
import 'package:guptik/services/node/social_reply_service.dart';

class LocalModelToggle extends StatefulWidget {
  const LocalModelToggle({super.key});

  @override
  State<LocalModelToggle> createState() => _LocalModelToggleState();
}

class _LocalModelToggleState extends State<LocalModelToggle> {
  final _svc = SocialReplyService();
  bool _on = false;
  bool _busy = true;
  String _model = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final s = await _svc.settings();
      if (!mounted) return;
      setState(() {
        _on = s['use_local'] == true;
        _model = s['model_name']?.toString() ?? '';
        _busy = false;
      });
    } catch (_) {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _set(bool v) async {
    setState(() => _busy = true);
    try {
      await _svc.setUseLocal(v);
      if (mounted) setState(() => _on = v);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Use this PC’s AI model'),
      subtitle: Text(
        _on
            ? (_model.isEmpty ? 'On — GupTik AI settings on the node' : 'On — $_model')
            : 'Off — GupTik hosted models (wired in AI chat next)',
        style: const TextStyle(fontSize: 12),
      ),
      value: _on,
      onChanged: _busy ? null : _set,
    );
  }
}
