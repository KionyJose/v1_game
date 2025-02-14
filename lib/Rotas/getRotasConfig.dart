// ignore_for_file: file_names

import 'package:get_it/get_it.dart';

import 'PaadGet.dart';

class GetRotasConfg {
  final getIt = GetIt.instance;

  void configure() {
    getIt.registerSingleton<PaadGet>(PaadGet());  
    // getIt.registerSingleton<ReserverOrderRepository>(ReserverOrderRepository());
    // getIt.registerSingleton<LoginRepository>(LoginRepository());
    // getIt.registerSingleton<AdminRepository>(AdminRepository());
    // getIt.registerSingleton<LobyRepository>(LobyRepository());
    // getIt.registerSingleton<SorteadorRepository>(SorteadorRepository());
    // getIt.registerSingleton<JogadorRepository>(JogadorRepository());
  }
}
