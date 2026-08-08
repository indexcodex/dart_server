import 'dart:convert';

import '../api/test_post_data.dart';
import '../model/response_model/test_post_data_response.dart';
import '../model/request_model/test_post_data_request.dart';

Future<PostDataResponse> postDataModule(PostDataRequest postDataRequest) async {
  // prepare the data to return
  PostDataResponse responseData = PostDataResponse();

  try {
    // build the json request
    String jsonRequest = jsonEncode(postDataRequest.toJson());
    // build the json response
    String jsonReponse = await postData(jsonRequest);
    // comvert the jsonResponse to object
    responseData = PostDataResponse.fromJson(jsonDecode(jsonReponse));
  } catch (e) {
    // throw the error back to the caller
    rethrow;
  }

  // return the response object
  return responseData;
}
