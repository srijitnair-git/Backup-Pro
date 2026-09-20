enum SyncDirection {
  toNas,
  fromNas,
  twoWay;

  String get label {
    switch (this) {
      case SyncDirection.toNas:
        return 'To NAS';
      case SyncDirection.fromNas:
        return 'From NAS';
      case SyncDirection.twoWay:
        return 'Two-Way';
    }
  }
}

class FolderPair {
  String local;
  String remote;
  SyncDirection direction;

  FolderPair({
    required this.local,
    required this.remote,
    this.direction = SyncDirection.toNas,
  });

  Map<String, dynamic> toJson() => {
        'local': local,
        'remote': remote,
        'direction': direction.name,
      };

  factory FolderPair.fromJson(Map<String, dynamic> json) => FolderPair(
        local: json['local'] as String,
        remote: json['remote'] as String,
        direction: SyncDirection.values.firstWhere(
          (d) => d.name == json['direction'],
          orElse: () => SyncDirection.toNas,
        ),
      );
}
