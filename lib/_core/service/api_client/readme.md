# USAGE 1: Single File

```
final file = await http.MultipartFile.fromPath(
  'file',
  image.path,
);

await api.upload(
  url: uploadUrl,
  fields: {
    'userId': '123',
    'caption': 'Hello!',
  },
  files: [file],
);
```

# USAGE 2: Multiple Files

```
final avatar = await http.MultipartFile.fromPath(
  'avatar',
  avatarPath,
);

final resume = await http.MultipartFile.fromPath(
  'resume',
  resumePath,
);

await api.upload(
  url: uploadUrl,
  files: [
    avatar,
    resume,
  ],
);
```

# USAGE 3: Stream Uploads

```
final file = http.MultipartFile(
  'video',
  file.openRead(),
  await file.length(),
  filename: 'movie.mp4',
);

await api.upload(
  url: uploadUrl,
  fields: {
    'userId': '123',
    'caption': 'Hello!',
  },
  files: [file],
);
```

# CURL USAGE 1: Upload a single file

```
curl -X POST http://0.0.0.0:1001/upload \
  -F "file=@/path/to/image.jpg"
```

# CURL USAGE 2: Upload a file with form fields

```
curl -X POST http://0.0.0.0:1001/upload \
  -F "userId=123" \
  -F "caption=Hello from curl\!" \
  -F "file=@/path/to/image.jpg"
```

# CURL USAGE 3: Upload multiple files

```
curl -X POST http://0.0.0.0:1001/upload \
  -F "userId=123" \
  -F "file=@image1.jpg" \
  -F "file=@image2.jpg"

curl -X POST http://0.0.0.0:1001/upload \
  -F "avatar=@avatar.png" \
  -F "resume=@resume.pdf"
```

# CURL USAGE 4: Include headers

```
curl -X POST http://0.0.0.0:1001/upload \
  -H "X-App-Id: YOUR_APP_ID" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "userId=123" \
  -F "file=@image.jpg"
```