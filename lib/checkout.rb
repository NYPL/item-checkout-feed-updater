require_relative './util.rb'

class Checkout
  attr_accessor :id, :created, :isbn, :barcode, :title, :author, :link, :item_type, :coarse_item_type, :location_type

  @@item_types = {}
  File.open('./distinct_item_types_report.csv').each do |line|
    matched = line.match(/(.*),(\d*),(\w*)/)
    @@item_types[matched[2].to_i] = matched[3] if matched
  end

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

  def self.marc_value(record, marc, subfield)
    var_block = record['varFields']
      .select { |field| field['marcTag'] == marc }
      .first
    if ! var_block.nil?
      subfield_block = var_block['subfields']
        .select { |subfield_b| subfield_b['tag'] == subfield }
        .first
      if ! subfield_block.nil?
        return subfield_block['content']
      end
    end

    nil
  end

  def self.map_item_type_to_coarse_item_type(item_type)
    @@item_types[item_type.to_i]
  end

  def self.location_type(item_type)
    item_type.to_i >= 100 ? 'Branch' : 'Research'
  end

  def self.from_item_record(item)
    checkout = Checkout.new
    checkout.item_type = item['fixedFields']['61']['value']
    checkout.coarse_item_type = self.map_item_type_to_coarse_item_type checkout.item_type
    checkout.location_type = self.location_type checkout.item_type
    checkout.id = item['id']
    checkout.barcode = item['barcode']
    checkout.created = item['updatedDate']

    if item['bibIds'].is_a?(Array) && ! item['bibIds'].empty?
      response = Application.platform_api_client.get "bibs/#{item['nyplSource']}/#{item['bibIds'].first}"
      if response && response['data']
        bib = response['data']
        Application.logger.debug "Got bib for item #{item['id']}: #{bib.to_json}"

        checkout.title = bib['title']
        checkout.author = bib['author']
        checkout.link = "https://browse.nypl.org/iii/encore/record/C__Rb#{item['bibIds'].first}"

        # Get ISBN out of 020 $a (per https://docs.google.com/spreadsheets/d/1RtDxIpzcCrVqJqUjmMGkn8n2hX3BZVN9QvbB1HRgx1c/edit#gid=0&range=35:35 ):
        checkout.isbn = self.marc_value bib, '020', 'a'
        checkout.isbn.gsub! /\s\(.*/, '' if !checkout.isbn.nil?
      end
    end

    checkout
  end
end
