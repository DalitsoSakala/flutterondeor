abstract class AbstractUser{
  dynamic id;
  void toJson()=>Map<String,dynamic>;
  static AbstractUser Function(Map<String,dynamic>)? fromJsonGetter;

}