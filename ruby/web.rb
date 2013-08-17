require 'sinatra/base'
require 'sinatra/content_for'
require 'json'
require 'padrino-helpers'
require File.dirname(__FILE__) + '/models'
require File.dirname(__FILE__) + '/serialcomms'

class Breadcrumb
  attr_reader :name, :path
  def initialize(name, path)
    @name = name
    @path = path
  end
end

class BreadcrumbBuilder
  def self.build_crumbs(path)
    slices = path.split('/').reject{|s| s.length == 0}
    current_path = []
    @crumbs = slices.map do |path|
      current_path << path
      name = path =~ /\d+/ ? Brew.find(path.to_i).name : path
      Breadcrumb.new(name, current_path.join('/'))
    end
    @crumbs.unshift(Breadcrumb.new('Home', '/'))
  end
end

class Web < Sinatra::Base
  helpers Sinatra::ContentFor
  register Padrino::Helpers
  set :public_folder, File.dirname(__FILE__) + '/public'
  set :views, File.dirname(__FILE__) + '/views'

  before do
    Datastore.connect!
    @breadcrumbs = BreadcrumbBuilder.build_crumbs(request.path_info)
    @active_tty = ActiveTty.last
  end

  get '/' do
    redirect to('/brews')
  end

  get '/brews' do
    @brews = Brew.all

    perform_render(model: @brews, view: :"brews_index")
  end

  get '/brews/new' do
    @brew = Brew.new
    erb :"new_brew"
  end

  post '/brews' do
    params = extract_params['brew']
    creation_params = params
    creation_params = params.merge(active: params['active']) unless params['active'].nil?
    new_brew = Brew.create(creation_params)

    perform_render(model: new_brew, redirect: "/brews/#{new_brew.id}")
  end

  get '/brews/:brew_id' do
    perform_render(model: brew, view: :"brew_show")
  end

  post '/brews/:brew_id/activate' do
    brew.activate!
    redirect "/brews/#{brew.id}"
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
    Thread.new do
      communicator.warmup
      communicator.enable_display
      communicator.done!
    end
    redirect '/brews'
  end

  get '/panel/disable' do
    Thread.new do
      communicator.warmup
      communicator.disable_display
      communicator.done!
    end
    redirect '/brews'
  end

  get '/tty' do
    if @active_tty
      erb :"tty_index"
    else
      redirect '/tty/configure'
    end
  end

  get '/tty/configure' do
    @active_tty = ActiveTty.new
    @ttys = ActiveTty.available_ttys
    erb :"configure_tty"
  end

  post '/tty' do
    @tty = ActiveTty.first_or_initialize
    @tty.update_attributes(name: params[:tty][:name])
    redirect '/tty'
  end

  get '/tty/test' do
    @active_tty = ActiveTty.first_or_initialize
    begin
      @communicator = Serial::Communicator.new(@active_tty.device)
      @communicator.warmup
      @communicator.done!
      @connected = {connection: true}
    rescue => e
      @connected = {connection: false}
    end
    perform_render view: :"tty_index"
  end

  post '/tty/test' do
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
    @communicator ||= Serial::Communicator.new(@active_tty.device)
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