require 'sinatra'
require File.dirname(__FILE__) + '/models'

before do
  Datastore.connect!
end

get '/brews' do
  "Hello World"
end

post '/brews' do
  creation_params = {name: params[:name]}
  creation_params = creation_params.merge(active: params[:active]) unless params[:active].nil?
  new_brew = Brew.create(creation_params)
  [new_brew.id, new_brew.name]
end

get '/brews/:brew_id' do
  [brew.name, brew.temperatures.map(&:reading).to_s]
end

get '/brews/:brew_id/temperatures' do
  brew.temperatures.map {|t| [t.reading, t.logged_at]}
end

post '/brews/:brew_id/temperatures' do
  temperature = brew.temperatures.create(reading: params[:reading], logged_at: params[:logged])
  [temperature.id, temperature.reading]
end

private

def brew
  @brew ||= Brew.where(:id => params[:brew_id]).first
end

