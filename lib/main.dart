import 'dart:async';
import 'package:flutter/material.dart';
import 'mw_fall_detection.dart';

// import 'mw_device_info.dart';
// void main() => runApp(MyApp());

mw_fall_detection fall_dectect = mw_fall_detection(100000, 10);
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

  void _on_fall() {
    //แทนที่จะใช้ setState ก็เซ็ตค่าผ่าน StreamController แทน
    controller.add("FALL");
  }

  void _off_fall() {
    //แทนที่จะใช้ setState ก็เซ็ตค่าผ่าน StreamController แทน
    controller.add("OK");
  }

  @override
  void initState() {
    print("object");
    controller.add("_on_fall");
    fall_dectect.mw_check_fall_detction_state();
    super.initState();
  }

  @override
  void dispose() {
    _mw_stop_fall_detection();
    controller.close();
    super.dispose();
  }

  void _mw_stop_fall_detection() {
    if (_mw_fall_detection == null) return;
    _mw_fall_detection?.cancel();
    _mw_fall_detection = null;
    fall_dectect.mw_stop_fall_detection();
  }

  void start_fall_detection() {
    fall_dectect.mw_start_fall_detection();
    Stream event = fall_dectect.mw_event_sensor.stream;
    _mw_fall_detection = event.listen((value) {
      setState(() {
        print('${value.timestamp}  ${value.state} ${value.location}');

        if (value.state == "Warning") {
          _on_fall();
          // final device_info = mw_device_info();
          // device_info.deviceName;
          print('Value from controller:  ${value.state} ');
        } else if (value.state == "Normal") {
          print('Value from controller:  ${value.state} ');
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter Sensors Example'),
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
                    builder: (context, snapshot) =>
                        Text('count is ${snapshot.data}'),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      MaterialButton(
                        child: Text("Critical"),
                        color: Colors.green,
                        onPressed: _on_fall,
                      ),
                      MaterialButton(
                        child: Text("I'm OK"),
                        color: Colors.red,
                        onPressed: _off_fall,
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
