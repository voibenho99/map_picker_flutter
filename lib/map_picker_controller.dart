import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:latlng/latlng.dart';
import 'package:map/map.dart';
import 'package:dio/dio.dart';
import 'map_picker_address.dart';
import 'map_picker_theme.dart';
import 'dart:core' as c;
import 'dart:core';

class MapPickerController with _Base {
  /// # Urls to get geocode infos
  static const _URL_ADDRESS =
      'https://maps.googleapis.com/maps/api/geocode/json?address=[ADDRESS]';
  static const _URL_LAT_LNG =
      'https://maps.googleapis.com/maps/api/geocode/json?latlng=[LAT],[LON]';

  final _progress = BehaviorSubject<bool>.seeded(false);
  final _address = BehaviorSubject<MapPickerAddress?>();
  final MapController mapController;
  final MapPickerTheme theme;
  final String key;
  final double? zoomOnGoTo;

  final searchControl = TextEditingController();

  Stream<MapPickerAddress?> get outStreamAddress => _address.stream;
  Stream<bool> get outStreamProgress => _progress.stream;
  double _scaleStart = 1.0;
  c.bool _hasError = false;
  Offset? _dragStart;

  String get currentAddress => _address.value?.formattedAddress ?? '-';
  MapPickerAddress? get popAddress => _hasError ? null : _address.value;

  MapPickerController({
    required this.key,
    required this.theme,
    required this.mapController,
    this.zoomOnGoTo,
  });

  /// Go To place with latLng
  goTo(LatLng? latLng) {
    if (latLng != null) {
      mapController.center = latLng;
      if (zoomOnGoTo != null) {
        mapController.zoom = zoomOnGoTo!;
      }
    }
  }

  /// Go To initial place again
  goToInitial() => goTo(theme.initialLocation);

  /// Zoom on double tap
  onDoubleTap() => mapController.zoom += 0.5;

  /// On Star Change Scale
  onScaleStart(ScaleStartDetails details) {
    _dragStart = details.focalPoint;
    _scaleStart = 1.0;
  }

  /// On Change Scale
  onScaleUpdate(ScaleUpdateDetails details) {
    final scaleDiff = details.scale - _scaleStart;
    _scaleStart = details.scale;

    if (scaleDiff > 0) {
      mapController.zoom += 0.02;
    } else if (scaleDiff < 0) {
      mapController.zoom -= 0.02;
    } else {
      final now = details.focalPoint;
      final diff = now - (_dragStart ?? Offset(0, 0));
      _dragStart = now;
      mapController.drag(diff.dx, diff.dy);
    }
  }

  /// Here is for web and desktop, when wheel scrolling of mouse, it will apply or remove zoom
  onPointerSignal(PointerSignalEvent e) {
    if (e is PointerScrollEvent) {
      final sl = e.scrollDelta.dy;

      if (sl > 0) {
        // to down
        if (mapController.zoom > 3) {
          mapController.zoom -= 0.5;
        }
      } else {
        // to up
        if (mapController.zoom <= 20.5) {
          mapController.zoom += 0.5;
        }
      }
    }
  }

  String _replaceIt({
    required String text,
    required c.Map<String, String> remove,
  }) =>
      remove.keys.fold<String>(
        text,
        (text, element) => text.replaceAll(element, remove[element] ?? ''),
      );

  String _getExtraArgs() =>
      (theme.lang != null ? '&language=${theme.lang}' : '') + '&key=$key';

  /// # Get address by LatLnt
  getAddressByLatLng() async {
    final position = mapController.center;
    _progress.sink.add(true);

    try {
      final resp = await Dio().get(
        _replaceIt(
          text: _URL_LAT_LNG + _getExtraArgs(),
          remove: {
            '[LAT]': position.latitude.toString(),
            '[LON]': position.longitude.toString()
          },
        ),
      );

      final addr = _extractAddressFromResponse(resp);
      if (addr != null) {
        _address.sink.add(addr);
      }
    } catch (msg) {
      _address.sink.add(
        MapPickerAddress(
          formattedAddress: theme.errorAddressNotFound,
          latLng: position,
        ),
      );
      _hasError = true;
    }

    _progress.sink.add(false);
  }

  /// # Get address by text
  getAddressByAddress(String address) async {
    _progress.sink.add(true);

    try {
      final resp = await Dio().get(
        _replaceIt(
          text: _URL_ADDRESS + _getExtraArgs(),
          remove: {
            '[ADDRESS]': address.toString(),
          },
        ),
      );

      final addr = _extractAddressFromResponse(resp);
      goTo(addr?.latLng);
      if (addr != null) {
        _address.sink.add(addr);
      }
    } catch (msg) {
      _address.sink.add(
        MapPickerAddress(
          formattedAddress: theme.errorAddressNotFound,
        ),
      );
      _hasError = true;
    }

    _progress.sink.add(false);
  }

  MapPickerAddress? _extractAddressFromResponse(Response resp) {
    if (resp.data == null ||
        resp.data['status'] != 'OK' ||
        resp.data['results'] == null ||
        (resp.data['results'] as List).isEmpty) {
      return null;
    }

    final result = (resp.data['results'] as List).first!;

    final location = result['geometry']['location'];
    final latLng = LatLng(location['lat'], location['lng']);
    final formattedAddress = result['formatted_address']?.toString();
    final placeId = result['place_id']?.toString();

    MapPickerAddressComponent? country,
        city,
        postalCode,
        administrativeAreaLevel1,
        administrativeAreaLevel2,
        subLocalityLevel1,
        subLocalityLevel2;

    if (result['address_components'] is List<dynamic> &&
        result['address_components'].length != null &&
        result['address_components'].length > 0) {
      for (var i = 0; i < result['address_components'].length; i++) {
        var tmp = result['address_components'][i];
        var types = tmp['types'] as List<dynamic>?;
        var shortName = tmp['short_name'];
        var longName = tmp['long_name'];
        if (types == null) {
          continue;
        }

        if (types.contains('sublocality_level_1')) {
          subLocalityLevel1 = MapPickerAddressComponent(
            shortName: shortName,
            name: longName,
          );
        }
        if (types.contains('sublocality_level_2')) {
          subLocalityLevel2 = MapPickerAddressComponent(
            shortName: shortName,
            name: longName,
          );
        }
        if (types.contains('locality')) {
          city = MapPickerAddressComponent(
            shortName: shortName,
            name: longName,
          );
        }
        if (types.contains('administrative_area_level_2')) {
          administrativeAreaLevel2 = MapPickerAddressComponent(
            shortName: shortName,
            name: longName,
          );
        }
        if (types.contains('administrative_area_level_1')) {
          administrativeAreaLevel1 = MapPickerAddressComponent(
            shortName: shortName,
            name: longName,
          );
        }
        if (types.contains('country')) {
          country = MapPickerAddressComponent(
            shortName: shortName,
            name: longName,
          );
        }
        if (types.contains('postal_code')) {
          postalCode = MapPickerAddressComponent(
            shortName: shortName,
            name: longName,
          );
        }
      }
    }

    return MapPickerAddress(
      formattedAddress: formattedAddress,
      latLng: latLng,
      country: country,
      city: city,
      administrativeAreaLevel1: administrativeAreaLevel1,
      administrativeAreaLevel2: administrativeAreaLevel2,
      subLocalityLevel1: subLocalityLevel1,
      subLocalityLevel2: subLocalityLevel2,
      postalCode: postalCode,
      placeId: placeId,
    );
  }

  /*String _extractAddress(Response resp) {
    final emptyAddress = theme.errorAddressMissing;

    try {
      if (resp.data != null && resp.data['status'] == 'OK') {
        final address = resp.data['results'];

        if ((address as List).length > 0) {
          try {
            _hasError = false;
            return address[0]['formatted_address'].toString();
          } catch (msg) {
            _hasError = true;
            return emptyAddress;
          }
        }
      }

      _hasError = true;
      return emptyAddress;
    } catch (msg) {
      _hasError = true;
      return theme.errorAddressNotFound;
    }
  }*/

  /*LatLng? _extractLatLng(Response resp) {
    try {
      if (resp.data != null && resp.data['status'] == 'OK') {
        final address = resp.data['results'];

        if ((address as List).length > 0) {
          final lg = address[0]['geometry']['location'];
          return LatLng(lg['lat'], lg['lng']);
        }
      }
    } catch (msg) {}

    return null;
  }*/

  @override
  void dispose() {
    _address.close();
    _progress.close();
  }
}

abstract class _Base {
  void dispose();
}
