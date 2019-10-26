import 'dart:math';

import 'package:audioplayers/audio_cache.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

void main() => runApp(RandomTimerApp());

class RandomTimerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Random Timer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: RandomTimerHomePage(title: 'Random Timer Home Page'),
    );
  }
}

class RandomTimerHomePage extends StatefulWidget {
  RandomTimerHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _RandomTimerHomePageState createState() => _RandomTimerHomePageState();
}

enum _RandomTimerPhase {
  idle,
  timing,
  alarming,
}

class _RandomTimerHomePageState extends State<RandomTimerHomePage> {
  final Random _random = Random(0);

  _RandomTimerPhase _phase = _RandomTimerPhase.idle;

  int _seconds = 0;
  int _lowerBound = 1;
  int _upperBound = 1;

  final List<String> _errorMessages = <String>[];

  // The controllers preserve the editing status after hiding and re-adding the
  // text fields.
  final TextEditingController _lowerBoundController = TextEditingController();
  final TextEditingController _upperBoundController = TextEditingController();

  final AudioCache _audioCache = AudioCache(prefix: 'audio/');
  static const String _kAudioName = 'alarm.mp3';

  AudioPlayer _audioPlayer;

  final Map<_RandomTimerPhase, DateTime> timings = {};

  void _start() {
    setState(() {
      _phase = _RandomTimerPhase.timing;
      timings[_phase] = DateTime.now();
      _seconds = _lowerBound + _random.nextInt(_upperBound - _lowerBound + 1);
      Future<void>.delayed(Duration(seconds: _seconds), () {
        setState(() {
          // Check the phase to make sure that there's only one alarm at a time.
          if (_phase == _RandomTimerPhase.timing) {
            _phase = _RandomTimerPhase.alarming;
            timings[_phase] = DateTime.now();
            _audioCache.loop(_kAudioName).then((AudioPlayer player) {
              assert(_audioPlayer == null);
              _audioPlayer = player;
            });
          }
        });
      });
    });
  }

  void _stop() {
    setState(() {
      if (_audioPlayer != null) {
        _audioPlayer.stop();
        _audioPlayer = null;
      }
      _phase = _RandomTimerPhase.idle;
      timings[_phase] = DateTime.now();
    });
  }

  void _checkBounds() {
    _errorMessages.clear();
    if (_lowerBound < 1) {
      _errorMessages
          .add('Lower bound must be no less than 1 ($_lowerBound given).');
      _lowerBound = 1;
    }
    if (_lowerBound > _upperBound) {
      _errorMessages.add(
        'Lower bound ($_lowerBound given) must be no less than '
        'upper bound ($_upperBound given).',
      );
      _upperBound = _lowerBound;
    }
  }

  Duration get _alarmDuration {
    assert(timings[_RandomTimerPhase.idle].isAfter(timings[_RandomTimerPhase.alarming]));
    return timings[_RandomTimerPhase.idle].difference(timings[_RandomTimerPhase.alarming]);
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> errorWidgets = <Widget>[];
    if (_errorMessages.length > 0) {
      errorWidgets = <Widget>[
        Container(height: 20.0),
        Text(
          _errorMessages.join('. '),
          style: TextStyle(
            color: Colors.red,
            fontSize: 12.0,
          ),
        ),
      ];
    }

    List<Widget> inputWidgets = <Widget>[
      Text(
        'Lower bound (in seconds):',
      ),
      TextField(
        controller: _lowerBoundController,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        onChanged: (String value) {
          setState(
            () {
              _lowerBound = int.tryParse(value) ?? 1;
              _checkBounds();
            },
          );
        },
      ),
      Container(height: 50.0),
      Text(
        'Upper bound (in seconds):',
      ),
      TextField(
        controller: _upperBoundController,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        onChanged: (String value) {
          setState(
            () {
              _upperBound = int.tryParse(value) ?? 1;
              _checkBounds();
            },
          );
        },
      ),
    ];

    final List<String> stats = [
      'Random timer between $_lowerBound and $_upperBound seconds.',
    ];
    if (_phase != _RandomTimerPhase.timing) {
      stats.add('Last run: $_seconds seconds.');
    }
    if (_phase == _RandomTimerPhase.idle && timings[_phase] != null) {
      stats.add('Alarm lasts: ${_alarmDuration.inSeconds} seconds.');
    }

    Widget column = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(height: 50.0),
        if (_phase == _RandomTimerPhase.idle) ...inputWidgets,
        ...errorWidgets,
        Container(height: 60.0),
        Text(
          stats.join(' '),
        ),
        if (_phase == _RandomTimerPhase.timing) LinearProgressIndicator(),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SafeArea(
        minimum: EdgeInsets.only(bottom: 100.0),
        child: Scrollbar(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.0),
              child: column,
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _phase == _RandomTimerPhase.idle ? _start : _stop,
        tooltip: _phase == _RandomTimerPhase.idle ? 'Start' : 'Stop',
        child: Icon(
            _phase == _RandomTimerPhase.idle ? Icons.play_arrow : Icons.stop),
      ),
    );
  }
}
