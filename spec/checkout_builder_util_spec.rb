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
    it 'should assign all the properties of the item to the checkout' do
      test_item = {
        'fixedFields' => {
          '61' => {
            'value' => 55
          }
        },
        'id' => '123456',
        'barcode' => '123456789',
        'updatedDate' => '2019-04-08T15:18:03-04:00'
      }
      test_checkout = Checkout.new
      CheckoutBuilderUtil.initial_checkout_property_assignment(test_item, test_checkout)
      expect(test_checkout.item_type).to eq(55)
      expect(test_checkout.coarse_item_type).to eq('Book')
      expect(test_checkout.location_type).to eq('Research')
      expect(test_checkout.id).to eq('123456')
      expect(test_checkout.barcode).to eq('123456789')
      expect(test_checkout.created).to eq('2019-04-08T15:18:03-00:00')
    end
  end

  describe '#assign_isbn' do
  end

  describe '#checkout_bib_property_assignment' do
  end

  describe '#get_bib' do
  end
end
