class Guvera::Dynamodb::BatchWriter
  attr_accessor :items

  def initialize client, table_name
    @changes = []
    @table_name = table_name
    @client = client
  end

  def upsert item
    @changes << {
      put_request: {
        item: item.to_hash
      }
    }
  end

  def delete item
    @changes << {
      delete_request: {
        key: item.key
      }
    }
  end

  def << item
    upsert item
  end

  def save
    threads = []
    @changes.each_slice(25) do |items|
      threads << Thread.new do
        @client.batch_write_item({
          request_items: {
            "#{@table_name}" => items
          }
        })
      end
    end
    threads.each {|t| t.join }
  end
end
