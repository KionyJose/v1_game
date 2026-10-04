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
    return DownloadRecord(
        id: id,
        name: json['name'] as String,
        torrentFiles: (json['torrentFiles'] as List).cast<String>().toList(),
        destination: download['destination'] as String? ?? '',
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
  }
}
