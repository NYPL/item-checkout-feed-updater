require 'spec_helper'

describe Checkout do
  describe '#from_item_record' do
    describe 'laptop item' do
      before(:each) do
        mock_api_client = instance_double(PlatformApiClient)
        allow(PlatformApiClient).to receive(:new).and_return(mock_api_client)
        allow(mock_api_client).to receive(:get).and_return({ "data" => fixture('bib-laptop.json') })

        Application.platform_api_client = PlatformApiClient.new
      end

      it 'generates laptop checkout' do
        checkout = Checkout.from_item_record(fixture('item-laptop.json'))

        expect(checkout).to be_a(Checkout)
        expect(checkout.id).to eq('34132673')
        expect(checkout.created).to eq('2019-04-10T17:36:22-00:00')
        expect(checkout.isbn).to be_nil
        expect(checkout.barcode).to eq('33333406215299')
        expect(checkout.title).to eq('Laptops.')
        expect(checkout.author).to eq('')
        expect(checkout.link).to eq('https://browse.nypl.org/iii/encore/record/C__Rb17990921')
      end
    end

    describe 'laptop item' do
      before(:each) do
        mock_api_client = instance_double(PlatformApiClient)
        allow(PlatformApiClient).to receive(:new).and_return(mock_api_client)
        allow(mock_api_client).to receive(:get).and_return({ "data" => fixture('bib-cee-lo.json') })

        Application.platform_api_client = PlatformApiClient.new
      end

      it 'generates cee-lo album checkout' do
        checkout = Checkout.from_item_record(fixture('item-cee-lo.json'))

        expect(checkout).to be_a(Checkout)
        expect(checkout.id).to eq('25855062')
        expect(checkout.created).to eq('2019-04-10T20:52:48-00:00')
        expect(checkout.isbn).to be_nil
        expect(checkout.barcode).to eq('33333289418770')
        expect(checkout.title).to eq('The lady killer [sound recording]')
        expect(checkout.author).to eq('Cee-Lo (Musician)')
        expect(checkout.link).to eq('https://browse.nypl.org/iii/encore/record/C__Rb18672258')
      end
    end
  end
end
