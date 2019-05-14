require_relative File.join('..', 'lib', 's3_writer')
require_relative File.join('..', 'lib', 'platform_api_client')
require_relative File.join('..', 'lib', 'checkout')

ENV['RANDOMIZATION_METHOD'] = 'none'

def fixture(which)
  return JSON.parse(File.read(File.join('spec', 'fixtures', which)))
end
