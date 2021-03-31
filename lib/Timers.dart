import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:smart_home_app/Devices.dart';
import 'package:smart_home_app/RequestHandler.dart';
import 'main.dart';

class Timers extends StatefulWidget {
  static List<Timer> timers;
  const Timers({Key key}) : super(key: key);

  @override
  _TimersState createState() => _TimersState();
}

class TimersList extends StatefulWidget {
  @override
  _TimersListState createState() => _TimersListState();
}

class _TimersListState extends State<TimersList> {
  
  Future<List<dynamic>> timerRequest;

  @override
  void initState() {
    super.initState();
    Timers.timers = [];
    timerRequest = RequestHandler().fetchTimers();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(
         heightFactor: 1,
         child: Column(
           children: [
             FutureBuilder(
                future: timerRequest,
                builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
                  Widget content;
                  if(snapshot.connectionState == ConnectionState.done){
                    if(snapshot.hasData){
                      var data = snapshot.data;
                      if(data.length == 0){
                        content = Padding(
                          padding: EdgeInsets.only(top: 25),
                          child: Text("No timers added. Please add one", style: Theme.of(context).primaryTextTheme.caption.apply(color: Colors.red), ),
                        );
                      }
                      Timers.timers.clear();
                      for (var value in data) {
                        TimerData curr = TimerData.fromJson(value);
                        Timers.timers.add(Timer(data: curr,));
                      }
                      content = Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: Timers.timers
                      );
                    }
                    else if(snapshot.hasError){
                      print(snapshot.error);
                    }
                  }
                  if(content != null){
                    return content;
                  }
                  return LinearProgressIndicator();
                },
              ),
              RaisedButton(
                onPressed: ()=>setState((){
                  timerRequest = RequestHandler().fetchTimers();
                }),
                child: const Text("Refresh"),
              )
           ],
         )
      ),
    );
  }
}

class _TimersState extends State<Timers> {
  Future<TimerData> pendingTimer;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: navigationDrawer(context),
      appBar: AppBar(
        title: const Text('Timers'),
      ),
      body: TimersList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {addTimer();},
        elevation: 2.0,
        shape: CircleBorder(),
        child: FutureBuilder(
          future: pendingTimer,
          builder: (context, snapshot) {
            Icon icon = Icon(
              Icons.add,
              size: 35.0,
            );
            if(snapshot.connectionState == ConnectionState.done) {
              if(snapshot.hasData){
                Timer newTimer = Timer(data: snapshot.data,);
                Timers.timers.add(newTimer);
                SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context)=>TimerEditor(data: snapshot.data)));
                });
              }
              return icon;
            }
            else if(snapshot.connectionState == ConnectionState.waiting){
              return CircularProgressIndicator();
            }
            else return icon;
          }
        )
      ),
    );
  }

  void addTimer(){
    setState(() {
      pendingTimer = RequestHandler().addTimer();
    });
  }
}

class TimerData{
  bool active;
  String name;
  int id;
  TimeOfDay activationTime;
  DeviceStatus newStatus;
  bool repeat;
  List<dynamic> loop;
  TimerData({
    this.activationTime, 
    this.active, 
    this.newStatus, 
    this.name,
    this.loop,
    this.id,
    this.repeat,
  });
   factory TimerData.fromJson(Map<String, dynamic> json){
     return TimerData(
       activationTime: TimeOfDay(hour: json['time']['hour'], minute: json['time']['minute']),
       name: json['name'],
       id: json['id'],
       newStatus: json['newStatus'] == null ? null : DeviceStatus.fromJson(json['status']),
       loop: json['loop'],
       active: json['active'],
       repeat: json['oneTime']
     );
   }
   Map<String, dynamic> toJson(){
     return <String, dynamic>{
       'time': {
         'hour': activationTime.hour,
         'minute': activationTime.minute
       },
       'id': id,
       'name': name,
       'status': newStatus.toJson(),
       'loop': loop,
       'active': active,
       'oneTime': !repeat
     };
   }
}

class Timer extends StatefulWidget {
  final TimerData data;

  Timer({Key key, this.data}) : super(key: key);

  @override
  _TimerState createState() => _TimerState();
}

class _TimerState extends State<Timer> {

  @override
  void initState() {
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: InkWell(
          onTap: (){
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => TimerEditor(data: widget.data,)));
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: EdgeInsets.only(left: 10),
                child: Text(widget.data.name, style: Theme.of(context).primaryTextTheme.headline5,),
              ),
              Switch(value: widget.data.active, onChanged: (value){
                setState(() {
                  widget.data.active = value;  
                });
                RequestHandler().changeTimer(widget.data);
              })
            ],
          ),
        ),
      ),
    );
  }
}

class TimerEditor extends StatefulWidget {
  final TimerData data;
  TimerEditor({Key key, this.data}) : super(key: key);

  @override
  _TimerEditorState createState() => _TimerEditorState();
}

class _TimerEditorState extends State<TimerEditor> {
  bool editingName = false;

  @override
  Widget build(BuildContext context) {
    var controlTheme = BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Theme.of(context).primaryColor,

    );
    var textStyle = Theme.of(context).primaryTextTheme.subtitle1;
    if(widget.data == null){
      // widget.data = data;
      print("data null");
    }
    if(widget.data.newStatus == null && MyApp.devices != null){
      widget.data.newStatus = MyApp.devices[0].status;
    }
    var txt = TextEditingController();
    txt.text = widget.data.name;
    return Scaffold(
      appBar: AppBar(
        title: editingName ? TextField(
            controller: txt,
            autofocus: true,
            style: Theme.of(context).primaryTextTheme.headline5,
          ) : GestureDetector(
          child: Text(widget.data.name, style: Theme.of(context).primaryTextTheme.headline4,),
          onTap: (){
            if(!editingName) {
              setState(() {
                editingName = true;
              });
            }
          },
        ),
        actions: [
          IconButton(
            icon: Icon(editingName ? Icons.done : Icons.edit),
            onPressed: (){setState(() {
              if(editingName){
                widget.data.name = txt.text;
              }
              editingName = !editingName;
            });},
          ),
        ],
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => apply(widget.data),
        )
      ),
      bottomNavigationBar: Row(
        children: [
          Container(
            padding: EdgeInsets.all(0),
            width: MediaQuery.of(context).size.width/2.2,
            child: FlatButton(
              color: Colors.redAccent,
              onPressed: () => showDialog(context: context, builder: (context){
                return AlertDialog(
                  title: Text("Delete ${widget.data.name}?"),
                  actions: [
                    RaisedButton(
                      onPressed: () => RequestHandler().removeTimer(widget.data.id).then((value){
                        Navigator.of(context).popUntil(ModalRoute.withName('/timers'));
                        // Scaffold.of(context).setState((){});
                      }),
                      child: const Text("Yes"),
                    ),
                    RaisedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text("No"),
                    )
                  ],
                );
              }),
              child: Text("Remove"),
            ),
          ),
          Container(
            padding: EdgeInsets.all(0),
            width: MediaQuery.of(context).size.width/2.2,
            child: FlatButton(
              color: Colors.blue,
              onPressed: () => RequestHandler().changeTimer(widget.data),
              child: Text("Save"),
            ),
          )
        ]
      ),
      body: Container(
        padding: EdgeInsets.all(5),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: Container(
                  decoration: controlTheme,
                  padding: EdgeInsets.only(left: 5, top: 10, bottom: 10),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Active", style: textStyle),
                          Switch(value: widget.data.active, onChanged: (value){setState(() {
                            widget.data.active = value;
                          });})
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Target Device", style: textStyle),
                          DropdownButton(
                              items: MyApp.devices == null
                                  ? <DropdownMenuItem<int>>[DropdownMenuItem(child: Text("None"), value: null,)]
                                  : MyApp.devices.map((e) => DropdownMenuItem(
                                  child: DropdownItem(
                                    icon: e.typeInfo.deviceIcon,
                                    name: e.name,
                                  ),
                                  value: e.status.id)).toList(),
                              value: MyApp.devices == null ? null : widget.data.newStatus.id,
                              onChanged: (value){
                                setState(() {
                                  widget.data.newStatus = MyApp.devices.firstWhere((element) => element.status.id == value).status;
                                });
                              }
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Time Invoked", style: textStyle,),
                          FlatButton(
                              onPressed: (){
                                showTimePicker(context: context, initialTime: TimeOfDay.now())
                                    .then((value) {
                                  setState(() {
                                    if(value != null)
                                      widget.data.activationTime = value;
                                  });
                                });
                              },
                              child: Text(
                                widget.data.activationTime.format(context),
                                style: Theme.of(context).primaryTextTheme.headline5.apply(color: Theme.of(context).accentColor)
                              )
                          )
                        ],
                      ),

                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: Container(
                  decoration: controlTheme,
                  padding: EdgeInsets.only(left: 5,top: 10, bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text("New Status", style: Theme.of(context).primaryTextTheme.headline4),
                      Divider(),
                      Container(
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("Device power", style: textStyle,),
                                  Switch(value: widget.data.newStatus.isOn, onChanged: (value){setState(() {
                                    widget.data.newStatus.isOn = value;
                                  });})
                                ],
                              ),
                              buildStatusControls(context)
                            ],
                          )
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Theme.of(context).accentColor,
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.only(left: 5),
                        decoration: controlTheme,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Repeat", style: textStyle,),
                            Checkbox(value: widget.data.repeat, onChanged: (value){
                              setState(() {
                                widget.data.repeat = value;
                              });
                            })
                          ],
                        ),
                      ),
                      AnimatedContainer(
                        curve: Curves.fastOutSlowIn,
                        duration: const Duration(milliseconds: 500),
                        height: widget.data.repeat ? 50 : 0,
                        child: Opacity(
                          opacity: widget.data.repeat ? 1 : 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              WeakDayRepeatWidget(data: widget.data,dayName: "Po",index: 0,),
                              WeakDayRepeatWidget(data: widget.data,dayName: "Ut",index: 1,),
                              WeakDayRepeatWidget(data: widget.data,dayName: "St",index: 2,),
                              WeakDayRepeatWidget(data: widget.data,dayName: "Št",index: 3,),
                              WeakDayRepeatWidget(data: widget.data,dayName: "Pi",index: 4,),
                              WeakDayRepeatWidget(data: widget.data,dayName: "So",index: 5,),
                              WeakDayRepeatWidget(data: widget.data,dayName: "Ne",index: 6,),
                            ],
                          ),
                        )
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      )
    );
  }

  void apply(TimerData timer){
    RequestHandler().changeTimer(timer).whenComplete((){
      Navigator.of(context).pop();
    });
  }

  
  Widget buildStatusControls(BuildContext context){
    try{
      if(MyApp.devices == null) throw Exception("No devices found");
      if(widget.data.newStatus == null) throw Exception("Please select a device");
      // var selectedDevice = MyApp.devices.firstWhere((element) => element.status.id == widget.data.newStatus.id);
      // if(selectedDevice is AirConditioner){
      //   return AcControls(status: widget.data.newStatus as ACStatus, canApply: false,);
      // }
      // else if(selectedDevice is Light) {
      //   return LightControls(status: widget.data.newStatus as LightStatus, canApply: false,);
      // }
      (widget.data.newStatus as CustomDeviceStatus).props = {};
      return CustomControls(
        status: widget.data.newStatus,
        type: (widget.data.newStatus as CustomDeviceStatus).type, 
        controls: RequestHandler().fetchControls(widget.data.newStatus.id),
        apply: (){},
      );
    }
    catch(e){
      return Text(e.toString(), style: TextStyle(color: Colors.red),);
    }
  }
}

class WeakDayRepeatWidget extends StatefulWidget {
  final String dayName;
  final int index;
  final TimerData data;
  WeakDayRepeatWidget({this.data,this.dayName,this.index}):super();

  @override
  _WeakDayRepeatWidgetState createState() => _WeakDayRepeatWidgetState();
}

class _WeakDayRepeatWidgetState extends State<WeakDayRepeatWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(
        children: [
          Text(widget.dayName, style: Theme.of(context).primaryTextTheme.subtitle1.apply(color: Colors.black),),
          Container(
            child: Checkbox(
              checkColor: Colors.black,
              onChanged: (value){
                setState(() {
                  widget.data.loop[widget.index] = value;
                });
              },
              value: widget.data.loop[widget.index],
              // checkColor: Theme.of(context).primaryColor,
            ),
            width: 30,
            height: 20,
          ),
        ],
      ),
    );
  }
}
