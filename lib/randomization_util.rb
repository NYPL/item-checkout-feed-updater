def delta_seconds(checkouts)
  # Determine min and max dates of checkouts
  checkout_dates = checkouts.map { |checkout| checkout.created }.sort
  min_date = Time.parse checkout_dates.first
  max_date = Time.parse checkout_dates.last
  # Determine seconds elapsed between first and last checkout
  max_date - min_date
end

def none(checkouts_requiring_randomized_date, all_checkouts)
  checkouts_requiring_randomized_date
    .map { |checkout| Time.parse(checkout.created).iso8601 }
end

def random_shuffle(checkouts_requiring_randomized_date, all_checkouts)
  shuffled = checkouts_requiring_randomized_date
    .map { |checkout| [rand, checkout] }
    .sort
    .map { |(float, checkout)| checkout }
  none(shuffled, all_checkouts)
end

def uniform(checkouts_requiring_randomized_date, all_checkouts)
  Array.new(all_checkouts.size)
    .map { |ind| rand delta_seconds(all_checkouts) }
    .sort
    .reverse
    .map { |s| Time.at(Time.now - s).iso8601 }
end
