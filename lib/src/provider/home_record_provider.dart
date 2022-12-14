import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ridingpartner_flutter/src/models/record.dart';
import 'package:ridingpartner_flutter/src/models/route.dart';
import 'package:ridingpartner_flutter/src/pages/home_page.dart';
import 'package:ridingpartner_flutter/src/service/firebase_database_service.dart';
import 'package:ridingpartner_flutter/src/service/firestore_service.dart';

import '../models/place.dart';
import '../service/shared_preference.dart';

enum RecordState { loading, fail, none, success, empty }

class HomeRecordProvider extends ChangeNotifier {
  final FirebaseDatabaseService _firebaseDatabaseService =
      FirebaseDatabaseService();
  final FireStoreService _fireStoreService = FireStoreService();
  final _random = Random();

  final String _auth = FirebaseAuth.instance.currentUser!.displayName!;
  int _selectedIndex = 13;
  List<String> _daysFor14 = [];
  List<Record> _recordFor14Days = [];
  final int _recordLength = 14;
  Record? _prefRecord;
  int _count = 0;
  Place? _recommendPlace;
  Place? _recommendPlace2;

  List<Record> get recordFor14Days => _recordFor14Days;
  List<String> get daysFor14 => _daysFor14;
  int get selectedIndex => _selectedIndex;
  String get name => _auth;
  Place? get recommendPlace => _recommendPlace;
  Place? get recommendPlace2 => _recommendPlace2;

  RecordState _recordState = RecordState.loading;
  RecordState get recordState => _recordState;

  void setIndex(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  getData() {
    getRecomendPlace();
    getRecord();
  }

  getRecomendPlace() async {
    List<Place> places = await _fireStoreService.getPlaces();
    _recommendPlace = places[_random.nextInt(places.length)];
    _recommendPlace2 = places[_random.nextInt(places.length)];

    while (_recommendPlace == _recommendPlace2) {
      _recommendPlace2 = places[_random.nextInt(places.length)];
    }
  }

  Future getRecord() async {
    setList();
    setDate();

    Map<String, dynamic> result =
        await _firebaseDatabaseService.getAllRecords();
    _recordState = result['state'];

    if (_recordState == RecordState.success) {
      List<Record> data = result['data'];
      if (_prefRecord != data.last && _prefRecord != null) {
        // ????????? ????????? ????????? ?????? ?????? (ex. ???????????? ??????)
        saveRecord(_prefRecord!);
        data.add(_prefRecord!);
      }
      get14daysRecord(data);

      notifyListeners();
    }

    notifyListeners();
  }

  void setList() {
    _recordFor14Days = [];
    for (int i = 0; i < 14; i++) {
      _recordFor14Days.add(Record());
    }
  }

  void setDate() {
    _daysFor14 = [];
    DateTime today = DateTime.now();
    for (int i = 0; i < _recordLength; i++) {
      DateTime currentDay = today.subtract(Duration(days: i));
      String day = dayToDayString(currentDay.day);
      String weekday = weekdayIntToString(currentDay.weekday);
      if (i == 0) {
        _daysFor14.add("??????, $day $weekday");
      } else {
        _daysFor14.add("$day $weekday");
      }
    }
    _daysFor14 = _daysFor14.reversed.toList();
  }

  void get14daysRecord(List<Record> records) {
    DateTime today = DateTime.now();

    for (var element in records) {
      int days = int.parse(
          today.difference(DateTime.parse(element.date!)).inDays.toString());
      if (days < _recordLength) {
        _count++;
        // 14??? ???????????? ??? ????????? ??????
        _recordFor14Days[days] = element;
        // 30, 31, 1, 2, 3 ~ ?????? ?????? ?????? ?????? ????????? ???????????? ?????? map??? ????????? ?????? ??????
        // ????????? ????????????, ????????? Map??????
      }
      if (_count == 0) {
        _recordState = RecordState.empty;
      }
    }
    _recordFor14Days = _recordFor14Days.reversed.toList();
  }

  String dayToDayString(int day) {
    if (day < 10) {
      return "0$day";
    }
    return day.toString();
  }

  String weekdayIntToString(int code) {
    switch (code) {
      case 1:
        return "???";
      case 2:
        return "???";
      case 3:
        return "???";
      case 4:
        return "???";
      case 5:
        return "???";
      case 6:
        return "???";
      case 7:
        return "???";
      default:
        return "";
    }
  }

  void saveRecord(Record record) {
    _firebaseDatabaseService.saveRecordFirebaseDb(record);
  }
}
