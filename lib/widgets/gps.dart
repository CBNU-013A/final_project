// widgets/gps.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; //위도 경도 가져옴
import 'package:geocoding/geocoding.dart';
import 'package:final_project/styles/styles.dart';

class CurrentAddressWidget extends StatefulWidget {
  const CurrentAddressWidget({super.key});

  @override
  State<CurrentAddressWidget> createState() => _CurrentAddressWidgetState();
}

class _CurrentAddressWidgetState extends State<CurrentAddressWidget> {
  String? _currentAddress;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentAddress();
  }

  Future<void> _loadCurrentAddress() async {
    try {
      Position position = await _getCurrentLocation();

      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;

        setState(() {
          _currentAddress =
              '${place.street}, ${place.locality}, ${place.administrativeArea} ${place.country}';
          _isLoading = false;
        });
      } else {
        setState(() {
          _currentAddress = '주소 정보를 찾을 수 없습니다.';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("❗ 오류 발생: $e");
      setState(() {
        _currentAddress = '위치 정보를 가져올 수 없습니다.';
        _isLoading = false;
      });
    }
  }

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('위치 서비스 비활성화');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('위치 권한 거부됨');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('위치 권한 영구 거부됨');
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.grey));
    } else {
      debugPrint(_currentAddress);
      return Text(
        _currentAddress ?? '주소 없음',
        style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.marineBlue),
        textAlign: TextAlign.center,
      );
    }
  }
}
