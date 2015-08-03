require "guvera/dynamodb/version"
require 'aws-sdk'
require 'logger'

module Guvera
  class Dynamodb
    class << self
      attr_accessor :logger
    end
  end
end

Guvera::Dynamodb.logger = Logger.new(STDOUT)

require "guvera/dynamodb/request"
require "guvera/dynamodb/response"
require "guvera/dynamodb/cursor"
require "guvera/dynamodb/batch_writer"
require "guvera/dynamodb/model"
