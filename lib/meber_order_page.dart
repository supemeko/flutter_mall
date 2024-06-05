import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mall/config/service_url.dart';
import 'package:flutter_mall/utils/http_util.dart';
import 'package:flutter_mall/widgets/cached_image_widget.dart';
import 'dart:developer' as developer;
import 'model/order_list_model.dart';

// Use bitmasks to keep the code concise, and if you don't know this technique, Google it
// 使用位掩码使代码保持简洁，如果你不了解这种技术，谷歌它
const int _statusWaitPay = 1;
const int _statusWaitSend = 2;
const int _statusSend = 4;
const int _statusFinish = 8;
const int _statusClose = 16;
const int _statusInvalid = 32;

enum _PageTabs {
  all(
      title: "全部",
      mask: _statusWaitPay &
          _statusWaitSend &
          _statusSend &
          _statusFinish &
          _statusClose &
          _statusInvalid),
  waitPay(title: "待支付", mask: _statusWaitSend),
  waitReceiving(title: "待收货/使用", mask: _statusWaitSend & _statusSend),
  finish(title: "已完成", mask: _statusFinish),
  cancel(title: "已取消", mask: _statusClose);

  final String title;
  final int mask;

  const _PageTabs({required this.title, required this.mask});
}

extension _PageTabExtension on _PageTabs {
  List<int> get orderStatuses {
    return [
      if (mask & _statusWaitPay == _statusWaitPay) 0,
      if (mask & _statusWaitSend == _statusWaitSend) 1,
      if (mask & _statusSend == _statusSend) 2,
      if (mask & _statusFinish == _statusFinish) 3,
      if (mask & _statusClose == _statusClose) 4,
      if (mask & _statusInvalid == _statusInvalid) 5,
    ];
  }
}

enum _OrderStatus {
  waitPay(title: "等待付款"),
  waitSend(title: "待发货"),
  send(title: "等待收货"),
  finish(title: "交易完成"),
  close(title: "交易关闭"),
  invalid(title: "无效订单");

  final String title;

  const _OrderStatus({required this.title});
}

/// 订单页组件
class MemberOrderPageWidget extends StatefulWidget {
  const MemberOrderPageWidget({super.key});

  @override
  State<MemberOrderPageWidget> createState() => _MemberOrderPageWidgetState();
}

class _MemberOrderPageWidgetState extends State<MemberOrderPageWidget>
    with TickerProviderStateMixin, _PageData {
  late PageController _pageViewController;
  late TabController _tabController;
  int _currentPageIndex = 0;

  static final tabCount = _PageTabs.values.length;
  static final tabTiles =
      _PageTabs.values.map((tab) => Tab(text: tab.title)).toList();

  @override
  void initState() {
    super.initState();
    _pageViewController = PageController();
    _tabController = TabController(length: tabCount, vsync: this);
  }

  @override
  void dispose() {
    super.dispose();
    _pageViewController.dispose();
    _tabController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: tabCount,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('我的订单'),
          titleTextStyle: const TextStyle(fontSize: 16, color: Colors.black),
          centerTitle: true,
          bottom: PreferredSize(
              preferredSize: const Size(double.infinity, 50.0),
              child: TabBar(
                indicatorColor: const Color(0xfffa436a),
                labelColor: const Color(0xfffa436a),
                tabs: tabTiles,
                onTap: _onTapTabBar,
              )),
        ),
        body: Column(
          children: [
            const SizedBox(height: 10.0),
            Expanded(
              child: PageView(
                controller: _pageViewController,
                onPageChanged: _onPageChanged,
                children: _PageTabs.values.map((tab) {
                  final tabData = _getTabData(tab);
                  if (tabData == null) {
                    return Container();
                  }
                  return _TabWidget(
                    tab: tab,
                    queryList: (page) async {
                      await _queryTabData(tab);
                      setState(() {});
                    },
                    cancelOrder: (orderId) {
                      return _cancelOrder(orderId);
                    },
                    data: tabData,
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onTapTabBar(int index) async {
    setState(() {
      _currentPageIndex = index;
      _pageViewController.animateToPage(_currentPageIndex,
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    });
  }

  void _onPageChanged(int currentPageIndex) {
    setState(() {
      _tabController.index = currentPageIndex;
      _queryTabData(_PageTabs.values[currentPageIndex]);
      _currentPageIndex = currentPageIndex;
    });
  }
}

class _TabWidget extends StatelessWidget {
  final _PageTabs tab;
  final List<OrderData> data;
  final Function(int page) queryList;
  final Function(int orderId) cancelOrder;
  final int page = 1;

  const _TabWidget({
    super.key,
    required this.tab,
    required this.queryList,
    required this.cancelOrder,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    var border = const BorderSide(width: 1, color: Color(0xfff5f5f5));
    var boxDecoration = BoxDecoration(border: Border(bottom: border));
    return Container(
      decoration: boxDecoration,
      width: double.infinity,
      child: Column(
        children: [
          Expanded(
            child: Expanded(
              child: ListView.builder(
                itemCount: data.length,
                itemBuilder: buildCard,
              ),
            ),
          ),
          const Text("没有商品哦"),
          const SizedBox(height: 50),
          buildPersonalizedProductRecommendations()
        ],
      ),
    );
  }

  Widget buildCard(BuildContext context, int orderIndex) {
    return _OrderCard(orderData: data[orderIndex]);
  }

  // 构建订单操作
  Container buildOrderOperate(int index) {
    int status = data[index].status;
    int orderId = data[index].id;
    return Container(
      padding: const EdgeInsets.only(right: 5),
      height: 40,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Visibility(
            visible: status == 0,
            child: TextButton(
              onPressed: () async {
                await cancelOrder(orderId);
              },
              // style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.white12)),
              child: const Text("取消订单",
                  style: TextStyle(fontSize: 14, color: Color(0xff303133))),
            ),
          ),
          Visibility(
              visible: status == 2,
              child: TextButton(
                onPressed: () {},
                // style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.white12)),
                child: const Text("查看物流",
                    style: TextStyle(fontSize: 14, color: Color(0xff303133))),
              )),
          Visibility(
              visible: status == 0,
              child: TextButton(
                onPressed: () {},
                // style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.white12)),
                child: const Text("立即付款",
                    style: TextStyle(fontSize: 14, color: Color(0xfffa436a))),
              )),
          // const SizedBox(
          //   width: 5,
          // ),
          Visibility(
              visible: status == 2,
              child: TextButton(
                onPressed: () {},
                // style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Color(0xfff7bcc8))),
                child: const Text("确认收货",
                    style: TextStyle(fontSize: 14, color: Color(0xfffa436a))),
              )),
          Visibility(
              visible: status == 3,
              child: TextButton(
                onPressed: () {},
                // style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Color(0xfff7bcc8))),
                child: const Text("评价商品",
                    style: TextStyle(fontSize: 14, color: Color(0xfffa436a))),
              )),
        ],
      ),
    );
  }

  // 构建订单支付金额
  Container buildAmount(BoxDecoration boxDecoration, int index) {
    return Container(
      padding: const EdgeInsets.only(right: 15),
      height: 40,
      decoration: boxDecoration,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Text("共",
              style: TextStyle(fontSize: 13, color: Color(0xff707070))),
          Text(data[index].orderItemList.length.toString(),
              style: const TextStyle(fontSize: 13, color: Color(0xff303133))),
          const Text("件商品 实付款",
              style: TextStyle(fontSize: 13, color: Color(0xff707070))),
          const Text(" ￥",
              style: TextStyle(fontSize: 12, color: Color(0xff707070))),
          Text(data[index].payAmount.toString(),
              style: const TextStyle(fontSize: 16, color: Color(0xff303133))),
        ],
      ),
    );
  }

  // 构建商品列表
  Column buildProductList(int index) {
    return Column(
      children: data[index].orderItemList.map((item) {
        return Container(
          padding: const EdgeInsets.only(right: 15, top: 15),
          // decoration: boxDecoration,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CachedImageWidget(
                60,
                60,
                item.productPic,
                fit: BoxFit.contain,
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.productName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 15, color: Color(0xff303133))),
                    const Text("颜色:黑色;容量:128G; x 1",
                        style:
                            TextStyle(fontSize: 13, color: Color(0xff707070))),
                    Row(
                      children: [
                        const Text("￥",
                            style: TextStyle(
                                fontSize: 12, color: Color(0xff707070))),
                        Text(item.productPrice.toString(),
                            style: const TextStyle(
                                fontSize: 15, color: Color(0xff303133))),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // 构建订单生成时间和订单状态
  Container buildCreateTime(BoxDecoration boxDecoration, int index) {
    return Container(
      padding: const EdgeInsets.only(right: 15),
      height: 40,
      decoration: boxDecoration,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(data[index].createTime.toString(),
                style: const TextStyle(fontSize: 14, color: Color(0xff303133))),
          ),
          Text(getOrderStatus(data[index].status),
              style: const TextStyle(fontSize: 14, color: Color(0xfffa436a))),
          Visibility(
              visible: getDeleteStatus(data[index].status),
              child: Container(
                margin: const EdgeInsets.only(left: 10),
                child: Image.asset(
                  "images/delete.png",
                  height: 17,
                  width: 16,
                ),
              ))
        ],
      ),
    );
  }

  // 状态转换
  String getOrderStatus(int status) {
    //0->待付款；1->待发货；2->已发货；3->已完成；4->已关闭；5->无效订单',
    Map statusMap = <int, String>{};
    statusMap[0] = "等待付款";
    statusMap[1] = "待发货";
    statusMap[2] = "等待收货";
    statusMap[3] = "交易完成";
    statusMap[4] = "交易关闭";
    statusMap[5] = "无效订单";

    return statusMap[status];
  }

  // 是否显示删除图标
  bool getDeleteStatus(int status) {
    //0->待付款；1->待发货；2->已发货；3->已完成；4->已关闭；5->无效订单',
    Map statusMap = <int, bool>{};
    statusMap[0] = false;
    statusMap[1] = false;
    statusMap[2] = false;
    statusMap[3] = true;
    statusMap[4] = true;
    statusMap[5] = true;

    return statusMap[status];
  }

  Widget buildPersonalizedProductRecommendations() {
    return const Column(
      children: [
        Text("个性化推荐商品1"),
        Text("个性化推荐商品2"),
        Text("个性化推荐商品3"),
      ],
    );
  }
}

(bool, dynamic) defaultMatch(OrderData orderData) {
  return (true, null);
}

(bool, dynamic) afterSalesMatch(OrderData orderData) {
  var orderItemList = orderData.orderItemList;
  return (orderItemList[0].realAmount > 500, null);
}

(bool, dynamic) sellMatch(OrderData orderData) {
  var orderItemList = orderData.orderItemList;
  return (orderItemList[0].realAmount > 1000, null);
}

enum _OrderCardActionType {
  buyAgain("再次购买", defaultMatch),
  afterSales("退换/售后", afterSalesMatch),
  sell("卖了换钱", sellMatch),
  invoice("查看发票", defaultMatch),
  evaluate("评价晒单", defaultMatch),
  delete("删除", defaultMatch),
  ;

  final String title;
  final (bool, dynamic) Function(OrderData orderData) condition;

  const _OrderCardActionType(this.title, this.condition);

  (bool, _OrderCardAction) match(OrderData orderData) {
    var (cond, dync) = condition(orderData);
    return (cond, _OrderCardAction(this, dync));
  }
}

class _OrderCardAction {
  final _OrderCardActionType actionType;
  final dynamic params;

  const _OrderCardAction(this.actionType, this.params);
}

class _OrderCard extends StatelessWidget {
  OrderData orderData;

  _OrderCard({super.key, required this.orderData});

  List<_OrderCardAction> matchActions() {
    List<_OrderCardAction> actions = [];
    for (var actionType in _OrderCardActionType.values) {
      var (result, params) = actionType.match(orderData);
      if (result) {
        actions.add(params);
      }
    }
    return actions;
  }

  @override
  Widget build(BuildContext context) {
    final itemList = orderData.orderItemList;
    final actions = matchActions();

    assert(itemList.isNotEmpty,
        'The order should have included at least one item, but order(${orderData.id}) did not');

    return Card(
        margin: const EdgeInsets.all(10),
        child: Container(
          padding: const EdgeInsets.only(left: 15, right: 15),
          child: Column(
            children: [
              SizedBox(
                height: 40,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(orderData.createTime.toString(),
                          style: const TextStyle(
                              fontSize: 14, color: Color(0xff303133))),
                    ),
                    Text(_OrderStatus.values[orderData.status].title,
                        style: const TextStyle(
                            fontSize: 14, color: Color(0xfffa436a)))
                  ],
                ),
              ),
              SizedBox(
                  height: 100,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ...orderData.orderItemList.length > 1
                          ? middleLayout1()
                          : middleLayout0(),
                      SizedBox(
                        width: 100,
                        child: ListTile(
                          title: Text('￥${orderData.totalAmount}',
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xff707070))),
                          subtitle: Text("共${orderData.orderItemList.length}件",
                              style: const TextStyle(
                                  fontSize: 10, color: Color(0xff707070))),
                        ),
                      )
                    ],
                  )),
              ListTile(
                title: Row(
                  children: [
                    if (actions.length > 3) ...[
                      const Text("更多",
                          style: TextStyle(
                              fontSize: 12, color: Color(0xffaaacb0))),
                      const Expanded(child: Text(""))
                    ],
                    ...actions
                        .map((e) {
                          return <Widget>[
                            TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(
                                  shape: const RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(20)),
                                side: BorderSide(
                                    color: Color(0xffaaacb0), width: 1),
                              )),
                              child: const Text("买了换钱",
                                  style: TextStyle(
                                      fontSize: 14, color: Color(0xff303133))),
                            ),
                            const SizedBox(width: 5)
                          ];
                          return const SizedBox(width: 5);
                        })
                        .expand<Widget>((element) => element as List<Widget>)
                        .toList()
                  ],
                ),
              )
            ],
          ),
        ));
  }

  List<Widget> middleLayout0() {
    // 商品描述，如果只有1件商品的话，就需要显示商品信息
    final firstItem = orderData.orderItemList[0];

    final firstItemDesc = () {
      // 最多显示多少个UTF16编码单元（可以显示的文字数量是有限的，没必要显示太多）
      const maximumNumberOfUnitCodesAtDisplay = 60;
      var desc = firstItem.productName;
      var attr = jsonDecode(firstItem.productAttr);
      for (var x in attr) {
        desc += x['key'] + x['value'];
        if (desc.length > maximumNumberOfUnitCodesAtDisplay) {
          break;
        }
      }
      return desc;
    }();

    return [
      CachedImageWidget(
        96,
        96,
        firstItem.productPic,
        fit: BoxFit.contain,
      ),
      const SizedBox(width: 1),
      Expanded(
          child: ListTile(
              title: Text(
        firstItemDesc,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      )))
    ];
  }

  List<Widget> middleLayout1() {
    var orderItemList = orderData.orderItemList;
// 最多允许显示多少件商品图片（可以显示的图片数量是有限的，没必要显示太多）
    const maximumNumberOfPicturesAtDisplay = 4;
    final pictureIterator = orderItemList
        .sublist(0, min(orderItemList.length, maximumNumberOfPicturesAtDisplay))
        .map((elem) => elem.productPic);

    return [
      Expanded(
          child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                  children: pictureIterator
                      .map((elem) => Row(
                            children: [
                              CachedImageWidget(
                                96,
                                96,
                                elem,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(width: 8)
                            ],
                          ))
                      .toList())))
    ];
  }
}

mixin _PageData {
  List<List<OrderData>?> list = _PageTabs.values.map((e) => null).toList();

  Future<void> _queryTabData(_PageTabs tab) async {
    const page = 1;
    Response result = await HttpUtil.get("$orderListDataUrl$page", data: {
      "status": tab.orderStatuses,
    });
    list[tab.index] = OrderPageResp.fromJson(result.data).data;
  }

  Future<void> _cancelOrder(int orderId) async {
    Response result = await HttpUtil.get("$orderCancelUrl/$orderId");
    developer.log('$result');
  }

  List<OrderData>? _getTabData(_PageTabs tab) {
    return list[tab.index];
  }
}
