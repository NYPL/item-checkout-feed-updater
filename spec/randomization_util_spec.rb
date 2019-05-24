require 'spec_helper'

describe 'Randomization Utils' do
  test_times  = [
    "2019-05-24 15:01:15 -0400",
    "2019-05-24 13:36:27 -0400",
    "2019-05-24 14:28:51 -0400",
    "2019-05-24 12:45:47 -0400",
    "2019-05-24 15:13:37 -0400",
    "2019-05-24 14:10:53 -0400",
    "2019-05-24 14:05:29 -0400",
    "2019-05-24 14:10:10 -0400",
    "2019-05-24 14:35:31 -0400",
    "2019-05-24 15:10:02 -0400",
  ]

  test_checkouts = []

  10.times do |i|
    checkout = Checkout.new
    checkout.created = test_times[i]
    checkout.randomized_date = ( i > 4)
    test_checkouts << checkout
  end


  describe 'RandomizationHelperUtil' do
    describe '#delta_seconds' do
      it 'should return the correct delta' do
        expect(RandomizationHelperUtil
          .delta_seconds(test_checkouts))
          .to be_within(1)
          .of(8869)
      end
    end

    describe '#checkouts_requiring_randomized_date' do
      it 'should select the checkouts that do not yet have randomized_date set' do
        expect(RandomizationHelperUtil
          .checkouts_requiring_randomized_date(test_checkouts)
          .length).to eq(5)
      end
    end

    describe '#last_time' do
      it 'should get the last time' do
        expect(
          RandomizationHelperUtil
          .last_time(test_checkouts))
          .to eq(Time.parse("2019-05-24 15:13:37 -0400"))
      end
    end
  end

  describe 'PostProcessingRandomizationUtil' do
    test_opts = {
      new_checkouts: test_checkouts
    }
    describe '#none' do
      it 'should convert timestamps to iso8601' do
        expect(PostProcessingRandomizationUtil.none(test_opts)).to eq(
          [
            "2019-05-24T15:01:15-04:00",
            "2019-05-24T13:36:27-04:00",
            "2019-05-24T14:28:51-04:00",
            "2019-05-24T12:45:47-04:00",
            "2019-05-24T15:13:37-04:00",
            "2019-05-24T14:10:53-04:00",
            "2019-05-24T14:05:29-04:00",
            "2019-05-24T14:10:10-04:00",
            "2019-05-24T14:35:31-04:00",
            "2019-05-24T15:10:02-04:00",
          ]
        )
      end
    end

    describe '#uniform' do
      it 'should generate a sorted list of times in the given range' do
        allow(PostProcessingRandomizationUtil).to receive(:rand).and_return(*(10.times))
        expect(PostProcessingRandomizationUtil.uniform(test_opts)).to eq(
          [
            "2019-05-24T15:13:28-04:00",
            "2019-05-24T15:13:29-04:00",
            "2019-05-24T15:13:30-04:00",
            "2019-05-24T15:13:31-04:00",
            "2019-05-24T15:13:32-04:00",
            "2019-05-24T15:13:33-04:00",
            "2019-05-24T15:13:34-04:00",
            "2019-05-24T15:13:35-04:00",
            "2019-05-24T15:13:36-04:00",
            "2019-05-24T15:13:37-04:00",
          ]
        )
      end
    end

    describe '#add_randomized_dates!' do
    end

    describe '#process!' do
    end

    describe 'missing randomization method' do
    end
  end

  describe 'PreProcessingRandomizationUtil' do
    describe '#random_shuffle' do
    end

    describe '#process' do
    end

    describe 'missing method' do
    end
  end
end
