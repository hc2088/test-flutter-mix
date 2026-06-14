import 'package:flutter/material.dart';
import 'package:pigeon_demo_plugin/pigeon_demo_plugin.dart';

class PigeonDemoPage extends StatefulWidget {
  const PigeonDemoPage({super.key});

  @override
  State<PigeonDemoPage> createState() => _PigeonDemoPageState();
}

class _PigeonDemoPageState extends State<PigeonDemoPage> {
  final PigeonDemoPlugin _plugin = PigeonDemoPlugin();

  DeviceInfoReply? _deviceInfo;
  CounterReply? _counterReply;
  int _counter = 0;
  String? _error;
  bool _loadingDevice = false;
  bool _loadingCounter = false;

  Future<void> _loadDeviceInfo() async {
    setState(() {
      _loadingDevice = true;
      _error = null;
    });

    try {
      final DeviceInfoReply reply =
          await _plugin.getDeviceInfo(prefix: 'Hello');
      setState(() {
        _deviceInfo = reply;
      });
    } catch (error) {
      setState(() {
        _error = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingDevice = false;
        });
      }
    }
  }

  Future<void> _incrementOnNativeSide() async {
    setState(() {
      _loadingCounter = true;
      _error = null;
    });

    try {
      final CounterReply reply = await _plugin.increment(_counter);
      setState(() {
        _counter = reply.value ?? _counter;
        _counterReply = reply;
      });
    } catch (error) {
      setState(() {
        _error = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingCounter = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pigeon Plugin Demo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          FilledButton.icon(
            onPressed: _loadingDevice ? null : _loadDeviceInfo,
            icon: const Icon(Icons.phone_iphone),
            label: Text(_loadingDevice ? 'Loading...' : 'Read native info'),
          ),
          const SizedBox(height: 12),
          _InfoTile(
            title: 'Platform',
            value: _deviceInfo?.platform ?? '-',
          ),
          _InfoTile(
            title: 'OS version',
            value: _deviceInfo?.osVersion ?? '-',
          ),
          _InfoTile(
            title: 'Model',
            value: _deviceInfo?.model ?? '-',
          ),
          _InfoTile(
            title: 'Native message',
            value: _deviceInfo?.message ?? '-',
          ),
          const Divider(height: 32),
          Text(
            'Counter: $_counter',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _loadingCounter ? null : _incrementOnNativeSide,
            icon: const Icon(Icons.add),
            label:
                Text(_loadingCounter ? 'Calculating...' : 'Increment native'),
          ),
          const SizedBox(height: 12),
          _InfoTile(
            title: 'Counter reply',
            value: _counterReply?.message ?? '-',
          ),
          if (_error != null) ...<Widget>[
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 120,
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
