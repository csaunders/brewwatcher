require 'sinatra/base'
require 'sinatra/content_for'
require 'json'
require File.dirname(__FILE__) + '/models'
require File.dirname(__FILE__) + '/serialcomms'

class Web < Sinatra::Base
  helpers Sinatra::ContentFor
  set :public_folder, File.dirname(__FILE__) + '/public'
  set :views, File.dirname(__FILE__) + '/views'

  before do
    Datastore.connect!
  end

  get '/' do
    redirect to('/brews')
  end

  get '/brews' do
    @brews = Brew.all

    perform_render(model: @brews, view: :"brews_index")
  end

  post '/brews' do
    params = extract_params
    creation_params = {name: params['name']}
    creation_params = creation_params.merge(active: params['active']) unless params['active'].nil?
    new_brew = Brew.create(creation_params)

    perform_render(model: new_brew, redirect: "/brews/#{new_brew.id}")
  end

  get '/brews/:brew_id' do
    perform_render(model: brew, view: :"brew_show")
  end

  get '/brews/:brew_id/temperatures' do
    brew.temperatures.each{ |t| puts t.logged_at.inspect }
    @temperatures = brew.temperatures
    perform_render(model: @temperatures, view: :"temperature_index")
  end

  post '/brews/:brew_id/temperatures' do
    params = extract_params
    temperature = brew.temperatures.create(reading: params['reading'], logged_at: params['logged'])
    path = "/brews/#{params[:brew_id]}/temperatures/#{temperature.id}"
    perform_render(model: temperature, redirect: path)
  end

  get '/panel/enable' do
    communicator.enable_display
    redirect '/brews'
  end

  get '/panel/disable' do
    communicator.disable_display
    redirect '/brews'
  end

  private

  def perform_render(options)
    if json?
      options.fetch(:model, {}).to_json
    elsif options[:redirect]
      redirect options[:redirect]
    else
      erb options[:view]
    end
  end

  def communicator
    @communicator ||= Serial::Communicator.new('/dev/tty.usbmodem1431')
  end

  def json?
    request.env['CONTENT_TYPE'] == 'application/json'
  end

  def extract_params
    if json?
      request.body.rewind
      JSON.parse(request.body.read)
    else
      params
    end
  end

  def brew
    @brew ||= Brew.where(:id => params[:brew_id]).first
  end
end