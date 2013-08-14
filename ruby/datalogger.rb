require File.dirname(__FILE__) + '/models'
require File.dirname(__FILE__) + '/serialcomms'
require 'time'
Datastore.connect!

begin
  tty = ActiveTty.first
  communicator = Serial::Communicator.new(tty.device)

  temperature = communicator.get_temperature
  temperature.save
rescue => e
  File.open("#{Dir.home}/logs/datalogger_error.log", "ab") do |file|
    log_time = Time.now.strftime("[%Y-%m-%d %H:%M:%S]")
    file.puts "#{log_time} #{e.message}"
  end
end