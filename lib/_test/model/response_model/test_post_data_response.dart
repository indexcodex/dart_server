class PostDataResponse {
  // Factory constructor to create an instance from JSON
  factory PostDataResponse.fromJson(Map<String, dynamic> json) {
    return PostDataResponse(
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      loginStatus: json['loginStatus'] ?? '',
      profilePicture: json['profilePicture'] ?? '',
    );
  }
  PostDataResponse({
    this.userId,
    this.userName,
    this.loginStatus,
    this.profilePicture,
  });
  final String? userId;
  final String? userName;
  final String? loginStatus;
  final String? profilePicture;

  // Method to convert an instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'loginStatus': loginStatus,
      'profilePicture': profilePicture,
    };
  }
}
