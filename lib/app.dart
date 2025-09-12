// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'core/theme/app_theme.dart';
// import 'core/di/service_locator.dart';
// import 'presentation/blocs/auth/auth_bloc.dart';
// import 'presentation/blocs/user/user_bloc.dart';
// import 'routes/app_router.dart';

// class ChatApp extends StatelessWidget {
//   const ChatApp({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return MultiBlocProvider(
//       providers: [
//         BlocProvider(create: (_) => getIt<AuthBloc>()..add(AuthCheckRequested())),
//         BlocProvider(create: (_) => getIt<UserBloc>()),
//         // Add other global blocs here
//       ],
//       child: MaterialApp.router(
//         title: 'Chat App',
//         theme: AppTheme.lightTheme,
//         darkTheme: AppTheme.darkTheme, 
//         themeMode: ThemeMode.system,
//         routerConfig: AppRouter.router,
//         debugShowCheckedModeBanner: false,
//       ),
//     );
//   }
// }