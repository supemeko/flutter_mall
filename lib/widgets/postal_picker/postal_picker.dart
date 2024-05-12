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
import 'package:flutter_mall/widgets/postal_picker/view/postal_picker_widget.dart';
import 'model/page.dart' as postal_page;

/// 外部调用
class PostalPicker {
  /// 展示
  static void show({
    required BuildContext context,
    AnimationController? animController,
    // 背景透明度
    double opacity = 0.5,
    // 点击外部是否消失
    bool dismissible = true,
    // 高度
    double height = 500.0,
    // 标题高度
    double titleHeight = 50.0,
    // 顶部圆角
    double corner = 20.0,
    // 背景颜色
    Color? backgroundColor,
    // 距离左边的间距
    double paddingLeft = 15.0,
    // 标题组件
    Widget? titleWidget,
    // 选择文字
    String? selectText,
    // 关闭图标组件
    Widget? closeWidget,
    // tab 高度
    double tabHeight = 40.0,
    // 是否显示指示器
    bool showTabIndicator = true,
    // tab 间隔
    double tabPadding = 10.0,
    // 指示器颜色
    Color? tabIndicatorColor,
    // 指示器高度
    double tabIndicatorHeight = 3.0,
    // tab 字体大小
    double labelTextSize = 15.0,
    // tab 选中的字体颜色
    Color? selectedLabelColor,
    // tab 未选中的字体颜色
    Color? unselectedLabelColor,
    // item 头部高度
    double itemHeadHeight = 30.0,
    // item 头部背景颜色
    Color? itemHeadBackgroundColor,
    // item 头部分割线颜色
    Color? itemHeadLineColor,
    // item 头部分割线高度
    double itemHeadLineHeight = 0.1,
    // item 头部文字样式
    TextStyle? itemHeadTextStyle,
    // item 高度
    double itemHeight = 40.0,
    // 索引组件宽度
    double indexBarWidth = 28,
    // 索引组件 item 高度
    double indexBarItemHeight = 20,
    // 索引组件背景颜色
    Color indexBarBackgroundColor = Colors.black12,
    // 索引组件文字样式
    TextStyle? indexBarTextStyle,
    // 列表选中的图标组件
    Widget? itemSelectedIconWidget,
    // 列表选中的文字样式
    TextStyle? itemSelectedTextStyle,
    // 列表未选中的文字样式
    TextStyle? itemUnSelectedTextStyle,

    /// page
    required postal_page.Page page,
  }) {
    showModalBottomSheet(
        context: context,
        backgroundColor: backgroundColor,
        isScrollControlled: true,
        isDismissible: dismissible,
        barrierColor: Colors.black.withOpacity(opacity),
        transitionAnimationController: animController,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(corner),
            topRight: Radius.circular(corner),
          ),
        ),
        builder: (BuildContext context) {
          return PostalPickerWidget(
            height: height,
            titleHeight: titleHeight,
            corner: corner,
            backgroundColor: backgroundColor,
            paddingLeft: paddingLeft,
            titleWidget: titleWidget,
            selectText: selectText,
            closeWidget: closeWidget,
            tabHeight: tabHeight,
            showTabIndicator: showTabIndicator,
            tabPadding: tabPadding,
            tabIndicatorColor: tabIndicatorColor,
            tabIndicatorHeight: tabIndicatorHeight,
            labelTextSize: labelTextSize,
            selectedLabelColor: selectedLabelColor,
            unselectedLabelColor: unselectedLabelColor,
            itemHeadHeight: itemHeadHeight,
            itemHeadBackgroundColor: itemHeadBackgroundColor,
            itemHeadLineColor: itemHeadLineColor,
            itemHeadLineHeight: itemHeadLineHeight,
            itemHeadTextStyle: itemHeadTextStyle,
            itemHeight: itemHeight,
            indexBarWidth: indexBarWidth,
            indexBarItemHeight: indexBarItemHeight,
            indexBarBackgroundColor: indexBarBackgroundColor,
            indexBarTextStyle: indexBarTextStyle,
            itemSelectedIconWidget: itemSelectedIconWidget,
            itemSelectedTextStyle: itemSelectedTextStyle,
            itemUnSelectedTextStyle: itemUnSelectedTextStyle,
            page: page,
          );
        });
  }
}
