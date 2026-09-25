enum TorrentStatus {
  idle,
  parsing,
  downloading,
  paused,
  checkingIntegrity,
  completed,
  error,
}

class TorrentModel {
  final String name;
  final String saveDirectory;
  final int totalBytes;
  final int downloadedBytes;
  final double progress; // 0.0 a 1.0
  final double downloadSpeed; // KB/s
  final int peersCount;
  final TorrentStatus status;
  final String? errorMessage;

  TorrentModel({
    required this.name,
    required this.saveDirectory,
    required this.totalBytes,
    required this.downloadedBytes,
    required this.progress,
    required this.downloadSpeed,
    required this.peersCount,
    required this.status,
    this.errorMessage,
  });

  factory TorrentModel.initial() {
    return TorrentModel(
      name: 'Nenhum torrent carregado',
      saveDirectory: '',
      totalBytes: 0,
      downloadedBytes: 0,
      progress: 0.0,
      downloadSpeed: 0.0,
      peersCount: 0,
      status: TorrentStatus.idle,
    );
  }

  TorrentModel copyWith({
    String? name,
    String? saveDirectory,
    int? totalBytes,
    int? downloadedBytes,
    double? progress,
    double? downloadSpeed,
    int? peersCount,
    TorrentStatus? status,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return TorrentModel(
      name: name ?? this.name,
      saveDirectory: saveDirectory ?? this.saveDirectory,
      totalBytes: totalBytes ?? this.totalBytes,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      progress: progress ?? this.progress,
      downloadSpeed: downloadSpeed ?? this.downloadSpeed,
      peersCount: peersCount ?? this.peersCount,
      status: status ?? this.status,
      errorMessage: clearErrorMessage ? null : errorMessage ?? this.errorMessage,
    );
  }
}
