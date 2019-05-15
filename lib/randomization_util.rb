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

  # THE CLASS METHODS OF THIS CLASS SHOULD BE EXACTLY THE POSSIBLE RANDOMIZATION_METHODs
  # that require post-processing. Any of these methods, together with those
  # in the PreProcessingRandomizationUtil should be possible values for
  # ENV[RANDOMIZATION_METHOD]

  # This is basically a no-op method, to be used if we aren't randomizing
  def self.none(opts)
    opts[:new_checkouts]
      .map { |checkout| Time.parse(checkout.created).iso8601 }
  end

  def self.uniform(opts)
    # Generate random creation times over covered timespan:
    Array.new(opts[:new_checkouts].size)
      .map { |ind| rand RandomizationHelperUtil.delta_seconds(opts[:new_checkouts]) }
      .sort
      .reverse
      .map { |s| Time.at(Time.now - s).iso8601 }
  end

  def self.add_randomized_dates!(checkouts)
    # If a checkout is new, it will not have a randomized date assigned to it yet
    # We pass the new checkouts and the list of all checkouts to the randomization
    # method named in ENV. Right now none of the randomization methods actually care about
    # the all_checkouts variable, but it might be a useful context variable in the future
    randomization_args = {
      new_checkout: RandomizationHelperUtil.checkouts_requiring_randomized_date(checkouts),
      all_checkouts: checkouts
    }
    randomized_dates = self.send(ENV['RANDOMIZATION_METHOD'], randomization_args)
    randomization_args[:new_checkout].each_with_index do |checkout, idx|
      checkout.randomized_date = randomized_dates[idx]
    end
  end

  # An overall main method to process checkouts. Currently we just have to add dates
  def self.process!(checkouts)
    self.add_randomized_dates!(checkouts)
  end

  # If a randomization method doesn't require any post-processing, it won't be listed
  # as a method of this class. method_missing will catch it and execute a no-op (in this case,
  # the 'none' method, corresponding to no randomization). We check that the arguments make sense
  # in order to avoid having this called totally accidentally.
  def self.method_missing(method, *args, &block)
    if (args[0].is_a? Hash) && args.length == 1 && args[0][:new_checkouts]
      self.none(args[0])
    else
      super
    end
  end

end

class PreProcessingRandomizationUtil
  # THE CLASS METHODS OF THIS CLASS SHOULD BE EXACTLY THE POSSIBLE RANDOMIZATION_METHODs
  # that require pre-processing. Any of these methods, together with those
  # in the PostProcessingRandomizationUtil, should be possible values for
  # ENV[RANDOMIZATION_METHOD]

  # If a randomization method doesn't require any pre-processing, it won't be listed
  # as a method of this class. method_missing will catch it and execute a no-op
  def self.method_missing(method, *args, &block)
    args[0]
  end

  def random_shuffle(array)
    array
      .map { |record| [rand, record] }
      .sort { |(float, record)| float}
      .map { |(float, record)| record }
  end

  # Generates a new array of randomized records using the method named in ENV
  # The possible values for 'RANDOMIZATION_METHOD' should be exactly names
  # of those methods in
  # PreProcessingRandomizationUtil and PostProcessingRandomizationUtil
  def process(array)
    self.send(ENV['RANDOMIZATION_METHOD'], records)
  end
end
