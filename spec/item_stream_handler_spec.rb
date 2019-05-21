require 'spec_helper'

describe ItemStreamHandler do
  describe '#handle' do
    describe 'deduping based on ids' do
      ItemTypeTally = {
        time: Time.now,
        tallies: Hash.new {|h,k| h[k] = 0 }
      }
      item_stream_handler = nil
      mock_event = {
        "Records" => [
          {
            "eventSource" => "aws:kinesis",
            "kinesis" => {
              "data" => "FAKE_DATA"
            }
          }
        ]
      }
      decoded_data = {
        "status" => {
          "duedate" => "12/31/3000"
        },
        "id" => "1234"
      }
      mock_decoder = {}
      mock_checkout = {}

      before(:each) do
        item_stream_handler = ItemStreamHandler.new
        # ItemStreamHandler::RECENT_IDS.clear
        ItemHandlerRecords::RECENT_IDS.clear

        ENV['CHECKOUT_ID_EXPIRE_TIME'] = '1000000'

        allow(mock_decoder).to receive(:decode).and_return(decoded_data)
        allow(AvroDecoder).to receive(:by_name).and_return(mock_decoder)

        allow(mock_checkout).to receive(:id).and_return(1)
        allow(mock_checkout).to receive(:categories).and_return(['Book'])
        allow(mock_checkout).to receive(:tallies).and_return({})
        allow(mock_checkout).to receive(:barcode).and_return('1234')
        allow(mock_checkout).to receive(:title).and_return('Book Title')
        allow(Checkout).to receive(:from_item_record).and_return(mock_checkout)

        mock_s3_writer = instance_double(S3Writer)
        allow(mock_s3_writer).to receive(:write)
        allow(Application).to receive(:s3_writer).and_return(mock_s3_writer)
        allow(item_stream_handler).to receive(:add_checkout).and_return(nil)
      end

      it 'should process a checkout with a new id' do
        item_stream_handler.handle(mock_event)
        expect(item_stream_handler).to have_received(:add_checkout).once
      end

      it 'should not process a checkout with a recent id' do
        item_stream_handler.handle(mock_event)
        item_stream_handler.handle(mock_event)
        expect(item_stream_handler).to have_received(:add_checkout).once
      end

      it 'should process a checkout with an old id' do
        ENV['CHECKOUT_ID_EXPIRE_TIME'] = nil
        item_stream_handler.handle(mock_event)
        expect(item_stream_handler).to have_received(:add_checkout).once
      end
    end
  end
end
