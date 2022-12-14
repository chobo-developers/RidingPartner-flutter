import 'dart:async';

import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as google_map;
import 'package:latlong2/latlong.dart';
import 'package:ridingpartner_flutter/src/models/route.dart';
import 'package:ridingpartner_flutter/src/provider/riding_provider.dart';
import 'package:ridingpartner_flutter/src/service/naver_map_service.dart';
import 'package:ridingpartner_flutter/src/utils/user_location.dart';

import '../models/place.dart';
import '../models/position_stream.dart';

enum SearchRouteState { loading, fail, empty, success, locationFail }

class NavigationProvider with ChangeNotifier {
  final NaverMapService _naverMapService = NaverMapService();
  //make constructer with one Place type parameter
  NavigationProvider(this._ridingCourse);
  //make constructer without parameter
  NavigationProvider.empty();

  Position? _position;
  final Distance _calDistance = const Distance();
  RidingState _ridingState = RidingState.before;
  SearchRouteState _searchRouteState = SearchRouteState.loading;

  final PositionStream _positionStream = PositionStream();

  late List<Place> _ridingCourse;
  List<Guide> _route = [];
  List<int> _distances = [];
  List<google_map.LatLng> _polylinePoints = [];
  List<google_map.LatLng> get polylinePoints => _polylinePoints;

  late Guide _goalPoint;
  late Place _goalDestination;
  Guide? _nextPoint;
  Place? _nextDestination;
  late Place _finalDestination;
  Timer? _timer;
  int _remainedDistance = 0;
  int _totalDistance = 0;
  bool isFirst = true;
  bool visivility = false;

  LatLng? _bearingPoint;

  Guide get goalPoint => _goalPoint;
  Position? get position => _position;
  List<Guide>? get route => _route;
  RidingState get ridingState => _ridingState;
  SearchRouteState get searchRouteState => _searchRouteState;
  List<Place> get course => _ridingCourse;
  LatLng? get bearingPoint => _bearingPoint;
  int get remainedDistance => _remainedDistance;
  int get totalDistance => _totalDistance;
  Place? get nextDestination => _nextDestination;

  bool _disposed = false;

  void setState(RidingState state) {
    _ridingState = state;
    if (state == RidingState.pause) {
      _timer?.cancel();
    }
    notifyListeners();
  }

  void setVisivility() {
    visivility = !visivility;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _positionStream.dispose();
    super.dispose();
  }

  Future<void> getRoute() async {
    final myLocation = MyLocation();
    _goalDestination = _ridingCourse.first;
    _finalDestination = _ridingCourse.last;
    if (_ridingCourse.length > 1) {
      _nextDestination = _ridingCourse.elementAt(1);
    }
    isFirst = true;

    try {
      myLocation.getMyCurrentLocation();
      _position = myLocation.position;
    } catch (e) {
      print(e.toString());
      myLocation.checkPermission();
      _position = null;
      _searchRouteState = SearchRouteState.locationFail;
      notifyListeners();
      return;
    }

    Place startPlace = Place(
        id: null,
        title: "??? ??????",
        latitude: _position!.latitude.toString(),
        longitude: _position!.longitude.toString(),
        jibunAddress: null);

    if (_ridingCourse.length > 1) {
      num distanceToCourseStart = _calDistance.as(
          LengthUnit.Meter,
          LatLng(_position!.latitude, _position!.longitude),
          LatLng(double.parse(_ridingCourse.first.latitude!),
              double.parse(_ridingCourse.first.longitude!)));

      num distanceToCourseLast = _calDistance.as(
          LengthUnit.Meter,
          LatLng(_position!.latitude, _position!.longitude),
          LatLng(double.parse(_ridingCourse.last.latitude!),
              double.parse(_ridingCourse.last.longitude!)));

      // ??????????????? ???????????? ??? ???????????? ????????? ??????
      if (distanceToCourseLast < distanceToCourseStart) {
        _ridingCourse = List.from(_ridingCourse.reversed);
      }
    }

    Map<String, dynamic> response = await _naverMapService
        .getRoute(startPlace, _finalDestination, _ridingCourse)
        .catchError((onError) {
      return {'result': SearchRouteState.fail};
    });

    _searchRouteState = response['result'];

    if (_searchRouteState == SearchRouteState.success) {
      response = response['data'];

      _route = response['guides'];
      _remainedDistance = response['sumdistance'];
      if (_totalDistance < response['sumdistance']) {
        _totalDistance = response['sumdistance'];
      }
      _distances = response['distances'];

      if (_route.length == 1) {
        _goalPoint = _route[0];
        _nextPoint = null;
      } else {
        _goalPoint = _route[0];
        _nextPoint = _route[1];
      }
      _bearingPoint = latLngFromGuide(_goalPoint);
      // _route.forEach((element) {
      //   _remainedDistance += element.
      // })
      _polyline();
    } else {
      _route = [];
    }
    notifyListeners();
  }

  // Future<String> getMyLocationAddress(Position position) async {
  //   final url =
  //       "https://dapi.kakao.com/v2/local/geo/coord2address.json?x=$lon&y=$lat&input_coord=WGS84";
  //   Map<String, String> requestHeaders = {'Authorization': 'KakaoAK $kakaoKey'};
  //   final response = await http.get(Uri.parse(url), headers: requestHeaders);
  //   final address = json.decode(response.body)['documents'][0]['address']
  //           ['address_name'] ??
  //       '';
  //   developer.log(address);

  //   return address;
  // }

  Future<void> startNavigation() async {
    setState(RidingState.riding);
    _positionStream.controller.stream.listen((pos) {
      _position = pos;
    });

    _timer = Timer.periodic(Duration(seconds: 1), ((timer) {
      _calToPoint();
    }));
  }

  void _calToPoint() {
    LatLng? point = latLngFromGuide(_goalPoint);
    LatLng? nextLatLng = latLngFromGuide(_nextPoint);
    _bearingPoint = point;

    if (nextLatLng != null) {
      num distanceToPoint = _calDistance.as(LengthUnit.Meter,
          LatLng(_position!.latitude, _position!.longitude), point!);

      // ????????? ????????? ?????????
      num distanceToNextPoint = _calDistance.as(LengthUnit.Meter,
          LatLng(_position!.latitude, _position!.longitude), nextLatLng);

      num distancePointToPoint =
          _calDistance.as(LengthUnit.Meter, point, nextLatLng);

      if (distanceToPoint > distancePointToPoint + 10) {
        // 2??? ??????
        // c + am
        if (_nextDestination != null) {
          _calToDestination(); // ?????? ????????? ???????????? ?????? ?????? ???????????? ??? ???????????? ????????? ?????? ????????? ?????????????????? ??????
        }
        getRoute();
      } else {
        if (distanceToPoint <= 10 ||
            distanceToPoint > distanceToNextPoint + 50) {
          // ??? ????????? ??????????????? a > b??????
          _isDestination(); // ??????????????? ??????
          if (_route!.length == 2) {
            _route!.removeAt(0);
            _goalPoint = _route![0]; //
            _nextPoint = null;
            if (isFirst) {
              _polylinePoints.removeAt(0);
              isFirst = false;
            }
            _remainedDistance -= _distances.last;
            _distances.removeLast();
          } else {
            _route!.removeAt(0);
            _goalPoint = _route![0]; //
            _nextPoint = _route![1];
            if (isFirst) {
              isFirst = false;
            } else {
              _polylinePoints.removeAt(0);
            }
            _remainedDistance -= _distances.last;
            _distances.removeLast();
          }
        }
      }
    }
  }

  void _isDestination() {
    num distanceToDestination = _calDistance.as(
        LengthUnit.Meter,
        LatLng(_position!.latitude, _position!.longitude),
        LatLng(double.parse(_goalDestination.latitude!),
            double.parse(_goalDestination.longitude!)));

    if (distanceToDestination < 10) {
      if (_ridingCourse.length == 1) {
        // ?????? ????????? ??????!
      } else if (_ridingCourse.length == 2) {
        _ridingCourse.removeAt(0);
        _goalDestination = _ridingCourse[0];
        _nextDestination = null;
      } else {
        _ridingCourse.removeAt(0);
        _goalDestination = _ridingCourse[0];
        _nextDestination = _ridingCourse[1];
      }
    }
  }

  void _calToDestination() {
    num distanceToDestination = _calDistance.as(
        LengthUnit.Meter,
        LatLng(_position!.latitude, _position!.longitude),
        LatLng(double.parse(_goalDestination.latitude!),
            double.parse(_goalDestination.longitude!)));

    num distanceToNextDestination = _calDistance.as(
        LengthUnit.Meter,
        LatLng(_position!.latitude, _position!.longitude),
        LatLng(double.parse(_nextDestination!.latitude!),
            double.parse(_nextDestination!.longitude!)));

    if (distanceToDestination > distanceToNextDestination) {
      // ?????? ???????????? ????????????????
      // ok ->
      if (true) {
        _ridingCourse.removeAt(0);
      }
    }
  }

  void stopNavigation() {
    setState(RidingState.pause);
    _timer?.cancel();
  }

  void _polyline() {
    List<PolylineWayPoint>? turnPoints = _route
        ?.map((route) => PolylineWayPoint(location: route.turnPoint ?? ""))
        .toList();
    List<google_map.LatLng> pointLatLngs = [];

    turnPoints?.forEach((element) {
      List<String> a = element.location.split(',');
      pointLatLngs
          .add(google_map.LatLng(double.parse(a[1]), double.parse(a[0])));
    });

    _polylinePoints = pointLatLngs;
    if (_disposed) return;
    notifyListeners();
  }

  LatLng? latLngFromGuide(Guide? guide) {
    if (guide != null) {
      List<double>? a =
          (guide.turnPoint?.split(','))?.map((p) => double.parse(p)).toList();
      if (a == null) {
        return null;
      } else {
        return LatLng(a.elementAt(1), a.elementAt(0));
      }
    } else {
      return null;
    }
  }
}
