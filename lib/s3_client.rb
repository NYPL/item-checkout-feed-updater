require 'aws-sdk-s3'
require 'base64'

class S3Client
  @@s3 = nil

  def initialize
    @s3 = self.class.aws_s3_client
  end 

  def write(path, data)
    bucket = @s3.bucket(ENV['S3_BUCKET_NAME'])
    Application.logger.debug "Writing #{data} to #{ENV['S3_BUCKET_NAME']}/#{path}"
    response = bucket.object(ENV['S3_FEED_KEY']).put({
      acl: 'public-read',
      body: data
    })
    # `response` is a PutObjectOutput:
    # https://docs.aws.amazon.com/sdkforruby/api/Aws/S3/Types/PutObjectOutput.html
    Application.logger.debug "Wrote to bucket: #{response}"
    response
  end

  def self.aws_s3_client
    @@s3 = Aws::S3::Resource.new(region: 'us-east-1', stub_responses: ENV['APP_ENV'] == 'test') if @@s3.nil?
    @@s3
  end
end
