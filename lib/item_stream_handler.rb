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

    Application.logger.debug "ItemStreamHandler#add_checkout: Collected checkouts size is now #{@checkouts.size}"

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

  # Returns true if given item appears to represent a recent checkout. Must:
  #  - be a Hash
  #  - have a non-nil status.duedate
  #  - have an id
  def item_is_checkout? (item)
    is_checkout = item.is_a?(Hash) &&
      item['status'].is_a?(Hash) && ! item['status']['duedate'].nil? &&
      item['id'].is_a?(String)
    Application.logger.debug "ItemStreamHandler#handle: Skipping non-checkout item: #{item}" unless is_checkout
    is_checkout
  end

  def get_decoded_records(event)
    records = event["Records"]
      .select { |record| record["eventSource"] == "aws:kinesis" }


    records = PreProcessingRandomizationUtil.process(records)

    decoded_records = records
      .map { |record| avro_decoder('Item').decode record["kinesis"]["data"] }
      .each { |decoded_record| Application.logger.debug "ItemStreamHandler#handle: Decoded item: #{decoded_record}" }
  end

  def convert_record_to_checkout(decoded_records)
    decoded_records
      .select { |decoded| item_is_checkout? decoded }
      .map { |decoded| Checkout.from_item_record decoded }
  end

  def process_checkouts(checkouts)
    checkouts
      .each { |checkout| Application.logger.debug "De-duping by id: #{checkout.id}, #{RECENT_IDS}" }
      .select { |checkout| RECENT_IDS[checkout.id] && Time.now - RECENT_IDS[checkout.id]< ENV["CHECKOUT_ID_EXPIRE_TIME"].to_i }
      .each { |checkout| add_checkout checkout }
      .each { |checkout| Application.logger.debug "ItemStreamHandler#handle: Added checkout: #{checkout.id} (#{checkout.barcode}) \"#{checkout.title}\"" }
      .each { |checkout| update_count checkout }
      .each { |checkout| RECENT_IDS[checkout.id] = Time.now }
  end

  def handle (event)

    update_tally_if_necessary
    decoded_records = get_decoded_records event
    checkouts = convert_record_to_checkout decoded_records
    checkouts = process_checkouts checkouts
    PostProcessingRandomizationUtil.process! @checkouts unless @checkouts.nil?

    Application.logger.info "ItemStreamHandler#handle: Processed #{event['Records'].size} records (#{checkouts.count} checkouts)"

    # If any changes occurred, push latest to S3 via S3Writer
    Application.s3_writer.write @checkouts if checkouts.count > 0

    { success: true }
  end
end
