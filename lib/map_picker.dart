import 'package:cached_network_image/cached_network_image.dart';
import 'package:map_picker_flutter/map_picker_address.dart';
import 'package:map_picker_flutter/map_picker_map_type.dart';
import 'map_picker_controller.dart';
import 'package:map/map.dart';
import 'map_picker_theme.dart';

export 'package:latlng/latlng.dart';
export 'map_picker_template.dart';
export 'map_picker_address.dart';
export 'map_picker_theme.dart';

import 'package:flutter/material.dart';

class MapPicker extends StatelessWidget {
  /// Global theme
  static late MapPickerTheme _gTheme;

  /// Global searchBuilder Widget
  static Widget Function(Function(String address) search)? _searchBuilder;

  /// Global addressBuilder Widget
  static Widget Function(String address, Function done)? _addressBuilder;

  /// Global progressDialog Widget
  static Widget? _progressWidget;

  /// Global marker widget
  static Widget? _markerWidget;

  /// Google Maps API KEY
  static late String _key;

  /// # It need be called before you use this lib passing the theme and the Google Maps API KEY
  static init({
    Widget Function(Function(String address) search)? searchBuilder,
    Widget Function(String address, Function done)? addressBuilder,
    Widget? progressWidget,
    Widget? marker,
    required MapPickerTheme theme,
    required String key,
  }) {
    MapPicker._addressBuilder = addressBuilder;
    MapPicker._progressWidget = progressWidget;
    MapPicker._searchBuilder = searchBuilder;
    MapPicker._markerWidget = marker;
    MapPicker._gTheme = theme;
    MapPicker._key = key;
  }

  /// Same of global variables but here case you want change in a specific called
  final Widget Function(Function(String address) search)? searchBuilder;
  final Widget Function(String address, Function done)? addressBuilder;
  final MapPickerController controller;
  final Widget? progressWidget;
  final MapPickerTheme theme;
  final Widget? marker;
  final MapPickerMapType mapType;

  factory MapPicker({
    /// Custom search Builder Widget, case it is null, will be used the global or default
    Widget Function(Function(String address) search)? searchBuilder,

    /// Custom address Builder Widget, case it is null, will be used the global or default
    Widget Function(String address, Function done)? addressBuilder,

    /// Custom progress Widget, case it is null, will be used the global or default
    Widget? progressWidget,

    /// Custom theme, case it is null, will be used the global or default
    MapPickerTheme? theme,

    /// Custom Marker, case it is null, will be used the global or default
    Widget? marker,

    /// Map tile type, defaults to roadmap
    MapPickerMapType mapType = MapPickerMapType.roadmap,

    /// Zoom level to apply when focusing on a specific location, for example after an address has been selected
    double? zoomOnGoTo,
  }) =>
      MapPicker._internal(
        progressWidget:
            progressWidget ?? _progressWidget ?? CircularProgressIndicator(),
        addressBuilder: addressBuilder ?? _addressBuilder,
        searchBuilder: searchBuilder ?? _searchBuilder,
        marker: marker ?? _markerWidget,
        controller: MapPickerController(
          theme: theme ?? _gTheme,
          key: _key,
          mapController: MapController(
            location: theme?.initialLocation ?? _gTheme.initialLocation,
            zoom: theme?.zoom ?? _gTheme.zoom,
          ),
          zoomOnGoTo: zoomOnGoTo,
        ),
        theme: theme ?? _gTheme,
        mapType: mapType,
      );

  MapPicker._internal({
    this.marker,
    this.searchBuilder,
    this.addressBuilder,
    this.progressWidget,
    required this.controller,
    required this.theme,
    required this.mapType,
  });

  dispose() => controller.dispose();

  Future pop(context) async {
    Navigator.pop(context, controller.popAddress);
    dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: Listener(
              onPointerSignal: controller.onPointerSignal,
              child: GestureDetector(
                onScaleEnd: (details) => controller.getAddressByLatLng(),
                onScaleUpdate: controller.onScaleUpdate,
                onScaleStart: controller.onScaleStart,
                onDoubleTap: controller.onDoubleTap,
                child: Map(
                  controller: controller.mapController,
                  builder: (context, x, y, z) {
                    final url =
                        'https://mt1.google.com/vt/lyrs=${mapType.tileCode}@129&x=$x&y=$y&z=$z';

                    return CachedNetworkImage(
                        errorWidget: (c, w, s) => CircularProgressIndicator(),
                        fit: BoxFit.contain,
                        imageUrl: url);
                  },
                ),
              ),
            ),
          ),
          Center(
            child: marker ??
                Image.asset(
                  'assets/ic_location.png',
                  package: 'map_picker_flutter',
                  height: 50,
                  width: 50,
                ),
          ),
          Positioned(
            right: 0,
            left: 0,
            top: 0,
            child: searchBuilder != null
                ? searchBuilder!(controller.getAddressByAddress)
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                          ),
                          margin: EdgeInsets.all(20),
                          child: Container(
                            margin: EdgeInsets.symmetric(horizontal: 15),
                            width: width * .4 - 40,
                            padding:
                                EdgeInsets.only(bottom: 5, right: 15, left: 15),
                            child: TextField(
                              controller: controller.searchControl,
                              decoration: InputDecoration(
                                labelText: theme.searchLabel,
                                hintText: theme.searchHint,
                                prefixIcon: IconButton(
                                  icon: Icon(Icons.arrow_back_outlined),
                                  onPressed: () => Navigator.pop(context),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(Icons.search),
                                  onPressed: () =>
                                      controller.getAddressByAddress(
                                    controller.searchControl.text,
                                  ),
                                ),
                              ),
                              onSubmitted: controller.getAddressByAddress,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            left: 0,
            child: StreamBuilder<bool>(
              stream: controller.outStreamProgress,
              initialData: true,
              builder: (c, s) => (s.data ?? true)
                  ? (progressWidget ??
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                              margin: EdgeInsets.only(bottom: 15),
                              child: CircularProgressIndicator())
                        ],
                      ))
                  : StreamBuilder<MapPickerAddress?>(
                      stream: controller.outStreamAddress,
                      builder: (c, ad) => (addressBuilder != null
                          ? addressBuilder!(
                              ad.data?.formattedAddress ?? theme.noAddress,
                              dispose,
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Card(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    margin: EdgeInsets.all(15),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 25, vertical: 10),
                                      alignment: Alignment.center,
                                      width: width * .4 - 40,
                                      child: Text(
                                        ad.data?.formattedAddress ??
                                            theme.noAddress,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
