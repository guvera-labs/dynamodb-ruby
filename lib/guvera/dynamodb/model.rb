class Guvera::Dynamodb::Model
  attr_accessor :is_new

  class << self
    def dynamodb
      @dynamodb||=Aws::DynamoDB::Client.new
    end

    def field name, type=:string, default=nil
      @fields||={}
      @fields[name] = { type: type, default: default }
      attr_accessor name.to_s.to_sym
    end

    def table_name table_name=nil
      @table_name=table_name unless table_name.nil?
      @table_name
    end

    def fields
      @fields
    end

    def dynamoid_compatability_mode
      @dynamoid_compatability_mode = true
    end

    def is_dynamoid_compatability_mode?
      @dynamoid_compatability_mode
    end

    def key block
      @key_block = block unless block.nil?
    end

    def determine_key obj
      @key_block.call(obj)
    end

    def table_schema &schema
      @table_schema = schema if block_given?
      @table_schema
    end

    def add_hook target, method
      @hooks||={}
      @hooks[target]||=[]
      @hooks[target] << method
    end

    def before_save method
      add_hook :before_save, method
    end

    def after_save method
      add_hook :after_save, method
    end

    def before_create method
      add_hook :before_create, method
    end

    def after_create method
      add_hook :after_create, method
    end

    def before_destroy method
      add_hook :before_destroy, method
    end

    def hooks_for_target target
      if @hooks.nil?
        []
      else
        @hooks[target]||[]
      end
    end

    def table_exists?
      self.dynamodb.describe_table(
        table_name: self.table_name,
      )
      true
    rescue Aws::DynamoDB::Errors::ResourceNotFoundException => e
      false
    end

    def create_table
      LOGGER.info "Creating table #{table_name}"
      self.dynamodb.create_table(self.table_schema.call.merge(table_name: self.table_name))

      while !table_exists? do
        LOGGER.debug "Waiting for table #{table_name} to be created"
        sleep 1
      end
    rescue Aws::DynamoDB::Errors::ResourceInUseException => e
      LOGGER.info "#{table_name} table already exists"
    end

    def query conditions, options={}

      options = { scan_index_forward:options } unless options.is_a? Hash

      request = Request.new self
      request.method = :query
      request.params = {
        table_name: self.table_name,
        key_conditions: conditions,
        scan_index_forward: false,
      }.merge(options)

      request
    end

    def count conditions, options={}
      params = {
        table_name: self.table_name,
        select: "COUNT",
        key_conditions: conditions
      }.merge(options)

      response = self.dynamodb.query(params)

      response['count']
    end

    def scan options={limit: 50}
      request = Request.new self
      request.method = :scan
      request.params = {
        table_name: self.table_name,
      }.merge(options)

      request
    end

    def find_by_key key_hash
      item = self.dynamodb.get_item(
        table_name: self.table_name,
        key: key_hash
      )
      return nil if item.item.nil?

      obj = self.new
      obj.from_dynamodb_model_hash item.item
      obj
    rescue Aws::DynamoDB::Errors::ResourceNotFoundException => e
      puts "GOt an exception: #{e}"
      return nil
    end

    def find_by_keys keys
      response = self.dynamodb.batch_get_item(
        request_items: {
          self.table_name => {
            keys: keys
          }
        }
      )

      puts response

      resp.responses[self.table_name].map do |item|
        puts item
        obj = self.new
        obj.from_dynamodb_model_hash item
        obj
      end

    end

    def batch_writer
      BatchWriter.new dynamodb, table_name
    end

  end

  def initialize
    @is_new = true
    @created_at = Time.now
    @updated_at = Time.now

    self.class.field :updated_at, :datetime
    self.class.field :created_at, :datetime
  end

  def from_dynamodb_model_hash hash, update_with_nils=false
    self.is_new = false
    hash = hash.dup.symbolize_keys

    self.class.fields.each_pair do |key, data|
      value = hash[key]

      case data[:type]
      when :datetime
        if self.class.is_dynamoid_compatability_mode?
          value = value.nil? ? nil : Time.at(value.to_f)
        else
          value = value.nil? ? nil : Time.at(value.to_f/1000)
        end
      when :integer
        value = value.to_i
      when :hash
        if value.nil?
          # nil is fine
        elsif self.class.is_dynamoid_compatability_mode?
          # convert from YAML?
          value = YAML.load(value)
        end
      when :boolean
        if self.class.is_dynamoid_compatability_mode?
          # Dynamoid doesnt support BOOL
          value = value=='t'
        end
      when :float
        value = value.to_f
      end

      self.send "#{key}=", value unless value.nil? and !update_with_nils
    end
    nil
  end

  def reload
    item = self.class.dynamodb.get_item(
      table_name: self.class.table_name,
      key: self.class.determine_key(self)
    )
    return nil if item.item.nil?
    from_dynamodb_model_hash item.item
  end

  def to_hash
    attributes = {}
    self.class.fields.each_pair do |key, data|
      value = self.send(key.to_s.to_sym)

      if data[:type]==:datetime
        value = (value.to_f*1000).to_i
      end

      attributes[key.to_s.to_sym] = value
    end

    attributes
  end

  def delete
    self.invoke_hooks_for_target :before_destroy

    self.class.dynamodb.delete_item(
      table_name: self.class.table_name,
      key: self.class.determine_key(self)
    )
  end

  def destroy
    self.delete
  end

  def record_attributes with_keys=false
    self.updated_at = Time.now

    attributes = {}
    self.class.fields.each_pair do |key, data|
      value = self.send(key.to_s.to_sym)

      case data[:type]
      when :datetime
        if self.class.is_dynamoid_compatability_mode?
          value = value.to_f
        else
          value = (value.to_f*1000).to_i
        end
      when :string
        value = value.nil? ? nil : value.to_s
      when :boolean
        if self.class.is_dynamoid_compatability_mode?
          # Dynamoid doesnt support BOOL
          value = value ? 't' : 'f'
        end
      when :hash
        if self.class.is_dynamoid_compatability_mode?
          # convert from YAML?
          value = YAML.dump(value)
        end

        # DynamoDB supports JSON blobs, so should be ok
      when :integer, :float
        # Should be ok?
      end

      attributes[key.to_s.to_sym] = { value: value, action: 'PUT'}
    end

    unless with_keys
      self.key.keys.each do |key|
        attributes.delete key.to_s.to_sym
      end
    end

    attributes
  end

  def key
    self.class.determine_key(self)
  end

  def save
    self.invoke_hooks_for_target :before_create if self.is_new
    self.invoke_hooks_for_target :before_save

    self.updated_at = Time.now

    attributes = record_attributes false

    self.class.dynamodb.update_item(
      table_name: self.class.table_name,
      key: self.key,
      attribute_updates: attributes
    )

    self.invoke_hooks_for_target :after_create if self.is_new
    self.invoke_hooks_for_target :after_save

    self.is_new = false
  end

  def invoke_hooks_for_target target
    self.class.hooks_for_target(target).each {|method| self.send method }
  end
end
