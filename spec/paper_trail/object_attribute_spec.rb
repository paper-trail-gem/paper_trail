require "spec_helper"

RSpec.describe PaperTrail::AttributeSerializers::ObjectAttribute do
  describe '#serialize', database: :postgres do
    it 'serializes a postgres array into a plain array' do
      attrs = { 'post_ids' => [1, 2, 3] }
      PaperTrail::AttributeSerializers::ObjectAttribute.new(PostgresUser).serialize(attrs)
      expect(attrs['post_ids']).to eq [1,2,3]
    end
  end
end
