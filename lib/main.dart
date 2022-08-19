import 'dart:async';
import 'package:flutter/material.dart';
import 'mw_fall_detection.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';

// import 'mw_device_info.dart';
// void main() => runApp(MyApp());

mw_fall_detection fall_dectect = mw_fall_detection(10000, 60);
main() {
  runApp(MaterialApp(home: MyApp()));
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription? _mw_fall_detection;
  int _counter = 0;
  StreamController<String> controller = new StreamController<String>();

  void _on_fall() async {
    //แทนที่จะใช้ setState ก็เซ็ตค่าผ่าน StreamController แทน
    controller.add("FALL");

    await FlutterRingtonePlayer.play(
      android: AndroidSounds.ringtone,
      ios: IosSounds.glass,
      looping: true, // Android only - API >= 28
      volume: 0.2, // Android only - API >= 28
      asAlarm: false, // Android only - all APIs
    );
    // FlutterRingtonePlayer.playRingtone(
    //     volume: 0.1, looping: true, asAlarm: false);
  }

  void _off_fall() async {
    //แทนที่จะใช้ setState ก็เซ็ตค่าผ่าน StreamController แทน
    controller.add("OK");

    await FlutterRingtonePlayer.stop();
  }

  @override
  void initState() {
    print("object");
    controller.add("OK");
    fall_dectect.mw_check_fall_detction_state();
    super.initState();
  }

  @override
  void dispose() {
    _mw_stop_fall_detection();
    controller.close();
    FlutterRingtonePlayer.stop();

    super.dispose();
  }

  void _mw_stop_fall_detection() async {
    if (_mw_fall_detection == null) return;
    await _mw_fall_detection?.cancel();
    _mw_fall_detection = null;
    fall_dectect.mw_stop_fall_detection();
  }

  void start_fall_detection() {
    if (_mw_fall_detection != null) return;
    fall_dectect.mw_start_fall_detection();
    Stream event = fall_dectect.mw_event_sensor.stream;
    _mw_fall_detection = event.listen((value) {
      setState(() {
        print(
            '${value.timestamp}  ${value.state} ${value.location.longitude} ${value.location.latitude} ');

        if (value.state == "06") {
          _on_fall();
          // final device_info = mw_device_info();
          // device_info.deviceName;
          FlutterRingtonePlayer.playNotification();

          print('Value from controller:  ${value.state} ');
        } else if (value.state == "00") {
          print('Value from controller:  ${value.state} ');
          FlutterRingtonePlayer.stop();
        }
      });
    });
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        key: _scaffoldKey,
        drawer: _left_drawer(),
        appBar: AppBar(
          title: const Text('Flutter Sensors Example'),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.qr_code),
              tooltip: 'find',
              onPressed: () {
                // handle the press
              },
            ),
          ],
        ),
        body: Container(
          padding: EdgeInsets.all(16.0),
          alignment: AlignmentDirectional.topCenter,
          child: Column(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  MaterialButton(
                      child: Text("Start"),
                      color: Colors.green,
                      onPressed: () => start_fall_detection()),
                  Padding(
                    padding: EdgeInsets.all(2.0),
                  ),
                  MaterialButton(
                    child: Text("Stop"),
                    color: Colors.red,
                    onPressed: () => _mw_stop_fall_detection(),
                  ),
                ],
              ),
              Padding(padding: EdgeInsets.only(top: 1.0)),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  StreamBuilder(
                      stream: controller.stream,
                      builder: (context, snapshot) {
                        // Text('count is ${snapshot.data}'),
                        if (snapshot.data == 'OK')
                          return Text('count is ${snapshot.data}');
                        else
                          return AlertDialog(
                              title: const Text('AlertDialog Title'),
                              content: SingleChildScrollView(
                                child: ListBody(
                                  children: const <Widget>[
                                    Text('Fall detection alarm.'),
                                    // Text(
                                    //     'Would you like to approve of this message?'),
                                  ],
                                ),
                              ),
                              actions: <Widget>[
                                TextButton(
                                  child: const Text('is you OK'),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => MyApp()),
                                    );
                                  },
                                ),
                              ]);
                      }),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      MaterialButton(
                        child: Text("SOS"),
                        color: Colors.green,
                        onPressed: _on_fall,
                      ),
                      MaterialButton(
                        child: Text("I'm OK"),
                        color: Colors.red,
                        onPressed: _off_fall,
                        // onPressed: () {
                        //   _scaff
                        // },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FirstRoute extends StatelessWidget {
  const FirstRoute({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _left_drawer(),
      appBar: AppBar(
        title: const Text('First Route'),
      ),
      body: Center(
        child: ElevatedButton(
          child: const Text('Home'),
          onPressed: () {
            // Navigate to second route when tapped.
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MyApp()),
            );
          },
        ),
      ),
    );
  }
}

class SecondRoute extends StatelessWidget {
  const SecondRoute({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _left_drawer(),
      appBar: AppBar(
        title: const Text('Second Route'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Navigate back to first route when tapped.
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MyApp()),
            );
          },
          child: const Text('Home'),
        ),
      ),
    );
  }
}

class _left_drawer extends StatelessWidget {
  const _left_drawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        DrawerHeader(
          duration: const Duration(microseconds: 10),
          margin: const EdgeInsets.only(bottom: 2.0),
          padding: const EdgeInsets.fromLTRB(40.0, 40.0, 8.0, 8.0),
          decoration: BoxDecoration(color: Colors.white),
          child: Text("Menu",
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 60,
                  fontWeight: FontWeight.w800)),
        ),
        ListTile(
          title: const Text('home'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MyApp()),
            );
          },
        ),
        ListTile(
          title: const Text('page1'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SecondRoute()),
            );
          },
        ),
        ListTile(
          title: const Text('page2'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FirstRoute()),
            );
          },
        ),
      ],
    );
  }
}
