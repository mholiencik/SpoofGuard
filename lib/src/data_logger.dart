import 'dart:io';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';

import 'sensor_data.dart';

class DataLogger {
  late String filePath;

  int numberOfAnomalies = 0;
  late List<double> distances = List.empty(growable: true);
  late List<double> bearingDifferences = List.empty(growable: true);

  DataLogger(){
    initFilePath();
  }

  dispose() {
    String string = '\n';
    string += '~Number of anomalies: ${numberOfAnomalies.toString()}\n';
    string += '~Bearing differences: ${bearingDifferences.toString()}\n';
    string += '~Distances: ${distances.toString()}\n';
    string += '~Average distance: ${distances.reduce((a, b) => a + b) / distances.length} \n\n';
    saveToFile(string);
  }

  Future<void> initFilePath() async {
    Directory directory = await getApplicationDocumentsDirectory();

    var formatter = DateFormat('yyyy-MM-dd_HH-mm-ss');
    String filename = 'sensor_data_${formatter.format(DateTime.now())}.txt';
    filePath = '${directory.path}/data/$filename';
    print(filePath);
    File file = File(filePath);
    await file.create(recursive: true);
    saveToFile('|         Timestamp          |       Location       |     AHRSLocation     |      User Accelerometer     |        Accelerometer        |          Gyroscope          |         Magnetometer        |\n'
               '| yyyy-MM-dd HH-mm-ss.SSSSSS | latitude | longitude | latitude | longitude |    X    |    Y    |    Z    |    X    |    Y    |    Z    |    X    |    Y    |    Z    |    X    |    Y    |    Z    |\n');
  }

  void logSensorData(DateTime timeStamp, SensorData sensorData, LatLng location, LatLng predictedLocation, double distance, double bearingDifference ,bool isAnomaly){
    if (isAnomaly) {
      numberOfAnomalies++;
    }
    distances.add(distance);
    bearingDifferences.add(bearingDifference);

    String string = '| ';
    string += ('${timeStamp.toString().padLeft(23, ' ')} |');
    string += ('${location.latitude >= 0 ? '+' : ''}${location.latitude.toStringAsFixed(5).padLeft(8, '0')} |');
    string += ('${location.longitude >= 0 ? '+' : ''}${location.longitude.toStringAsFixed(5).padLeft(9, '0')} |');
    string += ('${predictedLocation.latitude >= 0 ? '+' : ''}${predictedLocation.latitude.toStringAsFixed(5).padLeft(8, '0')} |');
    string += ('${predictedLocation.longitude >= 0 ? '+' : ''}${predictedLocation.longitude.toStringAsFixed(5).padLeft(9, '0')} |');
    string += ('${sensorData.userAccelerometer!.x >= 0 ? '+' : ''}${sensorData.userAccelerometer!.x.toStringAsFixed(3).padLeft(7, '0')} |');
    string += ('${sensorData.userAccelerometer!.y >= 0 ? '+' : ''}${sensorData.userAccelerometer!.y.toStringAsFixed(3).padLeft(7, '0')} |');
    string += ('${sensorData.userAccelerometer!.z >= 0 ? '+' : ''}${sensorData.userAccelerometer!.z.toStringAsFixed(3).padLeft(7, '0')} |');
    string += ('${sensorData.accelerometer!.x >= 0 ? '+' : ''}${sensorData.accelerometer!.x.toStringAsFixed(3).padLeft(7, '0')} |');
    string += ('${sensorData.accelerometer!.y >= 0 ? '+' : ''}${sensorData.accelerometer!.y.toStringAsFixed(3).padLeft(7, '0')} |');
    string += ('${sensorData.accelerometer!.z >= 0 ? '+' : ''}${sensorData.accelerometer!.z.toStringAsFixed(3).padLeft(7, '0')} |');
    string += ('${sensorData.gyroscope!.x >= 0 ? '+' : ''}${sensorData.gyroscope!.x.toStringAsFixed(3).padLeft(7, '0')} |');
    string += ('${sensorData.gyroscope!.y >= 0 ? '+' : ''}${sensorData.gyroscope!.y.toStringAsFixed(3).padLeft(7, '0')} |');
    string += ('${sensorData.gyroscope!.z >= 0 ? '+' : ''}${sensorData.gyroscope!.z.toStringAsFixed(3).padLeft(7, '0')} |');
    string += ('${sensorData.magnetometer!.x >= 0 ? '+' : ''}${sensorData.magnetometer!.x.toStringAsFixed(3).padLeft(7, '0')} |');
    string += ('${sensorData.magnetometer!.y >= 0 ? '+' : ''}${sensorData.magnetometer!.y.toStringAsFixed(3).padLeft(7, '0')} |');
    string += ('${sensorData.magnetometer!.z >= 0 ? '+' : ''}${sensorData.magnetometer!.z.toStringAsFixed(3).padLeft(7, '0')} |');
    string += ('\n');

    saveToFile(string);
  }

  void saveToFile(String string) async {
    try {
      final file = File(filePath);
      var sink = file.openWrite(mode: FileMode.append);
      sink.write(string);
      print('Data saved to file $filePath');
      print(string);
      sink.close();
    } catch (e) {
      print('Error: $e');
    }
  }
}
