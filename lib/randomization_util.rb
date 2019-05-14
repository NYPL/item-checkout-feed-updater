class PostProcessingRandomizationUtil

  def self.delta_seconds(checkouts)
    # Determine min and max dates of checkouts
    checkout_dates = checkouts.map { |checkout| checkout.created }.sort
    min_date = Time.parse checkout_dates.first
    max_date = Time.parse checkout_dates.last
    # Determine seconds elapsed between first and last checkout
    max_date - min_date
  end

  def self.none(opts)
    opts[:checkouts_requiring_randomized_date]
      .map { |checkout| Time.parse(checkout.created).iso8601 }
  end

  def self.uniform(opts)
    Array.new(opts[:checkouts_requiring_randomized_date].size)
      .map { |ind| rand self.delta_seconds(opts[:all_checkouts]) }
      .sort
      .reverse
      .map { |s| Time.at(Time.now - s).iso8601 }
  end

  def self.method_missing(method, *args, &block)
    if (args[0].is_a? Hash) && args.length == 1 && args[0][:checkouts_requiring_randomized_date]
      self.none(args[0])
    else
      super
    end
  end

  def self.checkouts_requiring_randomized_date(checkouts)
    checkouts.select { |checkout| !checkout.randomized_date }
  end


  def self.add_randomized_dates!(checkouts)
    # Generate random creation times over covered timespan:
    randomization_args = {
      checkouts_requiring_randomized_date: self.checkouts_requiring_randomized_date(checkouts),
      all_checkouts: checkouts
    }
    randomized_dates = self.send(ENV['RANDOMIZATION_METHOD'], randomization_args)
    randomization_args[:checkouts_requiring_randomized_date].each_with_index do |checkout, idx|
      checkout.randomized_date = randomized_dates[idx]
    end
  end

end

class PreProcessingRandomizationUtil
  def self.method_missing(method, *args, &block)
    args[0]
  end

  def random_shuffle(array)
    array
      .map { |record| [rand, record] }
      .sort { |(float, record)| float}
      .map { |(float, record)| record }
  end
end
