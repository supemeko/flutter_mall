import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mall/config/service_url.dart';
import 'package:flutter_mall/model/address_list.dart';
import 'package:flutter_mall/widgets/postal_picker/table/table_postal.dart';
import 'package:fluttercontactpicker/fluttercontactpicker.dart';
import 'package:location/location.dart';

import 'utils/http_util.dart';
import 'widgets/address_add_lookup_text_field.dart';
import 'widgets/postal_picker/postal_picker.dart';
import 'widgets/postal_picker/table/table_node.dart';
import 'widgets/postal_picker/table/tables.dart';
import 'widgets/postal_picker/model/page.dart' as postal_page;
import 'package:flutter_z_location/flutter_z_location.dart';

///
/// 添加收货地址页面
///
/// 作者：刘飞华
/// 日期：2023/11/21 17:17
///
class AddressAdd extends StatefulWidget {
  final AddressListData? data;

  const AddressAdd({super.key, this.data});

  @override
  State<AddressAdd> createState() => _AddressAddState();
}

class _AddressAddState extends State<AddressAdd> {
  /// 记录是否为默认收货地址
  late int _defaultStatus;

  /// 记录是新建页面还是修改页面
  late bool _create;

  /// 记录的唯一索引
  int? _id;

  /// 记录的收货人名称
  final _name = TextEditingController();

  /// 记录的收货人手机号
  final _phoneNumber = TextEditingController();

  /// 记录的收货地址的邮递区域（所在区域）
  final _postalRegion = TextEditingController();

  /// 邮递区域
  List<String> postalList = ["", "", "", ""];

  /// 邮递区号
  late String _postalCode;

  /// 记录的收货地址详细信息
  final _detailAddress = TextEditingController();

  /// 用户提供的地址信息
  final _userProvideAddressInfo = TextEditingController();

  /// 用户提供的地址信息【用户正在输入】
  final FocusNode _userProvideAddressInfoFocus = FocusNode();

  /// 表单的key
  final _formKey = GlobalKey<FormState>();

  /// 收货地址数据
  final postalTables = defaultTables();

  @override
  void initState() {
    super.initState();
    final data = widget.data;
    _create = data?.id == null;
    _id = data?.id;
    _name.text = data?.name ?? '';
    _phoneNumber.text = data?.phoneNumber ?? '';
    _defaultStatus = data?.defaultStatus ?? 0;
    _postalCode = data?.postCode ?? '';
    postalList[0] = data?.province ?? '';
    postalList[1] = data?.city ?? '';
    postalList[2] = data?.region ?? '';
    postalList[3] = '';
    _postalRegion.text = _postalRegionDesc;
    _detailAddress.text = data?.detailAddress ?? '';
  }

  String get _postalRegionDesc {
    var ss = "";
    for (final s in postalList) {
      ss += s.isNotEmpty ? "$s " : "";
    }
    ss = ss.trim();
    if (ss.isEmpty) {
      return "省/市/县";
    }
    return ss;
  }

  @override
  Widget build(BuildContext context) {
    var textStyle = const TextStyle(fontSize: 15, color: Color(0xff303133));
    var border = const BorderSide(width: 1, color: Color(0xfff5f5f5));
    var boxDecoration =
        BoxDecoration(color: Colors.white, border: Border(bottom: border));

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(_create ? "新增收货地址" : "修改收货地址",
            style: const TextStyle(fontSize: 16, color: Colors.black)),
        centerTitle: true,
        actions: [
          if (!_create)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('删除确认'),
                    content: const Text('你确定要删除这个收货地址吗?'),
                    actions: [
                      TextButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          try {
                            await HttpUtil.get('$addressDelete/${_id!}');
                            if (!context.mounted) return;
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                duration: Duration(milliseconds: 1000),
                                content: Text('操作成功'),
                                backgroundColor: Colors.green, // 设置背景颜色为绿色
                              ),
                            );
                          } catch (e) {
                            print("失败:${e}");
                          }
                        },
                        child: const Text('确认'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('取消'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: Container(
        color: const Color(0xfff5f5f5),
        // padding: const EdgeInsets.symmetric(horizontal: 15),
        width: MediaQuery.of(context).size.width,
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 5),
                padding: const EdgeInsets.all(5),
                decoration: boxDecoration,
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Text("姓名", style: textStyle),
                    ),
                    Expanded(
                      flex: 4,
                      child: TextFormField(
                          validator: (value) =>
                              (value == null || value.isEmpty) ? "不能为空" : null,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(10),
                          ],
                          controller: _name,
                          onChanged: (text) {
                            setState(() {
                              _name.text = text;
                            });
                          },
                          style: textStyle),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: boxDecoration,
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Text("手机号码", style: textStyle),
                    ),
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(11),
                          ],
                          validator: (value) =>
                              value?.length != 11 ? '手机号码必须11位' : null,
                          controller: _phoneNumber,
                          onChanged: (text) {
                            setState(() {
                              _phoneNumber.text = text;
                            });
                          },
                          style: textStyle),
                    ),
                    Expanded(
                        child: IconButton(
                      icon: const Icon(Icons.contact_phone),
                      color: Colors.blue,
                      onPressed: () async {
                        try {
                          final PhoneContact contact =
                              await FlutterContactPicker.pickPhoneContact();
                          setState(() {
                            _phoneNumber.text = contact.phoneNumber!.number!;
                            _name.text = contact.fullName!;
                          });
                        } catch (e) {
                          print("通信录选择失败");
                        }
                      },
                    ))
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: boxDecoration,
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Text("所在区域", style: textStyle),
                    ),
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                          enableInteractiveSelection: false,
                          onTap: () async {
                            FocusScope.of(context).requestFocus(FocusNode());
                            final page = postal_page.Page(
                              tables: postalTables,
                              numberOfTabs: 4,
                              callback: (page) => {
                                setState(() {
                                  for (int i = 0; i < 4; i++) {
                                    // for 1..=4
                                    final pageIndex = i + 1;
                                    final postal =
                                        page.selectiveList[pageIndex];
                                    postalList[i] =
                                        postal.isNotEmpty ? postal.name : '';
                                    if (postal.isNotEmpty) {
                                      _postalCode = postal.postalCode;
                                    }
                                  }
                                  _postalRegion.text = _postalRegionDesc;
                                })
                              },
                            );
                            final postal = postalTables
                                    .getPostalByPostalCode(_postalCode) ??
                                rootPostal;
                            page.pick(postal);
                            PostalPicker.show(context: context, page: page);
                          },
                          validator: (value) =>
                              (value == null || value.isEmpty) ? "不能为空" : null,
                          decoration: const InputDecoration(
                            border: UnderlineInputBorder(),
                            hintText: "省份",
                            isDense: true,
                            contentPadding: EdgeInsets.all(10.0),
                          ),
                          controller: _postalRegion,
                          onChanged: (text) {
                            setState(() {
                              _postalRegion.text = text;
                            });
                          },
                          style: textStyle),
                    ),
                    Expanded(
                        flex: 1,
                        child: IconButton(
                          icon: const Icon(Icons.location_on),
                          color: Colors.blue,
                          onPressed: () async {
                            try {
                              // 获取GPS定位经纬度
                              Location location = new Location();
                              bool _serviceEnabled;
                              PermissionStatus _permissionGranted;
                              LocationData _locationData;

                              _serviceEnabled = await location.serviceEnabled();
                              if (!_serviceEnabled) {
                                _serviceEnabled =
                                    await location.requestService();
                                if (!_serviceEnabled) {
                                  print("服务没启动");
                                  return;
                                }
                              }

                              _permissionGranted =
                                  await location.hasPermission();
                              if (_permissionGranted ==
                                  PermissionStatus.denied) {
                                _permissionGranted =
                                    await location.requestPermission();
                                if (_permissionGranted !=
                                    PermissionStatus.granted) {
                                  print("请求权限没成功");
                                  return;
                                }
                              }
                              _locationData = await location.getLocation();

                              print(
                                  "loc:${_locationData.latitude},${_locationData.longitude}");
                              // 经纬度反向地理编码获取地址信息(省、市、区)
                              final loc =
                                  await FlutterZLocation.geocodeCoordinate(
                                      _locationData.latitude!,
                                      _locationData.longitude!,
                                      pathHead: 'assets/');
                              setState(() {
                                _postalCode = loc.districtId;
                                postalList[0] = loc.province;
                                postalList[1] = loc.city;
                                postalList[2] = loc.district;
                                _postalRegion.text = _postalRegionDesc;
                              });
                            } catch (e) {
                              print("获取地理信息失败了:$e");
                            }
                          },
                        ))
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: boxDecoration,
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Text("详细地址", style: textStyle),
                    ),
                    Expanded(
                      flex: 4,
                      child: TextFormField(
                          validator: (value) =>
                              (value == null || value.isEmpty) ? "不能为空" : null,
                          controller: _detailAddress,
                          onChanged: (text) {
                            setState(() {
                              _detailAddress.text = text;
                            });
                          },
                          style: textStyle),
                    ),
                  ],
                ),
              ),
              if (_create)
                Container(
                  color: Colors.white,
                  // margin: const EdgeInsets.only(top: 8, bottom: 20),
                  padding:
                      const EdgeInsets.symmetric(vertical: 7, horizontal: 15),
                  // height: 54,
                  child: LookupTextField(
                    onLookupText: (text) {
                      // 首先移除姓名手机号和姓名
                      var phone = null;
                      var name = null;
                      var detailAddress = null;
                      List<Postal> address = [];
                      // 1. lookup phone & name
                      var first = text.split(RegExp(r"[ ,;，；.。]"));
                      for (var s in first) {
                        s = s.trim();
                        if (RegExp(r"^1\d{10}$").hasMatch(s)) {
                          phone = s;
                        }
                        if (s.length > 2 && s.length < 4 && s.startsWith("张") ||
                            s.startsWith("曹") ||
                            s.startsWith("刘")) {
                          name = s;
                        }
                      }
                      // 2. lookup postal
                      List<Postal>? p = postalTables.lookupTree(text);
                      if (p != null) {
                        _postalCode = p.last.postalCode;
                        for (var i = 0; i < p.length; i++) {
                          postalList[i] = p[i].name;
                        }
                        _postalRegion.text = _postalRegionDesc;
                      }
                      // 3. remove all already
                      var third = text;
                      third = third.replaceAll(phone ?? ' ', ' ');
                      third = third.replaceAll(name ?? ' ', ' ');
                      if (p != null) {
                        for (var i = 0; i < p.length; i++) {
                          third = third.replaceAll(p[i].name, ' ');
                        }
                      }
                      // 4.
                      var fourth = third.split(RegExp(r"[ ,;，；.。]"));
                      for (var s in fourth) {
                        s = s.trim();
                        if (RegExp(r"^1\d{10}$").hasMatch(s)) {
                          phone ??= s;
                        }
                        if (s.length >= 2 &&
                                s.length <= 4 &&
                                s.startsWith("张") ||
                            s.startsWith("曹") ||
                            s.startsWith("刘")) {
                          name ??= s;
                        }
                        if (s.length >= 4) {
                          detailAddress ??= s;
                          if (detailAddress.length < s.length) {
                            detailAddress = s;
                          }
                        }
                      }
                      if (phone != null) {
                        _phoneNumber.text = phone;
                      }
                      if (name != null) {
                        _name.text = name;
                      }
                      if (detailAddress != null) {
                        _detailAddress.text = detailAddress;
                      }
                      print('[][][]phone:$phone');
                      print('[][][]name:$name');
                      print('[][][]detail:$detailAddress');
                    },
                  ),
                ),
              Container(
                color: Colors.white,
                margin: const EdgeInsets.only(top: 8, bottom: 20),
                padding:
                    const EdgeInsets.symmetric(vertical: 7, horizontal: 15),
                // height: 54,
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Text("设为默认", style: textStyle),
                    ),
                    Switch(
                      value: _defaultStatus & 0x1 == 0x1,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onChanged: (value) {
                        setState(() {
                          _defaultStatus = (_defaultStatus + 1) & 0x1;
                        });
                      },
                      activeColor: Colors.white,
                      activeTrackColor: const Color(0xfffa436a),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () async {
                  if (_formKey.currentState!.validate()) {
                    final url = _create ? addressAdd : addressUpdate;
                    var data = {
                      'name': _name.text,
                      'phoneNumber': _phoneNumber.text,
                      'defaultStatus': _defaultStatus,
                      'postCode': _postalCode,
                      'province': postalList[0],
                      'city': postalList[1],
                      'region': postalList[2],
                      'detailAddress': _detailAddress.text,
                      if (_id != null) 'id': _id,
                    };

                    try {
                      await HttpUtil.post(url, data: data);
                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          duration: Duration(milliseconds: 1000),
                          content: Text('操作成功'),
                          backgroundColor: Colors.green, // 设置背景颜色为绿色
                        ),
                      );
                    } catch (e) {
                      print("失败:${e}");
                    }
                  }
                },
                child: Container(
                  alignment: Alignment.center,
                  width: MediaQuery.of(context).size.width,
                  height: 40,
                  margin: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: const Color(0xfffa436a),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Text(
                    '提交',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
