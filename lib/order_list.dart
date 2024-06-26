import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mall/config/service_url.dart';
import 'package:flutter_mall/utils/http_util.dart';
import 'package:flutter_mall/widgets/cached_image_widget.dart';
import 'dart:developer' as developer;
import 'meber_order_page.dart';
import 'model/order_list_model.dart';

///
/// 订单列表页面
///
/// 作者：刘飞华
/// 日期：2023/11/21 17:17
///
class OrderList extends StatefulWidget {
  const OrderList({super.key});

  @override
  State<OrderList> createState() => _OrderListState();
}

class _OrderListState extends State<OrderList> with TickerProviderStateMixin {
  List<List<OrderData>> orderListData = [[], [], [], [], []];

  late PageController _pageViewController;
  late TabController _tabController;
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageViewController = PageController();
    _tabController =
        TabController(length: MemberOrderPageTabs.values.length, vsync: this);
  }

  @override
  void dispose() {
    super.dispose();
    _pageViewController.dispose();
    _tabController.dispose();
  }

  void _queryOrderListData(MemberOrderPageTabs tab, int page) async {
    Response result = await HttpUtil.get("$orderListDataUrl$page", data: {
      "status": tab.queryStatusList(),
    });
    setState(() {
      OrderPageResp orderListModel = OrderPageResp.fromJson(result.data);
      orderListData[tab.index] = orderListModel.data;
    });
  }

  Future<bool> cancelOrder(int orderId) async {
    // print("try cancel order $orderId!");
    Response result = await HttpUtil.get("$orderCancelUrl/$orderId");
    developer.log('$result');
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return MemberOrderPageWidget();
  }

  // @override
  // Widget build(BuildContext context) {
  //   return DefaultTabController(
  //     length: MemberOrderPageTabs.values.length,
  //     child: Scaffold(
  //       appBar: AppBar(
  //         title: const Text(' 我的订单 '),
  //         titleTextStyle: const TextStyle(fontSize: 16, color: Colors.black),
  //         centerTitle: true,
  //         bottom: PreferredSize(
  //           preferredSize: const Size(double.infinity, 50.0),
  //           child: PageIndicator(
  //               tabController: _tabController,
  //               currentPageIndex: _currentPageIndex,
  //               onUpdateCurrentPageIndex: (index) {
  //                 setState(() {
  //                   _currentPageIndex = index;
  //                   _pageViewController.animateToPage(_currentPageIndex,
  //                       duration: const Duration(milliseconds: 300),
  //                       curve: Curves.easeInOut);
  //                 });
  //               }),
  //         ),
  //       ),
  //       body: Column(
  //         children: [
  //           const SizedBox(height: 10.0),
  //           Expanded(
  //             child: PageView(
  //               controller: _pageViewController,
  //               onPageChanged: _handlePageViewChanged,
  //               children: MemberOrderPageTabs.values.map((tab) {
  //                 return OrderListInfo(
  //                   enumerate: tab,
  //                   onQueryList: (page) async {
  //                     _queryOrderListData(tab, page);
  //                   },
  //                   onOrderCancel: (orderId) {
  //                     return cancelOrder(orderId);
  //                   },
  //                   listData: orderListData[tab.index],
  //                 );
  //               }).toList(),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  void _handlePageViewChanged(int currentPageIndex) {
    _tabController.index = currentPageIndex;
    setState(() {
      print("_queryOrderListData:");
      _queryOrderListData(MemberOrderPageTabs.values[_currentPageIndex], 1);
      _currentPageIndex = currentPageIndex;
    });
  }

  void _updateCurrentPageIndex(int index) {
    _tabController.index = index;
    _pageViewController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }
}

class OtherPageIndicator extends StatelessWidget {
  const OtherPageIndicator({
    super.key,
    required this.tabController,
    required this.currentPageIndex,
    required this.onUpdateCurrentPageIndex,
  });

  final int currentPageIndex;
  final TabController tabController;
  final void Function(int) onUpdateCurrentPageIndex;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: MemberOrderPageTabs.values.map((tab) {
          bool isSelected = currentPageIndex == tab.index;
          return GestureDetector(
            onTap: () {
              onUpdateCurrentPageIndex(tab.index);
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue : Colors.grey,
                borderRadius: BorderRadius.circular(5),
              ),
              child:
                  Text(tab.title, style: const TextStyle(color: Colors.white)),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class PageIndicator extends StatelessWidget {
  const PageIndicator({
    super.key,
    required this.tabController,
    required this.currentPageIndex,
    required this.onUpdateCurrentPageIndex,
  });

  final int currentPageIndex;
  final TabController tabController;
  final void Function(int) onUpdateCurrentPageIndex;

  @override
  Widget build(BuildContext context) {
    return TabBar(
      indicatorColor: const Color(0xfffa436a),
      labelColor: const Color(0xfffa436a),
      tabs: MemberOrderPageTabs.values
          .map((tab) => Tab(text: tab.title))
          .toList(),
      onTap: (index) async {
        onUpdateCurrentPageIndex(index);
      },
    );
  }
}

class OrderListInfo extends StatelessWidget {
  final MemberOrderPageTabs enumerate;
  final Function(int page) onQueryList;
  final Function(int orderId) onOrderCancel;
  final List<OrderData> listData;
  final int page = 1;

  const OrderListInfo({
    super.key,
    required this.enumerate,
    required this.onQueryList,
    required this.onOrderCancel,
    required this.listData,
  });

  void query() {}

  @override
  Widget build(BuildContext context) {
    var border = const BorderSide(width: 1, color: Color(0xfff5f5f5));
    var boxDecoration = BoxDecoration(border: Border(bottom: border));
    return Container(
      decoration: boxDecoration,
      width: double.infinity,
      child: Column(
        children: [
          if (listData.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: listData.length,
                itemBuilder: buildOrderPageCard,
              ),
            ),
          if (listData.isEmpty) const Text("没有商品哦"),
          if (listData.isEmpty) const SizedBox(height: 50),
          if (listData.isEmpty) buildPersonalizedProductRecommendations()
        ],
      ),
    );
  }

  Card buildOrderPageCard(BuildContext context, int index) {
    // 订单的商品列表
    final orderData = listData[index];
    final itemList = orderData.orderItemList;

    assert(itemList.isNotEmpty,
        'The order should have included at least one item, but order(${orderData.id}) did not');

    // 订单的商品数量是否超过1个，超过时，不显示商品信息
    bool more = itemList.length > 1;

    // 订单的第一件商品
    final firstItem = itemList[0];

    // 商品描述，如果只有1件商品的话，就需要显示商品信息
    final firstItemDesc = () {
      if (more) {
        return "";
      }

      // 最多显示多少个UTF16编码单元（可以显示的文字数量是有限的，没必要显示太多）
      const firstItemDescCodeUnitsLimit = 60;
      var desc = firstItem.productName;
      var attr = jsonDecode(firstItem.productAttr);
      for (var x in attr) {
        desc += x['key'] + x['value'];
        if (desc.length > firstItemDescCodeUnitsLimit) {
          break;
        }
      }
      return desc;
    }();

    // 最多允许显示多少件商品图片（可以显示的图片数量是有限的，没必要显示太多）
    const maximumNumberOfPictures = 100;
    final pictureIterator = itemList
        .sublist(0, min(itemList.length, maximumNumberOfPictures))
        .map((elem) => elem.productPic);

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
                    Text(getOrderStatus(orderData.status),
                        style: const TextStyle(
                            fontSize: 14, color: Color(0xfffa436a)))
                  ],
                ),
              ),
              if (more)
                SizedBox(
                  height: 100,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
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
                              .toList(),
                        ),
                      )),
                      SizedBox(
                        width: 100,
                        child: ListTile(
                          title: const Text("￥1000.00",
                              style: TextStyle(
                                  fontSize: 12, color: Color(0xff707070))),
                          subtitle: Text("共${itemList.length}件",
                              style: const TextStyle(
                                  fontSize: 10, color: Color(0xff707070))),
                        ),
                      )
                    ],
                  ),
                ),
              if (!more)
                SizedBox(
                  height: 100,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CachedImageWidget(
                        96,
                        96,
                        firstItem.productPic,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(
                        width: 1,
                      ),
                      Expanded(
                          child: ListTile(
                        title: Text(
                          firstItemDesc,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )),
                      SizedBox(
                        width: 100,
                        child: ListTile(
                          title: const Text("￥1000.00",
                              style: TextStyle(
                                  fontSize: 12, color: Color(0xff707070))),
                          subtitle: Text("共${itemList.length}件",
                              style: const TextStyle(
                                  fontSize: 10, color: Color(0xff707070))),
                        ),
                      )
                    ],
                  ),
                ),
              ListTile(
                title: Row(
                  children: [
                    const Text("更多",
                        style:
                            TextStyle(fontSize: 12, color: Color(0xffaaacb0))),
                    const Expanded(child: Text("")),
                    TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                          shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                        side: BorderSide(color: Color(0xffaaacb0), width: 1),
                      )),
                      child: const Text("买了换钱",
                          style: TextStyle(
                              fontSize: 14, color: Color(0xff303133))),
                    ),
                    const SizedBox(width: 5),
                    TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                          shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                        side: BorderSide(color: Color(0xffaaacb0), width: 1),
                      )),
                      child: const Text("退换/售后",
                          style: TextStyle(
                              fontSize: 14, color: Color(0xff303133))),
                    ),
                    const SizedBox(width: 5),
                    TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                          shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                        side: BorderSide(color: Colors.red, width: 1),
                      )),
                      child: const Text("再次购买",
                          style: TextStyle(fontSize: 14, color: Colors.red)),
                    )
                  ],
                ),
              )
            ],
          ),
        )
        // Column(
        //   children: [
        //     Container(
        //       padding: const EdgeInsets.only(left: 15, right: 15),
        //       height: 40,
        //       child: Row(
        //         crossAxisAlignment: CrossAxisAlignment.center,
        //         children: [
        //           Expanded(
        //             child: Text(order.createTime.toString(),
        //                 style: const TextStyle(
        //                     fontSize: 14, color: Color(0xff303133))),
        //           ),
        //           Text(getOrderStatus(order.status),
        //               style:
        //                   const TextStyle(fontSize: 14, color: Color(0xfffa436a)))
        //         ],
        //       ),
        //     ),
        //     Container(
        //       padding: const EdgeInsets.only(left: 15, right: 15),
        //       height: 64,
        //       child: Row(
        //         crossAxisAlignment: CrossAxisAlignment.center,
        //         children: [
        //           Expanded(
        //             child: Text(order.createTime.toString(),
        //                 style: const TextStyle(
        //                     fontSize: 14, color: Color(0xff303133))),
        //           ),
        //           Text(getOrderStatus(order.status),
        //               style:
        //                   const TextStyle(fontSize: 14, color: Color(0xfffa436a)))
        //         ],
        //       ),
        //     ),
        //     ListTile(
        //       title: Text("操作选项"),
        //     )
        //   ],
        // ),
        );
  }

  // 构建订单操作
  Container buildOrderOperate(int index) {
    int status = listData[index].status;
    int orderId = listData[index].id;
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
                await onOrderCancel(orderId);
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
          Text(listData[index].orderItemList.length.toString(),
              style: const TextStyle(fontSize: 13, color: Color(0xff303133))),
          const Text("件商品 实付款",
              style: TextStyle(fontSize: 13, color: Color(0xff707070))),
          const Text(" ￥",
              style: TextStyle(fontSize: 12, color: Color(0xff707070))),
          Text(listData[index].payAmount.toString(),
              style: const TextStyle(fontSize: 16, color: Color(0xff303133))),
        ],
      ),
    );
  }

  // 构建商品列表
  Column buildProductList(int index) {
    return Column(
      children: listData[index].orderItemList.map((item) {
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
            child: Text(listData[index].createTime.toString(),
                style: const TextStyle(fontSize: 14, color: Color(0xff303133))),
          ),
          Text(getOrderStatus(listData[index].status),
              style: const TextStyle(fontSize: 14, color: Color(0xfffa436a))),
          Visibility(
              visible: getDeleteStatus(listData[index].status),
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

enum MemberOrderPageTabs { all, waitPay, waitReceiving, finish, cancel }

extension MemberOrderPageTabExtension on MemberOrderPageTabs {
  String get title {
    switch (this) {
      case MemberOrderPageTabs.all:
        {
          return "全部";
        }
      case MemberOrderPageTabs.waitPay:
        {
          return "待支付";
        }
      case MemberOrderPageTabs.waitReceiving:
        {
          return "待收货/使用";
        }
      case MemberOrderPageTabs.finish:
        {
          return "已完成";
        }
      case MemberOrderPageTabs.cancel:
        {
          return "已取消";
        }
    }
  }

  List<int> queryStatusList() {
    //订单状态：0->待付款；1->待发货；2->已发货；3->已完成；4->已关闭；5->无效订单
    switch (this) {
      case MemberOrderPageTabs.all:
        {
          return [0, 1, 2, 3, 4];
        }
      case MemberOrderPageTabs.waitPay:
        {
          return [0];
        }
      case MemberOrderPageTabs.waitReceiving:
        {
          return [1, 2];
        }
      case MemberOrderPageTabs.finish:
        {
          return [3];
        }
      case MemberOrderPageTabs.cancel:
        {
          return [4];
        }
    }
  }
}
