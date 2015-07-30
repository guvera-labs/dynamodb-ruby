$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'guvera/dynamodb'
require 'socket'
require 'timeout'
require 'aws-sdk'

def is_port_open? ip, port
  begin
    Timeout::timeout(1) do
      begin
        s = TCPSocket.new ip, port
        s.close
        return true
      rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
        return false
      end
    end
  rescue Timeout::Error
  end

  return false
end

RSpec.configure do |c|
  c.before :suite do
    @child_pid = Process.fork do

      # Bug in dynamodb-local means it doesnt actual honor the input array
      ARGV=["-inMemory","-port", "30180"]
      Dynamodb::Local::Server.start(ARGV)
    end

    while !is_port_open? 'localhost', 30180
      sleep 1
    end

    Aws.config.update(
      region: 'us-east-1',
      dynamodb: {
        endpoint: 'http://localhost:30180',
        # api_verison: '2012-08-10',
      }
    )
  end

  c.after :suite do
    Process.kill "KILL", @child_pid
    Process.wait
  end
end
