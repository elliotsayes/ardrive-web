import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:ardrive_network/src/responses.dart';
import 'package:ardrive_network/src/utils.dart';
import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:flutter/foundation.dart';
import 'package:isolated_worker/js_isolated_worker.dart';

const List<String> jsScriptsToImport = <String>['ardrive-network.js'];

class ArdriveNetwork {
  int retries;
  int retryDelayMs;
  bool noLogs;
  int retryAttempts = 0;

  ArdriveNetwork({
    this.retries = 8,
    this.retryDelayMs = 200,
    this.noLogs = false,
  });

  Dio dio() {
    final dio = Dio();

    if (!noLogs) {
      dio.interceptors.add(LogInterceptor());
    }

    if (retries > 0) {
      dio.interceptors.add(_getDioRetrySettings(dio));
    }

    return dio;
  }

  // get method
  // in the case where isJson and asBytes is false it will return a text response
  Future<ArDriveNetworkResponse> get({
    required String url,
    bool isJson = false,
    bool asBytes = false,
  }) async {
    checkIsJsonAndAsBytesParams(isJson, asBytes);

    final Map getIOParams = <String, dynamic>{};
    getIOParams['url'] = url;
    getIOParams['asBytes'] = asBytes;

    if (kIsWeb) {
      if (await _loadWebWorkers()) {
        return await _getWeb(
          url: url,
          isJson: isJson,
          asBytes: asBytes,
        );
      } else {
        return await _getIO(getIOParams);
      }
    }

    return await compute(_getIO, getIOParams);
  }

  Future<ArDriveNetworkResponse> getJson(String url) async {
    return get(url: url, isJson: true);
  }

  Future<ArDriveNetworkResponse> getAsBytes(String url) async {
    return get(url: url, asBytes: true);
  }

  Future<ArDriveNetworkResponse> _getIO(Map params) async {
    final String url = params['url'];
    final bool asBytes = params['asBytes'];

    try {
      Response response;
      if (asBytes) {
        response = await dio().get<List<int>>(
          url,
          options: Options(responseType: ResponseType.bytes),
        );
      } else {
        response = await dio().get(url);
      }

      return ArDriveNetworkResponse(
        data: response.data,
        statusCode: response.statusCode,
        statusMessage: response.statusMessage,
        retryAttempts: retryAttempts,
      );
    } catch (error) {
      throw ArDriveNetworkException(
        retryAttempts: retryAttempts,
        dioException: error,
      );
    }
  }

  Future<ArDriveNetworkResponse> _getWeb({
    required String url,
    required bool isJson,
    required bool asBytes,
  }) async {
    try {
      final LinkedHashMap<dynamic, dynamic> response =
          await JsIsolatedWorker().run(
        functionName: 'get',
        arguments: [
          url,
          isJson,
          asBytes,
          retries,
          retryDelayMs,
          noLogs,
        ],
      );

      if (response['error'] != null) {
        retryAttempts = response['retryAttempts'];

        throw response['error'];
      }

      return ArDriveNetworkResponse(
        data: asBytes ? Uint8List.view(response['data']) : response['data'],
        statusCode: response['statusCode'],
        statusMessage: response['statusMessage'],
        retryAttempts: response['retryAttempts'],
      );
    } catch (error) {
      throw ArDriveNetworkException(
        retryAttempts: retryAttempts,
        dioException: error,
      );
    }
  }

  Future<bool> _loadWebWorkers() async {
    return await JsIsolatedWorker().importScripts(jsScriptsToImport);
  }

  RetryInterceptor _getDioRetrySettings(Dio dio) {
    Duration retryDelay(int retryCount) =>
        Duration(milliseconds: retryDelayMs) * pow(1.5, retryCount);

    List<Duration> retryDelays =
        List.generate(retries, (index) => retryDelay(index));

    FutureOr<bool> setRetryAttempt(DioError error, int attempt) async {
      bool shouldRetry =
          await RetryInterceptor.defaultRetryEvaluator(error, attempt);

      if (shouldRetry) {
        retryAttempts = attempt;
      }

      return shouldRetry;
    }

    return RetryInterceptor(
      dio: dio,
      logPrint: noLogs ? null : print,
      retries: retries,
      retryDelays: retryDelays,
      retryEvaluator: setRetryAttempt,
    );
  }
}
