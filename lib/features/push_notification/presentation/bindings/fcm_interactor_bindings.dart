import 'package:get/get.dart';
import 'package:tmail_ui_user/features/base/interactors_bindings.dart';
import 'package:tmail_ui_user/features/push_notification/data/datasource/fcm_datasource.dart';
import 'package:tmail_ui_user/features/push_notification/data/datasource_impl/hive_fcm_datasource_impl.dart';
import 'package:tmail_ui_user/features/push_notification/data/local/fcm_cache_manager.dart';
import 'package:tmail_ui_user/features/push_notification/data/repository/fcm_repository_impl.dart';
import 'package:tmail_ui_user/features/push_notification/domain/repository/fcm_repository.dart';
import 'package:tmail_ui_user/features/push_notification/domain/usecases/delete_fcm_token_cache_interactor.dart';
import 'package:tmail_ui_user/features/push_notification/domain/usecases/get_fcm_token_cache_interactor.dart';
import 'package:tmail_ui_user/features/push_notification/domain/usecases/save_fcm_token_cache_interactor.dart';
import 'package:tmail_ui_user/main/exceptions/cache_exception_thrower.dart';

class FcmInteractorBindings extends InteractorsBindings {

  @override
  void bindingsDataSource() {
    Get.put<FCMDatasource>(Get.find<HiveFCMDatasourceImpl>());
  }

  @override
  void bindingsDataSourceImpl() {
    Get.put(HiveFCMDatasourceImpl(
      Get.find<FCMCacheManager>(),
      Get.find<CacheExceptionThrower>(),
    ));
  }

  @override
  void bindingsInteractor() {
    Get.put(DeleteFCMTokenCacheInteractor(Get.find<FCMRepositoryImpl>()));
    Get.put(SaveFCMTokenCacheInteractor(Get.find<FCMRepositoryImpl>()));
    Get.put(GetFCMTokenCacheInteractor(Get.find<FCMRepositoryImpl>()));
  }

  @override
  void bindingsRepository() {
    Get.put<FCMRepository>(Get.find<FCMRepositoryImpl>());
  }

  @override
  void bindingsRepositoryImpl() {
    Get.put(FCMRepositoryImpl(Get.find<FCMDatasource>()));
  }
}