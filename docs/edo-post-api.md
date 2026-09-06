# EDO post ingestion — API contract

Endpoints live on the `api` subdomain under `/edo/v1`.
Test host: `http://api.themetacity.test:5000` · Prod host: `https://api.themetacity.com`

Flow: **(1)** get a presigned upload per file → **(2)** upload each file straight to S3 →
**(3)** create the post, referencing the keys from step 1.

---

## 1. Presign an upload — `POST /edo/v1/media/presign`

One call per file. Request is `multipart/form-data` (or `application/x-www-form-urlencoded`).

Form fields:
- `filename` (required) — original name; the server sanitises it and picks the final key.
- `content_type` (optional) — if sent, the upload is locked to exactly this MIME type.

### Request
```
POST /edo/v1/media/presign HTTP/1.1
Host: api.themetacity.com
Content-Type: multipart/form-data; boundary=----X

------X
Content-Disposition: form-data; name="filename"

beach sunset.jpg
------X
Content-Disposition: form-data; name="content_type"

image/jpeg
------X--
```

### Response — `200 OK`
```json
{
  "success": true,
  "data": {
    "key": "9f8a7b6c5d4e4f3a2b1c0d9e8f7a6b5c/beach_sunset.jpg",
    "method": "PUT",
    "url": "https://tmc-blog.sg-sin-1.linodeobjects.com/9f8a7b6c5d4e4f3a2b1c0d9e8f7a6b5c/beach_sunset.jpg?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAEXAMPLE0PLACEHOLDER%2F20260905%2Fsg-sin-1%2Fs3%2Faws4_request&X-Amz-Date=20260905T043210Z&X-Amz-Expires=3600&X-Amz-SignedHeaders=content-type%3Bhost&X-Amz-Signature=b1946ac92492d2347c6235b4d2611184example5signature0placeholder00",
    "headers": { "Content-Type": "image/jpeg" }
  }
}
```

`method` is always `PUT`. `headers` is what you must send on the upload — present
only when you passed `content_type` (it is signed into the URL, so it must match
exactly). Without `content_type`, `headers` is `{}`.

**Keep `data.key`** — you send it back in step 3.

### Errors — `400`
Envelope is always `{ "success": false, "message": "...", "data": {} }`.

`filename` missing:
```json
{ "success": false, "data": {}, "message": "Missing 'filename'" }
```

Storage rejected the presign request:
```json
{ "success": false, "data": {}, "message": "Could not generate upload URL" }
```

---

## 2. Upload the file to S3

`PUT` the **raw file bytes** as the request body to `data.url`, sending every header in
`data.headers` (i.e. `Content-Type` when it was returned — it must match what was signed).
No form fields, no multipart. On success S3 returns `200 OK` (with an `ETag`). No
app-server call here.

```
PUT /9f8a7b6c5d4e4f3a2b1c0d9e8f7a6b5c/beach_sunset.jpg?X-Amz-Algorithm=... HTTP/1.1
Host: tmc-blog.sg-sin-1.linodeobjects.com
Content-Type: image/jpeg

<raw bytes of beach sunset.jpg>
```

---

## 3. Create the post — `POST /edo/v1/post`

`Content-Type: application/json`. Body:
- `text` (string, optional) — post body.
- `media` (array, optional) — each item is either a `{ "key", "content_type" }` object
  (preferred) or a bare key string. `key` must be a key returned in step 1.

A post must have **`text` or at least one `media` item** (or both). Media order is preserved.

### Request
```json
{
  "text": "First swim of the season 🏖️",
  "media": [
    { "key": "9f8a7b6c5d4e4f3a2b1c0d9e8f7a6b5c/beach_sunset.jpg", "content_type": "image/jpeg" },
    { "key": "1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d/waves.mp4",        "content_type": "video/mp4"  }
  ]
}
```

### Response — `201 Created`
```json
{
  "success": true,
  "data": {
    "id": "0192a8f4-3b2c-7d1e-9f00-1a2b3c4d5e6f",
    "content": "First swim of the season 🏖️",
    "media": [
      {
        "id": "0192a8f4-3b2c-7d1e-9f00-aa11bb22cc33",
        "key": "9f8a7b6c5d4e4f3a2b1c0d9e8f7a6b5c/beach_sunset.jpg",
        "content_type": "image/jpeg",
        "kind": "image",
        "position": 0
      },
      {
        "id": "0192a8f4-3b2c-7d1e-9f00-dd44ee55ff66",
        "key": "1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d/waves.mp4",
        "content_type": "video/mp4",
        "kind": "video",
        "position": 1
      }
    ],
    "created_at": "2026-09-05T04:32:10.512438+00:00",
    "updated_at": "2026-09-05T04:32:10.512438+00:00"
  }
}
```

`kind` is derived server-side from `content_type`: `image` / `video` / `audio`, else `file`.

---

## Error responses (all `POST /edo/v1/post`)

Envelope is always `{ "success": false, "message": "...", "data": { ... } }`.

Body is not a JSON object — `400`:
```json
{ "success": false, "data": {}, "message": "Expected a JSON object body" }
```

No text and no media — `400`:
```json
{ "success": false, "data": {}, "message": "A post needs text or at least one media item" }
```

A media entry has no `key` — `400`:
```json
{ "success": false, "data": {}, "message": "Each media entry needs a non-empty 'key'" }
```

A referenced key was never uploaded to S3 — `400` (the missing keys are listed):
```json
{
  "success": false,
  "message": "Some media were not found in storage",
  "data": { "missing": ["1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d/waves.mp4"] }
}
```
