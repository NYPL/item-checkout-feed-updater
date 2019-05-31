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
    test_checkout = Checkout.new
    test_categories = [
      'Substance',
      'Quantity',
      'Relatives',
    ]
    before(:each) do
      allow(test_checkout).to receive(:categories).and_return(test_categories)
      ItemTypeTally[:tallies] = Hash.new {|h,k| h[k] = 0}
      ItemTypeTally[:tallies]['Substance'] = 4
      ItemTypeTally[:tallies]['Quality'] = 1
    end

    after(:each) do
      ItemTypeTally[:tallies] = Hash.new {|h,k| h[k] = 0}
    end

    it 'should add to the ItemTypeTally\'s tallies' do
      expected_tallies = {
        'Substance' => 5,
        'Quantity' => 1,
        'Relatives' => 1,
        'Quality' => 1,
      }
      item_stream_handler.update_count test_checkout
      expect(ItemTypeTally[:tallies]).to eq(expected_tallies)
    end

    it 'should update the checkout\'s tallies' do
      expected_tallies = {
        'Substance' => 5,
        'Quantity' => 1,
        'Relatives' => 1,
      }
      item_stream_handler.update_count test_checkout
      expect(test_checkout.tallies).to eq(expected_tallies)
    end

    it 'should not add extraneous categories to the checkout\'s tallies' do
      item_stream_handler.update_count test_checkout
      expect(test_checkout.tallies['Quality']).to eq(0)
    end

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
    mock_decoder = []
    mock_event = {
      "Records" => [
        {
          "eventSource" => "aws:kinesis",
          "kinesis" => {
            "data" => "hello"
          }
        },
        {
          "eventSource" => "aws:kinesis",
          "kinesis" => {
            "data" => "world"
          }
        },
        {
          "eventSource" => "other_source",
          "kinesis" => {
            "data" => "goodbye world"
          }
        },
      ]
    }
    before(:each) do
      allow(AvroDecoder).to receive(:by_name).and_return(mock_decoder)
      allow(mock_decoder).to receive(:decode).and_return('decoded')
    end

    it 'should should decode the kinesis data for each record' do
      expect(mock_decoder).to receive(:decode).with("hello")
      expect(mock_decoder).to receive(:decode).with("world")
      item_stream_handler.get_decoded_records mock_event
    end

    it 'should log a message for each record' do
      expect(Application.logger).to receive(:debug).twice
      item_stream_handler.get_decoded_records mock_event
    end

    it 'should call PreProcessingRandomizationUtil' do
      allow(PreProcessingRandomizationUtil).to receive(:process).and_return([])
      expect(PreProcessingRandomizationUtil).to receive(:process)
      item_stream_handler.get_decoded_records mock_event
    end

    it 'should filter out non-kinesis events' do
      expect(mock_decoder).not_to receive(:decode).with("goodbye world")
      item_stream_handler.get_decoded_records mock_event
    end
  end

  describe "#convert_record_to_checkout" do
    test_items = [
      {'status' => {
          'duedate' => 'yesterday',
        },
        'id' => '1234'
      },
      {'status' => {
          'duedate' => 'yesterday',
        },
        'id' => '1234'
      },
      {'status' => {
          'duedate' => nil,
        },
        'id' => '1234'
      },
      {'status' => {},
        'id' => '1234'
      },
      {'status' => 'bad_status',
        'id' => '1234'
      },
      'banana',
    ]

    before(:each) do
      allow(Checkout).to receive(:from_item_record).and_return(Checkout.new, nil)
    end

    it 'should convert exactly the valid items' do
      expect(Checkout).to receive(:from_item_record).twice
      item_stream_handler.convert_record_to_checkout test_items
    end

    it 'should remove nils' do
      converted = item_stream_handler.convert_record_to_checkout(test_items)
      expect(converted.length).to eq(1)
    end
  end

  describe "#is_duplicate" do
    test_checkout = []
    before(:each) do
      allow(test_checkout).to receive(:id).and_return 0
      allow(Time).to receive(:now).and_return Time.parse "2019-05-29 11:21:34 -0400"
      allow(ENV).to receive(:[]).and_return 1
    end

    it 'should log messages before and after checking if duplicate' do
      expect(Application.logger).to receive(:debug).twice
      item_stream_handler.is_duplicate?(test_checkout)
    end

    it 'should return a false if RECENT_IDS doesn\'t have the checkout id' do
      ItemStreamHandler::RECENT_IDS[0] = nil
      expect(item_stream_handler.is_duplicate? test_checkout).to eq(false)
    end

    it 'should return false if RECENT_IDS has the checkout id but it has expired' do
      ItemStreamHandler::RECENT_IDS[0] = Time.parse "2019-05-29 11:21:24 -0400"
      expect(item_stream_handler.is_duplicate? test_checkout).to eq(false)
    end

    it 'should return true if RECENT_IDS has the checkout id and it is recent' do
      ItemStreamHandler::RECENT_IDS[0] = Time.parse "2019-05-29 11:21:34 -0400"
      expect(item_stream_handler.is_duplicate? test_checkout).to eq(true)
    end
  end

  describe "#update_recent_ids" do
    recent_ids = ItemStreamHandler::RECENT_IDS
    before(:each) do
      ItemStreamHandler::RECENT_IDS = {}
    end

    after(:each) do
      ItemStreamHandler::RECENT_IDS = recent_ids
    end

    it 'should set the value of checkout id key to the current time' do
      checkout = []
      allow(checkout).to receive(:id).and_return('id')
      allow(Time).to receive(:now).and_return('party time')
      item_stream_handler.update_recent_ids checkout
      expect(ItemStreamHandler::RECENT_IDS[checkout.id]).to eq(Time.now)
    end
  end

  describe "#process_checkout" do
    it 'should return early if checkout is duplicate' do
      allow(item_stream_handler).to receive(:is_duplicate?).and_return(true)
      expect(item_stream_handler).not_to receive(:add_checkout)
      expect(item_stream_handler).not_to receive(:update_count)
      expect(item_stream_handler).not_to receive(:update_recent_ids)
      processed = item_stream_handler.process_checkout([])
      expect(processed).to eq(nil)
    end

    it 'should call all the processing methods if checkout is not duplicate' do
      allow(item_stream_handler).to receive(:is_duplicate?).and_return(false)
      allow(item_stream_handler).to receive(:add_checkout).and_return(nil)
      allow(item_stream_handler).to receive(:update_count).and_return(nil)
      allow(item_stream_handler).to receive(:update_recent_ids).and_return(nil)
      expect(item_stream_handler).to receive(:add_checkout)
      expect(item_stream_handler).to receive(:update_count)
      expect(item_stream_handler).to receive(:update_recent_ids)
      processed = item_stream_handler.process_checkout([])
      expect(processed).to eq(nil)
    end
  end

  describe "#process_checkouts" do
    before(:each) do
      allow(item_stream_handler).to receive(:process_checkout).and_return(nil)
    end

    it 'should call process_checkout for each checkout' do
      expect(item_stream_handler).to receive(:process_checkout).thrice
      item_stream_handler.process_checkouts([0,0,0])
    end
  end

  describe "#clear_old_data" do
    it 'should call all the data clearing methods' do
      allow(item_stream_handler).to receive(:update_tally_if_necessary).and_return(nil)
      allow(item_stream_handler).to receive(:constrain_size).and_return(nil)
      allow(item_stream_handler).to receive(:remove_old_ids).and_return(nil)
      expect(item_stream_handler).to receive(:update_tally_if_necessary)
      expect(item_stream_handler).to receive(:constrain_size)
      expect(item_stream_handler).to receive(:remove_old_ids)
      item_stream_handler.clear_old_data
    end
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
          },
          {
            "eventSource" => "aws:kinesis",
            "kinesis" => {
              "data" => "FAKE_DATA"
            }
          },
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
        expect(item_stream_handler).to have_received(:add_checkout)
      end

      it 'should not process a checkout with a recent id in a new batch' do
        item_stream_handler.handle(mock_event)
        item_stream_handler.handle(mock_event)
        expect(item_stream_handler).to have_received(:add_checkout).once
      end

      it 'should not process a checkout with a duplicate id in the same batch' do
        item_stream_handler.handle(mock_event)
        expect(item_stream_handler).to have_received(:add_checkout).once
      end

      it 'should process a checkout with an old id' do
        ENV['CHECKOUT_ID_EXPIRE_TIME'] = nil
        item_stream_handler.handle(mock_event)
        expect(item_stream_handler).to have_received(:add_checkout).twice
      end
    end
  end
end
