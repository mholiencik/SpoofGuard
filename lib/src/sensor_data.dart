import 'package:vector_math/vector_math.dart';


class SensorData {
  late Vector3? userAccelerometer;
  late Vector3? accelerometer;
  late Vector3? gyroscope;
  late Vector3? magnetometer;

  SensorData({
    required this.userAccelerometer,
    required this.accelerometer,
    required this.gyroscope,
    required this.magnetometer,
  });

  void resetSensorData(){
    userAccelerometer = Vector3(0, 0, 0);
    accelerometer = Vector3(0, 0, 0);
    gyroscope = Vector3(0, 0, 0);
    magnetometer = Vector3(0, 0, 0);
  }
}