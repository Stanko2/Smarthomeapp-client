import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings.dart';
import 'RequestHandler.dart';
import 'Devices.dart';
import 'Groups.dart';
import 'Timers.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

ThemeMode themeMode;
void main(){

  runApp(MyApp());
  SharedPreferences.getInstance().then((prefs){
    themeMode = ThemeMode.values[prefs.getInt('theme')];
  });
}
enum ACmode { cool, heat, dry, fan, auto}
enum ACFanSpeed {low, med, high, auto, silent}
enum ACSwingMode {none, horizontal, vertical, both}

class MyApp extends StatelessWidget {
  static List<Device> devices;
  static Map<int, dynamic> cachedControls;
   // This widget is the root of your application.
   @override
   Widget build(BuildContext context) {
      cachedControls = new Map<int, dynamic>();
      return MaterialApp(
        title: 'Home Control',
        theme: ThemeData(
          primarySwatch: Colors.lightBlue,
          primaryColor: Colors.white,
          appBarTheme: AppBarTheme(
            color: Colors.blueAccent,
            centerTitle: true,
          )
        ),
        //  home: MainScreen(title: 'Home Control'),
        routes: {
          '/settings': (context) => Settings(),
          '/': (context) => MainScreen(title: 'Home Control',),
          '/groups': (context) => Groups(),
          '/timers': (context) => Timers()
        },
        // initialRoute: '/',
        themeMode: themeMode,
        darkTheme: ThemeData.dark(),
        debugShowCheckedModeBanner: false,
      );
   }
}

Widget navigationDrawer(BuildContext context) => Drawer(
  child: ListView(
    padding: EdgeInsets.zero,
    children: [
      DrawerHeader(
        child: Text(
          "Menu",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w600
          ),
        ),
        decoration: BoxDecoration(
          // color: Colors.blue,
          gradient: LinearGradient(colors: <Color>[Colors.blueAccent[400], Colors.blueAccent])
        ),
      ),
      ListTile(
        title: Text("Devices", style: TextStyle(fontSize: 14),),
        onTap: (){
          Navigator.popAndPushNamed(context, '/');
        },
        trailing: Icon(Icons.ad_units),
      ),
      ListTile(
        title: Text("Timers", style: TextStyle(fontSize: 14),),
        onTap: (){
          Navigator.popAndPushNamed(context, '/timers');
        },
        trailing: Icon(Icons.timer),
      ),
      ListTile(
        title: Text("Device Groups", style: TextStyle(fontSize: 14),),
        onTap: (){
          Navigator.popAndPushNamed(context, '/groups');
        },
        trailing: Icon(Icons.devices_other),
      ),
      Divider(thickness: 2,),
      ListTile(
        title: Text("Settings", style: TextStyle(fontSize: 14),),
        onTap: (){
          Navigator.pushNamed(context, '/settings');
        },
        trailing: Icon(Icons.settings),
      ),
    ],
  ),
);

class MainScreen extends StatelessWidget {
  final String title;
  const MainScreen({Key key, this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        drawer: navigationDrawer(context),
        appBar: AppBar(
          title: Text(title),
        ),
        body: MyHomePage()
    );
  }
}

class MyHomePage extends StatefulWidget {
   MyHomePage({Key key, this.title, this.serverAddress}) : super(key: key);
   final String title;
   final String serverAddress;

   
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>{

  Future<DeviceList> devices;
  @override
  void initState(){
    super.initState();
    SharedPreferences.getInstance().then((value){
      if(value.getString('Local IP Address') == null){
        value.setString('Local IP Address', RequestHandler.localUrl);
      }
      else RequestHandler.localUrl = value.getString('Local IP Address');
      if(value.getString('Global IP Address') == null){
        value.setString('Global IP Address', RequestHandler.localUrl);
      }
      else RequestHandler.globalUrl = value.getString('Global IP Address');
      RequestHandler.url = RequestHandler.localUrl;
      if(RequestHandler.uid == null){
        RequestHandler.login(context).then((value){
          devices = RequestHandler().fetchDevices();
          devices.whenComplete(() => setState((){}));
        });
      }
      else{
        devices = RequestHandler().fetchDevices();
        devices.whenComplete(() => setState((){}));
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DeviceList>(
        future: devices,
        builder: (context, snapshot){
          String msg = "done";
          if(snapshot.connectionState == ConnectionState.done){
              msg = "Connected";
              if(snapshot.hasData){
                return buildDeviceWidgets(snapshot.data);
              }
              else {
                if (snapshot.hasError){
                return Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text('${snapshot.error}'),
                      RaisedButton(
                        onPressed:  () => refreshDevices(),
                        child: const Text("Refresh"),
                      )
                    ],

                  ),
                );
              }
            }
          }
          else if(snapshot.connectionState == ConnectionState.waiting) msg = "Connecting";
           return Padding(
             padding: const EdgeInsets.all(8.0),
             child: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(msg),
                    CircularProgressIndicator()
                  ],
                ),
              ),
           );
        }
      );
   }

  Widget buildDeviceWidgets(DeviceList devices) {
    var dev = <Widget>[];
    dev.addAll(displayDevices(devices));
    dev.add(RaisedButton(
        onPressed: () => refreshDevices(),
        child: const Text("Refresh"),
    ));
    if(kIsWeb){
      var columns = (MediaQuery.of(context).size.width * MediaQuery.of(context).devicePixelRatio / 500).ceil();
      return StaggeredGridView.countBuilder(
        crossAxisCount: columns,
        itemCount: dev.length,
        itemBuilder: (BuildContext context, int index)=>new Container(
          child: dev[index],
        ),
        staggeredTileBuilder: (int index) => index == dev.length -1 ? new StaggeredTile.fit(columns) : new StaggeredTile.fit(1),
        mainAxisSpacing: 4.0,
        crossAxisSpacing: 4.0,
      );
    }
    else{
      return RefreshIndicator(
        onRefresh: refreshDevices,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Column(
              children: dev,
            ),
          ),
        ),
      );
    }
  }
  List<Widget> displayDevices(DeviceList deviceList){
    List<Widget> out = List.filled(deviceList.deviceCount, null);
    for (var i = 0; i < deviceList.devices.length; i++) {
      if(deviceList.devices[i].type == 0){
        // out[i] = Light(name: deviceList.devices[i].name,isOn:deviceList.devices[i].isOn, status: deviceList.devices[i]);
      }
      else if(deviceList.devices[i].type == 1){
        // out[i] = AirConditioner(name: deviceList.devices[i].name,isOn:deviceList.devices[i].isOn, status: deviceList.devices[i]);
      }
      else{
        out[i] = CustomDevice(name: deviceList.devices[i].name, status: deviceList.devices[i], isOn: deviceList.devices[i].isOn, type: deviceList.devices[i].type, controlsHeight: (deviceList.devices[i] as CustomDeviceStatus).controlsHeight);
      }
    }
    MyApp.devices = out.map((e) => e as Device).toList();
    return out;
  }

  Future<void> refreshDevices() async{
    setState(() {
      if(RequestHandler.uid != null) devices = RequestHandler().fetchDevices();
    });
  }
}
