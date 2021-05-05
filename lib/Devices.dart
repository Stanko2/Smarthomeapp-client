import 'package:flutter/material.dart';
import 'package:smart_home_app/main.dart';
import 'package:smart_home_app/RequestHandler.dart';
import 'package:smart_home_app/Fold.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:smart_home_app/NumberInput.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import 'package:icons_helper/icons_helper.dart';

// ignore: must_be_immutable
class Device extends StatefulWidget {
  final _foldingCellKey = GlobalKey<SimpleFoldingCellState>();
  final String name;
  DeviceProperties typeInfo;
  final double controlsHeight;
  final DeviceStatus status;
  bool isOn = false;
  bool unfolded = false;
  Device({
    @required this.name,
    @required this.typeInfo,
    this.controlsHeight = 200,
    this.isOn,
    this.status
  });
  static var devices = <int, DeviceProperties> {
    1: DeviceProperties(type: 1, deviceIcon: Icons.ac_unit, typeName: "Klimatizacia", controlWidgetHeight: 50),
    0: DeviceProperties(type: 0, deviceIcon: Icons.lightbulb_outline, typeName: "Lampa", controlWidgetHeight: 122),
    2: DeviceProperties(type: 2, deviceIcon: Icons.fiber_manual_record_rounded, typeName: "", controlWidgetHeight: 200),
  };
  @override
  _DeviceState<Device> createState() => new _DeviceState<Device>();
}

class _DeviceState<T extends Device> extends State<T>  {
  
  Color iconColor = Colors.red;
  Color pickerColor;
  double controlsHeight;
  Future<void> pendingChanges;
  Timer timer;

  Future<int> initControls() async{
    iconColor = widget.status.isOn ? Colors.green : Colors.red;
    return 0;
  }

  @override
  void initState() { 
    super.initState();
    pendingChanges = initControls();
    if(kIsWeb){
      widget._foldingCellKey?.currentState?.toggleFold();
      widget.unfolded = true;
    }
    // timer = Timer.periodic(new Duration(seconds: 10), (timer){pendingChanges = update(timer);});
  }
  
  @override
  Widget build(BuildContext context){
    controlsHeight = widget.controlsHeight;
    var foldingCell = SimpleFoldingCell(
      frontWidget: buildFront(context),
      padding: EdgeInsets.only(bottom: 5),
      innerBottomWidget: buildInner(context),
      innerTopWidget: buildFront(context),
      key: widget._foldingCellKey,
      animationDuration: Duration(milliseconds: 300),
      cellSize: Size(MediaQuery.of(context).size.width, 70),
      onClose: () => foldChanged(false),
      onOpen: () => foldChanged(true),
      innerHeight: controlsHeight,
    );
    var webContainer = Container(
      child: Column(
        children: [
          buildFront(context),
          buildInner(context)
        ],
      ),
    );
    var opacity = 0.25;
    if(widget.status != null){
      opacity = widget.status.online ? 1 : 0.25;
    }
    return Card(
      margin: EdgeInsets.all(5),
      child: InkWell(
        child: Opacity(
          opacity: opacity,
          child: kIsWeb ? webContainer : foldingCell,
        ),
        onTap: (){
          if(kIsWeb) return;
          widget._foldingCellKey?.currentState?.toggleFold();
          widget.unfolded = !widget.unfolded;
        },  
      ) 
    );
  }
  Widget buildInner(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(5),
      child: Visibility(
        visible: widget.unfolded,
        child: ClipRect(
          child: buildControls(context, widget.status),
        )
      )
    );
  }
  Widget buildControls(BuildContext context, DeviceStatus status){
    return Text("Device Controls");
  } 

  Widget buildFront(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children:[
              Container(
                padding: EdgeInsets.all(4),
                child: Icon(
                  widget.typeInfo.deviceIcon,
                  size: 70,
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name,
                      textAlign: TextAlign.right,
                      style: Theme.of(context).primaryTextTheme.headline6,
                    ),
                    Text(
                      widget.typeInfo.typeName,
                      textAlign: TextAlign.right,
                      style: Theme.of(context).primaryTextTheme.caption,
                    )
                  ],
                ),
              ),
            ]
          )
        ),
        buildFrontControls(context)
      ],
    );
  }

  Widget buildFrontControls(BuildContext context) {
    return FutureBuilder(
      future: pendingChanges,
      builder: (context, snapshot){
        switch(snapshot.connectionState){
          case ConnectionState.done:
            return IconButton(
                  onPressed: widget.status.online ? () => switchChanged(!widget.status.isOn) : null,
                  alignment: Alignment.center,
                  icon: Icon(
                    Icons.power_settings_new,
                    color: iconColor,
                  ),
            );
          default:
            return CircularProgressIndicator();
        }
      },
    //
    );
  }
  void foldChanged(bool fold){
    setState(() {
      widget.unfolded = fold;  
    });
  }
  void switchChanged(bool value){
    setState(() {
      widget.status.isOn = value;
      if(!value && widget.unfolded){
        widget._foldingCellKey?.currentState?.toggleFold();
      }
      // widget.status.applyChanges(context);
      pendingChanges = stageChanges().then((value) => setState((){
        iconColor = widget.status.isOn ? Colors.green : Colors.red;
      }));
    });
  }
  Future<void> stageChanges() async{
    try {
      var newStatus = await widget.status.applyChanges();
      setState(() {
        widget.status.update(newStatus);
      });
      return;
    }catch(e){
      ScaffoldMessenger.of(context).showSnackBar (SnackBar(content: Text(e.toString())));
    }
  }
  Future<void> update(Timer timer) async{
    if(widget.status == null){
      return;
    }
    await RequestHandler().updateDevice(widget.status);
    setState(() {});
  }
  @override
  void dispose(){
    timer?.cancel();
    super.dispose();
  }
}

class DeviceProperties{
  int type;
  IconData deviceIcon;
  String typeName;
  final double controlWidgetHeight;
  DeviceProperties({
    @required this.type,
    @required this.deviceIcon,
    this.typeName,
    this.controlWidgetHeight});
}

class DropdownItem extends StatelessWidget {
  final String name;
  final IconData icon;
  const DropdownItem({Key key, @required this.icon, @required this.name}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(3),
          child: Icon(
            icon,
            size: 25,
          ),
        ),
        Text(
          name,
          style: Theme.of(context).primaryTextTheme.subtitle1,
        )
      ],
    );
  }
}

class CustomDevice extends Device {
  final int type;
  CustomDevice({
    CustomDeviceStatus status,
    String name,
    bool isOn,
    this.type,
    double controlsHeight,
  }) : super(name: name,isOn: isOn, typeInfo: Device.devices[2], controlsHeight: controlsHeight, status: status);
  @override
  _CustomDeviceState createState() => new _CustomDeviceState();
}

class _CustomDeviceState extends _DeviceState<CustomDevice>{
  Future<Map<String, dynamic>> controls;

  @override
  void initState() {
    if(!MyApp.cachedControls.keys.contains(widget.type)){
      controls = RequestHandler().fetchControls(widget.status.id);
    }
    super.initState();
  }

  @override 
  Widget buildFront(BuildContext context) {
    if(MyApp.cachedControls[widget.type] == null){
      return FutureBuilder(
        future: controls,
        builder: (context, snapshot){
          if(snapshot.connectionState == ConnectionState.done){
            if(snapshot.hasError){
              return Text(snapshot.error);
            }
            MyApp.cachedControls[widget.type] = snapshot.data;
            var data = snapshot.data['typeInfo'];
            widget.typeInfo = DeviceProperties(type: 2, deviceIcon: getIconUsingPrefix(name: data['icon']), typeName: data['name'], controlWidgetHeight: 0);
            return super.buildFront(context);
          }
          else return new CircularProgressIndicator();
      });
    }
    else{
      var data = MyApp.cachedControls[widget.type]['typeInfo'];
      widget.typeInfo = DeviceProperties(type: 2, deviceIcon: getIconUsingPrefix(name: data['icon']), typeName: data['name'], controlWidgetHeight: 0);
      return super.buildFront(context);
    }
  }

  @override
  Widget buildControls(BuildContext context, DeviceStatus status){
    return CustomControls(type: widget.type, controls: controls, status: widget.status, apply: () async { await widget.status.applyChanges();},);
  }

}

class CustomControls extends StatefulWidget {
  final int type;
  final Future<Map<String, dynamic>> controls;
  final CustomDeviceStatus status;
  final Function() apply;
  CustomControls({this.type, this.controls, this.status, this.apply,}):super();
  @override
  _CustomControlsState createState() => _CustomControlsState();
}

class _CustomControlsState extends State<CustomControls> {
  @override
  Widget build(BuildContext context) {
    if(MyApp.cachedControls[widget.type] == null){
      return FutureBuilder(
          future: widget.controls,
          builder: (context, snapshot){
            if(snapshot.connectionState == ConnectionState.done){
              if(snapshot.hasError){
                return Text(snapshot.error);
              }
              MyApp.cachedControls[widget.type] = snapshot.data;
              return Column(
                children: getControlWidgets(snapshot.data['mainControls']),
              );
            }
            else return new CircularProgressIndicator();
          });
    }
    else{
      return Column(
        children: getControlWidgets(MyApp.cachedControls[widget.type]['mainControls'])
      );
    }
  }

  List<Widget> getControlWidgets(List<dynamic> controls){
    var out = <Widget>[];
    var textStyle = Theme.of(context).primaryTextTheme.subtitle1;
    controls.forEach((dynamic control) {
      String type = control['type'];
      Row w = Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(control['label'], style: textStyle,),
          ),
        ],
      );
      if(!widget.status.props.containsKey(control['property'])){
        widget.status.props[control['property']] = control['default'];
      }
      switch(type){
        case "Button":{
          w.children.add(createButton(control));
          break;
        }
        case "Range":{
          w.children.add(createSlider(control));
          break;
        }
        case "Switch":{
          w.children.add(createSwitch(control));
          break;
        }
        case "Color":{
          w.children.add(createColorPicker(control));
          break;
        }
        case "Number":{
          w.children.add(createNumberInput(control));
          break;
        }
        case "Option":{
          w.children.add(createDropdown(control));
          break;
        }
        default:
          {
            out.add(Text("Invalid Control Type"));
          }
      }
      out.add(w);
    });
    return out;
  }
  Widget createSlider(Map<String, dynamic> data){
    // return Slider(
    //   value: (widget.status).props[data['property']].toDouble(),
    //   onChanged: (e){setState(() {
    //     (widget.status).props[data['property']] = e;
    //     if(widget.apply) widget.status.applyChanges(context);
    //   });},
    //   min: data['min'].toDouble(),
    //   max: data['max'].toDouble(),
    // );
    var width = MediaQuery.of(context).size.width;
    var columns = (MediaQuery.of(context).size.width * MediaQuery.of(context).devicePixelRatio / 500).ceil();
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
          constraints: BoxConstraints(maxWidth: kIsWeb ? width * .75 / columns : width * .75),
          child: Slider(
            max: 100,
            min: 0,
            value: (widget.status).props[data['property']].toDouble(),
            onChanged: (value) {
              setState(() {
                (widget.status).props[data['property']] = value;
                widget.status.updatedProps.add(data['property']);
              });
            },
            onChangeEnd: (value) {
              widget.apply().then((newStatus){
                setState(() {});
              });
            }
          ),
        ),
        // Container(
        //   width: width * (13/100),
        //   child: Text(
        //     (widget.status).props[data['property']].toString().length < 5 ? (widget.status).props[data['property']].toString() : (widget.status).props[data['property']].toString().substring(0,5) + "%",
        //     style: Theme.of(context).primaryTextTheme.caption,
        //   )
        // )
      ],
    );
  }
  Widget createSwitch(Map<String, dynamic> data){
    return Switch(
      value: (widget.status).props[data['property']],
      onChanged: (e){setState(() {
        (widget.status).props[data['property']] = e;
        widget.status.updatedProps.add(data['property']);
        widget.apply();
      });},
    );
  }
  Widget createColorPicker(Map<String, dynamic> data){
    var c = widget.status.props[data['property']];
    assert(c['r']!=null);
    assert(c['g']!=null);
    assert(c['b']!=null);
    var color = Color.fromRGBO(c['r'], c['g'], c['b'], 1);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: RaisedButton(
        color: color, 
        onPressed: () => showColorDialog(color, data['property']),
        shape: CircleBorder(side: BorderSide(width: 2)),
      ),
    );
  }

  void showColorDialog(Color color, String property){
    var selectedColor = color;
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Pick a Color'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: SingleChildScrollView(
              padding: EdgeInsets.all(2),
              child: ColorPicker(
                pickerColor: color,
                onColorChanged: (c){
                  setState(() {
                    selectedColor = c;
                  });
                },
                enableAlpha: false,
              ),
            ),
            actions: <Widget>[
              FlatButton(
                child: const Text("Select"),
                onPressed: (){
                  setState(() {
                    widget.status.props[property] = {
                      'r': selectedColor.red,
                      'g': selectedColor.green,
                      'b': selectedColor.blue
                    };
                    widget.status.updatedProps.add(property);
                    widget.apply();
                  });
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        }
    );
  }

  Widget createNumberInput(Map<String, dynamic> data){
    return NumberInput(
      value: (widget.status).props[data['property']],
      onChange: (e){setState(() {
        (widget.status).props[data['property']] = e;
        widget.status.updatedProps.add(data['property']); 
        widget.apply();
      });},
      min: data['min'],
      max: data['max'],
    );
  }

  Widget createDropdown(Map<String, dynamic> data){
    var items = <DropdownMenuItem<dynamic>>[];
    data['items'].forEach((item){
      items.add(DropdownMenuItem(
        child: item['iconName'] == null ? Text(item['name']) : DropdownItem(icon: getIconUsingPrefix(name: item['iconName']), name: item['name']),
        value: item['value'] != null ? item['value'] : item['name'],
      ));
    });
    return DropdownButton(
      items: items,
      value: (widget.status).props[data['property']],
      onChanged: (e){
        setState(() {
          (widget.status).props[data['property']] = e;
          widget.status.updatedProps.add(data['property']);
          widget.apply();
        });
      },
    );
  }

  Widget createButton(Map<String, dynamic> data){
    Color color = data['color'] == null ? Theme.of(context).colorScheme.secondary : Color.fromARGB(1,data['color']['r'], data['color']['g'], data['color']['b']);
    return data['icon'] != null ? FlatButton.icon(
      onPressed: () => RequestHandler.postRequest('change/${data['event']}', {'id': widget.status.id}), 
      icon: Icon(getIconUsingPrefix(name: data['icon'])),
      color: color,
      label: Container(),) : FlatButton(
        onPressed: () => RequestHandler.postRequest('change/${data['event']}', {'id': widget.status.id}), 
        child: Text(data['buttonLabel'] == null ? 'Button' : data['buttonLabel']),
        color: color,
      );
  }
}
