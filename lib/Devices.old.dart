// // ignore: must_be_immutable
// class Light extends Device{
//   Light({
//     LightStatus status,
//     String name,
//     bool isOn
//   }) : super(name: name,isOn: isOn, typeInfo: Device.devices[0], controlsHeight: 122, status: status);
//   @override
//   _LightState createState() => new _LightState();
// }

// class _LightState extends _DeviceState<Light>{
//   @override
//   Widget buildControls(BuildContext context, DeviceStatus status){
//     return LightControls(status: status);
//   }
// }

// class LightControls extends StatefulWidget {
//   LightStatus status;
//   final bool canApply;
//   LightControls({this.canApply = true, this.status, Key key}):super(key: key);
//   @override
//   _LightControlsState createState() => _LightControlsState();
// }

// class _LightControlsState extends State<LightControls> {
//   Color pickerColor;
//   @override
//   Widget build(BuildContext context) {
//     var textStyle = Theme.of(context).primaryTextTheme.subtitle1;
//     var columns;
//     if(kIsWeb) columns = (MediaQuery.of(context).size.width * MediaQuery.of(context).devicePixelRatio / 500).ceil();
//     else columns = (MediaQuery.of(context).size.width * MediaQuery.of(context).devicePixelRatio / 1500).ceil();
//     var width = MediaQuery.of(context).size.width / columns;
//     return Container(
//       padding: EdgeInsets.only(left: 5, right: 5),
//       child: Column(
//         children: [
//           Text("Intensity", textAlign: TextAlign.left, style: textStyle,),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.start,
//             children: [
//               Container(
//                 child: Slider(
//                   max: 100,
//                   min: 0,
//                   value: widget.status.intensity.toDouble(),
//                   onChanged: (value) {
//                     setState(() {
//                       widget.status.intensity = value.toDouble();
//                     });
//                   },
//                   onChangeEnd: (value) {
//                     if(widget.canApply)
//                       widget.status.applyChanges(context).then((newStatus){
//                         setState(() {
//                           var status = newStatus as LightStatus;
//                           widget.status.isOn = status.isOn;
//                           widget.status.intensity = status.intensity;
//                           widget.status.color = status.color;
//                         });
//                       });
//                   },
//                 ),
//                 width: width * (78/100),
//               ),
//               Container(
//                 width: width * (13/100),
//                 child: Text(
//                   (widget.status.intensity.toString().length < 5 ? widget.status.intensity.toString() : widget.status.intensity.toString().substring(0,5))+ "%",
//                   style: Theme.of(context).primaryTextTheme.caption,
//                 )
//               )
//             ],
//           ),
//           Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children:[
//                 Text("Farba", style: textStyle,),
//                 RaisedButton(color: widget.status.color, onPressed: showColorDialog,shape: CircleBorder(side: BorderSide(width: 2)),)
//               ]
//           )
//         ],
//       )
//     );
//   }
//   void showColorDialog(){
//     showDialog(
//         context: context,
//         builder: (BuildContext context) {
//           return AlertDialog(
//             title: const Text('Pick a Color'),
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//             content: SingleChildScrollView(
//               padding: EdgeInsets.all(2),
//               child: MaterialPicker(
//                 pickerColor: widget.status.color,
//                 onColorChanged: colorChanged,
//               ),
//             ),
//             actions: <Widget>[
//               FlatButton(
//                 child: const Text("Select"),
//                 onPressed: (){
//                   setState(() {
//                     widget.status.color = pickerColor;
//                     if(widget.canApply) {
//                       widget.status.applyChanges(context).then((newStatus){
//                         widget.status = newStatus as LightStatus;
//                       });
//                     }
//                   });
//                   Navigator.of(context).pop();

//                 },
//               )
//             ],
//           );
//         }
//     );
//   }

//   void colorChanged(Color value){
//     setState(() {
//       pickerColor = value;
//     });
//   }
// }

// // ignore: must_be_immutable
// class AirConditioner extends Device{
//   AirConditioner({
//     String name = "Klimatizacia",
//     bool isOn,
//     ACStatus status,
//   }):super(
//     name: name, 
//     typeInfo: Device.devices[1], 
//     controlsHeight: 346,
//     isOn: isOn,
//     status: status
//   );
//   @override
//   _AirConditionerState createState() => new _AirConditionerState();

// }

// class _AirConditionerState extends _DeviceState<AirConditioner>{

//   @override
//   Widget buildFrontControls(BuildContext context){
//     var parent = super.buildFrontControls(context);
//     ACStatus status = widget.status as ACStatus;
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.end,
//       children: status.isOn ? [
//         Row(
//           children: [
//             Text("${status.indoorTemp}°C",
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.w800
//               ),
//             ),
//             VerticalDivider(indent: 5,endIndent: 5,thickness: 3,),
//             Text("${status.outdoorTemp}°C",
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.w800
//               ),
//             )
//           ],
//         ),
//         parent,
//       ] : [parent],
//     );
//   }
//   @override
//   Widget buildControls(BuildContext context, DeviceStatus status) {
//     return AcControls(status: widget.status,);
//   }
// }
// class AcControls extends StatefulWidget {
//   final ACStatus status;
//   final bool canApply;
//   AcControls({Key key, this.status, this.canApply = true}):super(key: key);
//   @override
//   _AcControlsState createState() => _AcControlsState();
// }

// class _AcControlsState extends State<AcControls> {
//   ACmode modeDropDownValue;
//   ACFanSpeed fanDropdownValue;
//   ACSwingMode swing;
//   int targetTemp;
//   bool ecoMode;
//   bool turboMode;
//   bool isDirty = false;

//   @override
//   void initState() {
//     super.initState();
//     ACStatus status = widget.status;
//     ecoMode = status.ecoMode;
//     turboMode = status.turboMode;
//     modeDropDownValue = status.mode;
//     fanDropdownValue = status.fanSpeed;
//     swing = status.swingMode;
//     targetTemp = status.targetTemp;
//     isDirty = false;
//   }
//   @override
//   Widget build(BuildContext context) {
//     var textStyle = Theme.of(context).primaryTextTheme.subtitle1;
//     return Column(
//       children: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text("Mode", style: textStyle,),
//             DropdownButton(
//               onChanged: (value) {
//                 setState(() {
//                   modeDropDownValue = value;
//                   widget.status.mode = value;
//                   isDirty = true;
//                 });
//               },
//               items: <List<Object>>[
//                 [Icons.ac_unit, ACmode.cool],
//                 [Icons.wb_sunny, ACmode.heat],
//                 [Icons.invert_colors_off, ACmode.dry],
//                 [Icons.loop, ACmode.fan],
//                 [Icons.brightness_auto, ACmode.auto]
//               ]
//                   .map<DropdownMenuItem<ACmode>>((var value) {
//                 return DropdownMenuItem<ACmode>(
//                   child: DropdownItem(icon: value[0] as IconData,
//                       name: EnumToString.convertToString(value[1])),
//                   value: value[1],
//                 );
//               }).toList(),
//               value: widget.status.mode,
//               underline: Container(height: 2, color: Colors.lightBlue,),
//             )
//           ],
//         ),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text('Fan Speed', style: textStyle,),
//             DropdownButton(
//               value: widget.status.fanSpeed,
//               onChanged: (value) {
//                 setState(() {
//                   fanDropdownValue = value;
//                   widget.status.fanSpeed = value;
//                   isDirty = true;
//                 });
//               },
//               underline: Container(height: 2, color: Colors.lightBlue,),
//               items: ACFanSpeed.values.map<DropdownMenuItem<ACFanSpeed>>((
//                   ACFanSpeed value) {
//                 return DropdownMenuItem(
//                   value: value,
//                   child: Text(EnumToString.convertToString(value),
//                     style: textStyle,
//                 ));
//               }).toList(),
//             )
//           ],
//         ),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text('Target Temperature', style: textStyle,),
//             NumberInput(
//               value: widget.status.targetTemp,
//               onChange: (int value) {
//                 setState(() {
//                   targetTemp = value;
//                   widget.status.targetTemp = value;
//                   isDirty = true;
//                 });
//             })
//           ],
//         ),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text('ECO Mode', style: textStyle,),
//             Switch(
//               value: widget.status.ecoMode,
//               onChanged: (value) {
//                 setState(() {
//                   ecoMode = value;
//                   widget.status.ecoMode = value;
//                   isDirty = true;
//                 });
//               },
//             )
//           ],
//         ),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text('Turbo Mode', style: textStyle,),
//             Switch(
//               value: widget.status.turboMode,
//               onChanged: (value) {
//                 setState(() {
//                   turboMode = value;
//                   widget.status.turboMode = value;
//                   isDirty = true;
//                 });
//               },
//             )
//           ],
//         ),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text("Swing", style: textStyle,),
//             DropdownButton(
//                 items: [
//                   ACSwingMode.none,
//                   ACSwingMode.vertical,
//                   ACSwingMode.horizontal,
//                   ACSwingMode.both
//                 ].map<DropdownMenuItem<ACSwingMode>>((e) {
//                   return DropdownMenuItem(
//                       child: Text(EnumToString.convertToString(e), style: textStyle,),
//                       value: e,
//                   );
//                 }).toList(),
//                 onChanged: (value) {
//                   setState(() {
//                     swing = value;
//                     widget.status.swingMode = value;
//                     isDirty = true;
//                   });
//                 },
//                 value: widget.status.swingMode,
//             )
//           ],
//         ),
//         widget.canApply ? RaisedButton(
//           onPressed: isDirty ? () {
//             setState(() {
//               isDirty = false;
//               if(widget.canApply)
//                 widget.status.applyChanges(context);
//             });
//           } : null,
//           child: Text("Apply"),
//         ) : Divider()
//       ],
//     );
//   }
// }