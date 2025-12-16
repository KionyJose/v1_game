// ignore_for_file: library_private_types_in_public_api, file_names
import 'package:flutter/material.dart';

class BarraProgressoYT extends StatefulWidget {
  final Duration duracaoTotal;
  final Duration duracaoInicial;

  const BarraProgressoYT({
    Key? key,
    required this.duracaoTotal,
    this.duracaoInicial = Duration.zero,
  }) : super(key: key);

  @override
  _BarraProgressoYTState createState() => _BarraProgressoYTState();
}

class _BarraProgressoYTState extends State<BarraProgressoYT> {

  @override
  Widget build(BuildContext context) {
    // Usa DIRETAMENTE o valor do controller ao invés de timer interno
    Duration tempoDecorrido = widget.duracaoInicial;
    
    double progressoPercentual = widget.duracaoTotal.inMilliseconds > 0
        ? tempoDecorrido.inMilliseconds / widget.duracaoTotal.inMilliseconds
        : 0.0;

    // Calculando minutos e segundos decorridos
    int minutosDecorridos = tempoDecorrido.inMinutes;
    int segundosDecorridos = tempoDecorrido.inSeconds % 60;

    // Calculando minutos e segundos restantes
    Duration restante = widget.duracaoTotal;
    int minutosRestantes = restante.inMinutes;
    int segundosRestantes = restante.inSeconds % 60;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 100),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            // height: 12,
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(3.0),
            ),
          ),
          FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progressoPercentual,
            child: Container(
              // height: 12,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color.fromARGB(255, 0, 60, 110), Color.fromARGB(255, 59, 0, 77)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(3.0),
              ),
            ),
          ),
          Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  child: Text(
                    '$minutosDecorridos:${segundosDecorridos.toString().padLeft(2, '0')}'
                    ' / '
                    '$minutosRestantes:${segundosRestantes.toString().padLeft(2, '0')}     ',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          
        ],
      ),
    );
  }
}
