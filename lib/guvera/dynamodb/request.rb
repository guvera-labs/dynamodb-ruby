class Guvera::Dynamodb::Request
  attr_accessor :method, :params, :model_class

  def initialize model_class
    @model_class = model_class
    @method = :query
    @query = {}
  end

  def response
    params = self.params.merge(@query)
    response = @model_class.dynamodb.send(@method, params)
    Guvera::Dynamodb::Response.new @model_class, response
  end

  def method_missing method, *args, &block
    response.send(method, *args, &block)
  end
end
