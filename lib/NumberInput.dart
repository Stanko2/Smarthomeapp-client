import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// ignore: must_be_immutable
class NumberInput extends StatefulWidget {
  int value;
  final int min;
  final int max;
  final ValueChange onChange;
  NumberInput({Key key, this.min = 17, this.max = 30, this.value = 24, @required this.onChange}) : super(key: key);

  @override
  _NumberInputState createState() => _NumberInputState();
}

typedef void ValueChange(int value);

class _NumberInputState extends State<NumberInput> {
  int value;
  @override
  void initState() { 
    super.initState();
    value = widget.value;
  }
  @override
  Widget build(BuildContext context) {
    return Container(
       child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.keyboard_arrow_down,
              size: 25,
            ),
            onPressed: () => setValue(-1),
          ),
          Text(value.toString()),
          IconButton(
            icon: Icon(
              Icons.keyboard_arrow_up,
              size: 25,
            ),
            onPressed: () => setValue(1),
          ),
        ],
      ),
    );
  }

  void setValue(int valueChange){
    setState(() {
      if(value + valueChange >= widget.min && value + valueChange <= widget.max){
        value += valueChange; 
        widget.value = value;
        widget.onChange(value);
      }
    });
  }
}