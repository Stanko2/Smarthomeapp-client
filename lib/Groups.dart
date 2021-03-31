import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:icons_helper/icons_helper.dart';
import 'package:smart_home_app/RequestHandler.dart';
import 'main.dart';
import 'Devices.dart';


class Groups extends StatelessWidget {
  const Groups({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: navigationDrawer(context),
      appBar: AppBar(
        title: Text('Device Groups'),
        backgroundColor: Colors.blue,
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: (){
          Navigator.push(context, MaterialPageRoute(builder: (context)=> GroupEditor(group: new DeviceGroup(),)));
        },
      ),
      body: GroupWidgetBuilder(),
    );
  }
}

class GroupEditor extends StatefulWidget {
  final DeviceGroup group;
  GroupEditor({this.group, Key key}): super(key: key);

  @override
  _GroupEditorState createState() => _GroupEditorState();
}

class _GroupEditorState extends State<GroupEditor> {
  @override
  Widget build(BuildContext context) {
    List<Widget> items = [];
    widget.group.devices.forEach((element) {
      items.add(GroupItem(
        icon: element.typeInfo.deviceIcon,
        key: ValueKey(element.status.id),
        name: element.name,
        typeName: element.typeInfo.typeName,
        deleteHandler: () => setState(()=>widget.group.devices.removeWhere((f) => f.status.id == element.status.id)),
      ));
    });
    var ctrl = TextEditingController();
    ctrl.text = widget.group.name;
    return Scaffold(
      appBar: AppBar(title: Text('Edit')),
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(shape: BoxShape.rectangle, color: Theme.of(context).colorScheme.primaryVariant),
            padding: EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Name', style: Theme.of(context).textTheme.headline6,),
                SizedBox(
                  height: 40,
                  width: 200,
                  child: TextField(
                    onSubmitted: (value){
                      setState(() {
                        widget.group.name = value;
                      });
                    }, 
                    controller: ctrl,
                    decoration: InputDecoration(),
                    autofocus: false,
                    style: Theme.of(context).textTheme.headline5
                  )
                )
              ],
            ),
          ),
          Expanded(
            child: widget.group.devices.length > 0 ? ReorderableListView(
              onReorder: (prev, next){
                if(next > prev) next--;
                setState(() {
                  var device = widget.group.devices.removeAt(prev);
                  widget.group.devices.insert(next, device);
                });
              },
              children: items,
              header: Text('Devices', style: Theme.of(context).textTheme.headline5,),
              padding: EdgeInsets.all(10),
            ) : Text('No devices added'),
          ),
          DropdownButton(
            items: getAvailableDevices(),
            value: MyApp.devices[0],
            onChanged: (item){setState(() {
              widget.group.devices.add(item);
            });},
          )
        ],
      ),
      bottomNavigationBar: RaisedButton(child: Text('Save'), onPressed: (){
        if(widget.group.id == null){
          RequestHandler.postRequest('groups/Add', widget.group.toJson()).then((value){
            print(value.body);
            Navigator.of(context).pop(context);
          });
        }
        else{
          RequestHandler.postRequest('groups/change', widget.group.toJson()).then((value){
            print(value.body);
            Navigator.of(context).pop(context);
          });
        }
      }),
    );
  }

  List<DropdownMenuItem> getAvailableDevices(){
    List<DropdownMenuItem<dynamic>> out = [];
    MyApp.devices.forEach((element) {
      if(!widget.group.contains(element)){
        out.add(DropdownMenuItem(
          child: DropdownItem(icon: element.typeInfo.deviceIcon, name: element.name,),
          value: element,
        ));
      }
    });
    return out;
  }
}

class GroupWidgetBuilder extends StatefulWidget {
  @override
  _GroupWidgetBuilderState createState() => _GroupWidgetBuilderState();
}

class _GroupWidgetBuilderState extends State<GroupWidgetBuilder> {
  Future<Response> groupsRequest;

  @override
  void initState() { 
    super.initState();
    groupsRequest = RequestHandler.getRequest('groups');
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: FutureBuilder(
        future: groupsRequest,
        initialData: null,
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if(snapshot.hasData){
            var data = json.decode(snapshot.data.body);
            var c = <GroupWidget>[];
            data.forEach((e){
              c.add(GroupWidget(group: DeviceGroup.parseJson(e), refresh: refresh,));
            });
            return Column(
              children: c,
            );
          }
          else if(snapshot.hasError){
            return Center(child: Text(snapshot.error.toString()));
          }
          return new CircularProgressIndicator.adaptive();
        },
      ),
    );
  }

  void refresh(){
    setState(() {
      groupsRequest = RequestHandler.getRequest('groups');
    });
  }
}

class GroupItem extends StatelessWidget {
  final IconData icon;
  final String name;
  final String typeName;
  final Function() deleteHandler;
  GroupItem({this.icon, this.name, this.typeName, this.deleteHandler, Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Card(
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children:[
                  Container(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      icon,
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
                          name,
                          textAlign: TextAlign.right,
                          style: Theme.of(context).primaryTextTheme.headline6,
                        ),
                        Text(
                          typeName,
                          textAlign: TextAlign.right,
                          style: Theme.of(context).primaryTextTheme.caption,
                        )
                      ],
                    ),
                  ),
                ]
              ),
              IconButton(icon: Icon(Icons.delete), onPressed: deleteHandler, color: Theme.of(context).colorScheme.error,)
            ],
          )
        ),
      ),
    );
  }
}

class GroupWidget extends StatefulWidget {
  final DeviceGroup group;
  final Function() refresh;
  GroupWidget({this.group, this.refresh, Key key}) : super(key: key);
  @override
  _GroupWidgetState createState() => _GroupWidgetState();
}

class _GroupWidgetState extends State<GroupWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Card(
        child: InkWell(
          onLongPress: (){
            Navigator.of(context).push(MaterialPageRoute(builder: (context)=> GroupEditor(group: widget.group,))).then((value){
              widget.refresh();
            });
          },
          child: Column(
            children: [
              Text(widget.group.name, style: Theme.of(context).textTheme.headline4,),
              Row(
                children: widget.group.types.map((e){
                  Color color;
                  if(e['isOn']=='on') color = Colors.green;
                  else if(e['isOn']=='off') color = Theme.of(context).colorScheme.error;
                  else color = Theme.of(context).colorScheme.onPrimary;
                  return InkWell(
                    child: Container(padding: EdgeInsets.all(10), child: Icon(getIconUsingPrefix(name: e['icon']), color: color, )),
                    onTap: (){
                      var address = "groups/${widget.group.id}/${e['id']}";
                      RequestHandler.postRequest(address, {}).then((value){
                        print(value.body);
                        widget.refresh();
                      });
                    },
                    onLongPress: (){
                      var address = "groups/${widget.group.id}/${e['id']}";
                      RequestHandler.getRequest(address).then((value){
                        Navigator.of(context).push(MaterialPageRoute(builder: (context)=> GroupTypeControls(
                          title: "${widget.group.name} - ${e['id']}",
                          status: DeviceStatus.fromJson(jsonDecode(value.body)),
                          groupId: widget.group.id,
                          type: e['id'],  
                        )));
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      )
    );
  }
}

class GroupTypeControls extends StatelessWidget {
  final String title;
  final int type;
  final int groupId;
  final CustomDeviceStatus status;

  const GroupTypeControls({Key key, this.title, this.type, this.groupId, this.status}) : super(key: key);
  
  Future<Map<String, dynamic>> getControls() async{
    var response = await RequestHandler.getRequest('groups/$groupId/$type/controls');
    return jsonDecode(response.body);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CustomControls(
          status: status,
          apply: () async{ await RequestHandler.postRequest('groups/$groupId/$type', status.toJson());}, 
          controls: getControls(), 
          type: type,
        ),
      ),
    );
  }
}

class DeviceGroup {
  List<Device> devices; 
  List<Map> types;
  String name;
  int id;

  DeviceGroup(){
    this.devices = [];
    this.types = [];
    this.name = 'Group';
  }

  factory DeviceGroup.parseJson(Map<String, dynamic> json){
    assert(json['name'] != null);
    assert(json['types'] != null);
    var group = DeviceGroup();
    group.name = json['name'];
    group.id = json['id'];
    json['types'].forEach((e){
      group.types.add(e);
    });
    json['devices'].forEach((e){
      group.devices.add(MyApp.devices.firstWhere((element) => element.status.id == e));
    });
    return group;
  }

  Map<String, dynamic> toJson(){
    return {
      'name': this.name,
      'id': this.id,
      'devices': devices.map((e) => e.status.id).toList(),
    };
  }

  bool contains(Device dev){
    return devices.contains(dev);
  }
}