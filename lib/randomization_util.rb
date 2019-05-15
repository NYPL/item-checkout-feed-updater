class RandomizationHelperUtil
  def self.delta_seconds(checkouts)
    # Determine min and max dates of checkouts
    checkout_dates = checkouts.map { |checkout| checkout.created }.sort
    min_date = Time.parse checkout_dates.first
    max_date = Time.parse checkout_dates.last
    # Determine seconds elapsed between first and last checkout
    max_date - min_date
  end

  def self.checkouts_requiring_randomized_date(checkouts)
    checkouts.select { |checkout| !checkout.randomized_date }
  end

end

class PostProcessingRandomizationUtil

  def self.none(opts)
    opts[:new_checkouts]
      .map { |checkout| Time.parse(checkout.created).iso8601 }
  end

  def self.uniform(opts)
    Array.new(opts[:new_checkouts].size)
      .map { |ind| rand RandomizationHelperUtil.delta_seconds(opts[:new_checkouts]) }
      .sort
      .reverse
      .map { |s| Time.at(Time.now - s).iso8601 }
  end

  def self.method_missing(method, *args, &block)
    if (args[0].is_a? Hash) && args.length == 1 && args[0][:new_checkouts]
      self.none(args[0])
    else
      super
    end
  end




  def self.add_randomized_dates!(checkouts)
    # Generate random creation times over covered timespan:
    randomization_args = {
      new_checkout: RandomizationHelperUtil.checkouts_requiring_randomized_date(checkouts),
      all_checkouts: checkouts
    }
    randomized_dates = self.send(ENV['RANDOMIZATION_METHOD'], randomization_args)
    randomization_args[:new_checkout].each_with_index do |checkout, idx|
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
