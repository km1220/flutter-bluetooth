import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show
  debugPaintSizeEnabled,
  debugPaintBaselinesEnabled,
  debugPaintLayerBordersEnabled,
  debugPaintPointersEnabled,
  debugRepaintRainbowEnabled;
import 'package:flutter_blue/abstractions/contracts/i_device.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_blue_example/app_configuration.dart';
import 'package:flutter_blue_example/app_home.dart';
import 'package:flutter_blue_example/app_settings.dart';
import 'package:flutter_blue_example/app_strings.dart';
import 'package:flutter_blue_example/device_page.dart';

class FlutterBlueApp extends StatefulWidget {
  @override
  FlutterBlueAppState createState() => new FlutterBlueAppState();
}

class FlutterBlueAppState extends State<FlutterBlueApp> {

  final FlutterBlue _flutterBlue = new FlutterBlue();
  Set<IDevice> _devices;

  AppConfiguration _configuration = new AppConfiguration(
      displayMode: DisplayMode.light,
      debugShowGrid: false,
      debugShowSizes: false,
      debugShowBaselines: false,
      debugShowLayers: false,
      debugShowPointers: false,
      debugShowRainbow: false,
      showPerformanceOverlay: false,
      showSemanticsDebugger: false
  );

  @override
  void initState() {
    super.initState();
    _devices = _flutterBlue.ble.adapter.devices;
    /*new StockDataFetcher((StockData data) {
      setState(() {
        data.appendTo(_stocks, _symbols);
      });
    });*/
  }

  void configurationUpdater(AppConfiguration value) {
    setState(() {
      _configuration = value;
    });
  }

  ThemeData get theme {
    switch (_configuration.displayMode) {
      case DisplayMode.light:
        return new ThemeData(
            brightness: Brightness.light,
            primarySwatch: Colors.blue
        );
      case DisplayMode.dark:
        return new ThemeData(
            brightness: Brightness.dark,
            accentColor: Colors.blueAccent
        );
    }
    assert(_configuration.displayMode != null);
    return null;
  }

  Route<Null> _getRoute(RouteSettings settings) {
    final List<String> path = settings.name.split('/');
    if (path[0] != '')
      return null;
    if (path[1] == 'device') {
      if (path.length != 3)
        return null;
      for(IDevice d in _devices) {
        if(d.id.toString() == path[2]) {
          return new MaterialPageRoute<Null>(
              settings: settings,
              builder: (BuildContext context) => new DevicePage(device: d)
          );
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    assert(() {
      debugPaintSizeEnabled = _configuration.debugShowSizes;
      debugPaintBaselinesEnabled = _configuration.debugShowBaselines;
      debugPaintLayerBordersEnabled = _configuration.debugShowLayers;
      debugPaintPointersEnabled = _configuration.debugShowPointers;
      debugRepaintRainbowEnabled = _configuration.debugShowRainbow;
      return true;
    });
    return new MaterialApp(
        title: 'FlutterBlue',
        theme: theme,
      localizationsDelegates: <_AppLocalizationsDelegate>[
        new _AppLocalizationsDelegate(),
      ],
        debugShowMaterialGrid: _configuration.debugShowGrid,
        showPerformanceOverlay: _configuration.showPerformanceOverlay,
        showSemanticsDebugger: _configuration.showSemanticsDebugger,
        routes: <String, WidgetBuilder>{
          '/':         (BuildContext context) => new AppHome(_configuration, configurationUpdater),
          '/settings': (BuildContext context) => new AppSettings(_configuration, configurationUpdater)
        },
        onGenerateRoute: _getRoute,
    );
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppStrings> {
  @override
  Future<AppStrings> load(Locale locale) => AppStrings.load(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

void main() {
  runApp(new FlutterBlueApp());
}