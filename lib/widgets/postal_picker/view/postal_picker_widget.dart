/*
 * BSD 2-Clause License
 *
 * Copyright (c) 2021, wenchao
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this
 * list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Original repository: https://github.com/wenchaosong/FlutterCityPicker
 */

import 'package:flutter/material.dart';
import '../model/page.dart' as postal_page;
import '../table/table_postal.dart';
import 'postal_list_widget.dart';

class PostalPickerWidget extends StatefulWidget {
  /// 组件高度
  final double? height;

  /// 标题高度
  final double? titleHeight;

  /// 顶部圆角
  final double? corner;

  /// 顶部圆角
  final Color? backgroundColor;

  /// 左边间距
  final double? paddingLeft;

  /// 标题样式
  final Widget? titleWidget;

  /// 选择文字
  final String? selectText;

  /// 关闭图标组件
  final Widget? closeWidget;

  /// tab 高度
  final double? tabHeight;

  /// 是否显示 indicator
  final bool? showTabIndicator;

  /// tab 间隔
  final double? tabPadding;

  /// indicator 颜色
  final Color? tabIndicatorColor;

  /// indicator 高度
  final double? tabIndicatorHeight;

  /// label 文字大小
  final double? labelTextSize;

  /// 选中 label 颜色
  final Color? selectedLabelColor;

  /// 未选中 label 颜色
  final Color? unselectedLabelColor;

  /// item 头部高度
  final double? itemHeadHeight;

  /// item 头部背景颜色
  final Color? itemHeadBackgroundColor;

  /// item 头部分割线颜色
  final Color? itemHeadLineColor;

  /// item 头部分割线高度
  final double? itemHeadLineHeight;

  /// item 头部文字样式
  final TextStyle? itemHeadTextStyle;

  /// item 高度
  final double? itemHeight;

  /// 索引组件宽度
  final double? indexBarWidth;

  /// 索引组件 item 高度
  final double? indexBarItemHeight;

  /// 索引组件背景颜色
  final Color? indexBarBackgroundColor;

  /// 索引组件文字样式
  final TextStyle? indexBarTextStyle;

  /// 选中城市的图标组件
  final Widget? itemSelectedIconWidget;

  /// 选中城市文字样式
  final TextStyle? itemSelectedTextStyle;

  /// 未选中城市文字样式
  final TextStyle? itemUnSelectedTextStyle;

  /// 当前页面
  final postal_page.Page page;

  const PostalPickerWidget({
    Key? key,
    this.height,
    this.titleHeight,
    this.corner,
    this.backgroundColor,
    this.paddingLeft,
    this.titleWidget,
    this.selectText,
    this.closeWidget,
    this.tabHeight,
    this.showTabIndicator,
    this.tabPadding,
    this.tabIndicatorColor,
    this.tabIndicatorHeight,
    this.labelTextSize,
    this.selectedLabelColor,
    this.unselectedLabelColor,
    this.itemHeadHeight,
    this.itemHeadBackgroundColor,
    this.itemHeadLineColor,
    this.itemHeadLineHeight,
    this.itemHeadTextStyle,
    this.itemHeight,
    this.indexBarWidth,
    this.indexBarItemHeight,
    this.indexBarBackgroundColor,
    this.indexBarTextStyle,
    this.itemSelectedIconWidget,
    this.itemSelectedTextStyle,
    this.itemUnSelectedTextStyle,
    required this.page,
  }) : super(key: key);

  @override
  State<PostalPickerWidget> createState() => _PostalPickerWidgetState();
}

class _PostalPickerWidgetState extends State<PostalPickerWidget>
    with TickerProviderStateMixin {
  // 定义页面需要的所有信息，使用信息的方法
  late postal_page.Page page;

  late TabController _tabController;
  late PageController _pageController;
  int _currentIndex = 0;

  void pickPostal(Postal postal) {
    setState(() {
      final over = page.pick(postal);
      final numberOfTabsIfOptional = page.numberOfTabsIfOptional;
      _tabController = TabController(
          length: numberOfTabsIfOptional,
          vsync: this,
          initialIndex: numberOfTabsIfOptional - 1);
      _pageController.animateToPage(numberOfTabsIfOptional - 1,
          duration: const Duration(milliseconds: 10), curve: Curves.linear);
      _currentIndex = numberOfTabsIfOptional - 1;
      if (over) {
        page.callback(page);
        Navigator.of(context).pop();
        return;
      }
    });
    return;
  }

  @override
  void initState() {
    super.initState();
    page = widget.page;

    final numberOfTabsIfOptional = page.numberOfTabsIfOptional;
    _tabController = TabController(
        length: numberOfTabsIfOptional,
        vsync: this,
        initialIndex: numberOfTabsIfOptional - 1);
    _pageController = PageController(initialPage: numberOfTabsIfOptional - 1);
    _currentIndex = numberOfTabsIfOptional - 1;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: widget.height,
        child: Column(
          children: [
            _topTextWidget(),
            Expanded(
              child: Column(
                children: [
                  _middleTabWidget(),
                  Expanded(child: _bottomListWidget())
                ],
              ),
            )
          ],
        ));
  }

  /// 头部文字组件
  Widget _topTextWidget() {
    return Container(
      height: widget.titleHeight,
      decoration: BoxDecoration(
        color:
            widget.backgroundColor ?? Theme.of(context).dialogBackgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(widget.corner!),
          topRight: Radius.circular(widget.corner!),
        ),
      ),
      child: Row(
        children: [
          SizedBox(width: widget.paddingLeft),
          widget.titleWidget ??
              const Text(
                '请选择所在地区',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
          Expanded(child: Container()),
          InkWell(
              onTap: () => Navigator.pop(context),
              child: SizedBox(
                width: widget.titleHeight,
                height: double.infinity,
                child: widget.closeWidget ?? const Icon(Icons.close, size: 26),
              )),
        ],
      ),
    );
  }

  /// 中间 tab 组件
  Widget _middleTabWidget() {
    return Container(
      width: double.infinity,
      height: widget.tabHeight,
      color: widget.backgroundColor ?? Theme.of(context).dialogBackgroundColor,
      child: TabBar(
        controller: _tabController,
        onTap: (index) {
          _currentIndex = index;
          if (mounted) {
            setState(() {});
          }
          _pageController.animateToPage(_currentIndex,
              duration: const Duration(milliseconds: 10), curve: Curves.linear);
        },
        isScrollable: true,
        indicatorSize: TabBarIndicatorSize.tab,
        tabAlignment: TabAlignment.start,
        padding:
            EdgeInsets.only(left: widget.paddingLeft! - widget.tabPadding! / 2),
        indicatorPadding: EdgeInsets.only(
          left: widget.tabPadding! / 2,
          right: widget.tabPadding! / 2,
        ),
        labelPadding: EdgeInsets.only(
          left: widget.tabPadding! / 2,
          right: widget.tabPadding! / 2,
        ),
        dividerHeight: 0,
        indicator: widget.showTabIndicator!
            ? UnderlineTabIndicator(
                borderSide: BorderSide(
                  width: widget.tabIndicatorHeight!,
                  color: widget.tabIndicatorColor ??
                      Theme.of(context).primaryColor,
                ),
              )
            : const BoxDecoration(),
        indicatorColor:
            widget.tabIndicatorColor ?? Theme.of(context).primaryColor,
        unselectedLabelColor: widget.unselectedLabelColor ?? Colors.black54,
        labelColor: widget.selectedLabelColor ?? Theme.of(context).primaryColor,
        tabs: page.tabTitles.map((tabTitles) {
          final (_, title) = tabTitles;
          return Text(
            title,
            style: TextStyle(fontSize: widget.labelTextSize),
          );
        }).toList(),
      ),
    );
  }

  /// 底部城市列表组件
  Widget _bottomListWidget() {
    return PageView(
      controller: _pageController,
      onPageChanged: (index) {
        _currentIndex = index;
        if (mounted) {
          setState(() {});
        }
        _tabController.animateTo(_currentIndex);
      },
      children: page.tabOptions.map((e) {
        final (index, postal, options) = e;
        return PostalListWidget(
          height: widget.height! - widget.titleHeight! - widget.tabHeight!,
          index: index,
          title: postal.isNotEmpty ? postal.name : "",
          selectText: widget.selectText,
          backgroundColor: widget.backgroundColor,
          paddingLeft: widget.paddingLeft,
          itemHeadHeight: widget.itemHeadHeight,
          itemHeadBackgroundColor: widget.itemHeadBackgroundColor,
          itemHeadLineColor: widget.itemHeadLineColor,
          itemHeadLineHeight: widget.itemHeadLineHeight,
          itemHeadTextStyle: widget.itemHeadTextStyle,
          itemHeight: widget.itemHeight,
          indexBarWidth: widget.indexBarWidth,
          indexBarItemHeight: widget.indexBarItemHeight,
          indexBarBackgroundColor: widget.indexBarBackgroundColor,
          indexBarTextStyle: widget.indexBarTextStyle,
          itemSelectedIconWidget: widget.itemSelectedIconWidget,
          itemSelectedTextStyle: widget.itemSelectedTextStyle,
          itemUnSelectedTextStyle: widget.itemUnSelectedTextStyle,
          options: options,
          onPickPostal: (postal) => pickPostal(postal),
        );
      }).toList(),
    );
  }
}
