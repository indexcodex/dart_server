import 'package:shelf_server/_core/service/config_service/config_service.dart';
import 'package:shelf_server/_core/service/ecc/ecc_facade.dart';
import 'package:shelf_server/_core/service/jwt/jwt_facade.dart';
import 'package:shelf_server/_core/service/mailer/mailer_impl.dart';
import 'package:shelf_server/_core/service/mysql/mysql.dart';
import 'package:shelf_server/_core/service/api_client/api_client.dart';
import 'package:shelf_server/_core/service/memcache/memcache.dart';
import 'package:shelf_server/_core/service/redis/redis_facade.dart';

class ServiceFacade {
  ApiClient api = ApiClient();
  EccFacade ecc = EccFacade();
  JwtFacade jwt = JwtFacade();
  Memcache memcache = Memcache();
  RedisFacade redis = RedisFacade();
  MySqlService sql = MySqlService();
  ConfigService config = ConfigService();
  MailerService mailer = MailerService();
}
