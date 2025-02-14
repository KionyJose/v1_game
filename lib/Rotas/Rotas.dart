import 'package:flutter/material.dart';
import 'package:v1_game/Tela/Begin.dart';

class Rotas {
  static Route<dynamic> geradorRotas(RouteSettings settings) {
    switch (settings.name) {
      // case '/': return MaterialPageRoute(builder: (context) => const HomePage());
      // case 'reserver_order_page': return generateSlideRoute(const ReserverOrderPage());
      // case 'adminPage': return  generateSlideRoute(const AdminPage());
      // case'loginPage': return generateSlideRoute(const LoginPage());
      // case'lobyPage': return generateSlideRoute(const LobyPage());
      // case'sorteador': return generateSlideRoute(const Sorteador());
      default: return MaterialPageRoute(builder: (_) => const Begin());
    }
  }

  // Função para definir as animações de transição
  static Route<dynamic> geradorSlideRotas(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        var tween =Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
    );
  }

  static Route<dynamic> generateFadeRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Adicionando a animação de fade
        var fadeAnimation =
            Tween<double>(begin: 0.0, end: 1.0).animate(animation);

        return FadeTransition(
          opacity: fadeAnimation,
          child: child,
        );
      },
    );
  }
}
