import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:tmail_ui_user/features/caching/config/hive_cache_config.dart';
import 'package:tmail_ui_user/main/bindings/main_bindings.dart';
import 'package:tmail_ui_user/main/localizations/app_localizations.dart';
import 'package:tmail_ui_user/main/localizations/app_localizations_delegate.dart';
import 'package:tmail_ui_user/main/localizations/localization_service.dart';
import 'package:tmail_ui_user/main/pages/app_pages.dart';
import 'package:tmail_ui_user/main/routes/app_routes.dart';
import 'package:tmail_ui_user/main/utils/app_utils.dart';
import 'package:worker_manager/worker_manager.dart';

void main() async {
  initLogger(() async {
    WidgetsFlutterBinding.ensureInitialized();
    ThemeUtils.setSystemLightUIStyle();
    await MainBindings().dependencies();
    await HiveCacheConfig().setUp();
    await HiveCacheConfig.initializeEncryptionKey();
    await Executor().warmUp();
    await AppUtils.loadEnvFile();
    runApp(const TMailApp());
  });
}

class TMailApp extends StatelessWidget {
  const TMailApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeUtils.appTheme,
      supportedLocales: LocalizationService.supportedLocales,
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (deviceLocale, supportedLocales) {
        for (var locale in supportedLocales) {
          if (locale.languageCode == deviceLocale?.languageCode) {
            return deviceLocale;
          }
        }
        return supportedLocales.first;
      },
      locale: LocalizationService.locale,
      fallbackLocale: LocalizationService.fallbackLocale,
      translations: LocalizationService(),
      onGenerateTitle: (context) {
        if (Get.currentRoute == AppRoutes.unknownRoutePage) {
          return AppLocalizations.of(context).page404;
        } else {
          return AppLocalizations.of(context).page_name;
        }
      },
      unknownRoute: AppPages.unknownRoutePage,
      defaultTransition: Transition.fade,
      initialRoute: AppRoutes.home,
      getPages: AppPages.pages);
  }
}