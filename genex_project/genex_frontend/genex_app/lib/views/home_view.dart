// // lib/views/home_view.dart
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../viewmodels/providers.dart';

// class HomeView extends ConsumerWidget {
//   const HomeView({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final authState = ref.watch(authViewModelProvider);
//     final authVM = ref.read(authViewModelProvider.notifier);

//     final username = authState.user?.name ?? 'Guest';
//     final role = authState.user?.role ?? '';

//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Welcome, $username'),
//         actions: [
//           IconButton(
//             onPressed: () async {
//               await authVM.logout();
//               Navigator.of(context).pushReplacementNamed('/signin');
//             },
//             icon: Icon(Icons.logout),
//           )
//         ],
//       ),
//       body: Center(child: Text('You are signed in as $role')),
//     );
//   }
// }
