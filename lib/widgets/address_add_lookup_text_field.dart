import 'package:flutter/material.dart';

class LookupTextField extends StatefulWidget {
  final Function(String) onLookupText;

  const LookupTextField({super.key, required this.onLookupText});

  @override
  State<LookupTextField> createState() => _LookupTextFieldState();
}

class _LookupTextFieldState extends State<LookupTextField> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isTyping = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _textController,
          maxLines: _isTyping ? 3 : 2,
          decoration: const InputDecoration(
            hintText: '尝试粘贴收件人姓名、手机号、收货地址、可快速识别您的收货信息',
          ),
          focusNode: _focusNode,
        ),
        Visibility(
          visible: _isTyping,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _textController.text = '';
                  });
                },
                child: const Text('清除'),
              ),
              ElevatedButton(
                onPressed: () {
                  widget.onLookupText(_textController.text);
                  FocusScope.of(context).unfocus();
                },
                child: const Text('提交'),
              )
            ],
          ),
        ),
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: 5),
            padding: const EdgeInsets.all(5),
            child: const Text("地址粘贴板",
                style: TextStyle(fontSize: 15, color: Colors.blueGrey)),
          ),
        ),
      ],
    );
  }
}
