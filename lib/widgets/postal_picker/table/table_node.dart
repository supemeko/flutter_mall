/// 用于描述postalCode的关系
class Node {
  /// 当前节点id
  final int id;

  /// 父节点id
  final int prevId;

  /// 当前节点级别
  final int lvl;

  /// 邮递区号【注意，默认使用中国地区编码作为"邮递区号"，而不是中国邮政系统中使用的邮递区号】
  final String postalCode;

  Node(this.id, this.prevId, this.lvl, this.postalCode);

  get isEmpty {
    return this == emptyNode;
  }

  get isNotEmpty {
    return !isEmpty;
  }
}

final emptyNode = Node(-1, -1, -1, "EmptyPostal");
final rootNode = Node(-2, -1, 0, "RootPostal");
