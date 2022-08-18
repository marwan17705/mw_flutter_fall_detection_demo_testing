import 'dart:async';
import 'package:geolocator/geolocator.dart';

import 'package:flutter_sensors/flutter_sensors.dart';
import 'dart:math';

class mw_fall_detection {
  int sample_update;
  StreamSubscription? _accelSubscription;
  StreamSubscription? _gyroSubscription;
  bool _accelAvailable = false;
  bool _gyroAvailable = false;
  List<double> _accelData = List.filled(3, 0.0);
  List<double> _gyroData = List.filled(3, 0.0);
  num abs_gyro = 0;
  num abs_accel = 0;
  List<abs_sample> mw_raw_accel = [];
  List<abs_sample> mw_raw_gyro = [];
  int _counter_accel = 0;
  int _counter_gyro = 0;
  DateTime? mw_start_fall;
  bool mw_is_fall = false;
  int _mw_normal_state_update = 3600;
  DateTime _mw_count_accel_update = DateTime.now();
  final mwFallUpper = 30;
  final mwGyroUpper = 15;
  final mwPeriodFall = 2000; //m

  StreamController<mw_state> mw_event_sensor =
      StreamController<mw_state>.broadcast();

  /// sample_update: frequency to scan sensor (microsecond).
  /// _mw_count_accel_update: frequency to update (second).
  mw_fall_detection(this.sample_update, this._mw_normal_state_update) {
    sample_update = this.sample_update;
    _mw_normal_state_update = this._mw_normal_state_update;
  }

  Future<void> _startAccelerometer() async {
    if (_accelSubscription != null) return;
    if (_accelAvailable) {
      final stream = await SensorManager().sensorUpdates(
        sensorId: Sensors.ACCELEROMETER,
        // interval: Sensors.SENSOR_DELAY_FASTEST,
        interval: Duration(microseconds: sample_update),
      );
      _accelSubscription = stream.listen((sensorEvent) async {
        String _status_check = "Normal";
        // print("_accelData");

        // setState(() {
        _accelData = sensorEvent.data;
        // });

        // num
        abs_accel = sqrt(pow(_accelData[0], 2) +
            pow(_accelData[1], 2) +
            pow(_accelData[2], 2));
        // print("abs_accel ${abs_accel}");

        // mw_event_sensor.add(0);
        // mw_send_state("Normal");

        if (abs_accel > mwFallUpper) {
          if (abs_gyro > mwGyroUpper) mw_is_fall = true;
          mw_start_fall = DateTime.now();

          // print(mw_start_fall?.second);
        } else {
          if (mw_is_fall) {
            mw_is_fall = false;
            DateTime? new_date = mw_start_fall?.add(const Duration(seconds: 1));
            DateTime? current_date = DateTime.now();

            int? new_ = new_date?.millisecondsSinceEpoch;
            int? current_ = current_date.millisecondsSinceEpoch;
            if (new_ != null) if (current_ < new_) {
              // print("fall detect");
              _status_check = "Warning";
              await mw_send_state(_status_check);
              // mw_event_sensor.add(mw_state(position,"waring"));
            }
          }
        }
        _counter_accel += 1;
        if (mw_raw_accel.length >= 50) {
          // sample = 19;
          // print(data);
          mw_raw_accel.removeAt(0);
          mw_raw_accel.add(abs_sample(_counter_accel, abs_accel));
        } else
          mw_raw_accel.add(abs_sample(_counter_accel, abs_accel));
        // print(
        //     "mw_send_state $_mw_count_accel_update *$sample_update == ${_mw_count_accel_update * sample_update / 1000000} > $_mw_normal_state_update");

        if ((_mw_count_accel_update.difference(DateTime.now()).inSeconds)
                .abs() >
            _mw_normal_state_update) {
          await mw_send_state(_status_check);
          _mw_count_accel_update = DateTime.now();

          // print(
          //     "mw_send_state $_mw_count_accel_update *$sample_update == ${_mw_count_accel_update * sample_update} > $_mw_normal_state_update");
        }
      });
    }
  }

  Future<num> _startGyroscope() async {
    if (_gyroSubscription != null) return 0;
    if (_gyroAvailable) {
      final stream = await SensorManager().sensorUpdates(
        sensorId: Sensors.GYROSCOPE,
        interval: Duration(microseconds: sample_update),
      );
      _gyroSubscription = stream.listen((sensorEvent) {
        // setState(() {
        _gyroData = sensorEvent.data;
        // });
        abs_gyro = sqrt(
            pow(_gyroData[0], 2) + pow(_gyroData[1], 2) + pow(_gyroData[2], 2));
        // print(mw_raw_gyro.length);
        // if (abs_gyro > 40)
        // mw_event_sensor.add(abs_gyro);
        // print("abs_gyro ${abs_gyro}");
        _counter_gyro += 1;
        if (mw_raw_gyro.length >= 50) {
          // sample = 19;

          // print(mw_raw_gyro);
          mw_raw_gyro.removeAt(0);
          mw_raw_gyro.add(abs_sample(_counter_gyro, abs_gyro));
        } else
          mw_raw_gyro.add(abs_sample(_counter_gyro, abs_gyro));

        // if (abs_gyro > 12) _decrementCounter0();
      });
    }
    return abs_gyro;
  }

  void _stopGyroscope() {
    if (_gyroSubscription == null) return;
    _gyroSubscription?.cancel();
    _gyroSubscription = null;
  }

  void _stopAccelerometer() {
    if (_accelSubscription == null) return;
    _accelSubscription?.cancel();
    _accelSubscription = null;
  }

  void mw_start_fall_detection() {
    // print("mw_start_fall_detection");
    mw_send_state("Normal");

    _startAccelerometer();
    _startGyroscope();
  }

  void mw_check_fall_detction_state() {
    _checkAccelerometerStatus();
    _checkGyroscopeStatus();
  }

  void mw_drop_fall_detection() {
    _stopAccelerometer();
    _stopGyroscope();
  }

  void _checkAccelerometerStatus() async {
    await SensorManager()
        .isSensorAvailable(Sensors.ACCELEROMETER)
        .then((result) {
      // setState(() {
      _accelAvailable = result;
      // print("_checkAccelerometerStatus ${result}");

      // });
    });
  }

  void _checkGyroscopeStatus() async {
    await SensorManager().isSensorAvailable(Sensors.GYROSCOPE).then((result) {
      // setState(() {
      _gyroAvailable = result;
      // print("_checkAccelerometerStatus ${result}");
      // });
    });
  }

  mw_send_state(String state) async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    mw_event_sensor.add(mw_state(position, state, DateTime.now()));
  }
}

class abs_sample {
  abs_sample(this.sample, this.abs);

  final num abs;
  final num sample;
}

class mw_state {
  mw_state(this.location, this.state, this.timestamp);

  final Position location;
  final String state;
  final DateTime timestamp;
}
