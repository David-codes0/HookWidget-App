import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

Stream<String> getDate() => Stream.periodic(
    const Duration(seconds: 1), (_) => DateTime.now().toIso8601String());

extension CompactMap<T> on Iterable<T?> {
  Iterable<T> compactMap<E>([E? Function(T?)? transform]) => map(
        transform ?? (e) => e,
      ).where((e) => e != null).cast();
}

const url =
    'https://images.unsplash.com/photo-1502085671122-2d218cd434e6?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=926&q=80';

class CountDown extends ValueNotifier<int> {
  late StreamSubscription sub;

  CountDown({required int from}) : super(from) {
    sub = Stream.periodic(
      const Duration(
        seconds: 2,
      ),
      (v) => from - v,
    ).takeWhile((value) => value >= 0).listen((value) {
      this.value = value;
    });
  }

  @override
  void dispose() {
    sub.cancel();
    super.dispose();
  }
}

class HomePage extends HookWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final countDown = useMemoized(() => CountDown(from: 100));
    final notifier = useListenable(countDown);

// //////////////////////////////////////
    final future = useMemoized(() => NetworkAssetBundle(Uri.parse(url))
        .load(url)
        .then((data) => data.buffer.asUint8List())
        .then((data) => Image.memory(data)));

    final snapshotImage = useFuture(future);
// /////////////////////////////
    final controller = useTextEditingController();

    final text = useState('');
    useEffect(() {
      controller.addListener(() {
        text.value = controller.text;
      });
      return null;
    }, [controller]);
// /////////////////////////////////////
    final datenow = useStream(getDate());
// //////////////////////////////////
    return Scaffold(
      appBar: AppBar(
        title: Text(datenow.data ?? 'HomePage'),
      ),
      body: Column(
        children: [
          TextField(
            controller: controller,
          ),
          Text(
            'You type: ${text.value}',
            style: Theme.of(context).textTheme.headline3,
          ),
          const SizedBox(
            height: 40,
          ),
          snapshotImage.data,
          const SizedBox(
            height: 40,
          ),
          Text(
            '${notifier.value}',
            style: Theme.of(context).textTheme.headline3,
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const MyHomepage()));
            },
            child: const Text('Animated scroll view Like Sliver app bar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ImageRotatingPage(),
                ),
              );
            },
            child: const Text('Image Rotating page'),
          ),
        ].compactMap().toList(),
      ),
    );
  }
}

const imageHeight = 300.0;

extension Normalize on num {
  num normalize(
    num selfRangemin,
    num selfRangemax, [
    num normalizeSelfRangemin = 0.0,
    num normalizeSelfRangemax = 1.0,
  ]) =>
      (normalizeSelfRangemax - normalizeSelfRangemin) *
      ((this - selfRangemin) / (selfRangemax - selfRangemin) +
          normalizeSelfRangemin);
}

class MyHomepage extends HookWidget {
  const MyHomepage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final opacity = useAnimationController(
      duration: const Duration(
        seconds: 5,
      ),
      initialValue: 1.0,
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    final size = useAnimationController(
      duration: const Duration(
        seconds: 5,
      ),
      initialValue: 1.0,
      lowerBound: 0.0,
      upperBound: 1.0,
    );

    final scrollcontroller = useScrollController();
    useEffect(() {
      scrollcontroller.addListener(() {
        final newOpacity = max(imageHeight - scrollcontroller.offset, 0.0);
        final normalized = newOpacity.normalize(0.0, imageHeight).toDouble();
        opacity.value = normalized;
        size.value = normalized;
      });

      return null;
    }, [scrollcontroller]);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Animated Scroll view'),
      ),
      body: Column(
        children: [
          SizeTransition(
            sizeFactor: size,
            axis: Axis.vertical,
            axisAlignment: -1.0,
            child: FadeTransition(
                opacity: opacity,
                child: Container(
                  height: 100,
                  color: Colors.yellow,
                )),
          ),
          SizeTransition(
            sizeFactor: size,
            axis: Axis.vertical,
            axisAlignment: -1.0,
            child: FadeTransition(
                opacity: opacity,
                child: Container(
                  height: 100,
                  color: Colors.purple,
                )),
          ),
          SizeTransition(
            sizeFactor: size,
            axis: Axis.vertical,
            axisAlignment: -1.0,
            child: FadeTransition(
                opacity: opacity,
                child: Container(
                  height: 100,
                  color: Colors.blue,
                )),
          ),
          SizeTransition(
            sizeFactor: size,
            axis: Axis.vertical,
            axisAlignment: -1.0,
            child: FadeTransition(
                opacity: opacity,
                child: Container(
                  height: 100,
                  color: Colors.green,
                )),
          ),
          Expanded(
            child: ListView.builder(
              controller: scrollcontroller,
              itemCount: 100,
              itemBuilder: (context, index) => (ListTile(
                title: Text('Person ${index + 1}'),
              )),
            ),
          )
        ],
      ),
    );
  }
}

class ImageRotatingPage extends HookWidget {
  const ImageRotatingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    late final StreamController<double> controller;

    controller = useStreamController(
      onListen: () => controller.sink.add(0.0),
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Object Rotator'),
      ),
      body: StreamBuilder<double>(
          stream: controller.stream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const CircularProgressIndicator();
            } else {
              final rotation = snapshot.data ?? 0.0;
              return GestureDetector(
                onTap: () {
                  controller.sink.add(rotation - 10);
                },
                onDoubleTap: () {
                  controller.sink.add(rotation + 10);
                },
                child: RotationTransition(
                  turns: AlwaysStoppedAnimation(rotation / 360),
                  child: Center(
                    child: Container(
                      height: 400,
                      color: Colors.green,
                    ),
                  ),
                ),
              );
            }
          }),
    );
  }
}
