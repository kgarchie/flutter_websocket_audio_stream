import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mic_stream/mic_stream.dart';
import 'package:web_socket_channel/io.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'WebSocket Audio Stream',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class RaisedButton extends StatelessWidget {
  const RaisedButton({super.key, this.onPressed, this.child});

  final VoidCallback? onPressed;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: child,
    );
  }
}

class _MyHomePageState extends State<MyHomePage> {
  late IOWebSocketChannel _channel;
  late StreamSubscription<List<int>> _streamSubscription;
  late Stream<List<int>>? stream;
  bool _isRecording = false;
  int count = 0;
  List<String> _serverMessages = [];

  @override
  void dispose() {
    _streamSubscription.cancel();
    _channel.sink.close();
    super.dispose();
  }

  Future<void> _startRecording() async {
    MicStream.shouldRequestPermission(true);
    _connectToServer();

    _serverMessages = [];

    stream = await MicStream.microphone(
      audioSource: AudioSource.DEFAULT,
      sampleRate: 48000,
      channelConfig: ChannelConfig.CHANNEL_IN_MONO,
      audioFormat: AudioFormat.ENCODING_PCM_16BIT,
    );

    setState(() {
      _isRecording = true;
    });
    _streamSubscription = stream?.listen((data) {
      _channel.sink.add(data);
    }) as StreamSubscription<List<int>>;
  }

  Future<void> _stopRecording() async {
    _streamSubscription.cancel();
    setState(() {
      _isRecording = false;
    });
    _disconnectFromServer();
    count = 0;
  }

  void _connectToServer() {
    _channel = IOWebSocketChannel.connect('ws://192.168.100.43:5000');
    _channel.stream.listen((data) {
      count++;
      var message = '$count: $data';
      setState(() {
        _serverMessages.add(message);
      });
    });
  }

  void _disconnectFromServer() {
    _channel.sink.close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WebSocket Audio Stream'),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: <Widget>[
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(left: 20),
                child: Text(
                  'Transcribed Messages',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: MediaQuery.of(context).size.height - 200,
              child: ListView.builder(
                itemCount: _serverMessages.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_serverMessages[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _isRecording ? _stopRecording() : _startRecording();
        },
        child: _isRecording ? const Icon(Icons.stop) : const Icon(Icons.mic),
      ),
    );
  }

}
