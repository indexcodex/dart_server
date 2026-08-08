class PostDataRequest {
  // Factory constructor to create an instance from JSON
  factory PostDataRequest.fromJson(Map<String, dynamic> json) {
    return PostDataRequest(
      userName: json['userName'] ?? '',
      otp: json['otp'] ?? '',
    );
  }
  PostDataRequest({this.userName, this.otp});
  final String? userName;
  final int? otp;

  // Method to convert an instance to JSON
  Map<String, dynamic> toJson() {
    return {'userName': userName, 'otp': otp};
  }
}
