import 'dart:math';

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:vector_math/vector_math.dart';

const double EARTH_RADIUS_METERS = 6378137;

class AHRSFusion {
  late Vector3 velocity;
  late Vector3 location;

  late Quaternion orientation;

  Position? startingPosition;

  double distance = 0;
  double bearingDifference = 0;
  bool isAnomaly = false;

  AHRSFusion(){
    velocity = Vector3.zero();
    location = Vector3.zero();
    orientation = Quaternion.identity();
  }

  void init(Position position){
    velocity = initVelocity(position);
    location = Vector3.zero();
    orientation = Quaternion.identity();
    startingPosition = position;
  }

  Vector3 initVelocity(Position position){
    double headingRadians = radians(position.heading);
    velocity = Vector3(position.speed * cos(headingRadians), position.speed * sin(headingRadians), 0);
    return velocity;
  }

  void updateLocation(Vector3 userAccelerometerVector, double timeDelta){
    if (orientation == Quaternion.identity()){
      return;
    }
    Vector3 globalAcceleration = orientation.rotate(userAccelerometerVector); // acceleration in global coordinates
    velocity += globalAcceleration * timeDelta; // velocity
    location += velocity * timeDelta; // location
  }

  void initOrientation(Vector3 magnetometerVector){
    magnetometerVector.normalize();
    double azimuth = atan2(magnetometerVector.y, magnetometerVector.x);
    double azimuthDegrees = degrees(azimuth); // conversion to degrees
    if (azimuthDegrees < 0) {
      azimuthDegrees += 360;
    }
    orientation = Quaternion.axisAngle(Vector3(0, 0, 1), radians(azimuthDegrees));
  }

  void updateOrientation(Vector3 gyroscopeVector, double timeDelta){
    if (orientation == Quaternion.identity()){
      return;
    }
    Quaternion gyroQuaternion = Quaternion.axisAngle(
        gyroscopeVector.normalized(),
        gyroscopeVector.length * timeDelta
    );
    orientation = (orientation * gyroQuaternion).normalized(); // rotation
  }

  LatLng iterate(Position position){
    if (startingPosition == null){
      init(position);
      return LatLng(position.latitude, position.longitude);
    }
    double predictedLatitude = radians(startingPosition!.latitude) + location.y / EARTH_RADIUS_METERS;
    double predictedLongitude = radians(startingPosition!.longitude) + location.x / (EARTH_RADIUS_METERS * cos(radians(position.latitude)));

    LatLng predictedPosition = LatLng(degrees(predictedLatitude), degrees(predictedLongitude));

    isAnomaly = checkAnomaly(position, predictedPosition);

    // Update the orientation and location for next iteration.
    init(position);

    return predictedPosition;
  }

  bool checkAnomaly(Position newMeasuredPosition, LatLng predictedPosition){
    double maxDistanceVariation = velocity.length;
    if (maxDistanceVariation < 1) maxDistanceVariation = 1;
    if (maxDistanceVariation > 10) maxDistanceVariation = 10;
    print('maxDistanceVariation: $maxDistanceVariation');

    distance = Geolocator.distanceBetween(
        newMeasuredPosition.latitude, newMeasuredPosition.longitude,
        predictedPosition.latitude, predictedPosition.longitude
    );
    double bearingNewMeasuredPosition = Geolocator.bearingBetween(
        startingPosition!.latitude, startingPosition!.longitude,
        newMeasuredPosition.latitude, newMeasuredPosition.longitude
    );
    double bearingPredictedPosition = Geolocator.bearingBetween(
        startingPosition!.latitude, startingPosition!.longitude,
        predictedPosition.latitude, predictedPosition.longitude
    );
    bearingDifference = (bearingNewMeasuredPosition - bearingPredictedPosition).abs();
    print('Distance: $distance, Bearing difference: $bearingDifference');
    if ((distance > maxDistanceVariation && bearingDifference > 90) ||
        (distance > (maxDistanceVariation + 5) && bearingDifference > 20) ||
        (distance > (maxDistanceVariation + 10))){
      print('Anomaly detected!');
      return true;
    }
    return false;
  }
}
