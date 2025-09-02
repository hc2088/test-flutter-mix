import 'dart:convert';
import 'dart:io';

import 'package:flutter_study/city_data/province.dart';

Future<void> main() async {
  // 读取国家 JSON
  final countryJson = await File('country_code.json').readAsString();
  final List<dynamic> countryList = json.decode(countryJson);

  List<Map<String, dynamic>> result = [];

  for (var country in countryList) {
    String cnName = country['cn'];
    String enName = country['en'];

    if (cnName == '中国') {
      // 中国特殊处理
      List<Map<String, dynamic>> provinces = [];

      provincesData.forEach((provinceCode, provinceName) {
        List<Map<String, dynamic>> cities = [];

        var provinceCities = citiesData[provinceCode] ?? {};
        provinceCities.forEach((cityCode, cityVal) {
          List<Map<String, dynamic>> areas = [];
          var areaData = citiesData[cityCode];
          if (areaData != null) {
            areaData.forEach((areaCode, areaVal) {
              areas.add({'name': areaVal['name']});
            });
          }
          if (areas.isNotEmpty) {
            cities.add({'name': cityVal['name'], 'children': areas});
          } else {
            cities.add({'name': cityVal['name']});
          }
        });

        if (cities.isNotEmpty) {
          provinces.add({'name': provinceName, 'children': cities});
        } else {
          provinces.add({'name': provinceName});
        }
      });

      result.add({'name': cnName, 'children': provinces});
    } else {
      // 非中国国家直接一级
      result.add({'name': cnName});
    }
  }

  // 写入 JSON 文件
  final output = File('countries_full.json');
  await output.writeAsString(JsonEncoder.withIndent('  ').convert(result));
  print('已生成 countries_full.json');
}
