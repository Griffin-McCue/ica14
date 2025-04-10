import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_in_app_messaging/firebase_in_app_messaging.dart';
import 'firebase_options.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(MessagingApp());
}

class MessagingApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Messaging + In-App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MessagingHomePage(title: 'Firebase Messaging + In-App'),
    );
  }
}

class MessagingHomePage extends StatefulWidget {
  final String title;
  const MessagingHomePage({Key? key, required this.title}) : super(key: key);

  @override
  _MessagingHomePageState createState() => _MessagingHomePageState();
}

class _MessagingHomePageState extends State<MessagingHomePage> {
  late FirebaseMessaging _messaging;
  String? _fcmToken;
  List<Map<String, String>> _notificationHistory = [];

  @override
  void initState() {
    super.initState();
    _initializeFirebaseMessaging();

    // Enable In-App Messaging (optional)
    FirebaseInAppMessaging.instance.setMessagesSuppressed(false);
    // You can also trigger custom events defined in Firebase Console:
    // FirebaseInAppMessaging.instance.triggerEvent("custom_event");
  }

  void _initializeFirebaseMessaging() async {
    _messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await _messaging.requestPermission();

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      _messaging.subscribeToTopic("messaging");

      _messaging.getToken().then((token) {
        setState(() {
          _fcmToken = token;
        });
        print("FCM Token: $token");
      });

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _handleMessage(message, inApp: true);
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleMessage(message, inApp: false);
      });
    }
  }

  void _handleMessage(RemoteMessage message, {bool inApp = false}) {
    String notificationType = message.data['notificationType'] ?? 'regular';
    String title = message.notification?.title ?? 'No Title';
    String body = message.notification?.body ?? 'No Body';

    setState(() {
      _notificationHistory.add({
        'type': notificationType,
        'title': title,
        'body': body,
      });
    });

    _showNotificationDialog(notificationType, title, body);
  }

  void _showNotificationDialog(String type, String title, String body) {
    MaterialColor dialogColor = type == 'important' ? Colors.red : Colors.blue;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dialogColor.shade100,
        title: Row(
          children: [
            Icon(
              type == 'important' ? Icons.warning : Icons.notifications,
              color: dialogColor,
            ),
            SizedBox(width: 8),
            Text(title, style: TextStyle(color: dialogColor.shade900)),
          ],
        ),
        content: Text(body, style: TextStyle(color: dialogColor.shade800)),
        actions: [
          TextButton(
            onPressed: () {
              print('Action button pressed');
              Navigator.of(context).pop();
            },
            child: Text('Acknowledge'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Dismiss'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationHistory() {
    if (_notificationHistory.isEmpty) {
      return Text('No notifications received yet.');
    }
    return ListView.builder(
      itemCount: _notificationHistory.length,
      itemBuilder: (context, index) {
        final notification = _notificationHistory[index];
        MaterialColor typeColor = notification['type'] == 'important' ? Colors.red : Colors.blue;
        return ListTile(
          leading: Icon(
            notification['type'] == 'important' ? Icons.warning : Icons.notifications,
            color: typeColor,
          ),
          title: Text(notification['title'] ?? 'Title'),
          subtitle: Text(notification['body'] ?? 'Body'),
          tileColor: typeColor.withOpacity(0.1),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            SelectableText(
              'FCM Token:\n${_fcmToken ?? "Loading..."}',
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
            SizedBox(height: 20),
            Text("Notification History", style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(child: _buildNotificationHistory()),
          ],
        ),
      ),
    );
  }
}