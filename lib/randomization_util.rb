def delta_seconds(checkouts)
  # Determine min and max dates of checkouts
  checkout_dates = checkouts.map { |checkout| checkout.created }.sort
  min_date = Time.parse checkout_dates.first
  max_date = Time.parse checkout_dates.last
  # Determine seconds elapsed between first and last checkout
  max_date - min_date
end

def none(checkouts)
end

def random_shuffle(checkouts)
end

def uniform(checkouts)
  Array.new(checkouts.size)
    .map { |ind| rand delta_seconds(checkouts) }
    .sort
    .reverse
    .map { |s| Time.at(Time.now - s).iso8601 }
end
