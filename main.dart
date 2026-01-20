import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tcc_3/models/filho_model.dart';
import 'package:tcc_3/services/notification_scheduler_service.dart';
import 'package:tcc_3/views/cadastrar_vacinas_screenfilho.dart';
import 'package:tcc_3/views/test_notificacoes_screen.dart';
import 'package:tcc_3/views/todasvacinasscreen.dart';
import 'package:tcc_3/views/home_page_filhos.dart';
import 'package:tcc_3/views/vacinaImport.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:tcc_3/services/notification_service.dart';
import 'firebase_options.dart';
import 'views/login_screen.dart';
import 'views/signup_screen.dart';
import 'views/home_page.dart';
import 'views/forgot_password_screen.dart';
import 'views/meus_filhos_screen.dart';
import 'views/datasimportantes.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// ===============================
// 🔔 CALLBACK PARA APP FECHADO
// ===============================
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  final payload = notificationResponse.payload;
  if (payload == null || payload.isEmpty) return;

  try {
    final data = jsonDecode(payload);

    navigatorKey.currentState?.pushNamed(
      '/home-filho',
      arguments: {
        'filhoId': data['filhoId'],
        'mostrarDialog': true,
        'meses': data['meses'],
        'vacinas': List<String>.from(data['vacinas']),
      },
    );
  } catch (_) {}
}

// ===============================
// 🌍 TIMEZONE
// ===============================
Future<void> _initTimezone() async {
  tz.initializeTimeZones();
  
  // AQUI: Certifique-se de que está usando .identifier
  final String localTz = (await FlutterTimezone.getLocalTimezone()).identifier;
  
  tz.setLocalLocation(tz.getLocation(localTz));
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final notificationPlugin = FlutterLocalNotificationsPlugin();

  await notificationPlugin.getNotificationAppLaunchDetails();


  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await VaccineImporter().importVaccinesFromExcel();
  await initializeDateFormatting('pt_BR', null);
  await _initTimezone();

  // 🔔 INICIALIZA NOTIFICAÇÕES (ÚNICO PONTO)
  await AppNotification.instance.initialize(
    onTap: _onNotificationTapped,
    onTapBackground: notificationTapBackground,
  );

  await NotificationSchedulerService.instance.initialize();

  runApp(const MyApp());
}

// ===============================
// 🔔 CALLBACK APP ABERTO
// ===============================
void _onNotificationTapped(NotificationResponse notificationResponse) {
  final payload = notificationResponse.payload;
  if (payload == null || payload.isEmpty) return;

  try {
    final data = jsonDecode(payload);

    navigatorKey.currentState?.pushNamed(
      '/home-filho',
      arguments: {
        'filhoId': data['filhoId'],
        'mostrarDialog': true,
        'meses': data['meses'],
        'vacinas': List<String>.from(data['vacinas']),
      },
    );
  } catch (e) {
    debugPrint('Erro no payload da notificação: $e');
  }
}

// ===============================
// 🚀 APP
// ===============================
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'ImunizaKids',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
        Locale('en', 'US'),
      ],
      locale: const Locale('pt', 'BR'),
      initialRoute: LoginScreen.routeName,
      routes: {
        LoginScreen.routeName: (_) => const LoginScreen(),
        '/signup': (_) => const SignupScreen(),
        '/forgot': (_) => const ForgotPasswordScreen(),
        '/home': (_) => const HomePage(),
        MeusFilhosPage.routeName: (_) => const MeusFilhosPage(),
        DatasImportantesScreen.routeName: (_) => const DatasImportantesScreen(),
        TodasVacinasScreen.routeName: (_) => const TodasVacinasScreen(),
        TestNotificacoesScreen.routeName: (_) => const TestNotificacoesScreen(),
        '/cadastrar-vacinas': (_) => const VacinasTomadasScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/home-filho') {
          final args = settings.arguments as Map<String, dynamic>;

          final filhoId = args['filhoId'];
          final mostrarDialog = args['mostrarDialog'] ?? false;
          final int? meses = args['meses'];
          final List<String>? vacinas = args['vacinas'] != null
              ? List<String>.from(args['vacinas'])
              : null;

          return MaterialPageRoute(
            builder: (_) => FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('filhos')
                  .doc(filhoId)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Scaffold(
                    body: Center(child: Text('Filho não encontrado')),
                  );
                }

                final data = snapshot.data!.data() as Map<String, dynamic>;

                final filho = Filho(
                  id: filhoId,
                  nome: data['nome'],
                  dataNascimento:
                      (data['dataNascimento'] as Timestamp).toDate(),
                  genero: data['genero'] ?? 'M',
                  usuarioId: data['usuarioId'],
                );

                return HomePagefilhos(
                  filho: filho,
                  mostrarDialog: mostrarDialog,
                  meses: meses,
                  vacinas: vacinas,
                );
              },
            ),
          );
        }
        return null;
      },
    );
  }
}
