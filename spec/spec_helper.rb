require 'nypl_log_formatter'

require_relative File.join('..', 'lib', 's3_writer')
require_relative File.join('..', 'lib', 'platform_api_client')
require_relative File.join('..', 'lib', 'checkout')
require_relative File.join('..', 'lib', 'item_stream_handler')
require_relative File.join('..', 'lib', 'checkout_builder_util')

ENV['RANDOMIZATION_METHOD'] = 'none'

Application = OpenStruct.new
Application.platform_api_client = OpenStruct.new
Application.logger = NyplLogFormatter.new(STDOUT, level: ENV['LOG_LEVEL'] || 'error')

def fixture(which)
  return JSON.parse(File.read(File.join('spec', 'fixtures', which)))
end
