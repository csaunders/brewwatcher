require 'serialport'
require 'sqlite3'

class Temperature
  def initialize(tempstring)
    @temp = tempstring
  end
end

class Communicator
  BAUD_RATE = 9600
  DATA_BITS = 8
  STOP_BITS = 1
  attr_reader :serial
  def initialize(tty_name)
    @serial = SerialPort.new(tty_name, BAUD_RATE, DATA_BITS, STOP_BITS)
  end

  def send_message(message)
    serial.puts(message)
  end

  def read_message
    msg = ""
    while true do
      contents = serial.gets
      msg += contents if contents
      break if contents == nil && msg.length > 0
    end
    msg
  end

  def get_temperature
    send_message("timestamp temp")
    Temperature.new(read_message)
  end

end

class DataLogger
  def initialize(database_path, schema_file=nil)
    @db = SQLite3::Database.new database_path
    @db.execute(File.read(schema)) if schema
  end

  def save(temperature)
    insert =<<SQL
  INSERT INTO temperatures (logged_at, temperature)
  VALUES (?, ?)
SQL
    @db.execute(insert, temperature.at, temperature.value)
  end
end