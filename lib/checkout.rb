require_relative './util.rb'
require_relative './marc_util.rb'
require_relative './checkout_builder_util.rb'

class Checkout
  attr_accessor :id, :created, :isbn, :barcode, :title, :author, :link, :item_type, :coarse_item_type, :location_type

  def to_s
    "Checkout #{id}: #{title} by #{author} (isbn #{isbn})"
  end

  # Return true if named property (e.g. :title) is truthy
  def has?(prop)
    val = self.send prop
    ! val.nil? && ! val.empty?
  end

  def categories
    subs({ "locationType" => location_type, "coarseItemType" => coarse_item_type })
  end

  def tallies
    @tallies ||= Hash.new{|h,k| h[k] = 0}
  end

  def self.from_item_record(item)
    checkout = Checkout.new
    CheckoutBuilderUtil.initial_checkout_property_assignment(item, checkout)
    bib = CheckoutBuilderUtil.get_bib(item)
    CheckoutBuilderUtil.checkout_bib_property_assignment(bib, checkout, item)
    checkout
  end
end
