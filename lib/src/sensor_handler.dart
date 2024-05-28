import 'package:sensors_plus/sensors_plus.dart';
import 'package:vector_math/vector_math.dart';

import 'ahrs_fusion.dart';
import 'sensor_data.dart';

class SensorHandler {
  Stream<UserAccelerometerEvent> uaes = userAccelerometerEventStream();
  Stream<AccelerometerEvent> aes = accelerometerEventStream();
  Stream<GyroscopeEvent> ges = gyroscopeEventStream();
  Stream<MagnetometerEvent> mes = magnetometerEventStream();

  AHRSFusion ahrsFusion = AHRSFusion();

  SensorData? sensorData = SensorData(
  userAccelerometer: Vector3(0, 0, 0),
  accelerometer: Vector3(0, 0, 0),
  gyroscope: Vector3(0, 0, 0),
  magnetometer: Vector3(0, 0, 0),
  );

  double lastTimestampAccelerometer = 0.0;
  double lastTimestampGyroscope = 0.0;

  SensorHandler() {
    // Listen to sensor data

    uaes.listen((UserAccelerometerEvent event) {
      double currentTime = DateTime.now().millisecondsSinceEpoch.toDouble() / 1000.0; // Convert to seconds
      if (lastTimestampAccelerometer == 0.0) {
        lastTimestampAccelerometer = currentTime;
        return;
      }
      double timeDelta = currentTime - lastTimestampAccelerometer;
      lastTimestampAccelerometer = currentTime;

      sensorData!.userAccelerometer = Vector3(event.x, event.y, event.z);
      ahrsFusion.updateLocation(sensorData!.userAccelerometer!, timeDelta);
    });

    aes.listen((AccelerometerEvent event) {
      sensorData!.accelerometer = Vector3(event.x, event.y, event.z);
    });

    ges.listen((GyroscopeEvent event) {
      double currentTime = DateTime.now().millisecondsSinceEpoch.toDouble() / 1000.0; // Convert to seconds
      if (lastTimestampGyroscope == 0.0) {
        lastTimestampGyroscope = currentTime;
        return;
      }
      double timeDelta = currentTime - lastTimestampGyroscope;
      lastTimestampGyroscope = currentTime;

      sensorData!.gyroscope = Vector3(event.x, event.y, event.z);
      ahrsFusion.updateOrientation(sensorData!.gyroscope!, timeDelta);
    });

    mes.listen((MagnetometerEvent event) {
      sensorData!.magnetometer = Vector3(event.x, event.y, event.z);
      ahrsFusion.initOrientation(sensorData!.magnetometer!);
    });
  }

  void dispose(){
    uaes.drain();
    aes.drain();
    ges.drain();
    mes.drain();
  }
}
