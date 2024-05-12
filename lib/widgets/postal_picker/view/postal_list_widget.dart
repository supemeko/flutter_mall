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

import 'dart:math';

import 'package:flutter/material.dart';

import '../table/table_postal.dart';
import 'third_listview_section.dart';
import "package:collection/collection.dart";

/// 邮递区域列表组件
class PostalListWidget extends StatefulWidget {
  final double? height;

  /// 当前列表的索引
  final int? index;

  /// 选中 tab
  final String? title;

  /// 选择文字
  final String? selectText;

  /// 背景颜色
  final Color? backgroundColor;

  /// 左边间距
  final double? paddingLeft;

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

  /// 可选择的项（邮递区域）
  final List<Postal> options;

  /// 选择某个项
  final void Function(Postal postal) onPickPostal;

  const PostalListWidget({
    Key? key,
    this.height,
    this.index,
    this.title,
    this.selectText,
    this.backgroundColor,
    this.paddingLeft,
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
    required this.options,
    required this.onPickPostal,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => PostalListWidgetState();
}

class _PostalListGroupByFirstLetter implements ExpandableListSection<Postal> {
  String firstLetter;

  List<Postal> postalList;

  _PostalListGroupByFirstLetter({
    required this.firstLetter,
    required this.postalList,
  });

  @override
  List<Postal>? getItems() {
    return postalList;
  }

  @override
  bool isSectionExpanded() {
    return true;
  }

  @override
  void setSectionExpanded(bool expanded) {}
}

class PostalListWidgetState extends State<PostalListWidget>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();

  late String? _title = widget.title ?? widget.selectText ?? "请选择";

  /// 邮递区域选项
  List<Postal> _options = [];

  /// 邮递区域选项首字母分组
  List<_PostalListGroupByFirstLetter> _optionsGroupByFirstLetter = [];

  /// 回调函数
  late void Function(Postal postal) onPickPostal;

  @override
  void initState() {
    super.initState();

    _calculateOptionsGroupBy();
    onPickPostal = widget.onPickPostal;
  }

  @override
  void dispose() {
    if (mounted) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PostalListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.options != widget.options) {
      _calculateOptionsGroupBy();
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _calculateOptionsGroupBy() {
    _options = widget.options ?? [];
    _optionsGroupByFirstLetter = groupBy(_options, (p0) => p0.firstLetter)
        .entries
        .map((e) => _PostalListGroupByFirstLetter(
            firstLetter: e.key, postalList: e.value))
        .sorted((a, b) => a.firstLetter.compareTo(b.firstLetter))
        .toList();
  }

  /// 点击索引，列表滑动
  void clickIndexBar(int index) {
    if (index == 0) {
      _scrollController.jumpTo(0);
      return;
    }

    final groupIndex = index;
    final itemIndex = _optionsGroupByFirstLetter.sublist(0, index).fold(0,
        (previousValue, element) => previousValue + element.postalList.length);
    final position =
        widget.itemHeadHeight! * groupIndex + widget.itemHeight! * itemIndex;
    _scrollController.jumpTo(position);
  }

  /// 获取索引
  int _getIndex(double offset) {
    double h = (widget.height! -
            (_optionsGroupByFirstLetter.length * widget.indexBarItemHeight! +
                4)) /
        2;
    int index = (offset - h) ~/ widget.indexBarItemHeight!;
    return min(index, _optionsGroupByFirstLetter.length - 1);
  }

  /// 点击区域
  RenderBox? _getRenderBox(BuildContext context) {
    RenderObject? renderObject = context.findRenderObject();
    RenderBox? box;
    if (renderObject != null) {
      box = renderObject as RenderBox;
    }
    return box;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: widget.backgroundColor ?? Theme.of(context).dialogBackgroundColor,
      child: Stack(
        children: [
          ExpandableListView(
            controller: _scrollController,
            builder: SliverExpandableChildDelegate(
              sectionList: _optionsGroupByFirstLetter,
              headerBuilder: (context, sectionIndex, index) {
                return Container(
                  width: double.infinity,
                  height: widget.itemHeadHeight,
                  decoration: BoxDecoration(
                    border: Border(
                        bottom: BorderSide(
                      width: widget.itemHeadLineHeight!,
                      color: widget.itemHeadLineColor ?? Colors.black38,
                    )),
                    color: widget.itemHeadBackgroundColor ??
                        Theme.of(context).dialogBackgroundColor,
                  ),
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.only(left: widget.paddingLeft!),
                  child: Text(
                    _optionsGroupByFirstLetter[sectionIndex].firstLetter,
                    style: widget.itemHeadTextStyle ??
                        const TextStyle(fontSize: 15, color: Colors.black),
                  ),
                );
              },
              itemBuilder: (context, sectionIndex, itemIndex, index) {
                Postal postal = _optionsGroupByFirstLetter[sectionIndex]
                    .postalList[itemIndex];
                bool isSelect = postal.name == _title;
                return InkWell(
                  onTap: () {
                    _title = postal.name;
                    if (mounted) {
                      setState(() {});
                    }
                    onPickPostal(postal);
                  },
                  child: Container(
                    width: double.infinity,
                    height: widget.itemHeight,
                    padding: EdgeInsets.only(left: widget.paddingLeft!),
                    alignment: Alignment.centerLeft,
                    child: Row(children: [
                      Offstage(
                        offstage: !isSelect,
                        child: widget.itemSelectedIconWidget ??
                            Icon(Icons.done,
                                color: Theme.of(context).primaryColor,
                                size: 16),
                      ),
                      SizedBox(width: isSelect ? 3 : 0),
                      Text(postal.name,
                          style: isSelect
                              ? widget.itemSelectedTextStyle ??
                                  TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                  )
                              : widget.itemUnSelectedTextStyle ??
                                  const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ))
                    ]),
                  ),
                );
              },
            ),
          ),
          Positioned(
            right: widget.paddingLeft,
            top: 0,
            bottom: 0,
            child: SizedBox(
              width: widget.indexBarWidth,
              child: GestureDetector(
                onVerticalDragDown: (DragDownDetails details) {
                  RenderBox? box = _getRenderBox(context);
                  if (box == null) return;
                  int index = _getIndex(details.localPosition.dy);
                  if (index >= 0) {
                    clickIndexBar(index);
                  }
                },
                onVerticalDragUpdate: (DragUpdateDetails details) {
                  int index = _getIndex(details.localPosition.dy);
                  if (index >= 0) {
                    clickIndexBar(index);
                  }
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children:
                      List.generate(_optionsGroupByFirstLetter.length, (index) {
                    return _indexBarItem(index);
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _indexBarItem(int index) {
    // 有4种类型
    int type = 0;
    if (index == 0 && index == _optionsGroupByFirstLetter.length - 1) {
      // 只有1个
      type = 1;
    } else if (index == 0) {
      // 顶部
      type = 2;
    } else if (index == _optionsGroupByFirstLetter.length - 1) {
      // 底部
      type = 3;
    } else {
      // 中间
      type = 4;
    }
    return Container(
      width: widget.indexBarWidth,
      height: (index == 0 || index == _optionsGroupByFirstLetter.length - 1)
          ? widget.indexBarItemHeight! + 2
          : widget.indexBarItemHeight!,
      alignment: Alignment.center,
      padding: type == 2
          ? const EdgeInsets.only(top: 1)
          : type == 3
              ? const EdgeInsets.only(bottom: 1)
              : const EdgeInsets.all(0),
      decoration: BoxDecoration(
        color: widget.indexBarBackgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: (type == 1 || type == 2)
              ? const Radius.circular(50)
              : const Radius.circular(0),
          topRight: (type == 1 || type == 2)
              ? const Radius.circular(50)
              : const Radius.circular(0),
          bottomLeft: (type == 1 || type == 3)
              ? const Radius.circular(50)
              : const Radius.circular(0),
          bottomRight: (type == 1 || type == 3)
              ? const Radius.circular(50)
              : const Radius.circular(0),
        ),
      ),
      child: Text(
        _optionsGroupByFirstLetter[index].firstLetter,
        style: widget.indexBarTextStyle ??
            const TextStyle(fontSize: 14, color: Colors.black54),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
