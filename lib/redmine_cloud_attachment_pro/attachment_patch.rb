require 'aws-sdk-s3'
require 'google/cloud/storage'
require 'azure/storage/blob'
require_dependency 'attachment'

module RedmineCloudAttachmentPro
  module AttachmentPatch
    def self.included(base)
      base.class_eval do
        after_destroy :delete_from_cloud

        def storage_backend
          Redmine::Configuration["storage"]&.to_sym || :local
        end

        def files_to_final_location
          return unless @temp_file

          sha = Digest::SHA256.new
          content = read_temp_file(@temp_file, sha)
          self.disk_directory = target_directory

          upload_content(content)

          self.digest = sha.hexdigest
          @temp_file = nil

          set_content_type
        end

        def diskfile
          return local_diskfile unless cloud_diskfile?

          Tempfile.create(["redmine", File.extname(cloud_key)]).tap do |tmp|
            tmp.binmode
            begin
              download_from_cloud(tmp)
              tmp.rewind
            rescue => e
              Rails.logger.error("[CloudAttachmentPro] Fallback to local: #{e.message}")
              return local_diskfile
            end
          end.path
        end

        def delete_from_cloud
          return unless cloud_diskfile?

          begin
            delete_from_backend(cloud_key)
          rescue => e
            Rails.logger.error("[CloudAttachmentPro] Failed to delete #{cloud_key}: #{e.message}")
          end
        end

        private

        def upload_content(content)
          key = cloud_key

          case storage_backend
          when :s3
            s3_client.put_object(bucket: s3_bucket, key: key, body: content)
          when :gcs
            gcs_bucket.create_file(StringIO.new(content), key)
          when :azure
            azure_blob_client.create_block_blob(azure_container, key, content)
          else
            save_locally(content)
            return
          end

          self.disk_filename = "#{storage_backend}_#{File.basename(key)}"
        end

        def download_from_cloud(tmp)
          case storage_backend
          when :s3
            s3_client.get_object(bucket: s3_bucket, key: cloud_key) { |chunk| tmp.write(chunk) }
          when :gcs
            gcs_bucket.file(cloud_key)&.download(tmp.path)
          when :azure
            _, content = azure_blob_client.get_blob(azure_container, cloud_key)
            tmp.write(content)
          end
        end

        def delete_from_backend(key)
          case storage_backend
          when :s3
            s3_client.delete_object(bucket: s3_bucket, key: key)
            Rails.logger.info("[S3] Deleted #{key}")
          when :gcs
            gcs_bucket.file(key)&.delete
            Rails.logger.info("[GCS] Deleted #{key}")
          when :azure
            azure_blob_client.delete_blob(azure_container, key)
            Rails.logger.info("[Azure] Deleted #{key}")
          end
        end

        def save_locally(content)
          Attachment.create_diskfile(filename, disk_directory) do |f|
            self.disk_filename = File.basename(f.path)
            f.write(content)
          end
        end

        def set_content_type
          if content_type.blank? && filename.present?
            self.content_type = Redmine::MimeType.of(filename)
          end
          self.content_type = nil if content_type&.length.to_i > 255
        end

        def read_temp_file(temp_file, sha)
          content = temp_file.respond_to?(:read) ? temp_file.tap(&:rewind).read : temp_file.to_s
          sha.update(content)
          content
        end

        def cloud_filename
          disk_filename.presence || "#{SecureRandom.hex}_#{filename}"
        end

        def cloud_key
          prefix = "#{storage_backend}_"
          key = File.join(cloud_base_path, created_on.strftime('%Y/%m'), cloud_filename)
          cloud_diskfile? ? key.sub(/#{prefix}/, '') : key
        end

        def local_diskfile
          File.join(self.class.storage_path, disk_directory.to_s, disk_filename.to_s)
        end

        def cloud_diskfile?
          disk_filename.to_s.match?(/^(s3|gcs|azure)_[^_]+_/)
        end

        def cloud_config
          Redmine::Configuration[storage_backend.to_s] || {}
        end

        def cloud_base_path
          cloud_config['path'] || 'redmine/files'
        end

        def s3_client
          options = {
            access_key_id: cloud_config['access_key_id'],
            secret_access_key: cloud_config['secret_access_key'],
            region: cloud_config['region']
          }
        
          # Добавляем endpoint и force_path_style, если они указаны в конфиге
          options[:endpoint] = cloud_config['endpoint'] if cloud_config['endpoint'].present?
          options[:force_path_style] = cloud_config['force_path_style'] if cloud_config['force_path_style'].present?
        
          @s3_client ||= Aws::S3::Client.new(options)
        end

        def s3_bucket
          cloud_config['bucket']
        end

        def gcs_client
          @gcs_client ||= Google::Cloud::Storage.new(
            project_id: cloud_config['project_id'],
            credentials: cloud_config['gcs_credentials']
          )
        end

        def gcs_bucket
          @gcs_bucket ||= gcs_client.bucket(cloud_config['bucket'])
        end

        def azure_blob_client
          @azure_blob_client ||= Azure::Storage::Blob::BlobService.create(
            storage_account_name: cloud_config['account_name'],
            storage_access_key: cloud_config['access_key']
          )
        end

        def azure_container
          cloud_config['container']
        end
      end
    end
  end
end

Attachment.include RedmineCloudAttachmentPro::AttachmentPatch unless Attachment.included_modules.include?(RedmineCloudAttachmentPro::AttachmentPatch)
