import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_home_app/Timers.dart';

class RequestHandler{
  static String localUrl = 'http://192.168.0.106:8000';
  static String globalUrl = 'http://49.12.74.49:8000';
  static String url = localUrl;
  static String uid;
  static Future<String> setUrl() async{
    try{
      await http.get(localUrl); 
      // if(response.body == 'OK')
      //   url = localUrl;
      // else
      //   url = globalUrl;
      url = localUrl;
    }
    catch(Exception){
      await http.get(globalUrl);
      url = globalUrl;
    }
    return url;
  }

  Future<DeviceList> fetchDevices() async {
      final response = await getRequest('devices');
      if(response.statusCode == 200){
        return DeviceList.fromJson(json.decode(response.body));
      }
      else{
        if(response.statusCode == 403){
          throw 'Permission denied, ask admin to grant you access';
        }
        throw Exception('Failed to load devices ' + response.statusCode.toString());
      }
  }
  Future<List<dynamic>> fetchTimers() async{
    final response = await getRequest('timers');
    List<dynamic> jsonbody = json.decode(response.body);
    return jsonbody;
  }
  Future<TimerData> addTimer() async{
    final response = await postRequest('addTimer', {});
    return TimerData.fromJson(json.decode(response.body));
  }
  Future<void> changeTimer(TimerData data) async {
    await postRequest('timerChange', data.toJson());
    return;
  }
  Future<void> removeTimer(int id) async{
    await postRequest('removeTimer', {'id': id});
    return;
  }

  Future<Map<String, dynamic>> fetchControls(int id) async {
    final http.Response response = await getRequest('devices/$id/controls');
    return json.decode(response.body);
  }

  static Future<http.Response> postRequest(String address, Map<String, dynamic> body, {api = true}) async{
    if(uid == null) throw 'user not logged in';
    var a = '$url/api/$address';
    if(!api) a = '$url/$address';
    http.Response response = await http.post(a, headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Access-Control-Allow-Credentials': 'true',
        'Access-Control-Allow-Origin': url,
        'authorization': uid,
      }, body: json.encode(body));
    if(response.statusCode == 403){
      throw 'Permission denied, ask admin to grant you access';
    }
    return response;
  }

  static Future<http.Response> getRequest(String address, {bool api = true}) async{
    var a = '$url/api/$address';
    if(!api) a = '$url/$address';
    http.Response response = await http.get(a, headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Access-Control-Allow-Credentials': 'true',
        'Access-Control-Allow-Origin': url,
        'authorization': uid,
    });
    if(response.statusCode == 403){
      throw 'Permission denied, ask admin to grant you access';
    }
    return response;
  }

  Future updateDevice(DeviceStatus status) async {
    if(status == null) return;
    try{
      final response = await getRequest('devices/${status.id}');
      return status.update(jsonDecode(response.body));
    }
    catch(e){
      print(e);
      status.online = false;
    }
  }

  static Future login(BuildContext context, {bool register = false}) async{
    var settings = await SharedPreferences.getInstance();
    if(!register){
      uid = settings.getString('UserId');
      http.Response response = await http.post('$url/login', headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Access-Control-Allow-Credentials': 'true',
        'Access-Control-Allow-Origin': url,
      }, body: jsonEncode({'uid': uid}));
      print(response.body);
      var body = json.decode(response.body);
      if(body['status'] == 'ERR'){
        if(body['message'] == 'user does not exist'){
          uid = null;
          await login(context, register: true);
        }
      }
      return;
    }
    else{
      var name = await Navigator.of(context).push(MaterialPageRoute(builder: loginDialog));
      print(name);
      http.Response res = await http.post('$url/register', headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Access-Control-Allow-Credentials': 'true',
        'Access-Control-Allow-Origin': url,
      }, body: jsonEncode({'name': name}));
      var body = json.decode(res.body);
      if(body['status']=='ERR'){
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('gjaio')));
        await login(context, register: true);
      }     
      settings.setString('UserId', body['user']['uid']);
      uid = body['user']['uid'];
      print(uid);
    }
  }

  static Widget loginDialog(BuildContext context){
    var txt = TextEditingController();
    return WillPopScope(
      onWillPop: () async => txt.text.length > 0,
      child: Scaffold(
        body: Container(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Nickname'),
                TextField(
                  controller: txt,
                  style: Theme.of(context).textTheme.headline4,
                  decoration: InputDecoration(
                    hintText: 'Enter username',
                  ),
                ),
              ],
            ),
          )
        ),
        appBar: AppBar(
          title: Center(child: Text("Register new user")), 
          automaticallyImplyLeading: false,
        ),
        bottomNavigationBar: FlatButton(
          onPressed: (){
          if(txt.text.length > 0){
            Navigator.of(context).pop(txt.text);
          }
        }, 
        child: Text('Create', style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),), 
        color: Theme.of(context).colorScheme.secondary,),
      ),
    );
  }
}

class DeviceList{
  final List<DeviceStatus> devices;
  final int deviceCount;
  DeviceList({this.deviceCount, this.devices});
  factory DeviceList.fromJson(Map<String,dynamic> json){
    int count = json['deviceCount'];
    List<DeviceStatus> devices = List.filled(count, null);

    for (var i = 0; i < count; i++) {
      devices[i] = DeviceStatus.fromJson(json['devices'][i]);
    }
    return DeviceList(deviceCount: count, devices: devices);
  }
}

abstract class DeviceStatus{
  final String name;
  final int type;
  final int id;
  bool isOn;
  bool online;
  DeviceStatus({this.name, this.isOn, this.type, this.id, this.online});

  factory DeviceStatus.fromJson(Map<String, dynamic> json){
    assert(json!=null);
    assert(json['name']!=null);
    assert(json['id']!=null);
    assert(json['type']!=null);
    if(json == null) return null;
    int type = json['type'];
    // if(type == 0) {
    //   return LightStatus(
    //     isOn: json['isOn'],
    //     id: json['id'],
    //     name: json['name'],
    //     type: type,
    //     intensity: json['intensity'].toDouble(),
    //     color: Color.fromARGB(
    //         255, json['color']['r'], json['color']['g'], json['color']['b']),
    //     online: json['online'],
    //   );
    // }
    // else if(type == 1)
      // return ACStatus(
      //   isOn: json['isOn'], 
      //   name: json['name'], 
      //   type: type,
      //   ecoMode: json['eco'],
      //   fanSpeed: ACFanSpeed.values[json['fanSpeed']],
      //   mode: ACmode.values[json['mode']],
      //   targetTemp: json['targetTemp'],
      //   turboMode: json['turbo'],
      //   id: json['id'],
      //   indoorTemp: json['indoorTemp'].toDouble(),
      //   outdoorTemp: json['outdoorTemp'].toDouble(),
      //   swingMode: ACSwingMode.values[json['swingMode']],
      //   online: json['online'],
      // );
    // else{
      assert(json['controlsHeight']!=null);
      return CustomDeviceStatus(
        name: json['name'],
        id: json['id'],
        online: json['online'],
        isOn: json['isOn'],
        props: json['props'],
        type: type,
        controlsHeight: json['controlsHeight'].toDouble(),
      );
    // }
  }
  Map<String, dynamic> toJson(){
    return {
      'isOn': true,
      'name': 'svetlo 1',
      'intensity': 100.0,
      'color': 0xffffff,
      'type': 0,
      'id': id,
    };
  }
  Future<Map<String, dynamic>> applyChanges() async{
    final http.Response response = await RequestHandler.postRequest('change', toJson()); 
    if(response.statusCode == 200){
      Map<String, dynamic> jsonBody = jsonDecode(response.body);
      if(jsonBody['status'] == 'ERR'){
        throw Exception('Exception: ' + jsonBody['message']);
      }
      return jsonBody['newStatus'];
    }
    else{
      throw Exception('Failed to connect to server ${response.statusCode}');
    }
  }
  void update(Map<String, dynamic> newStatus){

  }
}

class CustomDeviceStatus extends DeviceStatus{
  Map<String, dynamic> props;
  final double controlsHeight;
  final List<String> updatedProps = [];
  CustomDeviceStatus({
    this.controlsHeight,
    this.props,
    String name,
    int type,
    bool isOn,
    int id, bool online,
  }) : super (id: id, isOn: isOn, name: name, type:type, online: online);
  @override
  Map<String, dynamic> toJson(){
    var data = <String, dynamic>{
      'isOn': isOn,
      'id': id,
      'type': 2,
      'name': name,
      'controlsHeight': controlsHeight,
    };
    data['props'] = {};
    if(props != null){
      updatedProps.forEach((element) {
        if(data['props'][element] != null) return;
        data['props'][element] = props[element];
      });
    }
    return data;
  }
  @override
  Future<Map<String, dynamic>> applyChanges() async{
    var ret = await super.applyChanges();
    updatedProps.clear();
    return ret;
  }

  @override
  void update(Map<String, dynamic> newStatus){
    props.keys.forEach((element) {
      if(newStatus.keys.contains(element)){
        props[element] = newStatus[element];
      }
    });
  }
}

// class LightStatus extends DeviceStatus{
//   double intensity;
//   Color color;
//   LightStatus({
//     this.color = Colors.red,
//     this.intensity = 100,
//     String name,
//     int type,
//     bool isOn,
//     int id, bool online,
//   }) : super(id: id, isOn: isOn, name: name, type:type, online: online);
//   @override
//   Map<String, dynamic> toJson(){
//     return {
//       'isOn': isOn,
//       'name': name,
//       'intensity': intensity,
//       'color': { 'r': color.red, 'g': color.green,'b': color.blue },
//       'type': 0,
//       'id': id,
//     };
//   }
//   @override
//   void update(Map<String, dynamic> newStatus){
//     if(newStatus.keys.contains('intensity')){
//       intensity = newStatus['intensity'];
//     }
//     if(newStatus.keys.contains('color')){
//       color = Color.fromARGB(255, newStatus['color']['r'], newStatus['color']['g'], newStatus['color']['b']);
//     }
//     if(newStatus.keys.contains('online')){
//       online = newStatus['online'];
//     }
//   }
// }

// class ACStatus extends DeviceStatus{
//   ACmode mode;
//   ACFanSpeed fanSpeed;
//   ACSwingMode swingMode;
//   int targetTemp;
//   double indoorTemp;
//   double outdoorTemp;
//   bool ecoMode;
//   bool turboMode;
//   ACStatus({
//     this.ecoMode = false,
//     this.fanSpeed = ACFanSpeed.auto,
//     this.mode = ACmode.auto,
//     this.turboMode = false,
//     this.targetTemp = 24,
//     this.indoorTemp,
//     this.outdoorTemp,
//     this.swingMode = ACSwingMode.none,
//     String name,
//     int type,
//     bool isOn,
//     int id,
//     bool online
//   }) : super(id: id, isOn: isOn, name: name, type:type, online: online);
//   Map<String, dynamic> toJson(){
//     return <String, dynamic>{
//       'isOn': isOn,
//       'name': name,
//       'mode': mode.index,
//       'fanSpeed': fanSpeed.index,
//       'turbo': turboMode,
//       'eco': ecoMode,
//       'targetTemp': targetTemp,
//       'type': 1,
//       'id': id,
//       'swingMode': swingMode.index,
//       'outdoorTemp': outdoorTemp,
//       'indoorTemp': indoorTemp
//     };
//   }
// }