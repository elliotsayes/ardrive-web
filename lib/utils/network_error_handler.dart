import 'package:ardrive/utils/error.dart';
import 'package:http/http.dart';

class NetworkErrorHandler {
  NetworkError handle(Response response) {
    final requestRoute = response.request?.url.path;
    final statusCode = response.statusCode;
    final reasonPhrase = response.reasonPhrase ?? '';
    if (response.statusCode >= 500) {
      return ServerError(
          statusCode: statusCode,
          requestRoute: requestRoute,
          reasonPhrase: reasonPhrase);
    }
    if (response.statusCode == 429) {
      return RateLimitError(
          requestRoute: requestRoute, reasonPhrase: reasonPhrase);
    }
    return UnknownNetworkError(
        statusCode: statusCode,
        requestRoute: requestRoute,
        reasonPhrase: reasonPhrase);
  }
}
