require 'spec_helper'

describe ItemStreamHandler do
  describe '#handle' do
    describe 'deduping based on ids' do
      ItemTypeTally = {
        time: Time.now,
        tallies: Hash.new {|h,k| h[k] = 0 }
      }
      irrelevant = []
      Application = irrelevant
      item_stream_handler = ItemStreamHandler.new
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
        }
      }
      mock_decoder = {}
      mock_checkout = {}

      before(:each) do
        ENV['CHECKOUT_ID_EXPIRE_TIME'] = '1000000'
        allow(mock_decoder).to receive(:decode).and_return(decoded_data)
        allow(AvroDecoder).to receive(:by_name).and_return(mock_decoder)
        allow(mock_checkout).to receive(:id).and_return(1)
        allow(Checkout).to receive(:from_item_record).and_return(mock_checkout)
        allow(item_stream_handler).to receive(:add_checkout).and_return(nil)
        allow(item_stream_handler).to receive(:update_count).and_return(nil)
        allow(irrelevant).to receive_messages(logger: irrelevant, info: irrelevant, s3_writer: irrelevant, write: irrelevant)
      end

      it 'should process a checkout with a new id' do
        item_stream_handler.handle(mock_event)
        expect(item_stream_handler).to have_received(:add_checkout).once
      end

      it 'should not process a checkout with a recent id' do
        item_stream_handler.handle(mock_event)
        expect(item_stream_handler).not_to have_received(:add_checkout)
      end

      it 'should process a checkout with an old id' do
        ENV['CHECKOUT_ID_EXPIRE_TIME'] = nil
        item_stream_handler.handle(mock_event)
        expect(item_stream_handler).to have_received(:add_checkout).once
      end
    end
  end
end
