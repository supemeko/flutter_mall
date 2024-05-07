import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mall/config/service_url.dart';
import 'package:flutter_mall/model/address_list.dart';

import 'utils/http_util.dart';
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

  /// 记录的收货地址邮编
  final _postCode = TextEditingController();

  /// 记录的收货地址省份
  final _province = TextEditingController();

  /// 记录的收货地址城市
  final _city = TextEditingController();

  /// 记录的收货地址区级行政规划
  final _region = TextEditingController();

  /// 记录的收货地址详细信息
  final _detailAddress = TextEditingController();

  /// 表单的key
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final data = widget.data;
    _create = data?.id == null;
    _id = data?.id;
    _name.text = data?.name ?? '';
    _phoneNumber.text = data?.phoneNumber ?? '';
    _defaultStatus = data?.defaultStatus ?? 0;
    _postCode.text = data?.postCode ?? '';
    _province.text = data?.province ?? '';
    _city.text = data?.city ?? '';
    _region.text = data?.region ?? '';
    _detailAddress.text = data?.detailAddress ?? '';
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
                      flex: 4,
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
                      child: Text("邮政编码", style: textStyle),
                    ),
                    Expanded(
                      flex: 4,
                      child: TextFormField(
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(6)
                          ],
                          validator: (value) =>
                              value?.length != 6 ? '邮政编码必须6位' : null,
                          controller: _postCode,
                          onChanged: (text) {
                            setState(() {
                              _postCode.text = text;
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
                      child: Text("所在区域", style: textStyle),
                    ),
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                          validator: (value) =>
                              (value == null || value.isEmpty) ? "不能为空" : null,
                          decoration: const InputDecoration(
                            border: UnderlineInputBorder(),
                            hintText: "省份",
                            isDense: true,
                            contentPadding: EdgeInsets.all(10.0),
                          ),
                          controller: _province,
                          onChanged: (text) {
                            setState(() {
                              _province.text = text;
                            });
                          },
                          style: textStyle),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                          validator: (value) =>
                              (value == null || value.isEmpty) ? "不能为空" : null,
                          decoration: const InputDecoration(
                            border: UnderlineInputBorder(),
                            hintText: "城市",
                            isDense: true,
                            contentPadding: EdgeInsets.all(10.0),
                          ),
                          controller: _city,
                          onChanged: (text) {
                            setState(() {
                              _city.text = text;
                            });
                          },
                          style: textStyle),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                          validator: (value) =>
                              (value == null || value.isEmpty) ? "不能为空" : null,
                          decoration: const InputDecoration(
                            border: UnderlineInputBorder(),
                            hintText: "区级",
                            isDense: true,
                            contentPadding: EdgeInsets.all(10.0),
                          ),
                          controller: _region,
                          onChanged: (text) {
                            setState(() {
                              _region.text = text;
                            });
                          },
                          style: textStyle),
                    ),
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
                      'postCode': _postCode.text,
                      'province': _province.text,
                      'city': _city.text,
                      'region': _region.text,
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
