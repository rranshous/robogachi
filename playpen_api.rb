# GOAL: manage robogachis running on docker swarm

require 'net/http'
require 'docker-swarm-api'
require_relative 'simpleagent'

set :name, 'playpen_api'
set :http_port, (ENV['HTTP_PORT'] || 80).to_i
set :state_root, ENV['STATE_DIR'] || './state'
set :swarm_connection_string, ENV['DOCKER_HOST']
set :image_name, ENV['IMAGE_NAME'] || 'rranshous/robogachi'
set :cluster_host, ENV['CLUSTER_HOST'] || 'localhost'

state_field :added_names, []
state_field :removed_names, []

def log msg
  STDOUT.print "#{msg}\n"
  STDOUT.flush
end

log "it's playpen time!"

action 'add_new' do |state, opts|
  log 'adding new'
  agent_name = generate_random_name
  log "agent name: #{agent_name}"
  container_name = agent_name
  replicas = 1
  log "swarm: #{swarm}"
  # TODO: mount volume from host
  service_def = {
    "Name"=>container_name,
    "TaskTemplate" =>
    {"ContainerSpec" =>
     {"Networks" => [],
      "Image" => Config.get(:image_name),
      "Args" => [agent_name],
      "Mounts" => [],
      "User" => "root"},
      "Env" => [],
      "Placement" => {},
      "RestartPolicy" => {"Condition"=>"on-failure",
                          "Delay"=>1,
                          "MaxAttempts"=>3}},
    "Mode"=>{"Replicated" => {"Replicas" => replicas}},
    "UpdateConfig" => {"Delay" => 2,
                       "Parallelism" => 2,
                       "FailureAction" => "pause"},
    "EndpointSpec"=>
     {"Ports" => [{"Protocol"=>"tcp",
                   "TargetPort" => 80}]},
  }
  log "creating service: #{service_def}"
  r = swarm.create_service(service_def)
  log "created service: #{r}"
  # TODO: block until service starts?
  state.added_names << agent_name
  { name: agent_name }
end

report 'status' do |state|
  log 'getting status'
  { robogachi_names: names(state) }
end

report 'status_of' do |state, opts|
  params = opts[:request].query
  name = params["name"]
  uri = URI(url_for(name))
  log "getting status of: #{uri.to_s}"
  Net::HTTP.start(uri.host, uri.port) do |http|
    JSON.parse(http.request_get('/action/status').read_body)
  end
end

action 'forward' do |state, opts|
  params = opts[:request].query
  name = params["name"]
  url = url_for(name)
  opts[:response]['Location'] = url.to_s
  { url: url }
end

def url_for name
  service = swarm.find_service_by_name(name)
  port = service.hash["Endpoint"]["Ports"].map do |port_def|
    port_def["PublishedPort"]
  end.first
  forward_url = "http://#{Config.get(:cluster_host)}:#{port}"
  forward_url
end

def swarm
  docker_host = 'unix:///var/run/docker.sock'
  @master_connection ||= Docker::Swarm::Connection.new(docker_host)
  Docker::Swarm::Swarm.find(@master_connection)
end

def names state
  state.added_names - state.removed_names
end

def generate_random_name
  @all_words ||= File.readlines('mechanical-engineering-words.txt').map(&:chomp)
  random_words = @all_words.sample(3)
  "robogachi-#{random_words.join('-')}"
end

log 'done loading'
