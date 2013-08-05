require 'active_record'
require 'sqlite3'
require 'time'

module Datastore
  COMMAND = "--execcmd"
  def self.connect!
    ActiveRecord::Base.establish_connection(
      adapter: 'sqlite3',
      database: 'db/db.sqlite'
    )
    ActiveRecord::Base.include_root_in_json = false

    parse_to_commands(File.read('db/schema.sql')).each do |cmd|
      ActiveRecord::Base.connection.execute cmd
    end
  end

  def self.parse_to_commands(schema)
    schema.split COMMAND
  end
end

class Temperature < ActiveRecord::Base
  SEPARATOR = "|"
  belongs_to :brew

  def self.parse(message, brew = nil)
    brew ||= Brew.active_brew
    date, reading, *rest = message.split(SEPARATOR)
    brew.temperatures.new(logged_at: DateTime.parse(date), reading: reading.to_f)
  end
end

class Brew < ActiveRecord::Base
  has_many :temperatures

  def self.active_brew
    Brew.where(active: true).first
  end

  def average_temp
    temperatures.inject(0){|r, t| r += t.reading} / temperatures.count
  end

end