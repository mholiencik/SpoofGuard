import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class KalmanFilter {
  final double minAccuracy = 1.0;
  late int q; // process noise - uncertainty of the model in m/s
  late double lat;
  late double lng;
  late double lastTimestamp; // in milliseconds
  late double variance; // for P matrix, object uninitialised: negative

  KalmanFilter(){
    variance = -1;
  }

  void SetState(Position position){
    lat = position.latitude;
    lng = position.longitude;
    lastTimestamp = position.timestamp.millisecondsSinceEpoch.toDouble();
    variance = position.accuracy * position.accuracy;
  }

  LatLng process(Position position){
    double accuracy = position.accuracy;
    if (accuracy < minAccuracy){
      accuracy = minAccuracy;
    }

    if (variance < 0) { // initialize
      SetState(position);
    } else { //apply filter
      double currentTimestamp = position.timestamp.millisecondsSinceEpoch.toDouble();
      double timeDelta = currentTimestamp - lastTimestamp;
      if (timeDelta > 0){
        lastTimestamp = currentTimestamp;
        variance += timeDelta * q * q / 1000;
      }

      // Kalman gain matrix K = Covarariance * Inverse(Covariance + MeasurementVariance)
      double K = variance / (variance + accuracy * accuracy);
      // apply K for position
      lat += K * (position.latitude - lat);
      lng += K * (position.longitude - lng);
      // new Covarariance  matrix is (IdentityMatrix - K) * Covarariance
      variance = (1 - K) * variance;
    }
    q = position.speed.round();
    return LatLng(lat, lng);
  }
}
