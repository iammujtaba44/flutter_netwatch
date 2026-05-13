import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_netwatch/flutter_netwatch.dart';
import 'package:http/http.dart' as http;

late Dio dio;
late http.Client httpClient;

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  NetWatch.initialize(
    config: const NetWatchConfig(
      enabled: true,
      maskSensitiveData: true,
      showFloatingBubble: true,
      showNotifications: true,
      maxTransactions: 200,
      performanceBudgetMs: 1000,
    ),
  );

  dio = Dio(BaseOptions(baseUrl: 'https://jsonplaceholder.typicode.com'));
  dio.interceptors.add(NetWatch.dioInterceptor);

  httpClient = NetWatch.httpClient(http.Client());

  // Register replayers so the Replay FAB shows up on the detail screen.
  // First replayer whose canHandle() returns true wins. Order matters.
  NetWatch.registerReplayer(NWDioReplayer(dio));
  NetWatch.registerReplayer(NWHttpClientReplayer(httpClient));

  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'flutter_netwatch demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF6750A4),
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: const Color(0xFF6750A4),
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      builder: NetWatch.builder,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _lastResult = '';

  Future<void> _runCall(Future<void> Function() call, String label) async {
    setState(() => _lastResult = '$label running...');
    try {
      await call();
      setState(() => _lastResult = '$label done — open NetWatch to inspect');
    } catch (e) {
      setState(() => _lastResult = '$label failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('flutter_netwatch demo'),
        actions: const [
          _OpenButton(),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Tap any button to make an HTTP request. NetWatch will capture it.',
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Dio',
            children: [
              _Btn(
                label: 'GET /posts/1',
                onTap: () => _runCall(
                  () async => dio.get<dynamic>('/posts/1'),
                  'GET /posts/1',
                ),
              ),
              _Btn(
                label: 'POST /posts (with password)',
                onTap: () => _runCall(
                  () async => dio.post<dynamic>(
                    '/posts',
                    data: {
                      'title': 'hello',
                      'body': 'world',
                      'password': 'super-secret',
                      'user': {'token': 'jwt-here'},
                    },
                    options: Options(headers: {
                      'Authorization': 'Bearer my-token',
                      'X-API-Key': 'abc-123',
                    }),
                  ),
                  'POST /posts',
                ),
              ),
              _Btn(
                label: 'GET /404 (will fail)',
                onTap: () => _runCall(
                  () async => dio.get<dynamic>('/posts/999999'),
                  'GET 404',
                ),
              ),
              _Btn(
                label: 'Slow GET (3s delay)',
                onTap: () => _runCall(
                  () async => dio.get<dynamic>(
                    'https://httpbin.org/delay/3',
                  ),
                  'Slow GET',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'http package',
            children: [
              _Btn(
                label: 'GET via http.Client',
                onTap: () => _runCall(
                  () async => httpClient.get(
                    Uri.parse('https://jsonplaceholder.typicode.com/users/1'),
                  ),
                  'http GET',
                ),
              ),
              _Btn(
                label: 'POST via http.Client',
                onTap: () => _runCall(
                  () async => httpClient.post(
                    Uri.parse('https://jsonplaceholder.typicode.com/posts'),
                    headers: const {
                      'Authorization': 'Bearer secret',
                      'Content-Type': 'application/json',
                    },
                    body: '{"name":"alice","password":"hunter2"}',
                  ),
                  'http POST',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Insecure / suspicious',
            children: [
              _Btn(
                label: 'GET http:// (insecure)',
                onTap: () => _runCall(
                  () async => dio.get<dynamic>('http://example.com'),
                  'HTTP request',
                ),
              ),
              _Btn(
                label: 'GET ?token=xyz (sensitive in URL)',
                onTap: () => _runCall(
                  () async => dio.get<dynamic>(
                    'https://jsonplaceholder.typicode.com/posts?token=secret123',
                  ),
                  'Sensitive URL',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: NetWatch.clear,
            icon: const Icon(Icons.delete_outline),
            label: const Text('Clear NetWatch'),
          ),
          const SizedBox(height: 16),
          if (_lastResult.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_lastResult),
            ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w700,
            fontSize: 12,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }
}

class _OpenButton extends StatelessWidget {
  const _OpenButton();

  @override
  Widget build(BuildContext context) {
    return const IconButton(
      icon: Icon(Icons.visibility),
      onPressed: NetWatch.open,
      tooltip: 'Open NetWatch',
    );
  }
}

class _Btn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _Btn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.tonal(
          onPressed: onTap,
          child: Text(label),
        ),
      ),
    );
  }
}
