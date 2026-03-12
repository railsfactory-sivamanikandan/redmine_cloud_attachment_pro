# Redmine Cloud Attachment Pro

**Redmine Cloud Attachment Pro** is a versatile Redmine plugin that enables dynamic storage of file attachments in multiple backends like Local Disk, Amazon S3 Google Cloud Storage and Microsoft Azure Blob Storage.

## 🔧 Features

- Seamless integration with Redmine's attachment system.
- Store files in:
  - 🖥️ Local filesystem (default)
  - ☁️ Amazon S3
  - 🌐 Google Cloud Storage and Azure Blob Storage (Need to be tested)
- Automatically uploads new attachments to the selected storage backend.
- Secure and efficient download handling from cloud sources.
- Clean deletion of attachments from cloud when removed from Redmine.
- Backward compatible and configurable per environment.

## ⚙️ Configuration

### Step 1: Add storage config to `config/configuration.yml`

🟡 Set the active backend:
```yaml
production:
  storage: s3   # or gcs or azure or local
```

🔹 Amazon S3 Configuration
```yaml
  s3:
    access_key_id: YOUR_AWS_KEY
    secret_access_key: YOUR_AWS_SECRET
    region: your-region
    bucket: your-bucket-name
    path: redmine/files

```

🔹 Yandex Object Storage S3 Configuration
```yaml
  s3:
    access_key_id: YOUR_AWS_KEY
    secret_access_key: YOUR_AWS_SECRET
    region: your-region
    bucket: your-bucket-name
    path: redmine/files
    endpoint: https://storage.yandexcloud.net
    force_path_style: true

```

🔹 Google Cloud Storage (GCS) Configuration

```yaml
  gcs:
    project_id: your-gcp-project
    gcs_credentials: /path/to/your/service-account.json
    bucket: your-gcs-bucket
    path: redmine/files
```

🔹 Microsoft Azure Blob Storage Configuration

```yaml
# config/configuration.yml
  azure:
    storage_account_name: "your-storage-account-name"
    storage_access_key: "your-storage-access-key"
    container: "your-container-name"
    path: "redmine/files"
```

🔒 Tip: Place credentials in a secure path outside of version control.


## 💾 Supported Backends

| Storage        | Upload | Download | Delete | Notes                          |
|----------------|--------|----------|--------|--------------------------------|
| Amazon S3      | ✅     | ✅       | ✅     | Uses `aws-sdk-s3`              |
| Google Cloud   | ✅     | ✅       | ✅     | Uses `google-cloud-storage`    |
| Microsoft Azure| ✅     | ✅       | ✅     | Uses `azure-storage-blob`      |
| Local Storage  | ✅     | ✅       | ✅     | Default fallback mechanism     |



🧪 Test

Upload files in Redmine issues, documents, etc. They will be stored in the selected backend based on your configuration. Deleting a file will also remove it from the cloud.

Step 2: Install and Migrate

```bash
bundle install
```

No migrations are needed for this plugin.

Step 3: Optional Rake Task
To update existing attachment filenames to include the S3 prefix:

```bash
bundle exec rake attachments:prefix_cloud_filenames RAILS_ENV=production
```

How it Works
Automatically detects and uploads new files to the selected storage.
Downloads from cloud storage when users request the file.
Deletes files from the cloud when an attachment is destroyed.

🔐 Security
All cloud credentials are securely pulled from configuration.yml. Avoid committing secrets to version control.


Compatibility
Redmine 5.x and above
Ruby 3.x and Rails 6.x or later
AWS SDK v3

🚀 Roadmap

✅ Amazon S3 Support

⏳ Google Cloud Storage Support

⏳ Microsoft Azure Blob Support

⏳ Web UI for configuring storage

📁 Plugin Installation

Clone into Redmine's plugin directory:

```bash
git clone https://github.com/railsfactory-sivamanikandan/redmine_cloud_attachment_pro plugins/redmine_cloud_attachment_pro
```

Then restart Redmine.


Author
Maintained by Sivamanikandan, Sedin Technologies Pvt Ltd, Chennai

📄 License

MIT License
