import 'dart:developer';

import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart';
import 'package:mca_project/data/models/shop_model/shop_model1.dart';

import '../utils/exceptions/custom_exception.dart';

class GeoLocatorService {
  static Future<Position?> getcurrentPosition() async {
    LocationPermission permission;
    final bool locationServiceEnabled =
        await Geolocator.isLocationServiceEnabled();
    if (!locationServiceEnabled) {
      // return Future.error('Location Services are Disabled');
      throw CustomException(
        message: "Location Services are Disabled",
        errorType: ErrorType.locationServicesDisabled,
      );
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time we could try
        // return Future.error('Location permission are denied');
        throw CustomException(
          message: "Please Allow location permission",
          errorType: ErrorType.locationpermissionDenied,
        );
      }
    }
    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever
      // return Future.error('Location permission are permanently denied');
      throw CustomException(
        message: "Location permissions were denied !!",
        errorType: ErrorType.locationPermissionDeniedPermanently,
      );
    }
    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.

    return await Geolocator.getCurrentPosition(
        forceAndroidLocationManager: true,
        desiredAccuracy: LocationAccuracy.bestForNavigation);
  }

  static Future<LocationInfo> fetchLocationInfo(
      String? userEnteredLocation) async {
    try {
      late List<geocoding.Placemark> _placemarks;
      late double _latitude;
      late double _longtitude;
      if (userEnteredLocation == null) {
        //position from current location
        final position = await GeoLocatorService.getcurrentPosition();
        if (position == null) {
          throw CustomException(
            errorType: ErrorType.unknown,
            message: 'Something went wrong!,Please try agian',
          );
        }
        _placemarks = await geocoding.placemarkFromCoordinates(
            position.latitude, position.longitude);
        _latitude = position.latitude;
        _longtitude = position.longitude;
      } else {
//positon from the user entered address
        List<geocoding.Location> locations =
            await geocoding.locationFromAddress(userEnteredLocation);
        //to do: later pass all the location to the function
        //placemarkFromCoordinates to get all the placemarks
        //and let user choose the one he wants
        _placemarks = await geocoding.placemarkFromCoordinates(
            locations[0].latitude, locations[0].longitude);
        _longtitude = locations[0].longitude;
        _latitude = locations[0].latitude;
      }

      final shortAddress =

          // ${_placemarks[0].name},
          '${_placemarks[0].street},${_placemarks[0].locality},${_placemarks[0].postalCode} ${_placemarks[0].country}';
      return LocationInfo(
          completeAddress:
              '${_placemarks[0].name}, ${_placemarks[0].street}, ${_placemarks[0].subLocality}, ${_placemarks[0].locality}, ${_placemarks[0].administrativeArea}, ${_placemarks[0].postalCode}, ${_placemarks[0].country}',
          shortAddress: shortAddress,
          latitude: _latitude,
          longtitude: _longtitude);
    } on geocoding.NoResultFoundException {
      throw CustomException(
        errorType: ErrorType.noLocationFound,
        message: 'No Location Found',
      );
    } catch (e) {
      rethrow;
    }
  }
}
