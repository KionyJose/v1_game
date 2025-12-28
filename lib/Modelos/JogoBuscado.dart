// ignore_for_file: file_names

class JogoBuscado {
  final String name;
  final String exePath;
  final String installDir;
  final String platform;
  final String? thumbnailPath;

  JogoBuscado({required this.name, required this.exePath, required this.installDir, required this.platform, this.thumbnailPath});

  Map<String, dynamic> toMap(){
    return {
      'name': name,
      'exePath': exePath,
      'installDir': installDir,
      'platform': platform,
      'thumbnailPath': thumbnailPath,
    };
  }
}
