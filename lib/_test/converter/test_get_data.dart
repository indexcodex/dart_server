import 'dart:convert';

import '../api/test_get_data.dart';
import '../model/response_model/test_get_data_response.dart';

Future<GetDataResponse> getDataModule() async {
  // prepare the data to return
  GetDataResponse responseData = GetDataResponse();

  try {
    // build the json response
    String jsonReponse = await getData();
    // comvert the jsonResponse to object
    responseData = GetDataResponse.fromJson(jsonDecode(jsonReponse));
  } catch (e) {
    // throw the error back to the caller
    rethrow;
  }

  // return the response object
  return responseData;
}
