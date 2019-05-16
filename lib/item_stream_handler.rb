# require_relative 'errors'
require_relative 'avro_decoder'
require_relative 'checkout'
require_relative 'randomization_util'

class ItemStreamHandler
  MAX_CHECKOUTS_IN_MEMORY = ENV['MAX_CHECKOUTS_IN_MEMORY'].to_i
  RECENT_IDS = {}

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
    if Time.now.day != ItemTypeTally[:time].day
      ItemTypeTally[:time] = Time.now
      ItemTypeTally[:tallies] = Hash.new {|h,k| h[k] = 0}
    end
  end

  def update_count(checkout)
    checkout.categories.each do |category|
      ItemTypeTally[:tallies][category] += 1
      checkout.tallies[category] = ItemTypeTally[:tallies][category]
    end
  end

  def remove_old_ids(id_hash)
    id_hash.each do |(id, time)|
      id_hash.delete(id) if Time.now - time > ENV["CHECKOUT_ID_EXPIRE_TIME"].to_i
    end
  end


  # Handle storage of proxied requests
  def handle (event)

    update_tally_if_necessary
    checkout_count = 0

    records = event["Records"]
      .select { |record| record["eventSource"] == "aws:kinesis" }
    Application.logger.info "Records before randomization: #{records}"
    records = PreProcessingRandomizationUtil.send(ENV['RANDOMIZATION_METHOD'], records)
    Application.logger.info "Records after randomization #{records}"
    records.each do |record|
        avro_data = record["kinesis"]["data"]

        decoded = avro_decoder('Item').decode avro_data
        Application.logger.info "decoded: #{decoded}"
        # Presence of 'duedate' indicates it's checked-out
        if decoded && decoded['status'] && ! decoded['status']['duedate'].nil?
          checkout = Checkout.from_item_record decoded
          Application.logger.info "De-duping: #{checkout.id}, #{RECENT_IDS}"
          unless RECENT_IDS[checkout.id] && Time.now - RECENT_IDS[checkout.id]< ENV["CHECKOUT_ID_EXPIRE_TIME"].to_i
            add_checkout checkout
            checkout_count += 1
            Application.logger.info "Added checkout to count"
            update_count checkout
            RECENT_IDS[checkout.id] = Time.now
            remove_old_ids RECENT_IDS
          end
        end
      end
    PostProcessingRandomizationUtil.add_randomized_dates! @checkouts

    Application.logger.info "Processed #{event['Records'].size} records (#{checkout_count} checkouts)"

    # If any changes occurred, push latest to S3 via S3Writer
    Application.s3_writer.write @checkouts if checkout_count > 0

    { success: true }
  end
end
