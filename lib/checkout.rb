class Checkout
  attr_accessor :id, :created, :isbn, :barcode, :title, :author, :link, :item_type, :coarse_item_type, :collection

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

  def category
    "#{coarse_item_type}_#{collection}"
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

  def self.map_item_types_to_coarse_item_types(item_type)
    @@item_types[item_type.to_i]
  end

  def self.circulating?(item_type)
    item_type.to_i >= 100 ? 'circulating' : 'non-circulating'
  end

  def self.assign_item_type(item, checkout)
    checkout.item_type = item['fixedFields']['61']['value']
  end

  def self.assign_coarse_item_type(item, checkout)
    checkout.coarse_item_type = self.map_item_types_to_coarse_item_types checkout.item_type
  end

  def self.assign_collection(item, checkout)
    checkout.collection = self.circulating? checkout.item_type
  end

  def self.assign_id(item, checkout)
    checkout.id = item['id']
  end

  def self.assign_barcode(item, checkout)
    checkout.barcode = item['barcode']
  end

  def self.assign_created(item, checkout)
    checkout.created = item['updatedDate']
  end

  def self.assign_link(item, checkout)
    if item['bibIds'].is_a?(Array) && !item['bibIds'].empty?
      checkout.link = "https://browse.nypl.org/iii/encore/record/C__Rb#{item['bibIds'].first}"
    end
  end

  def self.assigners
    self.methods.select { |method| method.match? /assign_/ }
  end

  def self.add_bib_title(bib, checkout)
    checkout.title = bib['title']
  end

  def self.add_bib_author(bib, checkout)
    checkout.author = bib['author']
  end

  def self.add_bib_isbn(bib, checkout)
    # Get ISBN out of 020 $a (per https://docs.google.com/spreadsheets/d/1RtDxIpzcCrVqJqUjmMGkn8n2hX3BZVN9QvbB1HRgx1c/edit#gid=0&range=35:35 ):
    checkout.isbn = self.marc_value bib, '020', 'a'
    checkout.isbn.gsub! /\s\(.*/, '' if !checkout.isbn.nil?
  end

  def self.bib_adders
    self.methods.select { |method| method.match? /add_bib_/}
  end

  def self.get_bibs(item)
    response = nil
    if item['bibIds'].is_a?(Array) && ! item['bibIds'].empty?
      response = Application.platform_api_client.get "bibs/#{item['nyplSource']}/#{item['bibIds'].first}"
    end
    response && response['data'] ? response['data'] : nil
  end

  def self.make_initial_assignments_to_checkout(item, checkout)
    self.assigners.each do |assigner|
      self.send(assigner, item, checkout)
    end
  end

  def self.make_bib_based_assignments_to_checkout(item, checkout)
    bib = self.get_bibs(item)
    return unless bib
    Application.logger.debug "Got bib for item #{item['id']}: #{bib.to_json}"
    self.bib_adders.each do |bib_adder|
      self.send(bib_adder, bib, checkout)
    end
  end

  def self.from_item_record(item)
    checkout = Checkout.new
    self.make_initial_assignments_to_checkout(item, checkout)
    self.make_bib_based_assignments_to_checkout(item, checkout)
    checkout
  end
end
