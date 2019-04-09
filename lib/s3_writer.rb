require 'rubygems'
require 'nokogiri'

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

        xml.title = "Latest NYPL Checkouts"
        xml.author {
          xml.name "NYPL Digital"
        }
        xml.id "urn:nypl:item-checkout-feed"

        checkouts.each do |checkout|
          xml.entry {
            xml.id "#{checkout.id}-#{checkout.barcode}"
            xml.title "\"#{checkout.title}\" by #{checkout.author}"
            xml.link = checkout.id
            xml.updated = checkout.created
            xml['dcterms'].title checkout.title
            xml['dc'].contributor checkout.author
            xml['dc'].identifier "urn:isbn:#{checkout.isbn}"
            xml['dc'].identifier "urn:barcode:#{checkout.barcode}"
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
  end
end
