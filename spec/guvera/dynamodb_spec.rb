require 'spec_helper'
require 'dynamodb/local'

describe Guvera::Dynamodb do

  class TestDocument < Guvera::Dynamodb::Model
    table_name 'test_documents'
    field :hash_id, :string
    field :range, :integer
    field :number, :integer
    field :text, :string
    field :data, :hash

    key -> (entry) { { hash_id: entry.hash_id, range: entry.range } }

    table_schema do
      {
        attribute_definitions: [
          { attribute_name: "hash_id", attribute_type: "S" },
          { attribute_name: "range", attribute_type: "N" }
        ],
        key_schema: [
          { attribute_name: "hash_id", key_type: "HASH" },
          { attribute_name: "range", key_type: "RANGE" }
        ],
        provisioned_throughput: { read_capacity_units: 1, write_capacity_units: 1 }
      }
    end
  end

  it 'has a version number' do
    expect(Guvera::Dynamodb::VERSION).not_to be nil
  end

  context 'creating table' do
    it "should create a table" do
      TestDocument.create_table
      response = TestDocument.dynamodb.describe_table table_name: 'test_documents'
      puts response.inspect
    end
  end

  context 'creating resources' do
    it "should create a new record" do
      doc = TestDocument.new
      doc.hash_id = "test_1"
      doc.range = 1
      expect(doc.is_new).to eq(true)

      doc.text = "Test String"
      doc.save

      expect(doc.is_new).to eq(false)

      doc.reload
      expect(doc.text).to eq("Test String")
    end
  end

  context "fetching resources" do
    before :each do
      doc = TestDocument.new
      doc.hash_id = "existing_doc"
      doc.range = 1
      doc.save
    end

    it "should fetch a record" do
      doc = TestDocument.find_by_key hash_id: "existing_doc", range: 1
      expect(doc).to_not be_nil
      expect(doc.hash_id).to eq("existing_doc")
      expect(doc.range).to eq(1)
    end
  end
end
