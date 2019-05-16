require_relative 'randomization_util'

class ItemHandlerRecords

  attr_accessor :records

  def initialize(records_array)
    @records = records_array
  end

  def randomize_records!
    self.records = PreProcessingRandomizationUtil.send(ENV['RANDOMIZATION_METHOD'], records)
  end

  def decode_records!
    self.records = records.map do |record|
      avro_decoder('Item').decode record["kinesis"]["data"]
    end
  end

  def select_checkouts!
    self.records = records.select do |record|
      record && record['status'] && !record['status']['duedate'].nil?
    end
  end

  def build_checkouts!
    self.records = records.map do |record|
      Checkout.from_item_record record
    end
  end

  def reject_duplicates!
    self.records = records.reject do |checkout|
      RECENT_IDS[checkout.id] && Time.now - RECENT_IDS[checkout.id]< ENV["CHECKOUT_ID_EXPIRE_TIME"].to_i
    end
  end

end
