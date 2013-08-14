require File.dirname(__FILE__) + '/models'

tty = ActiveTty.first
communicator = Serial::Communicator.new(tty.device)

temperature = communicator.get_temperature
temperature.save