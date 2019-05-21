require_relative 'randomization_util'
require_relative 'avro_decoder'

class ItemHandlerRecords
  RECENT_IDS = {}

  attr_accessor :records

  def initialize(records_array)
    @records = records_array
  end

  # Get AvroDecoder instance by schema name
  def avro_decoder(name)
    @avro_decoders = {} if @avro_decoders.nil?
    @avro_decoders[name] = AvroDecoder.by_name(name) if @avro_decoders[name].nil?
    @avro_decoders[name]
  end

  def randomize_records!
    self.records = PreProcessingRandomizationUtil.send(ENV['RANDOMIZATION_METHOD'], records)
  end

  def decode_records!
    self.records = records.map do |record|
      decoded = avro_decoder('Item').decode record["kinesis"]["data"]
      Application.logger.debug "ItemStreamHandler#handle: Decoded item: #{decoded}"
      decoded
    end
  end

  def select_checkouts!
    self.records = records.select do |record|
      self.class.item_is_checkout? record
    end
  end

  def build_checkouts!
    self.records = records.map do |record|
      Checkout.from_item_record record
    end
  end

  def reject_duplicates!
    self.records = records.reject do |checkout|
      Application.logger.debug "De-duping by id: #{checkout.id}, #{RECENT_IDS}"
      RECENT_IDS[checkout.id] && Time.now - RECENT_IDS[checkout.id]< ENV["CHECKOUT_ID_EXPIRE_TIME"].to_i
    end
  end

  # "Record" current set of records as the complete set of valid, vetted
  # checkouts.
  def record_recents!
    self.records.each do |checkout|
      RECENT_IDS[checkout.id] = Time.now
    end
  end

  def process
    randomize_records!
    decode_records!
    select_checkouts!
    build_checkouts!
    reject_duplicates!

    record_recents!
    remove_old_ids RECENT_IDS

    records
  end

  def remove_old_ids(id_hash)
    id_hash.each do |(id, time)|
      id_hash.delete(id) if Time.now - time > ENV["CHECKOUT_ID_EXPIRE_TIME"].to_i
    end
  end

  # Returns true if given object appears to be a checkout.
  # Must:
  #  - be a Hash
  #  - have a non-nil status.duedate
  #  - have an id
  def self.item_is_checkout?(record)
    record.is_a?(Hash) &&
    record['status'].is_a?(Hash) && !record['status']['duedate'].nil? &&
    record['id'].is_a?(String)
  end

end
