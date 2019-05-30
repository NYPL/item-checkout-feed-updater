require 'spec_helper'

describe 'MarcUtil' do
  describe 'var_block' do
    it 'should return nil if record is falsey' do
    end

    it 'should return nil if record\'s varFields is falsey' do
    end

    it 'should return nil if record\'s varFields is not an Array' do
    end

    it 'should return the first varField with marcTag equal to value of marc' do
    end
  end

  describe 'subfield_block' do
    it 'should return nil if var_block is falsey' do
    end

    it 'should return nil if var_block\'s subfields is falsey' do
    end

    it 'should return nil if var_block\'s subfields is not an array' do
    end

    it 'should return the first subfield with tag equal to the given subfield' do
    end
  end

  describe 'subfield_block_content' do
    it 'should return subfield_block is subfield_block is falsey' do
    end

    it 'should return subfield_block\'s content if subfield_block has content' do
    end
  end

  describe 'marc_value' do
    it 'should return nil if record is falsey' do
    end

    it 'should return nil if record\'s varFields is falsey' do
    end

    it 'should return nil if record\'s varFields is not an Array' do
    end


    it 'should return nil if record has no matching varFields' do
    end

    it 'should return nil if records\'s matching varFields have no subfields' do
    end

    it 'should return nil if record\'s subfields is not an array' do
    end

    it 'should return nil if record\'s subfields has no content' do
    end

    it 'should return the content of record\'s subfield if there is content' do
    end
  end
end
