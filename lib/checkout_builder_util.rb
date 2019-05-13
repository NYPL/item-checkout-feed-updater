require_relative './marc_util.rb'

class CheckoutBuilderUtil

  @@item_types = {}
  File.open('./distinct_item_types_report.csv').each do |line|
    matched = line.match(/(.*),(\d*),(\w*)/)
    @@item_types[matched[2].to_i] = matched[3] if matched
  end


  def self.map_item_type_to_coarse_item_type(item_type)
    @@item_types[item_type.to_i]
  end

  def self.location_type(item_type)
    item_type.to_i >= 100 ? 'Branch' : 'Research'
  end

  def self.initial_checkout_property_assignment(item, checkout)
    checkout.item_type = item['fixedFields']['61']['value']
    checkout.coarse_item_type = self.map_item_type_to_coarse_item_type checkout.item_type
    checkout.location_type = self.location_type checkout.item_type
    checkout.id = item['id']
    checkout.barcode = item['barcode']
    checkout.created = item['updatedDate']
  end

  def self.assign_isbn(bib, checkout)
    # Get ISBN out of 020 $a (per https://docs.google.com/spreadsheets/d/1RtDxIpzcCrVqJqUjmMGkn8n2hX3BZVN9QvbB1HRgx1c/edit#gid=0&range=35:35 ):
    checkout.isbn = MarcUtil.marc_value bib, '020', 'a'
    checkout.isbn.gsub! /\s\(.*/, '' if !checkout.isbn.nil?
  end

  def self.checkout_bib_property_assignment(bib, checkout, item)
    return unless bib
    checkout.title = bib['title']
    checkout.author = bib['author']
    self.assign_isbn(bib, checkout)
    checkout.link = "https://browse.nypl.org/iii/encore/record/C__Rb#{item['bibIds'].first}"
  end

  def self.get_bib(item)
    return nil unless item['bibIds'].is_a?(Array) && !item['bibIds'].empty?
    response = Application.platform_api_client.get "bibs/#{item['nyplSource']}/#{item['bibIds'].first}"
    return nil unless response && response['data']
    bib = response['data']
    Application.logger.debug "Got bib for item #{item['id']}: #{bib.to_json}"
    bib
  end


end
