/// 邮递区域
class Postal {
  /// 该邮递区域的邮递区号
  final String postalCode;
  /// 该邮递区域的名字
  final String name;
  /// 该邮递区域名字的拼音首字母
  final String firstLetter;

  Postal(
      {required this.postalCode,
      required this.name,
      required this.firstLetter});

  bool get isEmpty {
    return this == emptyPostal;
  }

  bool get isNotEmpty {
    return this != emptyPostal;
  }
}

final emptyPostal = Postal(
  postalCode: "EmptyPostal",
  name: "待选择",
  firstLetter: "-",
);

final rootPostal = Postal(
  postalCode: "RootPostal",
  name: "根节点",
  firstLetter: "-",
);
