// ignore_for_file: file_names

import 'package:xinput_gamepad/xinput_gamepad.dart';

class Paad{

  recebeDados(Function(String) repasse){

    XInputManager.enableXInput();

    List<Controller> availableControllers = List.empty(growable: true);
    for (int controllerIndex in ControllersManager.getIndexConnectedControllers()) {
      final Controller controller = Controller(index: controllerIndex, buttonMode: ButtonMode.PRESS);
      controller.buttonsMapping = {
        
        // controller.vibrate(const Duration(seconds: 3));
        ControllerButton.A_BUTTON: () => repasse("2"),
        ControllerButton.B_BUTTON: () => repasse("3"),
        ControllerButton.X_BUTTON: () => repasse("1"),
        ControllerButton.Y_BUTTON: () => repasse("4"),
        ControllerButton.DPAD_UP: () => repasse("CIMA"),
        ControllerButton.DPAD_DOWN: () => repasse("BAIXO"),
        ControllerButton.DPAD_LEFT: () => repasse("ESQUERDA"),
        ControllerButton.DPAD_RIGHT: () => repasse("DIREITA"),
        ControllerButton.LEFT_SHOULDER: () => repasse("LB"),
        ControllerButton.RIGHT_SHOULDER: () => repasse("RB"),        
        ControllerButton.LEFT_THUMB: () => repasse("L3"),
        ControllerButton.RIGHT_THUMB: () => repasse("R3"),
        ControllerButton.START: () => repasse("START"),
        ControllerButton.BACK: () => repasse("SELECT"),
      };
      controller.buttonsCombination = {
        { ControllerButton.LEFT_SHOULDER,ControllerButton.RIGHT_SHOULDER }: () => repasse("[LB; RB]"),
        { ControllerButton.LEFT_THUMB, ControllerButton.RIGHT_THUMB}: () => repasse("[L3; R3]"),
        { ControllerButton.LEFT_SHOULDER, ControllerButton.RIGHT_SHOULDER, ControllerButton.A_BUTTON }: () => repasse("[LB; RB; A (2)]"),
      };
      controller.variableKeysMapping = {
        VariableControllerKey.LEFT_TRIGGER: (value) => repasse("LT - $value"),
        VariableControllerKey.RIGHT_TRIGGER: (value) => repasse("RT - $value"),


        VariableControllerKey.THUMB_LX: (value) => repasse("ANALOGICO ESQUERDO X - $value"),
        VariableControllerKey.THUMB_LY: (value) => repasse("ANALOGICO ESQUERDO Y - $value"),
        VariableControllerKey.THUMB_RX: (value) => repasse("ANALOGICO DIREITO X - $value"),
        VariableControllerKey.THUMB_RY: (value) => repasse("ANALOGICO DIREITO Y - $value")
      };
      // controller.onReleaseButton = (button) => debugPrint("$button has ben released");

      availableControllers.add(controller);
    }

    // debugPrint("Available controllers:");
    // for (Controller controller in availableControllers) {
    //   debugPrint("Controller ${controller.index}");
    // }

    for (Controller controller in availableControllers) {
      controller.listen();
    }
  }

}