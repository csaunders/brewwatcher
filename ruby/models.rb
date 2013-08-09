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
    ActiveRecord::Base.send(:include, ActiveModel::ForbiddenAttributesProtection)
    ActiveRecord::Base.send(:include, ActiveModel::ForbiddenAttributesProtection)

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

  def activate!
    Brew.update_all("active = 0", ["id NOT IN (?)", id])
    self.active = true
    save!
  end

  def average_temp
    return nil if temperatures.count == 0
    temperatures.inject(0){|r, t| r += t.reading} / temperatures.count
  end
end

class ActiveTty < ActiveRecord::Base
  self.table_name = 'active_tty'
  def self.available_ttys
    ttys = Dir.entries('/dev').reject do |entry|
      true unless entry =~ /tty([A-Z]|\.)|cu([A-Z]|\.)/
    end
    ttys.map { |name| ActiveTty.new(name: name) }
  end

  def device
    "/dev/#{name}"
  end
end