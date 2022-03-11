import 'package:latlng/latlng.dart';

class MapPickerAddressComponent {
  final String? shortName;
  final String? name;

  const MapPickerAddressComponent({this.shortName, this.name});
}

class MapPickerAddress {
  final String? formattedAddress;
  final LatLng? latLng;
  final MapPickerAddressComponent? country;
  final MapPickerAddressComponent? city;
  final MapPickerAddressComponent? administrativeAreaLevel1;
  final MapPickerAddressComponent? administrativeAreaLevel2;
  final MapPickerAddressComponent? subLocalityLevel1;
  final MapPickerAddressComponent? subLocalityLevel2;
  final MapPickerAddressComponent? postalCode;
  final String? placeId;

  String? get locality => city?.name;

  MapPickerAddress({
    this.formattedAddress,
    this.latLng,
    this.country,
    this.city,
    this.administrativeAreaLevel1,
    this.administrativeAreaLevel2,
    this.subLocalityLevel1,
    this.subLocalityLevel2,
    this.postalCode,
    this.placeId,
  });
}
