require 'serialport'
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
          enqueue(@serial.gets.chomp)
        end
      end
    end

    def read_message
      @mutex.synchronize do
        @queue.shift
      end
    end

    def enqueue(message)
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
      @queue = ResponseQueue.new(@serial)
    end

    def send_message(message)
      serial.puts(message)
    end

    def read_message(pattern = nil)
      while true do
        message = @queue.read_message
        break if pattern.nil? || message =~ pattern
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
      @queue.stop!
    end
  end
end