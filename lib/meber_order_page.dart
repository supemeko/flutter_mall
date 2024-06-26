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
const int _tabAllStatuses = _statusWaitPay |
    _statusWaitSend |
    _statusSend |
    _statusFinish |
    _statusClose |
    _statusInvalid;
const _tabWaitReceivingStatus = _statusWaitSend | _statusSend;

enum _PageTabs {
  all(title: "全部", mask: _tabAllStatuses),
  waitPay(title: "待支付", mask: _statusWaitPay),
  waitReceiving(title: "待收货/使用", mask: _tabWaitReceivingStatus),
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

  bool match(int orderType) {
    return index == orderType;
  }

  static _OrderStatus of(OrderData data) {
    if (data.status >= _OrderStatus.values.length) {
      return _OrderStatus.invalid;
    }
    return _OrderStatus.values[data.status];
  }
}

enum _OrderCardActionType {
  buyAgain("再次购买", defaultMatch),
  afterSales("退换/售后", afterSalesMatch),
  sell("卖了换钱", sellMatch),
  invoice("查看发票", defaultMatch),
  evaluate("评价晒单", defaultMatch2),
  delete("删除", deleteMatch),
  cancel("取消", cancelMatch),
  ;

  final String title;
  final (bool, dynamic) Function(OrderData orderData) condition;

  const _OrderCardActionType(this.title, this.condition);

  (bool, _OrderCardAction) generateAction(
      OrderData orderData, Function(String name, dynamic params) doAction) {
    var (cond, dync) = condition(orderData);
    return (
      cond,
      _OrderCardAction(
          actionType: this,
          doAction: () {
            doAction(title, dync);
          })
    );
  }
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
                    handleEvent: _handleEvent,
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

  void _onPageChanged(int currentPageIndex) async {
    await _queryTabData(_PageTabs.values[currentPageIndex]);
    setState(() {
      _tabController.index = currentPageIndex;
      _currentPageIndex = currentPageIndex;
    });
  }
}

class _TabWidget extends StatelessWidget {
  final _PageTabs tab;
  final List<OrderData> data;
  final Function(int page) queryList;
  final Function(OrderData orderData, String name, dynamic params) handleEvent;
  final int page = 1;

  const _TabWidget({
    super.key,
    required this.tab,
    required this.queryList,
    required this.data,
    required this.handleEvent,
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
            child: ListView.builder(
              itemCount: data.length,
              itemBuilder: (context, index) => _OrderCard(
                orderData: data[index],
                orderEvent: (name, params) async {
                  await handleEvent(data[index], name, params);
                },
              ),
            ),
          ),
          if (data.isEmpty) const Text("没有商品哦"),
          if (data.isEmpty) const SizedBox(height: 50),
          if (data.isEmpty) buildPersonalizedProductRecommendations()
        ],
      ),
    );
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

class _MoreButtonWidget extends StatefulWidget {
  final List<_OrderCardAction> actions;

  const _MoreButtonWidget(this.actions, {super.key});

  @override
  State<StatefulWidget> createState() => _MoreButtonWidgetState();
}

class _MoreButtonWidgetState extends State<_MoreButtonWidget> {
  late List<_OrderCardAction> actions;
  final OverlayPortalController _tooltipController = OverlayPortalController();

  @override
  void initState() {
    super.initState();
    actions = widget.actions;
  }

  @override
  Widget build(BuildContext context) {
    final link = LayerLink();
    return TextButton(
      onPressed: () async {
        _tooltipController.toggle();
      },
      style: TextButton.styleFrom(
        padding: const EdgeInsets.all(0),
        visualDensity: VisualDensity.compact,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
      ),
      child: OverlayPortal(
        controller: _tooltipController,
        overlayChildBuilder: (BuildContext context) {
          return Positioned(
            width: 100,
            child: CompositedTransformFollower(
              targetAnchor: Alignment.topRight,
              followerAnchor: Alignment.bottomLeft,
              offset: const Offset(-10, 0),
              link: link,
              child: Container(
                color: Colors.white,
                child: TapRegion(
                  consumeOutsideTaps: true,
                  onTapOutside: (event) async {
                    _tooltipController.hide();
                  },
                  child: Column(
                    children: actions.map(
                      (action) {
                        return SizedBox(
                          width: 100,
                          child: TextButton(
                            onPressed: () async {
                              await action.doAction();
                              _tooltipController.hide();
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.all(0),
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero,
                              ),
                            ),
                            child: Text(action.actionType.title),
                          ),
                        );
                      },
                    ).toList(),
                  ),
                ),
              ),
            ),
          );
        },
        child: CompositedTransformTarget(
            link: link,
            child: const Text('更多', style: TextStyle(fontSize: 14))),
      ),
    );
  }
}

(bool, dynamic) defaultMatch(OrderData orderData) {
  return (true, null);
}

(bool, dynamic) cancelMatch(OrderData orderData) {
  return (_OrderStatus.waitPay.match(orderData.status), null);
}

(bool, dynamic) deleteMatch(OrderData orderData) {
  return (_OrderStatus.close.match(orderData.status), null);
}

(bool, dynamic) defaultMatch2(OrderData orderData) {
  return (orderData.id != 12, null);
}

(bool, dynamic) afterSalesMatch(OrderData orderData) {
  var orderItemList = orderData.orderItemList;
  return (orderItemList[0].realAmount > 500, null);
}

(bool, dynamic) sellMatch(OrderData orderData) {
  var orderItemList = orderData.orderItemList;
  return (orderItemList[0].realAmount > 1000, null);
}

class _OrderCardAction {
  final _OrderCardActionType actionType;
  final Function() doAction;

  const _OrderCardAction({required this.actionType, required this.doAction});
}

class _OrderCard extends StatelessWidget {
  final OrderData orderData;
  final Function(String name, dynamic params) orderEvent;

  const _OrderCard(
      {super.key, required this.orderData, required this.orderEvent});

  @override
  Widget build(BuildContext context) {
    final itemList = orderData.orderItemList;
    final actions = _OrderCardActionType.values
        .map((e) => e.generateAction(orderData, orderEvent))
        .where((value) => value.$1)
        .map((e) => e.$2)
        .toList();

    assert(itemList.isNotEmpty,
        'The order should have included at least one item, but order(${orderData.id}) did not');

    bool needMoreAction = actions.length > 4;
    int displayActionCount = needMoreAction ? 3 : min(actions.length, 4);
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
                    Text(_OrderStatus.of(orderData).title,
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
                    if (needMoreAction) ...[
                      SizedBox(
                        width: 30,
                        height: 48,
                        child: _MoreButtonWidget(
                            actions.skip(displayActionCount).toList()),
                      )
                    ],
                    const Expanded(child: Text("")),
                    ...List.generate(displayActionCount,
                            (index) => displayActionCount - 1 - index)
                        .where((element) => element < actions.length)
                        .map((element) => actions[element])
                        .map((action) {
                          return <Widget>[
                            TextButton(
                              onPressed: () async {
                                await action.doAction();
                              },
                              style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  shape: const RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(20)),
                                      side: BorderSide(
                                          color: Color(0xffaaacb0), width: 1))),
                              child: Text(action.actionType.title,
                                  style: const TextStyle(
                                      fontSize: 14, color: Color(0xff303133))),
                            ),
                            const SizedBox(width: 5)
                          ];
                        })
                        .expand<Widget>((element) => element)
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
          ),
        ),
      )
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
                .map((elem) => Row(children: [
                      CachedImageWidget(
                        96,
                        96,
                        elem,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 8)
                    ]))
                .toList(),
          ),
        ),
      )
    ];
  }
}

mixin _PageData {
  List<List<OrderData>?> list = [..._PageTabs.values.map((e) => null)];

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

  Future<void> _handleEvent(
      OrderData orderData, String name, dynamic value) async {
    switch (name) {
      case "取消":
        _cancelOrder(orderData.id);
        return;
    }
    developer.log("${orderData.id} $name $value");
  }

  List<OrderData>? _getTabData(_PageTabs tab) {
    return list[tab.index];
  }
}
