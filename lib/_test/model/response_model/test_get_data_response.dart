// ===============
// GetDataResponse
// ===============
class GetDataResponse {
  // Factory constructor to create an instance from JSON
  factory GetDataResponse.fromJson(Map<String, dynamic> json) {
    return GetDataResponse(
      name: json['name'] ?? '',
      structure: json['structure'] ?? '',
      usage: json['usage'] ?? '',
      advantages: json['advantages'] ?? '',
      challenges: json['challenges'] ?? '',
      metadata: MetaData.fromJson(json['metadata'] ?? {}),
    );
  }
  GetDataResponse({
    this.name = '',
    this.structure = '',
    this.usage = '',
    this.advantages = const [],
    this.challenges = const [],
    this.metadata = const MetaData(),
  });

  final String name;
  final String structure;
  final String usage;
  final List advantages;
  final List challenges;
  final MetaData metadata;

  // Method to convert an instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'structure': structure,
      'usage': usage,
      'advantages': advantages,
      'challenges': challenges,
      'metadata': metadata.toJson(),
    };
  }
}

// ==============
// METADATA
// ==============
class MetaData {
  // Factory constructor to create an instance from JSON
  factory MetaData.fromJson(Map<String, dynamic> json) {
    return MetaData(
      date: json['date'] ?? '',
      users: json['users'] ?? '',
      author: Author.fromJson(json['author'] ?? {}),
    );
  }
  const MetaData({
    this.date = '',
    this.users = '',
    this.author = const Author(),
  });

  final String date;
  final String users;
  final Author author;

  // Method to convert an instance to JSON
  Map<String, dynamic> toJson() {
    return {'date': date, 'users': users, 'author': author.toJson()};
  }
}

// ==============
// AUTHOR
// ==============
class Author {
  // Factory constructor to create an instance from JSON
  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      firstname: json['firstname'] ?? '',
      middlename: json['middlename'] ?? '',
      lastname: json['lastname'] ?? '',
    );
  }
  const Author({this.firstname = '', this.middlename = '', this.lastname = ''});

  final String firstname;
  final String middlename;
  final String lastname;

  // Method to convert an instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'firstname': firstname,
      'middlename': middlename,
      'lastname': lastname,
    };
  }
}
