import 'dart:convert';
import 'dart:io' hide HttpOverrides;
import 'dart:io' as io;
import 'package:http/http.dart' as net;

import 'package:flutter/foundation.dart';
import 'package:flutterondeor/enum/net.dart';

import 'package:flutterondeor/alias.dart';
import 'file.dart';
import 'numbers.dart';

class AppHttpOverrides extends io.HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

class ResponseMapping<T> {
  final List<T> list;
  final Map<String, dynamic>? data;
  final JsonMap meta;
  final String? error;
  final int statusCode;
  final Map<String, dynamic> headers;

  const ResponseMapping({this.list = const [], this.data, this.meta = const {}, this.error, this.headers = const {}, required this.statusCode});
}

class RequestManager {
  final String backendApiURL;
  final dynamic auth;
  RequestManager({required this.backendApiURL,this.auth});

  Future<ResponseMapping> makeRequest<T>(String url,
      {JsonMap<String> jsonParams = const {},
      dynamic pk,
      StrMap? body,
      RequestBody bodyType = RequestBody.json,
      RequestMethod method = RequestMethod.get,
      List<UtilFile> files = const [],
      bool forceDefaultToken = false,
      String apiVersionBridge = 'api/v1/'}) async {
    String? jsonBody;
    assert(([RequestMethod.post, RequestMethod.patch].contains(method) && body is Map) || method == RequestMethod.get);
    final accessToken = forceDefaultToken ? auth.tokens.access : auth.accessToken;
    if (body is Map) {
      // jsonBody = json.encode(body);
      debugPrint('Outgoing payload $body');
    }
    if (pk != null && method == RequestMethod.patch) {
      url = '$url${url.endsWith('/') ? "" : '/'}$pk/';
    }
    url = '$backendApiURL/$apiVersionBridge$url'; // Some endpoints might not be located on different api branches
    debugPrint('Making http request to  $url with data $jsonBody, query params $jsonParams and access token $accessToken');
    return _sendRequest(
      url: url,
      method: method,
      headers: {
        if (accessToken != null) 'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      params: jsonParams,
      body: body,
      files: files,
      bodyType: bodyType,
    ).then((v) {
      final status = UtilNum(value: v.statusCode);
      final headers = v.headers;
      JsonMap val = jsonDecode(v.body)?? {};
      List<T> list = [];
      JsonMap meta = {};
      JsonMap<dynamic>? data;
      String? errorMessage;
      ResponseMapping result;

      switch (status) {
        case UtilNum(value: var x) when x >= 400:
          final headersError=v.headers['x-error-message'];
          errorMessage = val.containsKey('error') ? val['error']  : headersError??'An error occurred [Status $x]';
          result = ResponseMapping(list: [], data: null, meta: {}, statusCode: x, error: errorMessage);
        case UtilNum(value: var x) when x < 400:
          if (val.containsKey('results') && val.containsKey('count')) {
            list = List.from((val['results'] as List).map((v) => v as T));
          } else {
            data = val;
          }
          if (val.containsKey('meta')) {
            meta = (val['meta'] ?? {}) as Map<String, dynamic>;
          }
      }

      debugPrint('HTTP Response was returned with original data $data');
      debugPrint('HTTP Response was returned headers ${v.headers}');
      debugPrint('HTTP response was returned with list $list, data $data, meta $meta, error message $errorMessage, status ${status.value} and headers $headers');

      result = ResponseMapping(list: list, data: data, meta: meta, statusCode: status.value, headers: headers,error: errorMessage);
      return result;
    }).catchError((e) {
      debugPrint('HTTP Error occurred $e');
      return const ResponseMapping(statusCode: 400);
    });
  }
}

Future<net.Response> _sendRequest(
    {required String url,
    required RequestMethod method,
    required headers,
    List<UtilFile> files = const [],
    StrMap params = const {},
    StrMap? body,
    required RequestBody bodyType}) {
  var uri = Uri.parse(url);
  uri = Uri(host: uri.host, port: uri.port, queryParameters: {...uri.queryParameters, ...params}, path: uri.path, scheme: uri.scheme);
  Future<net.Response> attachFiles(String methodName) async {
    final request = net.MultipartRequest(methodName, uri);
    int counter = 1;
    for (final e in files) {
      request.files.add(net.MultipartFile(e.formField ?? 'file${counter++}', e.ref.readAsBytes().asStream(), await e.length,filename: e.filename));
    }
    request.fields.addAll(body ?? {});
    request.headers.addAll(headers);
    final res=await request.send();

    return net.Response.fromStream(res);
  }

  return switch (method) {
    RequestMethod.get => net.get(uri, headers: headers),
    RequestMethod.post => switch (bodyType) { RequestBody.formData => attachFiles('POST'), _ => net.post(uri, headers: headers, body: body) },
    RequestMethod.patch => switch (bodyType) { RequestBody.formData => attachFiles('PATCH'), _ => net.patch(uri, headers: headers, body: body) },
  };
}
