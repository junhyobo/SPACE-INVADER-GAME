import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';
import 'assets.dart';
import 'services/bgm_service.dart';
import 'services/sfx_service.dart';
import 'services/storage_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.I.init();

  // >>> ÁP GIÁ TRỊ ĐÃ LƯU CHO AUDIO NGAY KHI BOOT
  BgmService.I.setVolume(StorageService.I.getMusicVolumeSync());
  SfxService.I.setVolume(StorageService.I.getMusicVolumeSync());
  // <<<

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return  MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: Assets.uiFontFamily, 
        ),
      home: SplashScreen(),
    );
  }
}
