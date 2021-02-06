import 'dart:async';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:insta_clone/data_models/location.dart';

class LocationManager {
  Future<Location> getCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low);
    final placeMarks = await Geolocator.
    final placeMark = placeMarks.first;

    return Future.value(convert(placeMark));
  }

  Future<Location> updateLocation(double latitude, double longitude) async {
    final placeMarks = await Geolocator().placemarkFromCoordinates(latitude, longitude);
    final placeMark = placeMarks.first;
    return Future.value(convert(placeMark));
  }

  Location convert(Placemark placeMark) {
    return Location(
        latitude: placeMark.position.latitude,
        longitude: placeMark.position.longitude,
        country: placeMark.country,
        state: placeMark.administrativeArea,
        city: placeMark.locality);
  }
}
