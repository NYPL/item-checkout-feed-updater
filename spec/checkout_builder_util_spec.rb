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
    it 'should assign the isbn' do
      allow(MarcUtil).to receive(:marc_value).and_return "9781442466753"
      test_checkout = Checkout.new
      CheckoutBuilderUtil.assign_isbn(nil, test_checkout)
      expect(test_checkout.isbn).to eq("9781442466753")
    end

    it 'should remove trailing parentheticals' do
      allow(MarcUtil).to receive(:marc_value).and_return "9781442466753 (hardback)"
      test_checkout = Checkout.new
      CheckoutBuilderUtil.assign_isbn(nil, test_checkout)
      expect(test_checkout.isbn).to eq("9781442466753")
    end

    it 'should handle nil isbn' do
      allow(MarcUtil).to receive(:marc_value).and_return nil
      test_checkout = Checkout.new
      CheckoutBuilderUtil.assign_isbn(nil, test_checkout)
      expect(test_checkout.isbn).to eq(nil)
    end
  end

  describe '#checkout_bib_property_assignment' do
    it 'should return early and not assign any properties if bib is falsey' do
      test_bib = nil
      test_checkout = Checkout.new
      test_item  = {
        'bibIds' => [
          'abcdef'
        ]
      }
      assignment = CheckoutBuilderUtil.checkout_bib_property_assignment(test_bib, test_checkout, test_item)
      expect(assignment).to eq(nil)
      expect(test_checkout.title).to eq(nil)
      expect(test_checkout.author).to eq(nil)
      expect(test_checkout.isbn).to eq(nil)
      expect(test_checkout.link).to eq(nil)
    end

    it 'should assign bib and item properties to the checkout' do
      allow(MarcUtil).to receive(:marc_value).and_return "9781442466753"
      test_bib = {
        'title' => 'This test',
        'author' => 'Me'
      }
      test_checkout = Checkout.new
      test_item  = {
        'bibIds' => [
            'abcdef'
          ]
      }
      CheckoutBuilderUtil.checkout_bib_property_assignment(test_bib, test_checkout, test_item)
      expect(test_checkout.title).to eq('This test')
      expect(test_checkout.author).to eq('Me')
      expect(test_checkout.isbn).to eq("9781442466753")
      expect(test_checkout.link).to eq("https://browse.nypl.org/iii/encore/record/C__Rbabcdef")
    end

  end

  describe '#get_bib' do
  end
end
