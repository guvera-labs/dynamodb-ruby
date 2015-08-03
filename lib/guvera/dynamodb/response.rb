class Guvera::Dynamodb::Response
  attr_accessor :model_class

  def initialize cls, response
    @response = response
    @model_class = cls
  end

  def cursor
    Guvera::Dynamodb::Cursor.new @model_class, @response
  end

  def object_from_item item
    return nil if item.nil?

    obj = @model_class.new
    obj.from_dynamodb_model_hash item
    obj
  end

  def first
    item = @response.items.first
    object_from_item item
  end

  def first_page
    @response.items.map do |item|
      object_from_item item
    end
  end

  def each &block
    each_with_index do |item, index|
      yield item
    end
  end

  def each_with_index &block
    index = 0
    @response.each do |page|
      page.items.each do |item|
        obj = object_from_item item
        yield obj, index
        index += 1
        obj
      end
    end
  end

  def last_evaluated_key
    @response.last_evaluated_key
  end

  def count
    @response['count']
  end
end
