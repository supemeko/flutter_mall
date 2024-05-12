import 'dart:math';

import 'package:flutter_mall/widgets/postal_picker/table/tables.dart';

import '../table/table_postal.dart';

/// 页面数据
class Page {
  /// 存放着所有邮递区域相关的数据
  final Tables tables;

  /// 最多几级规划。【省市县乡，则4级；如果已经确定省份，选择市县乡，则3级；】
  final int numberOfTabs;

  /// 最高级别
  int get maxLevel {
    return numberOfTabs + 1;
  }

  /// 第n级选择的邮递区域对应的子集合区域【0：根目录下的选项，1：广东省下的选项，2：深圳市下的选项，3：福田区下的选项，4:福田街道下面的选项(无法选择)】
  List<List<Postal>> activityList = [];

  /// 第n级选择的邮递区域【0：根节点，1：广东省，2：深圳市，3：福田区，4：福田街道】
  List<Postal> selectiveList = [];

  /// 提交页面的回调函数 callback(this)
  void Function(Page page) callback;

  Page(
      {required this.tables,
      required this.numberOfTabs,
      required this.callback}) {
    for (int i = 0; i < maxLevel + 1; i++) {
      selectiveList.add(emptyPostal);
      activityList.add([]);
    }
  }

  /// 选择某个邮递区域，并查找该邮递区域的子节点
  bool pick(Postal postal) {
    // 获取右边区域对应的lvl(tabIndex);
    final node = tables.getNodeByPostalCode(postal.postalCode);
    assert(node.isNotEmpty);
    final lvl = node.lvl;

    // 清空之后的tab，并设置对应的tab；
    final selected = selectiveList[lvl];
    if (selected != postal) {
      for (int i = lvl; i < maxLevel + 1; i++) {
        selectiveList[i] = emptyPostal;
        activityList[i] = [];
      }
      selectiveList[lvl] = postal;
      activityList[lvl] = tables.getPostalListByPostalCode(postal.postalCode);
    }

    // 检查前面的tab，如果不符合则改成正确的tab
    var jNode = node;
    for (int j = lvl - 1; j >= 0; j--) {
      jNode = tables.getFatherNode(jNode);
      if (jNode.isEmpty) {
        break;
      }
      if (jNode.postalCode == selectiveList[j].postalCode) {
        break;
      }
      selectiveList[j] = tables.getPostalByPostalCode(jNode.postalCode)!;
      activityList[j] = tables.getPostalListByPostalCode(jNode.postalCode);
    }
    return activityList[lvl].isEmpty;
  }

  /// 可选tab的数量
  int get numberOfTabsIfOptional {
    final tmp = selectiveList.lastIndexWhere((element) => element.isNotEmpty);
    if (tmp < 0) {
      //没有选择任何节点时，选择根节点并返回可选Tab数为1
      pick(rootPostal);
      return 1;
    }
    if (activityList[tmp].isEmpty) {
      return tmp;
    }
    return min(tmp + 1, numberOfTabs);
  }

  /// 获取所有tab的标题
  Iterable<(int, String)> get tabTitles {
    return List.generate(
        numberOfTabsIfOptional,
        (index) => (
              index,
              selectiveList[index + 1].isNotEmpty
                  ? selectiveList[index + 1].name
                  : "请选择"
            ));
  }

  /// 获取所有tab的已选项和备选列表
  Iterable<(int, Postal, List<Postal>)> get tabOptions {
    return List.generate(numberOfTabsIfOptional,
        (index) => (index, selectiveList[index + 1], activityList[index]));
  }
}
