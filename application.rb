require 'nypl_log_formatter'

require_relative File.join('lib', 'item_stream_handler')
require_relative File.join('lib', 'platform_api_client')
require_relative File.join('lib', 's3_writer')

ItemTypeTally = {
  time: Time.now,
  tallies: Hash.new {|h,k| h[k] = 0}
}

Application = OpenStruct.new

Application.logger = NyplLogFormatter.new(STDOUT, level: ENV['LOG_LEVEL'] || 'info')
Application.platform_api_client = PlatformApiClient.new
Application.s3_writer = S3Writer.new

Application.item_handler = ItemStreamHandler.new

# Main handler:
def handle_event(event:, context:)
  Application.item_handler.handle event
end
