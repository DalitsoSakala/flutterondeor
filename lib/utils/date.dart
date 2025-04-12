String toYMDMS(DateTime d, {bool tz = false}){
  var str=d.toIso8601String().substring(0,16).replaceAll(':', '-');
  str=tz?str:str.replaceAll('T', '-');
  return str;
}