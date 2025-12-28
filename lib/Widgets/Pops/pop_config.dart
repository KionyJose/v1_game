import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:v1_game/Class/Paad.dart';
import 'package:v1_game/Controllers/MovimentoSistema.dart';
import 'package:v1_game/Controllers/SonsSistema.dart';
import 'package:v1_game/Global.dart';

class PopConfig {
  
  static config(BuildContext context) async {
    List<String> commandos = [];
    try{
    bool statePop = true;
    String retorno = "";
    int total = 7; // 7 controles de configuração (adicionado sequencia custom)
    FocusScopeNode focusScope = FocusScopeNode();
    
    // Cria cópias das configurações para poder cancelar
    double volumeTemp = configSistema.volume;
    bool introTemp = configSistema.intro;
    bool videosTelaPrincipalTemp = configSistema.videosTelaPrincipal;
    bool videosCardGameTemp = configSistema.noticias;
    List<String> sequenciaCustomTemp = List.from(configSistema.sequenciaAtivaMouseCustom);
    
    // Estado de edição da sequência
    bool editandoSequencia = false;
    List<String> sequenciaEditando = [];
    
    // Flag para controlar se comandoAtivo já foi desligado
    bool comandoAtivoDesligado = false;

    List<FocusNode> focusNodes = List.generate(total, (value)=> FocusNode());

    // Atualiza a tela
    void Function(void Function())? setStateDialog;

    // Função para fechar o dialog religando comandoAtivo
    void fecharDialog(BuildContext context, String resultado, Paad paad) {
      paad.comandoAtivo = true;
      Navigator.pop(context, resultado);
    }

    comandos(BuildContext context, String event, Paad paad){
      int total = 0;
      if(commandos.length == 2){
        commandos.removeAt(0);
        commandos.add(event);
        if(commandos[0] == "SELECT")total++;
        if(commandos[1] == "SELECT")total++;
        if(total == 2) fecharDialog(context, "cancelar", paad);
        if(total == 2) return false;
      }
      commandos.add(event);
      return true;
    }

    escutaPad(String event, Paad paad) {
      if(!statePop || event =="") return;
      debugPrint("=======   Escuta Pop Config  =======");

      // Se está editando sequência, captura os botões
      if(editandoSequencia) {
        // Filtra apenas botões permitidos (não analógicos nem gatilhos)
        List<String> botoesPermitidos = ["1", "2", "3", "4", "CIMA", "BAIXO", "ESQUERDA", 
                                         "DIREITA", "LB", "RB", "L3", "R3", "START", "SELECT"];
        
        if(botoesPermitidos.contains(event)) {
          sequenciaEditando.add(event);
          SonsSistema.pim();
          
          // Quando completar 5 botões, finaliza a edição
          if(sequenciaEditando.length == 5) {
            sequenciaCustomTemp = List.from(sequenciaEditando);
            editandoSequencia = false;
            sequenciaEditando.clear();
            SonsSistema.cheat();
          }
          
          setStateDialog?.call((){});
        }
        return;
      }

      statePop = comandos(context, event, paad);
      
      // Ajustes nos valores com setas
      if(event == "ESQUERDA" || event == "DIREITA"){
        // Volume (focusNodes[0])
        if(focusNodes[0].hasFocus){
          if(event == "DIREITA" && volumeTemp < 1.0) {
            volumeTemp = (volumeTemp + 0.1).clamp(0.0, 1.0);
            SonsSistema.click(); // Toca som para testar volume
          }
          if(event == "ESQUERDA" && volumeTemp > 0.0) {
            volumeTemp = (volumeTemp - 0.1).clamp(0.0, 1.0);
            SonsSistema.click(); // Toca som para testar volume
          }
          setStateDialog?.call((){});
          return;
        }
        
        // Intro (focusNodes[1]) - Toggle com setas
        if(focusNodes[1].hasFocus){
          introTemp = !introTemp;
          SonsSistema.click();
          setStateDialog?.call((){});
          return;
        }
        
        // Videos Tela Principal (focusNodes[2]) - Toggle com setas
        if(focusNodes[2].hasFocus){
          videosTelaPrincipalTemp = !videosTelaPrincipalTemp;
          SonsSistema.click();
          setStateDialog?.call((){});
          return;
        }
        
        // Videos Card Game (focusNodes[3]) - Toggle com setas
        if(focusNodes[3].hasFocus){
          videosCardGameTemp = !videosCardGameTemp;
          SonsSistema.click();
          setStateDialog?.call((){});
          return;
        }
      }

      MovimentoSistema.direcaoListView(focusScope, event);

      if(event == "3"){// Cancelar
        statePop = false;
        fecharDialog(context, "cancelar", paad);
      }
      if(event == "2"){// Confirmar ou Toggle
        debugPrint("======================================== BOTÃO 2 PRESSIONADO");
        
        // Toggle switches (true/false) com botão 2
        if(focusNodes[1].hasFocus){ // Intro
          introTemp = !introTemp;
          SonsSistema.click();
          setStateDialog?.call((){});
          return;
        }
        
        if(focusNodes[2].hasFocus){ // Videos Tela Principal
          videosTelaPrincipalTemp = !videosTelaPrincipalTemp;
          SonsSistema.click();
          setStateDialog?.call((){});
          return;
        }
        
        if(focusNodes[3].hasFocus){ // Videos Card Game
          videosCardGameTemp = !videosCardGameTemp;
          SonsSistema.click();
          setStateDialog?.call((){});
          return;
        }
        
        // Editar Sequência Custom (focusNodes[4])
        if(focusNodes[4].hasFocus){
          editandoSequencia = true;
          sequenciaEditando.clear();
          SonsSistema.cheat();
          setStateDialog?.call((){});
          return;
        }
        
        statePop = false;
        
        // Salvar (focusNodes[5])
        if (focusNodes[5].hasFocus) {
          configSistema.volume = volumeTemp;
          configSistema.intro = introTemp;
          configSistema.videosTelaPrincipal = videosTelaPrincipalTemp;
          configSistema.noticias = videosCardGameTemp;
          configSistema.sequenciaAtivaMouseCustom = sequenciaCustomTemp;
          fecharDialog(context, "salvar", paad);
        }
        
        // Cancelar (focusNodes[6])
        if (focusNodes[6].hasFocus) {
          fecharDialog(context, "cancelar", paad);
        }
        
        statePop = true;
      }
    }

    Widget buildConfigItem(String label, Widget control, FocusNode focus) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        child: Focus(
          focusNode: focus,
          child: Builder(
            builder: (context) {
              final hasFocus = Focus.of(context).hasFocus;
              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: hasFocus ? Colors.white12 : Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: hasFocus ? Colors.white : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: hasFocus ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    control,
                  ],
                ),
              );
            }
          ),
        ),
      );
    }

    Widget buildButton(String text, FocusNode focus, IconData icon) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Container(
              color: Colors.black38,
              height: 45,
              child: MaterialButton(
                focusNode: focus,
                focusColor: Colors.white70,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      text,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                onPressed: () {
                  final paad = Provider.of<Paad>(context, listen: false);
                  if(text == "Salvar") {
                    configSistema.volume = volumeTemp;
                    configSistema.intro = introTemp;
                    configSistema.videosTelaPrincipal = videosTelaPrincipalTemp;
                    configSistema.noticias = videosCardGameTemp;
                    configSistema.sequenciaAtivaMouseCustom = sequenciaCustomTemp;
                    fecharDialog(context, "salvar", paad);
                  } else {
                    fecharDialog(context, "cancelar", paad);
                  }
                },
              ),
            ),
          ),
        ),
      );
    }
    
    await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) {
          return Consumer<Paad>(
            builder: (_, paad, child) {
              // Desativa comandoAtivo ao entrar no popup (apenas uma vez)
              if(!comandoAtivoDesligado) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if(paad.comandoAtivo) {
                    paad.comandoAtivo = false;
                    comandoAtivoDesligado = true;
                  }
                });
              }
              
              escutaPad(paad.click, paad);
              
              return KeyboardListener(
                focusNode: FocusNode(),
                onKeyEvent: (KeyEvent event) {
                  if (event is KeyDownEvent) {
                    String key = MovimentoSistema.convertKeyBoard(event.logicalKey.keyLabel);
                    escutaPad(key, paad);
                  }
                },
                child: StatefulBuilder(
                  builder: (context, setState) {
                    setStateDialog = setState;
                    
                    return AlertDialog(
                      backgroundColor: Colors.transparent,
                      contentPadding: const EdgeInsets.only(left: 8, right: 8, bottom: 4),
                      content: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black87,
                                Colors.black87,
                              ],
                            ),
                          ),
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.38,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                // Limita a altura máxima para evitar overflow e permite rolagem quando necessário
                                maxHeight: MediaQuery.of(context).size.height * 0.9,
                              ),
                              child: SingleChildScrollView(
                                child: FocusScope(
                                  node: focusScope,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                  const SizedBox(height: 15),
                                  const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.settings, color: Colors.white, size: 24),
                                      SizedBox(width: 8),
                                      Text(
                                        "Configurações",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  
                                  // Volume
                                  buildConfigItem(
                                    "Volume",
                                    Row(
                                      children: [
                                        Text(
                                          "${(volumeTemp * 100).toInt()}%",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(Icons.volume_up, color: Colors.white, size: 20),
                                      ],
                                    ),
                                    focusNodes[0],
                                  ),
                                  
                                  // Intro
                                  buildConfigItem(
                                    "Som Intro",
                                    Icon(
                                      introTemp ? Icons.check_circle : Icons.cancel,
                                      color: introTemp ? Colors.green : Colors.red,
                                      size: 24,
                                    ),
                                    focusNodes[1],
                                  ),
                                  
                                  // Videos Tela Principal
                                  buildConfigItem(
                                    "Vídeos Tela Principal",
                                    Icon(
                                      videosTelaPrincipalTemp ? Icons.check_circle : Icons.cancel,
                                      color: videosTelaPrincipalTemp ? Colors.green : Colors.red,
                                      size: 24,
                                    ),
                                    focusNodes[2],
                                  ),
                                  
                                  // Videos Card Game
                                  buildConfigItem(
                                    "Noticias do Jogo",
                                    Icon(
                                      videosCardGameTemp ? Icons.check_circle : Icons.cancel,
                                      color: videosCardGameTemp ? Colors.green : Colors.red,
                                      size: 24,
                                    ),
                                    focusNodes[3],
                                  ),
                                  
                                  // Sequência Custom de Ativar Mouse
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                          child: Focus(
                                            focusNode: focusNodes[4],
                                            child: Builder(
                                              builder: (context) {
                                                final hasFocus = Focus.of(context).hasFocus;
                                                return Container(
                                                  padding: const EdgeInsets.all(10),
                                                  decoration: BoxDecoration(
                                                    color: hasFocus ? Colors.white12 : Colors.black26,
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(
                                                      color: hasFocus ? Colors.white : Colors.transparent,
                                                      width: 2,
                                                    ),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: [
                                                          Text(
                                                            "Sequência Custom Mouse",
                                                            style: TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 15,
                                                              fontWeight: hasFocus ? FontWeight.bold : FontWeight.normal,
                                                            ),
                                                          ),
                                                          Icon(
                                                            editandoSequencia ? Icons.edit : Icons.edit_outlined,
                                                            color: editandoSequencia ? Colors.orange : Colors.white70,
                                                            size: 18,
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 6),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                        decoration: BoxDecoration(
                                                          color: editandoSequencia ? Colors.orange.withValues(alpha:0.2) : Colors.black26,
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                        child: Text(
                                                          editandoSequencia 
                                                            ? "${sequenciaEditando.length}/5: ${sequenciaEditando.isEmpty ? '...' : sequenciaEditando.join(' → ')}"
                                                            : sequenciaCustomTemp.join(" → "),
                                                          style: TextStyle(
                                                            color: editandoSequencia ? Colors.orange : Colors.white70,
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }
                                            ),
                                          ),
                                        ),
                                  
                                  const Divider(color: Colors.white30, thickness: 1, height: 20),
                                  
                                  // Botões de ação
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    child: Row(
                                      children: [
                                        buildButton("Salvar", focusNodes[5], Icons.save),
                                        buildButton("Cancelar", focusNodes[6], Icons.close),
                                      ],
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 5),
                                ],
                              ),
                            ),
                          ),
                            )
                          )
                        ),
                      ),
                    );
                  }
                ),
              );
            }
          );
        }).then((value) => retorno = value.toString());

    return retorno;
    }catch(e){
      debugPrint("Erro no PopConfig: $e");
    }
    return "cancelar";
  }
}
