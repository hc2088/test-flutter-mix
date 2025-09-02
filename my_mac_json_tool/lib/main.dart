import 'dart:convert';
import 'dart:io';

import 'package:my_mac_json_tool/province.dart';
import 'package:path/path.dart' as p;

Future<void> main() async {
  // 获取当前脚本目录
  final currentDir = Directory.current.path;

  // 读取国家列表
  final countryFile = File(p.join(currentDir, 'country_code.json'));

  if (!await countryFile.exists()) {
    print('country_code.json 不存在，请放在项目根目录');
    return;
  }

  final countryJson = await countryFile.readAsString();
  final List<dynamic> countryList = json.decode(countryJson);

  List<Map<String, dynamic>> result = [];

  for (var country in countryList) {
    String cnName = country['cn'];
    String enName = country['en'];
    String? phoneCode = country['code'];
    String? alpha = country['alpha'];

    if (cnName == '中国') {
      List<Map<String, dynamic>> provinces = [];

      provincesData.forEach((provinceCode, provinceName) {
        var provinceCities = citiesData[provinceCode] ?? {};
        List<Map<String, dynamic>> cities = [];

        // 如果该省份只有一个城市，则直接平铺区县
        if (provinceCities.length == 1) {
          String onlyCityCode = provinceCities.keys.first;
          var areaData = citiesData[onlyCityCode] ?? {};

          List<Map<String, dynamic>> areas = [];
          areaData.forEach((areaCode, areaVal) {
            areas.add({
              'name': areaVal['name'],
              'postalCode': areaCode,
            });
          });

          provinces.add({
            'name': provinceName,
            'postalCode': provinceCode,
            if (areas.isNotEmpty) 'children': areas,
          });
        } else {
          // 多城市正常处理：省 -> 市 -> 区
          provinceCities.forEach((cityCode, cityVal) {
            List<Map<String, dynamic>> areas = [];
            var areaData = citiesData[cityCode];
            if (areaData != null) {
              areaData.forEach((areaCode, areaVal) {
                areas.add({
                  'name': areaVal['name'],
                  'postalCode': areaCode,
                });
              });
            }
            cities.add({
              'name': cityVal['name'],
              'postalCode': cityCode,
              if (areas.isNotEmpty) 'children': areas,
            });
          });

          provinces.add({
            'name': provinceName,
            'postalCode': provinceCode,
            if (cities.isNotEmpty) 'children': cities,
          });
        }
      });

      result.add({
        'name': cnName,
        'en': enName,
        if (alpha != null) 'alpha': alpha,
        if (phoneCode != null) 'code': phoneCode,
        'children': provinces,
      });
    } else {
      result.add({
        'name': cnName,
        'en': enName,
        if (alpha != null) 'alpha': alpha,
        if (phoneCode != null) 'code': phoneCode,
      });
    }
  }

  final output = File(p.join(currentDir, 'countries_full.json'));
  await output.writeAsString(JsonEncoder.withIndent('  ').convert(result));
  print('已生成 countries_full.json -> ${output.path}');
}
