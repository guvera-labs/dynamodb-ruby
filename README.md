[![Build Status](https://travis-ci.org/guvera-labs/dynamodb-ruby.svg)](https://travis-ci.org/guvera-labs/dynamodb-ruby)

# Guvera::Dynamodb

Map dynamodb tables to ruby classes in a manner not entirely unlike ActiveRecord or Dynamoid

This project was built with a degree of similarity to Dynamoid as that is what we were using.  Unfortnately, because it makes use of the AWS SDK v1, it doesnt give access to many more modern features such as secondary indices, etc.

So, while this is written to mimic some of the concepts in Dynamoid, it tries not to constrain how you write queries, allowing you to pass through query structures to AWS SDK - so you can do pretty much anything the SDK can do.

Please make sure you check out the AWS DynamoDB SDK docs here: http://docs.aws.amazon.com/sdkforruby/api/

## Installation

Add this line to your application's Gemfile:

    gem 'guvera-dynamodb'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install guvera-dynamodb

## Usage

### Class Definition

```ruby
require 'guvera/dynamoid'
class Document < Guvera::Dynamodb::Model
  table_name "documents"
  field :doc_id
  field :version, :integer
  field :timestamp, :integer
  field :data, :hash
  field :body, :string

  key -> (entry) { { doc_id: entry.doc_id, version: entry.version } }

  before_create :generate_id # can be (before|after)_(create|destroy|save)

  table_scheme do
    {
      attribute_definitions: [
        { attribute_name: "doc_id", attribute_type: "S" },
        { attribute_name: "version", attribute_type: "N" }
      ],
      key_schema: [
        { attribute_name: "doc_id", key_type: "HASH" },
        { attribute_name: "version", key_type: "RANGE" }
      ]
    }
  end

  class << self

  end

  def generate_id
    doc_id = SomeAwesomeIdGenerator.generate
  end
end
```

### Basic CRUD

Fetching by hash, or hash and range is relatively simple:

```ruby
doc = Document.find_by_key doc_id: 'doc123', version: 2
doc.body = "Some body text"
doc.save

# Elsewhere, we may wish to reload from DynamoDB
doc.reload

# And finally, delete the document
doc.delete
```

### Querying

Say we wanted to find the latest version of a given document

```ruby
class Document
  class << self
    def find_latest_version_of_doc doc_id
      self.query({
        "doc_id" => {
          attribute_value_list: [ doc_id ],
          comparison_operator: "EQ"
        },
        "version" => {
          attribute_value_list: [ 0 ],
          comparison_operator: "GE",
        }
      }, {
        scan_index_forward: false,
        # Could add filter expressions here, for example
      })
    end
  end
end
```

This will return a Request object that will lazily fetch the results when response or some other response method is called on it.  This can be useful to, for example, implement pagination by adjusting the request before it's actually invoked.  

### Scanning

Scanning is much more expensive that querying as it doesnt operate in the hash/range keys or indices, but simply sequentially enumerates documents in the table.  There is a method 'scan' which works in much the same way as 'query', allowing you to pass arguments down to the AWS SDK.

### Counting

There is a convenience method 'count' that will execute a query but set the query type to COUNT so it doesn't attempt to return any documents.

```ruby
class Document
  class << self
    def count_versions_for_doc doc_id
      self.count({
        "doc_id" => {
          attribute_value_list: [ doc_id ],
          comparison_operator: "EQ"
        },
        "version" => {
          attribute_value_list: [ 0 ],
          comparison_operator: "GE",
        }
      })
    end
  end
end
```

## Contributing

1. Fork it ( https://github.com/[my-github-username]/guvera-dynamodb/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
