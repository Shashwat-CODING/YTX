// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ytify_result.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class YtifyResultAdapter extends TypeAdapter<YtifyResult> {
  @override
  final int typeId = 0;

  @override
  YtifyResult read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return YtifyResult(
      title: fields[0] as String,
      thumbnails: (fields[1] as List).cast<YtifyThumbnail>(),
      resultType: fields[2] as String,
      isExplicit: fields[3] as bool,
      videoId: fields[4] as String?,
      browseId: fields[5] as String?,
      duration: fields[6] as String?,
      durationSeconds: fields[7] as int?,
      videoType: fields[8] as String?,
      artists: (fields[9] as List?)?.cast<YtifyArtist>(),
      album: fields[10] as YtifyAlbum?,
      views: fields[11] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, YtifyResult obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.thumbnails)
      ..writeByte(2)
      ..write(obj.resultType)
      ..writeByte(3)
      ..write(obj.isExplicit)
      ..writeByte(4)
      ..write(obj.videoId)
      ..writeByte(5)
      ..write(obj.browseId)
      ..writeByte(6)
      ..write(obj.duration)
      ..writeByte(7)
      ..write(obj.durationSeconds)
      ..writeByte(8)
      ..write(obj.videoType)
      ..writeByte(9)
      ..write(obj.artists)
      ..writeByte(10)
      ..write(obj.album)
      ..writeByte(11)
      ..write(obj.views);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is YtifyResultAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class YtifyThumbnailAdapter extends TypeAdapter<YtifyThumbnail> {
  @override
  final int typeId = 1;

  @override
  YtifyThumbnail read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return YtifyThumbnail(
      url: fields[0] as String,
      width: fields[1] as int,
      height: fields[2] as int,
    );
  }

  @override
  void write(BinaryWriter writer, YtifyThumbnail obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.url)
      ..writeByte(1)
      ..write(obj.width)
      ..writeByte(2)
      ..write(obj.height);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is YtifyThumbnailAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class YtifyArtistAdapter extends TypeAdapter<YtifyArtist> {
  @override
  final int typeId = 2;

  @override
  YtifyArtist read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return YtifyArtist(
      name: fields[0] as String,
      id: fields[1] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, YtifyArtist obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.id);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is YtifyArtistAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class YtifyAlbumAdapter extends TypeAdapter<YtifyAlbum> {
  @override
  final int typeId = 3;

  @override
  YtifyAlbum read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return YtifyAlbum(
      name: fields[0] as String,
      id: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, YtifyAlbum obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.id);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is YtifyAlbumAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
