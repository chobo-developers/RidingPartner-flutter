import 'dart:ffi';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:provider/provider.dart';
import 'package:ridingpartner_flutter/src/provider/bottom_navigation_provider.dart';
import 'package:ridingpartner_flutter/src/provider/home_record_provider.dart';
import 'package:ridingpartner_flutter/src/utils/permission_camera.dart';
import 'package:ridingpartner_flutter/src/utils/timestampToText.dart';

import '../models/record.dart';
import '../provider/riding_result_provider.dart';
import '../provider/weather_provider.dart';
import 'home_page.dart';

class RecordPage extends StatefulWidget {
  RecordPage({super.key});

  @override
  _RecordState createState() => _RecordState();
}

class _RecordState extends State<RecordPage> {
  late RidingResultProvider _recordProvider;

  File? _image;

  // 이미지를 보여주는 위젯
  Widget showImage() {
    if (_recordProvider.imageStatus == ImageStatus.init) {
      return const Text(
        "이미지를\n선택해주세요.",
        style: TextStyle(
          fontSize: 14.0,
          color: Color.fromARGB(0xFF, 0xDE, 0xE2, 0xE6),
        ),
        textAlign: TextAlign.center,
      );
    } else if (_recordProvider.imageStatus == ImageStatus.imageSuccess) {
      return Container(
          color: Colors.transparent,
          width: 64.0,
          height: 64.0,
          child: Center(
              child: _image == null
                  ? const Text(
                      '이미지 없음',
                      style: TextStyle(
                        fontSize: 13.0,
                        color: Color.fromARGB(0xFF, 0xDE, 0xE2, 0xE6),
                      ),
                      textAlign: TextAlign.center,
                    )
                  : Image.file(File(_image!.path))));
    } else {
      return const Text(
        "업로드 실패",
        style: TextStyle(
          fontSize: 13.0,
          color: Color.fromARGB(0xFF, 0xDE, 0xE2, 0xE6),
        ),
        textAlign: TextAlign.center,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Record _record = Record();
    num _speed = 0;

    _recordProvider = Provider.of<RidingResultProvider>(context);

    final imageStatus = _recordProvider.imageStatus;

    if (_recordProvider.recordState == RecordState.loading) {
      _recordProvider.getRidingData();
    }

    if (_recordProvider.recordState == RecordState.success) {
      _record = _recordProvider.record;
      if (_record.distance != null) {
        _speed = _record.distance as num;
        _speed = _speed / 3 * 3600;
      }
    }

    _record.distance ??= 0.0;
    DateTime today = DateTime.now();
    DateFormat format = DateFormat('yyyy년 MM월 dd일');
    String formattedDate = format.format(today);
    int hKcal = 401;

    return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(0xFF, 0xEE, 0x75, 0x00),
          elevation: 0.0,
        ),
        resizeToAvoidBottomInset: false,
        body: Container(
            padding:
                const EdgeInsets.only(left: 34, bottom: 40, top: 10, right: 34),
            decoration: const BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                  Color.fromARGB(0xFF, 0xEE, 0x75, 0x00),
                  Color.fromARGB(0xFF, 0xFF, 0xA0, 0x44)
                ])),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                const Text(
                  "즐거운 라이딩\n되셨나요?",
                  style: TextStyle(
                      color: Color.fromARGB(255, 255, 255, 255),
                      fontSize: 40.0,
                      fontFamily: "Pretendard",
                      fontWeight: FontWeight.w700),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 15.0),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 100.0,
                        height: 120.0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text(
                              "날짜",
                              style: TextStyle(
                                  fontSize: 16.0,
                                  fontFamily: "Pretendard",
                                  fontWeight: FontWeight.w500,
                                  color:
                                      Color.fromARGB(0xFF, 0xDE, 0xE2, 0xE6)),
                            ),
                            Text(
                              "주행 시간",
                              style: TextStyle(
                                  fontSize: 16.0,
                                  fontFamily: "Pretendard",
                                  fontWeight: FontWeight.w500,
                                  color:
                                      Color.fromARGB(0xFF, 0xDE, 0xE2, 0xE6)),
                            ),
                            Text(
                              "평균 속도",
                              style: TextStyle(
                                  fontSize: 16.0,
                                  fontFamily: "Pretendard",
                                  fontWeight: FontWeight.w500,
                                  color:
                                      Color.fromARGB(0xFF, 0xDE, 0xE2, 0xE6)),
                            ),
                            Text(
                              "주행 총 거리",
                              style: TextStyle(
                                  fontSize: 16.0,
                                  fontFamily: "Pretendard",
                                  fontWeight: FontWeight.w500,
                                  color:
                                      Color.fromARGB(0xFF, 0xDE, 0xE2, 0xE6)),
                            ),
                            Text(
                              "소모 칼로리",
                              style: TextStyle(
                                  fontSize: 16.0,
                                  fontFamily: "Pretendard",
                                  fontWeight: FontWeight.w500,
                                  color:
                                      Color.fromARGB(0xFF, 0xDE, 0xE2, 0xE6)),
                            )
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 120.0,
                        width: 130.0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Text(
                              formattedDate,
                              style: const TextStyle(
                                fontFamily: "Pretendard",
                                fontWeight: FontWeight.w500,
                                fontSize: 16.0,
                                color: Color.fromARGB(0xFF, 0xDE, 0xE2, 0xE6),
                              ),
                            ),
                            Text(
                              timestampToText(_record.timestamp!),
                              style: const TextStyle(
                                  fontSize: 16.0,
                                  fontFamily: "Pretendard",
                                  fontWeight: FontWeight.w500,
                                  color:
                                      Color.fromARGB(0xFF, 0xDE, 0xE2, 0xE6)),
                            ),
                            Text(
                              "${_record.distance! / _record.timestamp!} km/h",
                              style: const TextStyle(
                                  fontSize: 16.0,
                                  fontFamily: "Pretendard",
                                  fontWeight: FontWeight.w500,
                                  color:
                                      Color.fromARGB(0xFF, 0xDE, 0xE2, 0xE6)),
                            ),
                            Text(
                              "${_record.distance! / 1000} km",
                              style: const TextStyle(
                                  fontSize: 16.0,
                                  fontFamily: "Pretendard",
                                  fontWeight: FontWeight.w500,
                                  color:
                                      Color.fromARGB(0xFF, 0xDE, 0xE2, 0xE6)),
                            ),
                            Text(
                              "${(hKcal * (_record.timestamp!) / 4000).toStringAsFixed(1)} kcal",
                              style: const TextStyle(
                                  fontSize: 16.0,
                                  fontFamily: "Pretendard",
                                  fontWeight: FontWeight.w500,
                                  color:
                                      Color.fromARGB(0xFF, 0xDE, 0xE2, 0xE6)),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Container(
                        width: 64.0,
                        height: 64.0,
                        margin: const EdgeInsets.only(right: 20.0),
                        child: OutlinedButton(
                            onPressed: () {
                              if (imageStatus == ImageStatus.init) {
                                _recordProvider.confirmPermissionGranted();
                              }
                              if (imageStatus ==
                                  ImageStatus.permissionSuccess) {
                                _recordProvider.getImage(ImageSource.gallery);
                              } else if (imageStatus ==
                                  ImageStatus.permissionFail) {}
                            },
                            style: ButtonStyle(
                              side: MaterialStateProperty.all(const BorderSide(
                                color: Color.fromARGB(0xFF, 0xFD, 0xD3, 0xAB),
                                width: 2.0,
                              )),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Image(
                                  image:
                                      AssetImage('assets/icons/add_image.png'),
                                  color: Color.fromARGB(255, 255, 255, 255),
                                ),
                                Text(
                                  "사진",
                                  style: TextStyle(
                                      color: Color.fromARGB(
                                          0xFF, 0xDE, 0xE2, 0xE6),
                                      fontSize: 12.0),
                                )
                              ],
                            ))),
                    SizedBox(width: 64.0, height: 64.0, child: showImage())
                  ],
                ),
                const Divider(color: Color.fromARGB(0xFF, 0xF8, 0xF9, 0xFA)),
                Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(17),
                      color: Color.fromRGBO(255, 255, 255, 0.3)),
                  child: TextField(
                      style: TextStyle(
                        fontSize: 14.0,
                        color: Colors.black,
                      ),
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.all(16),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        hintText: "오늘의 라이딩은 어땠나요?",
                        hintStyle: TextStyle(
                          color: Colors.white,
                          fontSize: 14.0,
                        ),
                      )),
                ),
                SizedBox(
                  width: double.infinity,
                  height: 56.0,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    style: ButtonStyle(
                      shadowColor:
                          MaterialStateProperty.all<Color>(Colors.transparent),
                      padding: MaterialStateProperty.all<EdgeInsets>(
                          const EdgeInsets.all(13.0)),
                      backgroundColor: MaterialStateProperty.all<Color>(
                          const Color.fromARGB(0xFF, 0xFF, 0xFF, 0xFF)),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25.0),
                      )),
                    ),
                    child: const Text(
                      "기록 저장하기",
                      style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.w700,
                          color: Color.fromARGB(0xFF, 0xF0, 0x78, 0x05)),
                    ),
                  ),
                )
              ],
            )));
  }
}
