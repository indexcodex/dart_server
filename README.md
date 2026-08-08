# Shelf Server

A basic dart server powered by [shelf_plus](https://pub.dev/packages/shelf_plus) package. This guide will walk you through from running the cloned repo up to building your own server

---

### Before we begin

This server is built using VSCode and is recommended to use the same to avoid any conflicts

### Getting started

The initial files can already run out of the box. To run the dart server:

    1. Open the terminal and run **dart pub get**
    2. Open lib/main.dart
    3. Find **Run and Debug** section on the left side of VSCode
    4. Press **Run and Debug** button

Successfully running the server will print the following logs
```
Connecting to VM Service at ws://127.0.0.1:49537/RvZoYK2WAuc=/ws
Connected to the VM Service.
 Redis disabled
 JWT disabled
[hotreload] Hot reload is enabled.
 Shelf Server Initialized
 - env: ShelfServerEnv.dev
 - address: 0.0.0.0
 - port: 1001
 Rate limit request per second: 5
 Authentication disabled
 Encryption disabled
 Replay Guard disabled
 SSL disabled
```

### Server Connection Details

By default, the server will run on the following values:

    1. environment: dev
    2. ip address: 0.0.0.0
    3. port: 1001
    4. SSL: disabled

> It is recommended to run the server in this configuration at this point in time

### Trying out the server

The server has test APIs that you can access, open your preferred API client like postman or thunderclient and access the following endpoints:

```
Url: http://0.0.0.0:1001/post-data
Method: POST
Body:
  {
    "otp": 123123,
    "userName": "JohnDoe"
  }
```

```
Url: http://0.0.0.0:1001/get-data
Method: GET
```

```
Url: http://0.0.0.0:1001/get-dynamic-data/firstname/middlename/lastname
Method: GET
```

```
URL: http://0.0.0.0:1001/public/dart.png
Method: GET

or put the URL in your browser
```

### Creating your own API

To create your own API, your code must be added as a server handler. To do so:

    1. go to **lib/app/interface/server_handlers.dart**
    2. in line 44, under project handlers, you can add your API functions

> You can copy-paste the basic GET and basic POST functions then apply your own script

### Basic GET

```
void myFirstGetEndpoint(RouterPlus app) {
  app.get('/my-first-get-endpoint', (Request req) async {
    return Response(
      200,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "title": "Hello World",
        "detail": "My first GET endpoint response",
      }),
    );
  });
}

myFirstGetEndpoint(app);
```

> accessible via: http://0.0.0.0:1001/my-first-get-endpoint

### Basic POST

```
void myFirstPostEndpoint(RouterPlus app) {
  app.post('/my-first-post-endpoint', (Request req) async {
    final Map<String, dynamic> requestJson = await req.body.asJson;
    String firstName = requestJson['firstName'];
    String middleName = requestJson['middleName'];
    String lastName = requestJson['lastName'];

    return Response(
      200,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "title": "Hello $firstName",
        "detail": "It says here that your middle name is $middleName and your last name is $lastName. Is this correct?",
      }),
    );
  });
}

myFirstPostEndpoint(app);
```

> accessible via: http://0.0.0.0:1001/my-first-post-endpoint
> method: POST
> request body: {"firstName":"John","middleName":"Deer","lastName":"Doe"}

### Assets and Images

```
Drag and drop assets like images to public/asset folder. From there it can already be accessed in the browser when the server is running.
```

### Http Methods

HTTP methods define what action should be performed when accessing an endpoint.

```
GET: retrieve data
POST: create data
PUT: replace data
PATCH: update data
DELETE: remove data
```

> GET and POST methods are the commonly used ones

### Hot Restart / Hot Reload

Similar with Flutter, the server also supports hot restart and hot reload. As soon as you're done writing your code, saving it should update the server instance. In some cases, hot reload is not enough so we need to hot restart the server.

### Terminologies

    1. Handler: The function that executes when a specific endpoint is hit, containing the logic to process the request and produce a response.
    2. Endpoint: A combination of a URL (path) and an HTTP method (GET, POST).
    3. Request: The message sent by the client to the server, including method, URL, headers, and optional body (data).
    4. Response: The message sent by the server back to the client, including status code, headers, and optional body (data).
    5. Client: The user-facing application (mobile app, web app, desktop app, etc.)
    6. Server: The system that clients connect to for processing business logic and managing application data

### Linting and Code Quality

Run these three commands in your terminal to catch any silent runtime failures, formatting errors, or architectural issues:

```
dart format .
dart analyze
dart test
```

### Release mode

Release mode compiles the server into a single executable binary optimized for production use.

> Make sure you're in the shelf_server directory: type **ls** in the terminal and verify that pubspec.yaml appears in the output.

> Additionally, stop any active debug mode session by clicking the red square button in the top right corner of VS Code.

```
// Shelf server can be compiled as a binary to be a single executable file:
dart compile exe <ENTRY FILE> --output=<OUTPUT NAME>

// To compile the shelf server:
dart compile exe lib/main.dart --output=hello_shelf_server

// To run the shelf server:
./hello_shelf_server

// To stop the shelf server:
CTRL + C
```

---
> If you've made it this far, congratulations! You're ready to create your first Shelf server
---

# Part 2: Core Functions

Shelf server has pre built functions for ease of development

```
Core.config
..env                   // the currently configured environment
..port                  // the currently configured port
..ipAddress             // the currently configured server ip address
..enableSecurity        // determines if server is running with security enabled/disabled
..serverType            // defines what memory management system to use with middleware data
..memcacheRecordLimit   // the number of allowed records in an instance cache
..redisPort
..redisIpAddress
..appId
..guestTokenScope
..adminTokenScope
..accessTokenEndpointPassthrough
..requestPerSecond
..rateLimitValidityWindow
..maxPayloadSize
..cryptoEndpointPassthrough
..replayGuardEndpointPassthrough
..replayGuardValidityWindow
..databasePort
..databaseHost
..databaseName
..databaseUser
..databasePassword
..smtpHost
..smtpUsername
..smtpPassword
..requireSsl
```
> Core config is located at: lib/_core/config/shelf_server_config.dart

```
Core.service.api.sendRequest      // sends an API call to an endpoint
```
> API service is located at: lib/_core/service/api_client/api_client.dart

```
core.service.config
..isTokenWithinScope              // checks if accessToken has a valid scope
..accessTokenEndpointPassthrough  // endpoints that bypasses security
..cryptoEndpointPassthrough       // endpoints that bypasses security
..replayGuardEndpointPassthrough  // endpoints that bypasses security
```
> Config service is located at: lib/_core/service/config_service/config_service.dart

```
Core.service.ecc
..generateKeyPair     // generates a private and public key
..encrypt             // encrypts a payload
..decrypt             // decrypts a payload
..stringToPublicKey   // use the keys to encrypt/decrypt payload
..serverPrivateKey    // can be used for internal encrypt/decrypt
..serverPublicKey     // can be used for internal encrypt/decrypt
```
> Ecc service is located at: lib/_core/service/ecc/ecc_facade.dart

```
Core.service.jwt
..generateToken   // Generate access token using jwt keypair
..verifyToken     // Verify access token using jwt keypair

// to generate JWT private keys, type in terminal:
openssl ecparam -genkey -name prime256v1 -noout -out ec_private.pem

// to generate JWT public keys, type in terminal:
openssl ec -in ec_private.pem -pubout -out ec_public.pem

// If the command returns “command not found”:
brew install openssl
```
> JWT service is located at: lib/_core/service/jwt/jwt_facade.dart

```
Core.service.mailer.sendEmail   // send an email using shelf server
```
> note: an smtp client host and credential (username/password) is required to send an email

> Mailer service is located at: lib/_core/service/mailer/mailer_impl.dart

```
Core.service.redis
..init            // connect to the redis server
..set             // create a record
..setnx           // create a record if not exists
..get             // get a record
..getInt          // get a record and convert it to integer
..del             // delete a record
..expire          // set expiry on a record, in seconds
..exists          // check if a record exists
..ttl             // check expiry time of a record, in seconds
..incr            // increment an integer value
..setJson         // create a json record
..getJson         // get a json record
..getOrSet        // get a record, if it doesn't exists, run a function, then set it
..key             // create a generic record key
..nsEccUserKeys   // generate a record key for ecc user keys
..nsRateLimit     // generate a record key for rate limit
..nsReplayGuard   // generate a record key for replay guard
```
> Redis service is located at: lib/_core/service/redis/redis_facade.dart

```
Core.service.sql
..query             // generic query method
..transaction       // roll back data on query fail
..isDuplicate       // check if a value has duplicate
..exists            // check if a value exists
..getRecords        // returns the record as a list of map
..getSingleRecord   // returns a single result from the query
```
> SQL service is located at: lib/_core/service/mysql/mysql.dart

```
Core.util.log.devPrint  // print logs in non prod environment
```
> Log util is located at: lib/_core/util/logger/logger.dart

```
Core.util.network.getIpAddress  // returns the IP address of the client
```
> Network util is located at: lib/_core/util/network/network.dart

```
Core.util.response
..error     // returns an error response to the client
..success   // returns a success response to the client
```
> Response util is located at: lib/_core/util/response/response.dart

```
Core.util.unix
..dateNowMilli  // the date and time right now in milliseconds
..dateNowMicro  // the date and time right now in microseconds
..isExpired     // returns true if the given unix date is expired, else return false
..setExpiry     // creates a millisecond timestamp in the future to set as expiry
..oneSecond     // 1 second in milliseconds
..oneMinute     // 1 minute in milliseconds
..oneHour       // 1 hour in milliseconds
..oneDay        // 1 day in milliseconds
```
> Unix util is located at: lib/_core/util/unix/unix.dart

```
Core.util.uuid
..isValidUuidV4     // validates the input if its a valid uuid v4
..generateUuidV4    // generates a valid uuid v4
```
> Uuid util is located at: lib/_core/util/uuid/uuid_facade.dart

# Part 3: Shelf CLI

shelf server has built in shelf cli to help generate templates

> Make sure you're in the shelf_server directory: type **ls** in the terminal and verify that pubspec.yaml appears in the output.

### Run Shelf CLI

```
./shelf_cli.sh

// if shelf_cli returns a permission error, run this script
// it give executable permission to shell scripts
find shelf_cli/ -type f -name "*.sh" -exec chmod +x {} +
```

The following options are available in Shelf CLI

```
Welcome to Shelf-CLI! please select a command to run
(1) create new handler
(2) compile server
(3) run server
(4) clean shelf
Run command number: 
```

### Create new handler

generates a GET and POST handler template

```
Welcome to Shelf-CLI! please select a command to run
(1) create new handler
(2) compile server
(3) run server
(4) clean shelf
Run command number: 1
Enter the handler name in lowercase, use space as separator (eg hello world): get handler for hello world
Select handler type:
 (1) GET handler
 (2) POST handler
Choice: 1
Selected GET handler
Handler generated: export/get_handler_for_hello_world.dart
```

> the generated handler is located in export/ folder

### Compile Server

Compiles the server into a single executable binary optimized for production use

```
Welcome to Shelf-CLI! please select a command to run
(1) create new handler
(2) compile server
(3) run server
(4) clean shelf
Run command number: 2
Enter filename: helloWorldFromShelfServer
Enter version: 1.2.3
Compiling server...
Generated: /Users/myName/Documents/shelf_server/bin/helloWorldFromShelfServer_v1.2.3
Successfully compiled bin/helloWorldFromShelfServer_v1.2.3
```

> the generated binary is located in bin/ folder

### Run Server

Runs the generated binary of the compile server command

```
Welcome to Shelf-CLI! please select a command to run
(1) create new handler
(2) compile server
(3) run server
(4) clean shelf
Run command number: 3
Enter filename: helloWorldFromShelfServer
Enter version: 1.2.3
Starting server bin/helloWorldFromShelfServer_v1.2.3
 Redis disabled
 Rate limit disabled
 JWT disabled
[hotreload] Hot reload not enabled. Run this app with --enable-vm-service (or use debug run) in order to enable hot reload.
 Shelf Server Initialized
 - env: ShelfServerEnv.dev
 - address: 0.0.0.0
 - port: 1001
 Authentication disabled
 Encryption disabled
 Replay Guard disabled
 SSL disabled
```

### Clean Shelf

Deletes bin/ and export/ folders to free up space

```
Welcome to Shelf-CLI! please select a command to run
(1) create new handler
(2) compile server
(3) run server
(4) clean shelf
Run command number: 4
Delete bin/ and export/ folders? (y/n): y
Deleting folders...
Cleanup complete
```

# Part 4: Enable Security

Protect your Shelf server from external threats

### Getting started

To enable server security, we need to install some required dependencies

### OpenSSL

OpenSSL is an open source software library that implements cryptographic functions and secure communication protocols like SSL and TLS. In our case, we'll be using OpenSSL to generate JWT encryption keys

```
// check if openssl is intalled in your machine:
openssl --version

// if installed: OpenSSL x.y.z
// if not installed: openssl: command not found

// install openssl
brew install openssl
```

> once openssl is installed, no further action needed

### Redis

Redis is an in-memory data store commonly used as a database, cache, and message broker. By keeping data in RAM instead of relying on disk access for most operations, it delivers extremely low-latency performance

```
// check if redis is intalled in your machine:
redis-server --version

// if installed: Redis server v=x.y.z
// if not installed: redis-server: command not found

// install redis locally:
brew install redis

// start redis:
redis-server

// stop redis server
CTRL + C

// open redis terminal:
redis-cli

// stop redis terminal
CTRL + C
```

Basic redis usage: COMMAND arg1 arg2

```
SET: create a record
GET: read a record
EXISTS: check if a record exists
EXPIRE: attach expiration (in seconds) to a record
TTL: (time to live) check the remaining time before the record expires
DEL: delete a record
INCR: increment a numerical value
SCAN 0: check existing keys, zero is the page number, can be SCAN 1, SCAN 2, etc..
TYPE: returns the data type (redis is mostly string)
FLUSHALL: delete all existing records
```

Setup

```
To start working on redis, open 2 terminals:

Terminal 1: redis-server
Terminal 2: redis-cli

You can start typing commands in Terminal 2
```

Example

```
SET name John
// prints OK

GET name
// prints "John"

EXISTS name
// prints (integer) 1

EXPIRE name 100
// prints (integer) 1

TTL name
// prints (integer) the remaining time before the token expires

DEL name
// prints (integer) 1

SET surname Doe
// prints OK

TYPE surname 
// prints string

SET age 24
// prints OK

INCR age
// prints (integer) 25

INCR age
// prints (integer) 26

INCR age
// prints (integer) 27

SCAN 0
// prints
// 1) "0"
// 2) 1) "age"
//    2) "surname"

FLUSHALL
// prints OK

SCAN 0
// prints
// 1) "0"
// 2) (empty array)
```

> If you've made it this far, congratulations! You're ready to use redis

### MySQL / MariaDB

MySQL and MariaDB are widely used backend databases for websites, applications, systems, and cloud-based services, often serving as the primary source of business and application data

```
For databases, we will be utilizing applications to run and manage our workflow

// Enable/Disable database using XAMPP
Download XAMPP here: https://www.apachefriends.org/

// Connect to database using DBeaver
Download DBeaver here: https://dbeaver.io/download/
```

Basic SQL usage

```
CREATE `database_name`: creates an SQL database
USE `database_name`: tells SQL that you will be working on the selected database
DROP `database_name`: deletes a database
CREATE TABLE `table_name`: creates a table within the database
INSERT INTO `table_name`: create a new record
SELECT * FROM `table_name`: pull up all the existing records
UPDATE `table_name` SET column1 = value1 WHERE condition: update records that satisfy the condition
DELETE FROM `table_name` WHERE condition: delete records that satisfy the condition
TRUNCATE `table_name`: delete all records
DROP `table_name`: deletes a table
```

> database contains a collection of tables, just like how an excel file have multiple spreadsheet tabs in it

Setup

```
To start working on databases:

open XAMPP:
  - click "Manage Servers" tab
  - click MySQL Database
  - click "Start" button
  - wait for status to be "Running"

once MySQL Database is running, open DBeaver
  - uncheck "show tips on startup" and press close
  - in the dbeaver menu, find and click "Database"
  - click "New Database Connection"
  - select "MariaDB" and press the "Next" button
  - at this point, there's no need to add or change anything, just press "Finish" button

if you reach this part without issues, you are now connected to the database via DBeaver
  - right click "localhost" on the left window of DBeaver (localhost is the default connection name)
  - select "rename"
  - type in "shelfserver" then press the "OK" button
  - right click "shelfserver", then hover to "SQL Editor"
  - click "Open SQL script" (this is where we will write our database commands)
```

Example

> you can click the orange arrow to run the command

> don't forget your semicolons when writing the commands

```
-- create sample database
CREATE DATABASE `sampledb`;

-- switch to the created database
USE `sampledb`;

-- delete sample database
DROP DATABASE `sampledb`;

-- create shelf database
CREATE DATABASE `shelfserver`;

-- switch to the shelfserver db
USE `shelfserver`;

-- create shelfserver user
-- username: shelfserver
-- password: shelfserver (IDENTIFIED BY is what sets the password)
CREATE USER IF NOT EXISTS 'shelfserver'@'localhost' IDENTIFIED BY 'shelfserver';

-- give admin permission to the shelfserver database
GRANT ALL PRIVILEGES ON shelfserver.* TO 'shelfserver'@'localhost';

-- save changes
FLUSH PRIVILEGES;

-- create sample table
CREATE TABLE `sampletbl` (
  unique_id INT AUTO_INCREMENT PRIMARY KEY,
  first_name VARCHAR(64),
  last_name VARCHAR(64),
  age INT
);

-- check sample table contents (should return empty table)
SELECT * FROM `sampletbl`

-- create sample table record
INSERT INTO `sampletbl`(first_name, last_name, age) VALUES ("john", "doe", 24);

-- check sample table contents (should return the record of john doe)
SELECT * FROM `sampletbl`

-- create another sample table record
INSERT INTO `sampletbl`(first_name, last_name, age) VALUES ("jane", "doe", 21);

-- check sample table contents (should return the record of john doe and jane doe)
SELECT * FROM `sampletbl`

-- update jane doe's last_name (probably got married)
UPDATE `sampletbl` SET last_name="Roe" WHERE first_name="jane";

-- check sample table contents (should return the record of john and the updated record of jane)
SELECT * FROM `sampletbl`;

-- create another sample table record
INSERT INTO `sampletbl`(first_name, last_name, age) VALUES ("johnny", "bravo", 21);

-- check sample table contents (should return the record of john, jane, and johnny)
SELECT * FROM `sampletbl`;

-- only check records that have the age of 21 (should return jane and johnny)
SELECT * FROM `sampletbl` WHERE age=21;

-- delete all sampletbl records
TRUNCATE `sampletbl`;

-- check sample table contents (should return empty table)
SELECT * FROM `sampletbl`;

-- delete sample table
DROP TABLE `sampletbl`;

-- create shelf server keystore table (this is important when enabling server security)
CREATE TABLE IF NOT EXISTS keystore (
  device_id CHAR(36) NOT NULL PRIMARY KEY,
  client_pubkey VARCHAR(255),
  server_pubkey VARCHAR(255),
  server_prvkey VARCHAR(255),
  expires BIGINT NOT NULL
);
```

> If you've made it this far, congratulations! You're ready to use SQL databases

### Run Shelf Server with Security Enabled

```
1. start redis
2. start MySQL Database
3. open lib/_core/config/shelf_server_config.dart
4. find enableSecurity = false; update value to true
5. find appId = ['YOUR_APP_ID']; get any value from https://randomkeygen.com/
6. run the server
```

Successfully running the server with security enabled will print the following logs

```
Connecting to VM Service at ws://127.0.0.1:49546/CikGil2MtIE=/ws
Connected to the VM Service.
 Redis initialized
 - address: 0.0.0.0
 - port: 6379
 JWT keys not found. Generating...
 JWT keys generated
 JWT keys loaded into memory
[hotreload] Hot reload is enabled.
 Shelf Server Initialized
 - env: ShelfServerEnv.dev
 - address: 0.0.0.0
 - port: 1001
 Rate limit request per second: 5
 App ID mydynamicallygeneratedappid
 Authentication enabled
 Encryption enabled
 Replay Guard enabled
 Authentication bypass: [/handshake/init]
 Encryption bypass: [/handshake/init]
 Replay Guard bypass: [/handshake/init]
 SSL disabled
```

# Part 5: Connecting to a secured shelf server

Compared to a shelf server with security disabled, a secured shelf server authenticates the connecting client. Below are the layers of security the client needs to go through before successfully connecting to a secured shelf server

```
1. App Id: only clients with the correct App ID can connect
2. Rate Limit: a client can only send a limited number of requests per second
3. Authentication: a client must carry the correct access token
4. Encryption: a client must send the correct and untampered encrypted payload
5. Replay Guard: a client must send a unique request everytime
```

### Request Header

The following keys are required in the header when connecting to a secured shelf server

```
1. x-app-id: value can be found in lib/_core/config/shelf_server_config.dart from appId
2. x-access-token: provided by handshake api
3. x-guard: generated by the connecting client
4. encrypted payload: generated by the connecting client, using encryption keys from handshake api
```

### Trying out the secured shelf server

The server has test APIs that you can access, open your preferred API client like postman or thunderclient and access the following endpoints:

> Step 1: perform handshake
```
Url: http://0.0.0.0:1001/handshake/init
Method: POST
Header:
  x-app-id
Body:
  {
    "deviceId": "57fadfc5-5e15-465d-a6e2-e242585749ac",
    "clientPubkey": "BDod1Jf5iF1wYsEd0xtrbrRqfCc+jotj4d6f8Bpx7a9gy7WsnfmuYg+EI0XCdxoAPZNCtZeyktAwUghGh+wKdJE="
  }
```

After performing the handshake, the response will be something like this

```
{
  "securityEnabled": true,
  "serverPubkey": "BN2iuUk6R9LmgwTuqUgY9tWKiBbk1MNAd7h7Hq8SusHsr2Q4J20oxK8/0ZL68AKKQ8LxXXu6TV+4d3wqGf2x2UA=",
  "accessToken": "eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjowLCJkZXZpY2VJZCI6IjU3ZmFkZmM1LTVlMTUtNDY1ZC1hNmUyLWUyNDI1ODU3NDlhYyIsImlhdCI6MTc4MDc1NjkzMiwiZXhwIjoxNzgwODQzMzMyfQ.tQZ5UmaV8LEPWpMUIaK1UqUPOVxjKkuqLcYbudfao9fA8grrU70Ghb6FwgHYEtvJdA7VtZYi6jP-eG5-H8jyXw",
  "expires": 1780843332944
}
```

> take note of the response and save the value of serverPubkey and accessToken

### Generate x-guard

Go to: lib/_test/unit/generate_x_guard.dart

    1. find String serverPubkey = ''; and put the value of serverPubkey from handshake response
    2. run this in the terminal: dart run lib/_test/unit/generate_x_guard.dart
    3. take note of the output, we'll be using it in the next steps

> note: you need to generate x-guard with a valid uuid format everytime you will send a request

### Generate encrypted payload

Go to: lib/_test/unit/generate_encrypted_payload.dart

    1. find String serverPubkey = ''; and put the value of serverPubkey from handshake response
    2. run this in the terminal: dart run lib/_test/unit/generate_encrypted_payload.dart
    3. take note of the output, we'll be using it in the next steps

---
> What you just did is essentially unit testing
---

### What is unit testing?

```
Unit testing is a software development practice where the smallest testable parts of an application, called "units" (such as individual functions, methods, or classes), are isolated and verified for correctness. In our case, we generated x-guard and an encrypted payload.
```

### Sending requests to secured test endpoints

using the x-guard and encrypted payload we generated earlier, we will now use it to send a POST request

```
Url: http://0.0.0.0:1001/post-data
Method: POST
Header:
  x-app-id: from config
  x-access-token: from handshake response
  x-guard: generated from generate_x_guard.dart
Body:
  generated from generate_encrypted_payload.dart
```

GET requests only need x-guard since they don't require a request body

```
Url: http://0.0.0.0:1001/get-data
Header:
  x-app-id: from config
  x-access-token: from handshake response
  x-guard: generated from generate_x_guard.dart
Method: GET
```

```
Url: http://0.0.0.0:1001/get-dynamic-data/firstname/middlename/lastname
Header:
  x-app-id: from config
  x-access-token: from handshake response
  x-guard: generated from generate_x_guard.dart
Method: GET
```

### Decrypting a response

Go to: lib/_test/unit/decrypt_payload.dart

    1. find encryptedMessage: ''
    2. copy the encrypted response from our test endpoints
    3. paste it as encryptedMessage value
    4. run in terminal: dart run lib/_test/unit/decrypt_payload.dart
    5. the output should be the decrypted response

### Creating your own API

Creating your own api is still the same, no adjustments needed since the security check happens before the request reaches the handler via middlewares

### What is a middleware?

```
Middleware is code that sits between the client and the server and performs checks or processing such as authentication or decryption before passing the request to the handler.
```

```
Think of middleware as a security guard at a building entrance. Before visitors reach the office they want to visit, the guard checks their ID, logs their entry, or gives them directions. After that, they're allowed to proceed.

visitor: request
security guard: middleware
office: handler
```

---

> Would you look at that, we already reached the end of the documentation

> Congratulations!