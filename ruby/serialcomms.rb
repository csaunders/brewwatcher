require 'serialport'
require 'io/wait'
require File.dirname(__FILE__) + '/models'
Datastore.connect!

module Serial
  class ResponseQueue
    def initialize(serial)
      @serial = serial
      @queue = []
      @mutex = Mutex.new
      @processing = true
      @reader = Thread.new do
        while @processing
          message = @serial.gets.chop
          puts message.inspect
          enqueue(message)
        end
      end
    end

    def read_message
      puts "[read message] -- waiting for mutex"
      @mutex.synchronize do
        message = @queue.shift
      end
    end

    def enqueue(message)
      puts "[enqueue] -- wating for mutex"
      @mutex.synchronize do
        @queue << message
      end
    end

    def stop!
      @mutex.synchronize do
        @processing = false
      end
    end
  end

  class Communicator
    BAUD_RATE = 9600
    DATA_BITS = 8
    STOP_BITS = 1
    attr_reader :serial, :queue
    def initialize(tty_name)
      @serial = SerialPort.new(tty_name, BAUD_RATE, DATA_BITS, STOP_BITS)
    end

    def send_message(message)
      serial.puts(message)
    end

    def warmup
      puts "Sleeping while the connection gets ready"
      sleep(3)
      puts "Serial connection should be good now"
    end

    def read_message(pattern = nil)
      while true do
        message = serial.gets
        puts message
        break if pattern.nil? || message =~ pattern
        break unless serial.ready?
      end
      message
    end

    def get_temperature
      send_message("timestamp temp")
      Temperature.parse(read_message(/\|/))
    end

    def enable_display
      send_message("enable display")
    end

    def disable_display
      send_message("disable display")
    end

    def done!
      @serial.close
    end
  end
end