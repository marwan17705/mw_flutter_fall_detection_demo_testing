import 'dart:async';
// import 'dart:ffi';

import 'package:flutter/material.dart';

// import 'dart:math';
import 'mw_fall_detection.dart';

import 'package:http/http.dart' as http;

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

  @override
  void initState0() {
    super.initState();
    controller.add("_on_fall");
  }

  @override
  void dispose0() {
    super.dispose();
    controller.close();
  }

  void _on_fall() {
    //แทนที่จะใช้ setState ก็เซ็ตค่าผ่าน StreamController แทน
    controller.add("FALL");
  }

  void _off_fall() {
    //แทนที่จะใช้ setState ก็เซ็ตค่าผ่าน StreamController แทน
    controller.add("OK");
  }

  get_http() async {
    var url = Uri.parse(
        'https://gravity.giantiot.com:1880/api/ihealth/v1/patients/myqrcode');
    var response = await http.post(url,
        body: {'cid': '1102002240962'},
        headers: {'x-api-key': '16fa4bde-c4fd-4013-a565-0988a3734f46'});
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');
  }

  @override
  void initState() {
    get_http();
    print("object");
    fall_dectect.mw_check_fall_detction_state();
    super.initState();
  }

  @override
  void dispose() {
    _mw_stop_fall_detection();
    super.dispose();
  }

  void _mw_stop_fall_detection() {
    if (_mw_fall_detection == null) return;
    _mw_fall_detection?.cancel();
    _mw_fall_detection = null;
    fall_dectect.mw_drop_fall_detection();
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
                    builder: (context, snapshot) {
                      // print('render - Counter Widget: ');

                      // print('render - Counter Widget');

                      // final device = DeviceInfo();
                      // print(device.getDeviceSerialNumber());
                      return Text('count is ${snapshot.data}');
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      MaterialButton(
                        child: Text("_on_fall"),
                        color: Colors.green,
                        onPressed: _on_fall,
                      ),
                      MaterialButton(
                        child: Text("_off_fall"),
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
