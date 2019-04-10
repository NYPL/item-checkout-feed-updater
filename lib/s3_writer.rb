require 'rubygems'
require 'nokogiri'

require_relative 's3_client'

class S3Writer
  def s3_client
    @s3_client = S3Client.new if @s3_client.nil?
    @s3_client
  end

  def feed_xml(checkouts)
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.feed(
        'xmlns' => "http://www.w3.org/2005/Atom", 
        'xmlns:dc' => "http://purl.org/dc/elements/1.1/",
        'xmlns:dcterms' => "http://purl.org/dc/terms/") {

        xml.title "Latest NYPL Checkouts"
        xml.author {
          xml.name "NYPL Digital"
        }
        xml.id "urn:nypl:item-checkout-feed"
        xml.updated Time.now

        checkouts.each do |checkout|
          xml.entry {
            xml.id "#{checkout.id}-#{checkout.barcode}"
            title = "\"#{checkout.title}\""
            title += " by #{checkout.author}" if checkout.author
            xml.title title
            xml.link checkout.link
            xml.updated checkout.created
            xml['dcterms'].title checkout.title if checkout.title
            xml['dc'].contributor checkout.author if checkout.author
            xml['dc'].identifier "urn:isbn:#{checkout.isbn}" if checkout.isbn
            xml['dc'].identifier "urn:barcode:#{checkout.barcode}" if checkout.barcode
          }
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
