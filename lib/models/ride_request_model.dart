import 'package:firebase_database/firebase_database.dart';

class RideRequest {
  String? rideRequestId;
  String? userId;
  String? userName;
  String? userPhone;
  String? pickupAddress;
  double? pickupLatitude;
  double? pickupLongitude;
  String? destinationAddress;
  double? destinationLatitude;
  double? destinationLongitude;
  String? vehicleType;
  double? fare;
  double? distance;
  double? duration;
  String? status; // waiting, accepted, arrived, started, completed, cancelled
  String? driverId;
  String? driverName;
  String? driverPhone;
  String? vehicleModel;
  String? vehicleNumber;
  int? requestTime;

  RideRequest({
    this.rideRequestId,
    this.userId,
    this.userName,
    this.userPhone,
    this.pickupAddress,
    this.pickupLatitude,
    this.pickupLongitude,
    this.destinationAddress,
    this.destinationLatitude,
    this.destinationLongitude,
    this.vehicleType,
    this.fare,
    this.distance,
    this.duration,
    this.status,
    this.driverId,
    this.driverName,
    this.driverPhone,
    this.vehicleModel,
    this.vehicleNumber,
    this.requestTime,
  });

  // Convert to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'pickupAddress': pickupAddress,
      'pickupLatitude': pickupLatitude,
      'pickupLongitude': pickupLongitude,
      'destinationAddress': destinationAddress,
      'destinationLatitude': destinationLatitude,
      'destinationLongitude': destinationLongitude,
      'vehicleType': vehicleType,
      'fare': fare,
      'distance': distance,
      'duration': duration,
      'status': status ?? 'waiting',
      'driverId': driverId,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'vehicleModel': vehicleModel,
      'vehicleNumber': vehicleNumber,
      'requestTime': requestTime ?? DateTime.now().millisecondsSinceEpoch,
    };
  }

  // Create from Firebase snapshot
  RideRequest.fromSnapshot(DataSnapshot snapshot) {
    rideRequestId = snapshot.key;
    var data = snapshot.value as Map<dynamic, dynamic>;
    userId = data['userId'];
    userName = data['userName'];
    userPhone = data['userPhone'];
    pickupAddress = data['pickupAddress'];
    pickupLatitude = data['pickupLatitude']?.toDouble();
    pickupLongitude = data['pickupLongitude']?.toDouble();
    destinationAddress = data['destinationAddress'];
    destinationLatitude = data['destinationLatitude']?.toDouble();
    destinationLongitude = data['destinationLongitude']?.toDouble();
    vehicleType = data['vehicleType'];
    fare = data['fare']?.toDouble();
    distance = data['distance']?.toDouble();
    duration = data['duration']?.toDouble();
    status = data['status'];
    driverId = data['driverId'];
    driverName = data['driverName'];
    driverPhone = data['driverPhone'];
    vehicleModel = data['vehicleModel'];
    vehicleNumber = data['vehicleNumber'];
    requestTime = data['requestTime'];
  }
}