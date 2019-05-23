require 'spec_helper'


describe CheckoutBuilderUtil do
  describe '#map_item_type_to_coarse_item_type' do
    it 'should map 55 to Book' do
      expect(CheckoutBuilderUtil.map_item_type_to_coarse_item_type(55)).to eq('Book')
    end
    
    it 'should map 6 to Image' do
      expect(CheckoutBuilderUtil.map_item_type_to_coarse_item_type(6)).to eq('Image')
    end

    it 'should map 13 to AV' do
      expect(CheckoutBuilderUtil.map_item_type_to_coarse_item_type(13)).to eq('AV')
    end

    it 'should map 128 to Device' do
      expect(CheckoutBuilderUtil.map_item_type_to_coarse_item_type(128)).to eq('Device')
    end
  end

  describe '#location_type' do
    it 'should assign item types over 100 to Branch' do
      expect(CheckoutBuilderUtil.location_type(100)).to eq('Branch')
    end

    it 'should assign item types under 100 to Research' do
      expect(CheckoutBuilderUtil.location_type(99)).to eq('Research')
    end
  end

  describe '#initial_checkout_property_assignment' do
  end

  describe '#assign_isbn' do
  end

  describe '#checkout_bib_property_assignment' do
  end

  describe '#get_bib' do
  end
end
