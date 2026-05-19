# Google Cloud Storage for CLAiR uploads

Use GCS instead of Supabase Storage when you hit the ~50MB Supabase free-tier cap.

## 1. Create a bucket

1. [Cloud Storage → Create bucket](https://console.cloud.google.com/storage/create-bucket)
2. Name: e.g. `clair-uploads` (globally unique)
3. Region: same as your VM (e.g. `us-central1`)
4. **Public access**: allow public reads for profile photos (see step 3)

## 2. Service account permissions

Use `clair-vertex` (or a dedicated account) with:

- **Storage Object Admin** on the bucket (upload/delete), or
- **Storage Object Creator** + **Storage Object Viewer**

Same JSON key as Vertex works if the role includes storage.

## 3. Public read (required for `photo_url` in the app)

Profile photos and attachments are served via public HTTPS URLs.

**Option A — bucket-level (simplest for class projects)**

```bash
gcloud storage buckets add-iam-policy-binding gs://clair-uploads \
  --member=allUsers \
  --role=roles/storage.objectViewer
```

**Option B** — keep bucket private and switch to signed URLs later (needs code changes).

## 4. Backend environment

```env
STORAGE_BACKEND=gcs
GCS_BUCKET_NAME=clair-uploads
GCS_PROJECT_ID=team-09-805492068022
GOOGLE_APPLICATION_CREDENTIALS=/app/gcp-vertex-key.json
GCP_VERTEX_CREDENTIALS_PATH=/app/gcp-vertex-key.json
```

On **Render**: add the same vars; paste the service-account JSON as a secret file or env.

`SUPABASE_URL` / `SUPABASE_SERVICE_ROLE_KEY` are **not** required for uploads when using GCS (still keep `SUPABASE_DB_URL` for RAG on the VM).

## 5. Redeploy

```bash
docker compose up -d --build
```

Upload a profile photo — URL should look like:

`https://storage.googleapis.com/clair-uploads/profile-photos/<user-id>.jpg`

## Folder layout (single bucket)

| Prefix | Use |
|--------|-----|
| `profile-photos/` | Avatars |
| `appointment-attachments/` | Booking files, case docs, PDF cache |
| `chat-attachments/` | DM attachments |

## Switch back to Supabase

```env
STORAGE_BACKEND=supabase
```

Existing GCS URLs in the database still work; new uploads go to Supabase.
