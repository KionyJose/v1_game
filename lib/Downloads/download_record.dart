enum ReleaseSource { fitGirl, dodi, elAmigos, other, unknown }

ReleaseSource classifyReleaseSource(String source) {
  final value = source.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  if (value.contains('fitgirl')) return ReleaseSource.fitGirl;
  if (value.contains('dodi')) return ReleaseSource.dodi;
  if (value.contains('elamigos')) return ReleaseSource.elAmigos;
  return value.isEmpty ? ReleaseSource.unknown : ReleaseSource.other;
}

enum DownloadState {
  ready,
  preparing,
  queued,
  downloading,
  paused,
  canceled,
  completed,
  error
}

class DownloadRecord {
  final String id;
  String name;
  final List<String> torrentFiles;
  String sourceName;
  ReleaseSource get sourceType => classifyReleaseSource(sourceName);
  String edition;
  String pageUrl;
  String downloadUrl;
  Map<String, String> releaseInfo;
  final DateTime acquiredAt;
  String destination;
  bool destinationChosen;
  String? launchPath;
  String installationState = 'idle';
  String installationStatus = '';
  String? installationError;
  String? installationDirectory;
  String? installationProtocol;
  Map<String, dynamic> installationMetrics = {};
  double? installationProgress;
  bool get installing => installationState == 'extracting';
  DownloadState state;
  int totalBytes;
  int downloadedBytes;
  int speedBytes;
  int peers;
  String? gid;
  String? error;
  DateTime? startedAt;
  DateTime? completedAt;
  bool busy = false;
  // Tempo ativo da tentativa atual; pausa e fila não consomem esse prazo.
  Duration analysisElapsed = Duration.zero;
  DateTime? analysisUpdatedAt;
  bool receivedData = false;
  static const analysisDuration = Duration(minutes: 5);
  static const finalCheckDuration = Duration(minutes: 3);
  bool get waitingForData => running && !receivedData && downloadedBytes == 0;
  bool get checkingFinalData => analysisElapsed >= analysisDuration;
  Duration get analysisRemaining {
    final limit = checkingFinalData
        ? analysisDuration + finalCheckDuration
        : analysisDuration;
    final remaining = limit - analysisElapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  double get analysisProgress {
    final elapsed = checkingFinalData
        ? analysisElapsed - analysisDuration
        : analysisElapsed;
    final duration = checkingFinalData ? finalCheckDuration : analysisDuration;
    return (elapsed.inMilliseconds / duration.inMilliseconds).clamp(0, 1);
  }

  double get progress =>
      totalBytes > 0 ? (downloadedBytes / totalBytes).clamp(0, 1) : 0;
  bool get running => [
        DownloadState.downloading,
        DownloadState.queued,
        DownloadState.preparing
      ].contains(state);

  DownloadRecord(
      {required this.id,
      required this.name,
      required this.torrentFiles,
      required this.destination,
      required this.acquiredAt,
      this.destinationChosen = false,
      this.sourceName = '',
      this.edition = '',
      this.pageUrl = '',
      this.downloadUrl = '',
      this.releaseInfo = const {},
      this.state = DownloadState.ready,
      this.totalBytes = 0,
      this.downloadedBytes = 0,
      this.speedBytes = 0,
      this.peers = 0,
      this.gid,
      this.error,
      this.launchPath,
      this.startedAt,
      this.completedAt});

  Map<String, dynamic> toJson() => {
        'schemaVersion': 1,
        'id': id,
        'name': name,
        'releaseSource': {'type': sourceType.name, 'name': sourceName},
        'edition': edition,
        'releaseInfo': Map<String, String>.of(releaseInfo),
        'pageUrl': pageUrl,
        'downloadUrl': downloadUrl,
        'torrentFiles': List<String>.of(torrentFiles),
        'acquiredAt': acquiredAt.toIso8601String(),
        'download': {
          'state': state.name,
          'destination': destination,
          'destinationChosen': destinationChosen,
          'launchPath': launchPath,
          'installation': {
            'state': installationState,
            'status': installationStatus,
            'error': installationError,
            'directory': installationDirectory,
            'protocol': installationProtocol,
            'metrics': installationMetrics,
          },
          'totalBytes': totalBytes,
          'downloadedBytes': downloadedBytes,
          'speedBytes': speedBytes,
          'peers': peers,
          'gid': gid,
          'error': error,
          'startedAt': startedAt?.toIso8601String(),
          'completedAt': completedAt?.toIso8601String()
        },
      };

  factory DownloadRecord.fromJson(Map<String, dynamic> json) {
    final source = (json['releaseSource'] as Map?) ?? {};
    final download = (json['download'] as Map?) ?? {};
    final state = DownloadState.values.firstWhere(
        (s) => s.name == download['state'],
        orElse: () => DownloadState.ready);
    final id = json['id'] as String;
    if (!RegExp(r'^[a-fA-F0-9]{40}$').hasMatch(id)) {
      throw const FormatException('ID de torrent inválido');
    }
    final record = DownloadRecord(
        id: id,
        name: json['name'] as String,
        torrentFiles: (json['torrentFiles'] as List).cast<String>().toList(),
        destination: download['destination'] as String? ?? '',
        destinationChosen: download['destinationChosen'] == true,
        launchPath: download['launchPath'] as String?,
        acquiredAt: DateTime.parse(json['acquiredAt'] as String),
        sourceName: source['name'] as String? ?? '',
        edition: json['edition'] as String? ?? '',
        releaseInfo:
            (json['releaseInfo'] as Map?)?.cast<String, String>() ?? {},
        pageUrl: json['pageUrl'] as String? ?? '',
        downloadUrl: json['downloadUrl'] as String? ?? '',
        state: state,
        totalBytes: (download['totalBytes'] as num?)?.toInt() ?? 0,
        downloadedBytes: (download['downloadedBytes'] as num?)?.toInt() ?? 0,
        startedAt: DateTime.tryParse(download['startedAt'] as String? ?? ''),
        completedAt:
            DateTime.tryParse(download['completedAt'] as String? ?? ''),
        error: download['error'] as String?);
    final installation = (download['installation'] as Map?) ?? {};
    record.installationState = installation['state'] as String? ?? 'idle';
    record.installationStatus = installation['status'] as String? ?? '';
    record.installationError = installation['error'] as String?;
    record.installationDirectory = installation['directory'] as String?;
    record.installationProtocol = installation['protocol'] as String?;
    record.installationMetrics =
        (installation['metrics'] as Map?)?.cast<String, dynamic>() ?? {};
    if (record.installing) {
      record.installationState = 'failed';
      record.installationError =
          'A preparação foi interrompida. Clique em Jogar para tentar novamente.';
    }
    return record;
  }
}
