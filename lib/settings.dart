import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_home_app/RequestHandler.dart';
import 'package:smart_home_app/main.dart';
import 'package:settings_ui/settings_ui.dart';

class Settings extends StatelessWidget {
  const Settings({Key key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      drawer: navigationDrawer(context),
      body: Options(),
    );
  }
}

class Options extends StatefulWidget {
  const Options({
    Key key,
  }) : super(key: key);

  @override
  _OptionsState createState() => _OptionsState();
}

class _OptionsState extends State<Options> {
  Future userData;
  SharedPreferences prefs;

  @override
  void initState() { 
    super.initState();
    userData = RequestHandler.getRequest('user', api: false);
    SharedPreferences.getInstance().then((value) => setState((){
      prefs = value;
    }));
  }

  @override
  Widget build(BuildContext context) {
    if(prefs == null) return Container();
    return SettingsList(
      sections: [
        CustomSection(
          child: Padding(padding: EdgeInsets.all(5),)
        ),
        SettingsSection(
          title: 'Connection',
          tiles: [
            SettingsTile(title: 'Local Ip Address',trailing: Setting( 
              label: 'Local URL',
              onchange: (value) => prefs.setString('Local IP Address', value),
              defaultValue: prefs.getString('Local IP Address'),
            )),
            SettingsTile(title: 'Global Ip Address',trailing: Setting(
              label: 'Global URL',
              onchange: (value)=>prefs.setString('Global IP Address', value),
              defaultValue: prefs.getString('Global IP Address'),
            )),
          ],
        ),
        SettingsSection(
          title: 'User',
          tiles: [
              SettingsTile(title: 'UID', trailing: FlatButton(
                padding: EdgeInsets.all(0),
                child: Text('Copy', style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),),
                onPressed: (){ 
                  Clipboard.setData(new ClipboardData(text: RequestHandler.uid)).then((value) => 
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Copied'))));
                },
                color: Theme.of(context).colorScheme.secondary,
              )),
              SettingsTile(title: 'Display name', trailing: SizedBox(
                width: 230,
                child: FutureBuilder(
                  future: userData,
                  builder: (context, snapshot){
                    if(snapshot.hasData){
                      var data = jsonDecode(snapshot.data.body);
                      print(data);
                      return Setting(
                        defaultValue: data['user']['nickname'],
                        onchange: (value){
                          RequestHandler.postRequest('changeName', {'nickname': value}, api: false);
                        },
                      );
                    }
                    else if(snapshot.hasError) return Text(snapshot.error);
                    else return Container();
                  } 
                ),
              )),
          ],
        ),
        SettingsSection(
          title: 'Theme',
          tiles: [
            SettingsTile(title: 'App Theme', trailing: ThemeSetting(),)
          ],
        ),
        CustomSection(
          child: FutureBuilder(
            future: userData,
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if(snapshot.hasData){
                var otherUserData = jsonDecode(snapshot.data.body)['otherUsers'];
                if(otherUserData == null) return Container();
                return ManageAccessSection(userData: otherUserData);
              }
              return Container();
            },
          )
        )
      ],
    );
  }
}

class ManageAccessSection extends StatefulWidget {
  const ManageAccessSection({
    Key key,
    @required this.userData,
  }) : super(key: key);

  final List<dynamic> userData;

  @override
  _ManageAccessSectionState createState() => _ManageAccessSectionState();
}

class _ManageAccessSectionState extends State<ManageAccessSection> {
  @override
  Widget build(BuildContext context) {
    return SettingsSection(title: 'Manage Access',
      tiles: widget.userData.map((e)=>SettingsTile.switchTile(title: e['nickname'], onToggle: (value){
        setState(() {
          e['granted'] = value;
          print(e);
        });
        RequestHandler.postRequest('acceptPermission', {'user': e['uid'], 'hasPermission': value}, api: false);
      }, switchValue: e['granted'])).cast<SettingsTile>().toList(),
    );
  }
}

class ThemeSetting extends StatefulWidget {
  ThemeSetting({Key key}) : super(key: key);

  @override
  _ThemeSettingState createState() => _ThemeSettingState();
}

class _ThemeSettingState extends State<ThemeSetting> {
  ThemeMode mode;

  @override
  void initState() { 
    super.initState();
    SharedPreferences.getInstance().then((prefs){
      setState(() {
        mode = ThemeMode.values[prefs.getInt('theme')];  
      });
    });
  }
  @override
  Widget build(BuildContext context) {
    return DropdownButton(
      value: mode,
      items: <DropdownMenuItem<ThemeMode>>[
        DropdownMenuItem(
          value: ThemeMode.dark,
          child: Row(
            children: [
              Icon(Icons.brightness_low),
              Text("Dark")
            ],
          )
        ),
        DropdownMenuItem(
          value: ThemeMode.light,
          child: Row(
            children: [
              Icon(Icons.brightness_high),
              Text("Light")
            ],
          )
        ),
        DropdownMenuItem(
          value: ThemeMode.system,
          child: Row(
            children: [
              Icon(Icons.brightness_auto),
              Text("System default")
            ],
          )
        )
      ], 
      onChanged: (value) => themeChange(value)
    );
  }

  void themeChange(ThemeMode data){
    setState(() {
      mode = data;
      SharedPreferences.getInstance().then((prefs){
        prefs.setInt('theme', data.index);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Restart app to apply theme")));
      });
    });
  }
}


class Setting extends StatefulWidget {
  final String settingName;
  final String label;
  final Function(String) onchange;
  final String defaultValue;
  Setting({Key key, this.settingName, this.label, this.onchange, this.defaultValue}) : super(key: key);

  @override
  _SettingState createState() => _SettingState();
}

class _SettingState extends State<Setting> {
  var txt = TextEditingController();
  @override
  void initState() { 
    super.initState();
    txt.text = widget.defaultValue;
  }
  String get value {
    return txt.text;
  }

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, -5),
      child: SizedBox(
        width: 230,
        height: 35,
        child: TextField(
          maxLines: 1,
          maxLength: 1000,
          textAlignVertical: TextAlignVertical.center,
          textAlign: TextAlign.start,
          onSubmitted: (value){
            widget.onchange(value);

          },
          decoration: InputDecoration(
            hintText: widget.label,
            hintStyle: TextStyle(
              fontSize: 14                      
            ),
            border: UnderlineInputBorder(
              borderSide: BorderSide(width: 2),
              borderRadius: BorderRadius.circular(2),
            ),
            counterStyle: TextStyle(height: double.minPositive,),
            counterText: ""
          ),
          autocorrect: false,
          controller: txt,
          autofocus: false,
          
          keyboardType: TextInputType.url,
          style: TextStyle(
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}
