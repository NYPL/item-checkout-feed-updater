require 'spec_helper'

describe ItemStreamHandler do

  item_stream_handler = nil
  before(:each) do
    item_stream_handler = ItemStreamHandler.new
  end

  describe "#add_checkout" do
    test_checkout = {}
    before(:each) do
      allow(test_checkout).to receive(:id).and_return('test_checkout')
      allow(test_checkout).to receive(:barcode).and_return('test_checkout')
      allow(test_checkout).to receive(:title).and_return('test_checkout')
    end

    it 'should add the checkout to a new item_stream_handler' do
      item_stream_handler.add_checkout test_checkout
      expect(item_stream_handler.instance_variable_get(:@checkouts)).to include(test_checkout)
    end

    it 'should log messages' do
      expect(Application.logger).to receive(:debug).twice
      item_stream_handler.add_checkout test_checkout
    end
  end

  describe "#constrain_size" do
    it 'should result in an array with the given size if the array is big enough' do
      test_array = [1,2,3,4,5]
      item_stream_handler.constrain_size(test_array,2)
      expect(test_array.size).to eq(2)
    end

    it 'should not change the array if the array is smaller than the given size' do
      test_array = [1]
      item_stream_handler.constrain_size(test_array, 2)
      expect(test_array.size).to eq(1)
    end
  end

  describe "#update_tally_if_necessary" do
    item_type_tally = nil
    fake_now = []

    before(:each) do
      item_type_tally = ItemTypeTally
      allow(Time).to receive(:now).and_return(fake_now)
      allow(fake_now).to receive(:day).and_return(2)
    end

    after(:each) do
      ItemTypeTally = item_type_tally
    end

    it 'should update the ItemTypeTally if necessary' do
      fake_then = []
      allow(fake_then).to receive(:day).and_return(1)
      ItemTypeTally = {
        time: fake_then
      }
      item_stream_handler.update_tally_if_necessary
      expect(ItemTypeTally[:time]).to eq(fake_now)
      expect(ItemTypeTally[:tallies]).to eq({})
      ItemTypeTally[:tallies][:tally] += 1
      expect(ItemTypeTally[:tallies][:tally])
    end

    it 'should leave the ItemTypeTally unchanged if no change is required' do
      fake_then = []
      allow(fake_then).to receive(:day).and_return(2)

      ItemTypeTally = {
        time: fake_now
      }
      item_stream_handler.update_tally_if_necessary
      expect(ItemTypeTally[:time]).to eq(fake_then)
      expect(ItemTypeTally[:tallies]).to eq(nil)
    end
  end

  describe "#update_count" do
  end

  describe "#remove_old_ids" do
    it 'should remove exactly the expired ids' do
      expire_time = (ENV["CHECKOUT_ID_EXPIRE_TIME"] ||= "10").to_i
      allow(Time).to receive(:now).and_return(0)
      id_hash = {
        a: Time.now + expire_time + 1,
        b: Time.now + expire_time + 1,
        c: Time.now + expire_time - 1,
        d: Time.now + expire_time - 1,
      }
      item_stream_handler.remove_old_ids(id_hash)
      expect(id_hash[:a]).to_not eq(nil)
      expect(id_hash[:b]).to_not eq(nil)
      expect(id_hash[:c]).to_not eq(nil)
      expect(id_hash[:d]).to_not eq(nil)
    end
  end

  describe "#get_decoded_records" do
  end

  describe "#convert_record_to_checkout" do
  end

  describe "#is_duplicate" do
  end

  describe "#update_recent_ids" do
  end

  describe "#process_checkout" do
  end

  describe "#process_checkouts" do
  end

  describe "#clear_old_data" do
  end

  describe '#item_is_checkout?' do
    it 'should reject a malformed item' do
      expect(ItemStreamHandler.new.item_is_checkout?(nil)).to eq(false)
      expect(ItemStreamHandler.new.item_is_checkout?('fladeedle')).to eq(false)
      expect(ItemStreamHandler.new.item_is_checkout?(42)).to eq(false)
    end

    it 'should reject an empty item' do
      expect(ItemStreamHandler.new.item_is_checkout?({})).to eq(false)
    end

    it 'should reject an item with insufficient data' do
      expect(ItemStreamHandler.new.item_is_checkout?({ "status" => {}})).to eq(false)
      expect(ItemStreamHandler.new.item_is_checkout?({ "status" => { "duedate": nil }})).to eq(false)
      expect(ItemStreamHandler.new.item_is_checkout?({ "id" => "1" })).to eq(false)
    end

    it 'should identify an item with sufficient data' do
      expect(ItemStreamHandler.new.item_is_checkout?({ "status" => { "duedate": nil }, "id" => "1"})).to eq(false)
    end
  end

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
        ItemStreamHandler::RECENT_IDS.clear

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
