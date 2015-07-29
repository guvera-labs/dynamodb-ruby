class Guvera::Dynamodb::Cursor
  attr_accessor :page, :current_item

  def initialize cls, response
    @page_index = 0
    @total_index = 0
    @page = response
    @cls = cls

    @current_item = @page.items[0]
  end

  def current
    return nil if @current_item.nil?
    object_from_item @current_item
  end

  def next_item
    if @page_index + 1 >= @page.items.count
      if @page.last_page?
        @current_item = nil
        return nil
      end

      # next page
      @page_index = 0
      @page = @page.next_page
    else
      @page_index += 1
    end

    @total_index += 1

    @current_item = @page.items[@page_index]

    current
  end

  def index
    @total_index
  end

  def seek_to requested_index
    while self.index < requested_index
      next_item
    end
  end

  def object_from_item item
    obj = @cls.new
    obj.from_dynamodb_model_hash item
    obj
  end

end
