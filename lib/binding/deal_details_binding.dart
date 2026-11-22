import 'package:get/get.dart';
import 'package:rescu/model/deal_model.dart';

import '../feature/deal/deal_details_controller.dart';

class DealDetailsBinding extends Bindings {

  static String? get controllerTag {
    return Get.parameters["id"] ?? (Get.arguments is DealModel ? (Get.arguments as DealModel).id.toString() : null);
  }

  @override
  void dependencies() {

    Get.lazyPut(
      () => DealDetailsController(
        dealRepo: Get.find(),
        cartService: Get.find(),
        analytics: Get.find(),
      ),
      tag: controllerTag,
    );
  }
}
