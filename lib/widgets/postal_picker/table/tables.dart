import 'dart:collection';

import 'package:flutter_mall/widgets/postal_picker/meta/static_data.dart';

import 'table_node.dart';
import 'table_postal.dart';

/// 相关表
class Tables {
  /// 节点表 & id索引
  /// 应该将其视为`Node[]`, 并且`Node[]`附带一个`id`索引
  Map<int, Node> nodes = {};

  /// 邮递区域表 & 邮递区域邮递区号索引
  /// 应该将其视为`Postal[]`, 并且`Postal[]`附带一个`postalCode`索引
  Map<String, Postal> postalList = {};

  /// `Node[]`的`postalCode`索引
  final Map<String, Node> postalCodeNodesIndex = {};

  Tables();

  /// 获取邮递区域在表中的节点
  Node getNodeByPostalCode(String postalCode) {
    return postalCodeNodesIndex[postalCode] ?? emptyNode;
  }

  /// 获取邮递区域的子区域列表
  List<Postal> getPostalListByPostalCode(String postalCode) {
    final res = <Postal>[];
    final node = getNodeByPostalCode(postalCode);
    if (node == emptyNode) {
      return res;
    }
    for (final elem in nodes.values) {
      if (elem.prevId == node.id) {
        res.add(postalList[elem.postalCode]!);
      }
    }
    return res;
  }

  /// 获取邮递区号对应的邮递区域
  Postal? getPostalByPostalCode(String postalCode) {
    return postalList[postalCode];
  }

  /// 上一个node
  Node getFatherNode(Node node) {
    return nodes.values.firstWhere((element) => element.id == node.prevId);
  }

  /// lookup一个地址出来
  Postal? _lookup(String text) {
    (int, Postal)? maxLvlPostal;
    for (final postal in postalList.values) {
      if (text.contains(postal.name)) {
        var node = getNodeByPostalCode(postal.postalCode);
        maxLvlPostal ??= (node.lvl, postal);
        if (maxLvlPostal.$1 < node.lvl) {
          maxLvlPostal = (node.lvl, postal);
        }
      }
    }
    return maxLvlPostal?.$2;
  }

  List<Postal>? lookupTree(String text) {
    Postal? p = _lookup(text);
    if (p == null) {
      return null;
    }
    Node current = getNodeByPostalCode(p.postalCode);
    if (current.isEmpty && current == rootNode) {
      return null;
    }
    var res = [getPostalByPostalCode(current.postalCode)!];
    while (true) {
      current = getFatherNode(current);
      if (current.isEmpty || current == rootNode) {
        break;
      }
      res.add(getPostalByPostalCode(current.postalCode)!);
    }
    return res.reversed.toList();
  }
}

/// 返回静态数据作为Tables
Tables defaultTables() {
  final Tables tables = Tables();
  tables.nodes[-2] = rootNode;
  tables.postalList[rootNode.postalCode] = rootPostal;
  tables.postalCodeNodesIndex[rootNode.postalCode] = rootNode;
  provincesData.forEach((key, value) {
    final id = int.parse(key);
    final node = Node(id, rootNode.id, 1, key);
    final postal = Postal(postalCode: key, name: value, firstLetter: 'a');

    tables.nodes[node.id] = node;
    tables.postalList[node.postalCode] = postal;
    tables.postalCodeNodesIndex[node.postalCode] = node;
  });

  final data =
      Queue.from(citiesData.entries.map((e) => (e.key, e.value)).toList());
  while (data.isNotEmpty) {
    final elem = data.removeFirst();
    if (elem == null) {
      break;
    }
    final (firstKey, secondList) = elem;
    final up = tables.postalCodeNodesIndex[firstKey];
    if (up == null) {
      //放回末尾去
      data.addLast(elem);
      continue;
    }

    for (final entry in secondList.entries) {
      final secondKey = entry.key;
      final secondValue = entry.value;
      final id = int.parse(secondKey);
      final node = Node(id, up.id, up.lvl + 1, secondKey);
      final postal = Postal(
          postalCode: secondKey,
          name: secondValue['name'],
          firstLetter: secondValue['alpha']);

      tables.nodes[node.id] = node;
      tables.postalList[node.postalCode] = postal;
      tables.postalCodeNodesIndex[node.postalCode] = node;
    }
  }

  return tables;
}
