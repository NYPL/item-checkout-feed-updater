require 'spec_helper'

describe S3Writer do
  describe '#feed_xml' do
    describe 'cd item' do
      before(:each) do
        mock_api_client = instance_double(PlatformApiClient)
        allow(PlatformApiClient).to receive(:new).and_return(mock_api_client)
        allow(mock_api_client).to receive(:get).and_return({ "data" => fixture('bib-cee-lo.json') })

        mock_s3_client = instance_double(S3Client)
        allow(S3Client).to receive(:new).and_return(mock_s3_client)
        allow(mock_s3_client).to receive(:write).and_return({ "stuff" => true })

        load File.join('application.rb')
      end

      it 'generates feed' do
        feed_xml = S3Writer.new.feed_xml([
          Checkout.from_item_record(fixture('item-cee-lo.json'))
        ])

        expect(feed_xml).to be_a(String)

        feed = Nokogiri::XML(feed_xml)
        expect(feed).to be_a(Nokogiri::XML::Document)

        entries = feed.xpath('//xmlns:feed/xmlns:entry')
        expect(entries.size).to eq(1)

        expect(entries[0].xpath('xmlns:title').text).to eq('"The lady killer [sound recording]" by Cee-Lo (Musician)')
        expect(entries[0].xpath('dcterms:title').text).to eq('The lady killer [sound recording]')
        expect(entries[0].xpath('dc:contributor').text).to eq('Cee-Lo (Musician)')
      end
    end

    describe 'laptop item' do
      before(:each) do
        mock_api_client = instance_double(PlatformApiClient)
        allow(PlatformApiClient).to receive(:new).and_return(mock_api_client)
        allow(mock_api_client).to receive(:get).and_return({ "data" => fixture('bib-laptop.json') })

        mock_s3_client = instance_double(S3Client)
        allow(S3Client).to receive(:new).and_return(mock_s3_client)
        allow(mock_s3_client).to receive(:write).and_return({ "stuff" => true })

        load File.join('application.rb')
      end

      it 'generates feed' do
        feed_xml = S3Writer.new.feed_xml([
          Checkout.from_item_record(fixture('item-laptop.json'))
        ])

        expect(feed_xml).to be_a(String)

        feed = Nokogiri::XML(feed_xml)
        expect(feed).to be_a(Nokogiri::XML::Document)

        entries = feed.xpath('//xmlns:feed/xmlns:entry')
        expect(entries.size).to eq(1)
        expect(entries[0].xpath('xmlns:title').text).to eq('"Laptops."')
        expect(entries[0].xpath('dcterms:title').text).to eq('Laptops.')
        expect(entries[0].xpath('dc:contributor').size).to eq(0)
      end
    end
  end

  describe ' get_author' do
    it 'returns empty string if no author information' do
      get_author_empty_string = S3Writer.new.get_author('')
      expect(get_author_empty_string).to eq("")
    end
    it 'returns the string that consistsof author\'s first name and surname' do
      get_author_valid_string = S3Writer.new.get_author('Hanlon, Abby, author, illustrator.')
      expect(get_author_valid_string).to eq(" by Abby Hanlon")

      get_author_only_surname = S3Writer.new.get_author('Michaelides,')
      expect(get_author_only_surname).to eq(" by Michaelides")
    end
  end
end

