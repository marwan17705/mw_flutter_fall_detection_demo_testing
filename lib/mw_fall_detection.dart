import 'dart:async';
import 'package:geolocator/geolocator.dart';

import 'package:flutter_sensors/flutter_sensors.dart';
import 'dart:math';

/**
 * state 00 : normal update
 * state 06 : fall alarm
 */

class mw_fall_detection {
  int _sample_update;
  StreamSubscription? _accelSubscription;
  StreamSubscription? _gyroSubscription;
  bool _accelAvailable = false;
  bool _gyroAvailable = false;
  List<double> _accelData = List.filled(3, 0.0);
  List<double> _gyroData = List.filled(3, 0.0);
  num _abs_gyro = 0;
  num _abs_accel = 0;

  DateTime? _mw_start_fall;
  bool mw_is_fall = false;
  int _mw_normal_state_update = 3600;
  DateTime _mw_count_accel_update = DateTime.now();
  final _mwFallUpper = 30;
  final _mwGyroUpper = 15;
  final int _mwPeriodFall = 2000; //m

  StreamController<mw_state> mw_event_sensor = StreamController<mw_state>();

  /// _sample_update: frequency to scan sensor (microsecond).
  /// _mw_count_accel_update: frequency to update (second).
  mw_fall_detection(this._sample_update, this._mw_normal_state_update) {
    _sample_update = this._sample_update;
    _mw_normal_state_update = this._mw_normal_state_update;
  }

  Future<void> _startAccelerometer() async {
    if (_accelSubscription != null) return;
    if (_accelAvailable) {
      final stream = await SensorManager().sensorUpdates(
        sensorId: Sensors.ACCELEROMETER,
        // interval: Sensors.SENSOR_DELAY_FASTEST,
        interval: Duration(microseconds: _sample_update),
      );
      _accelSubscription = stream.listen((sensorEvent) async {
        String _status_check = "00";
        // print("_accelData");

        // setState(() {
        _accelData = sensorEvent.data;
        // });

        // num
        _abs_accel = sqrt(pow(_accelData[0], 2) +
            pow(_accelData[1], 2) +
            pow(_accelData[2], 2));
        // print("_abs_accel ${_abs_accel}");

        // mw_event_sensor.add(0);
        // _mw_send_state("00");

        if (_abs_accel > _mwFallUpper) {
          if (_abs_gyro > _mwGyroUpper) mw_is_fall = true;
          _mw_start_fall = DateTime.now();

          // print(_mw_start_fall?.second);
        } else {
          if (mw_is_fall) {
            mw_is_fall = false;
            DateTime? new_date =
                _mw_start_fall?.add(Duration(milliseconds: _mwPeriodFall));
            DateTime? current_date = DateTime.now();

            int? new_ = new_date?.millisecondsSinceEpoch;
            int? current_ = current_date.millisecondsSinceEpoch;
            if (new_ != null) if (current_ < new_) {
              // print("fall detect");
              _status_check = "06";
              await _mw_send_state(_status_check);
              // mw_event_sensor.add(mw_state(position,"waring"));
            }
          }
        }
        // print(
        //     "_mw_send_state $_mw_count_accel_update *$_sample_update == ${_mw_count_accel_update * _sample_update / 1000000} > $_mw_normal_state_update");

        if ((_mw_count_accel_update.difference(DateTime.now()).inSeconds)
                .abs() >=
            _mw_normal_state_update) {
          // await
          _mw_send_state(_status_check);
          // print((_mw_count_accel_update.difference(DateTime.now()).inSeconds)
          //     .abs());
          _mw_count_accel_update = DateTime.now();

          // print(
          //     "_mw_send_state $_mw_count_accel_update *$_sample_update == ${_mw_count_accel_update * _sample_update} > $_mw_normal_state_update");
        }
      });
    }
  }

  Future<num> _startGyroscope() async {
    if (_gyroSubscription != null) return 0;
    if (_gyroAvailable) {
      final stream = await SensorManager().sensorUpdates(
        sensorId: Sensors.GYROSCOPE,
        interval: Duration(microseconds: _sample_update),
      );
      _gyroSubscription = stream.listen((sensorEvent) {
        // setState(() {
        _gyroData = sensorEvent.data;
        // });
        _abs_gyro = sqrt(
            pow(_gyroData[0], 2) + pow(_gyroData[1], 2) + pow(_gyroData[2], 2));
      });
    }
    return _abs_gyro;
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
    _mw_send_state("00");
    _startAccelerometer();
    _startGyroscope();
  }

  void mw_check_fall_detction_state() {
    _checkAccelerometerStatus();
    _checkGyroscopeStatus();
  }

  void mw_stop_fall_detection() {
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

  _mw_send_state(String state) async {
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
