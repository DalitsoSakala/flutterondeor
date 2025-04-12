abstract class MapSerializable{
  Map<String,dynamic> toJson();
  String? get mapSerializableName;
  String? get mapSerializableDetails;
  DateTime? get mapSerializableTime;
}