require 'rubygems'
require 'nokogiri'

require_relative 's3_client'

class S3Writer
  def s3_client
    @s3_client ||= S3Client.new if @s3_client.nil?
  end

  def get_author(authorString)
    checkout_author_info_array = authorString.to_s.split(",")
    surname = checkout_author_info_array[0]
    first_name = checkout_author_info_array[1]

    checkout_author = surname || first_name ? " by #{checkout_author_info_array[1]} #{checkout_author_info_array[0]}" : ""

    checkout_author.rstrip.gsub(/ +/, " ")
  end

  def delta_seconds(checkouts)
    # Determine min and max dates of checkouts
    checkout_dates = checkouts.map { |checkout| checkout.created }.sort
    min_date = Time.parse checkout_dates.first
    max_date = Time.parse checkout_dates.last
    # Determine seconds elapsed between first and last checkout
    max_date - min_date
  end

  def creation_dates(checkouts)
    # Generate random creation times over covered timespan:
    @creation_dates ||= Array.new(checkouts.size)
      .map { |ind| rand delta_seconds(checkouts) }
      .sort
      .reverse
      .map { |s| Time.at(Time.now - s).iso8601 }
  end

  def generate_indexes(checkout, xml)
    checkout.tallies.each do |(category, tally)|
      xml['nypl'].index(category, tally)
    end
  end

  def generate_title(checkout)
    title = "\"#{checkout.title}\""
    title += checkout.has?(:author) ? get_author(checkout.author) : ""
  end

  def generate_tallies(xml)
    ItemTypeTally[:tallies].keys.each do |category|
      xml['nypl'].tally(category, ItemTypeTally[:tallies][category])
    end
  end

  def assign_checkout_properties(checkout, xml)
    xml.entry {
      xml.id "#{checkout.id}-#{checkout.barcode}"
      xml.title generate_title(checkout)
      xml.link checkout.link if checkout.has? :link
      # Assign somewhat random checkout time:
      xml.updated @creation_dates.shift
      xml['dcterms'].title checkout.title if checkout.has? :title
      xml['dc'].contributor checkout.author if checkout.has? :author
      xml['dc'].identifier "urn:isbn:#{checkout.isbn}" if checkout.has? :isbn
      xml['dc'].identifier "urn:barcode:#{checkout.barcode}" if checkout.has? :barcode
      xml['nypl'].locationType checkout.location_type
      xml['nypl'].coarseItemType checkout.coarse_item_type
      xml['nypl'].indexes { generate_indexes(checkout, xml) }
    }
  end

  def feed_xml(checkouts)
    creation_dates(checkouts)
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.feed(
        'xmlns' => "http://www.w3.org/2005/Atom",
        'xmlns:dc' => "http://purl.org/dc/elements/1.1/",
        'xmlns:dcterms' => "http://purl.org/dc/terms/",
        'xmlns:nypl' => "http://nypl.org/") {
          xml.title "Latest NYPL Checkouts"
          xml.author {
            xml.name "NYPL Digital"
          }
          xml.id "urn:nypl:item-checkout-feed"
          xml.updated Time.now
          xml['nypl'].tallies { generate_tallies(xml) }
          checkouts.each do |checkout|
            assign_checkout_properties(checkout, xml)
          end
        }
    end

    Application.logger.debug "Entry #{builder.to_xml}"

    # Application.logger.debug "Check out entry: #{entry}"
    builder.to_xml
  end

  def write(checkouts)
    xml = feed_xml checkouts
    Application.logger.debug "Generated atom feed: #{xml}"
    if ENV['S3_FEED_KEY']
      s3_client.write ENV['S3_FEED_KEY'], xml
    else
      Application.logger.error "No ENV['S3_FEED_KEY'] configured!"
    end
  end
end
