require 'redmine'
require_relative 'lib/redmine_cloud_attachment_pro/attachment_patch'

Redmine::Plugin.register :redmine_cloud_attachment_pro do
  name 'Redmine Cloud Attachment Pro plugin'
  author 'Sivamanikandan'
  description 'RedmineCloudAttachmentPro is a flexible plugin for Redmine that enables storing attachments in multiple backends including local storage, Amazon S3, and future support for Google Cloud and Microsoft Azure. It provides seamless, configurable storage options to suit diverse deployment needs.'
  version '0.0.1'
  url 'https://github.com/railsfactory-sivamanikandan/redmine_cloud_attachment_pro'
  author_url 'https://github.com/railsfactory-sivamanikandan'
end
