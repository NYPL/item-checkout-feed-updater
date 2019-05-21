describe ItemHandlerRecords do
  describe '#item_is_checkout?' do
    it 'should reject a malformed item' do
      expect(ItemHandlerRecords.item_is_checkout?(nil)).to eq(false)
      expect(ItemHandlerRecords.item_is_checkout?('fladeedle')).to eq(false)
      expect(ItemHandlerRecords.item_is_checkout?(42)).to eq(false)
    end

    it 'should reject an empty item' do
      expect(ItemHandlerRecords.item_is_checkout?({})).to eq(false)
    end

    it 'should reject an item with insufficient data' do
      expect(ItemHandlerRecords.item_is_checkout?({ "status" => {}})).to eq(false)
      expect(ItemHandlerRecords.item_is_checkout?({ "status" => { "duedate": nil }})).to eq(false)
      expect(ItemHandlerRecords.item_is_checkout?({ "id" => "1" })).to eq(false)
    end

    it 'should identify an item with sufficient data' do
      expect(ItemHandlerRecords.item_is_checkout?({ "status" => { "duedate": nil }, "id" => "1"})).to eq(false)
    end
  end
end
