require 'aws-sdk-s3'
require 'base64'

class S3Client
  @@s3 = nil

  def initialize
    @s3 = self.class.aws_s3_client
  end 

  def write(data)
    bucket = @s3.buckets[ENV['S3_BUCKET_NAME']]
    # bucket.objects[ENV['S3_FEED_KEY']].write data
    Application.logger.debug "Writing #{data} to #{ENV['S3_BUCKET_NAME']}/#{ENV['S3_FEED_KEY']}"
  end

  def self.aws_s3_client
    @@s3 = Aws::S3.new(region: 'us-east-1', stub_responses: ENV['APP_ENV'] == 'test') if @@s3.nil?
    @@s3
  end
end
