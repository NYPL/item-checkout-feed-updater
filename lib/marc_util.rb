class MarcUtil
  def self.var_block(record, marc)
    return nil unless record && record['varFields'] && record['varFields'].is_a?(Array)
    record['varFields']
      .select { |field| field['marcTag'] == marc }
      .first
  end

  def self.subfield_block(var_block, subfield)
    return nil unless var_block && var_block['subfields'] && var_block['subfields'].is_a?(Array)
    var_block['subfields']
      .select { |subfield_b| subfield_b['tag'] == subfield }
      .first
  end

  def self.subfield_block_content(subfield_block)
    subfield_block && subfield_block['content']
  end

  def self.marc_value(record, marc, subfield)
    var_block = self.var_block(record, marc)
    subfield_block = self.subfield_block(var_block, subfield)
    self.subfield_block_content subfield_block
  end
end
