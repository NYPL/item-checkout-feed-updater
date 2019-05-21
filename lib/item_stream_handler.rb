# require_relative 'errors'
require_relative 'checkout'
require_relative 'randomization_util'
require_relative 'item_handler_records'

class ItemStreamHandler
  MAX_CHECKOUTS_IN_MEMORY = ENV['MAX_CHECKOUTS_IN_MEMORY'].to_i

  def add_checkout(checkout)
    @checkouts = [] if @checkouts.nil?

    # Add checkout to end:
    @checkouts << checkout

    Application.logger.debug "ItemStreamHandler#handle: Added checkout: #{checkout.id} (#{checkout.barcode}) \"#{checkout.title}\""

    Application.logger.debug "ItemStreamHandler#add_checkout: Collected checkouts size is now #{@checkouts.size}"

    # Make sure @checkouts doesn't grow behond max:
    @checkouts = constrain_size @checkouts, MAX_CHECKOUTS_IN_MEMORY
  end

  # Reduce array to the given size
  # e.g. constrain_size([1, 2, 3], 2) => [2, 3]
  def constrain_size(arr, size)
    arr[(arr.size - size) ... size ]
  end

  def clear_tally_if_necessary
    if Time.now.day != ItemTypeTally[:time].day
      ItemTypeTally[:time] = Time.now
      ItemTypeTally[:tallies] = Hash.new {|h,k| h[k] = 0}
    end
  end

  def clear_old_data
    clear_tally_if_necessary
    # Make sure @checkouts doesn't grow behond max:
    @checkouts = constrain_size @checkouts, MAX_CHECKOUTS_IN_MEMORY unless @checkouts.nil?
  end

  def update_count(checkout)
    checkout.categories.each do |category|
      ItemTypeTally[:tallies][category] += 1
      checkout.tallies[category] = ItemTypeTally[:tallies][category]
    end
  end

  def raw_records(event)
    event["Records"]
      .select { |record| record["eventSource"] == "aws:kinesis" }
  end

  def get_checkouts_from_event(event)
    ItemHandlerRecords.new(raw_records(event))
      .process
  end

  def process_checkout(checkout)
    add_checkout checkout
    update_count checkout
  end

  def handle(event)
    clear_old_data
    checkouts = get_checkouts_from_event(event)
    checkouts.each do |checkout|
      process_checkout(checkout)
    end

    Application.logger.info "Processed #{event['Records'].size} records (#{checkouts.count} checkouts)"

    PostProcessingRandomizationUtil.process! @checkouts unless @checkouts.nil?

    Application.logger.info "ItemStreamHandler#handle: Processed #{event['Records'].size} records (#{checkouts.count} checkouts)"

    # If any changes occurred, push latest to S3 via S3Writer
    Application.s3_writer.write @checkouts if checkouts.count > 0

    { success: true }
  end
end
