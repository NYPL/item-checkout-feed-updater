# require_relative 'errors'
require_relative 'avro_decoder'
require_relative 'checkout'

class ItemStreamHandler
  MAX_CHECKOUTS_IN_MEMORY = ENV['MAX_CHECKOUTS_IN_MEMORY'].to_i

  def avro_decoder(name)
    @avro_decoders = {} if @avro_decoders.nil?
    @avro_decoders[name] = AvroDecoder.by_name(name) if @avro_decoders[name].nil?
    @avro_decoders[name]
  end

  def add_checkout(checkout)
    @checkouts = [] if @checkouts.nil?

    # Application.logger.debug "Adding checkout #{checkout}"

    # Add checkout to end:
    @checkouts << checkout

    Application.logger.debug "Collected checkouts size is now #{@checkouts.size}"

    # Make sure @checkouts doesn't grow behond max:
    @checkouts = constrain_size @checkouts, MAX_CHECKOUTS_IN_MEMORY
  end

  # Reduce array to the given size
  # e.g. constrain_size([1, 2, 3], 2) => [2, 3]
  def constrain_size(arr, size)
    excess_records = arr.size - size
    arr.shift excess_records if excess_records > 0
    arr
  end

  def update_tally_if_necessary
    if Time.now - ItemTypeTally[:time] >= 24*60*60
      ItemTypeTally[:time] = Time.now
      ItemTypeTally[:tallies] = Hash.new {|h,k| h[k] = 0}
    end
  end

  def update_count(checkout)
    ItemTypeTally[:tallies][checkout.category] += 1
  end

  # Handle storage of proxied requests
  def handle (event)

    update_tally_if_necessary

    event["Records"]
      .select { |record| record["eventSource"] == "aws:kinesis" }
      .each do |record|
        avro_data = record["kinesis"]["data"]

        decoded = avro_decoder('Item').decode avro_data

        # Presence of 'duedate' indicates it's checked-out
        if decoded && decoded['status'] && ! decoded['status']['duedate'].nil?
          checkout = Checkout.from_item_record decoded
          add_checkout checkout

          update_count checkout
        end
      end

    Application.logger.info "Processed #{event['Records'].size} records (#{checkout_count} checkouts)"

    # If any changes occurred, push latest to S3 via S3Writer
    Application.s3_writer.write @checkouts if checkout_count > 0

    { success: true }
  end
end
