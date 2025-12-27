import 'dart:io';
import 'package:flutter/material.dart';

class ModificaWind {
	/// Executa script para desabilitar Xbox Game Bar e Steam ao iniciar o sistema
	static Future<void> desabilitarXboxESteam() async {
		const scriptPath = 'assets/Scripts/disable_xbox_steam.ps1';
		try {
			await Process.run('powershell', [
				'-ExecutionPolicy', 'Bypass',
				'-File', scriptPath
			]);
		} catch (e) {
			// Trate o erro conforme necessário
			debugPrint('Erro ao executar script: $e');
		}
	}
}