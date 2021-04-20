import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const platform = const MethodChannel('samples.flutter/steps');

  String _stepCount = 'Unknown Step Count.';

  @override
  void initState() {
    super.initState();
    _getPedometerSteps();
  }

  Future<void> _getPedometerSteps() async {
    String stepCount;
    try {
      final int result = await platform.invokeMethod('getPedometerSteps');
      stepCount = 'No of Steps are $result .';
    } on PlatformException catch (e) {
      stepCount = "Failed to get Step Count: '${e.message}'.";
    }

    setState(() {
      _stepCount = stepCount;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              child: Text('Get Step Count'),
              onPressed: _getPedometerSteps,
            ),
            Text(_stepCount),
          ],
        ),
      ),
    );
  }
}
