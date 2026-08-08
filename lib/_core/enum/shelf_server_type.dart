/// defines what memory management system will be used
///
/// - monolith: utilize memcache to handle middleware data
/// - microservice: utlize redis to handle middleware data
enum ShelfServerType { monolith, microservice }
