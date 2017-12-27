# GOAL: manage robogachis running on docker swarm

require 'docker-swarm-api'
require_relative 'simpleagent'

set :name, 'playpen_api'
set :http_port, (ENV['HTTP_PORT'] || 80).to_i
set :state_root, ENV['STATE_DIR'] || './state'
set :swarm_connection_string, ENV['DOCKER_HOST']
set :image_name, ENV['IMAGE_NAME'] || 'rranshous/robogachi'

state_field :added_names, []
state_field :removed_names, []

action 'add_new' do |state, opts|
  agent_name = generate_random_name
  puts "agent name: #{agent_name}"
  container_name = agent_name
  docker_host = 'unix:///var/run/docker.sock'
  replicas = 1
  master_connection = Docker::Swarm::Connection.new(docker_host)
  swarm = Docker::Swarm::Swarm.find(master_connection)
  puts "swarm: #{swarm}"
  # TODO: mount volume from host
  service_def = {
    "Name"=>container_name,
    "TaskTemplate" =>
    {"ContainerSpec" =>
     {"Networks" => [], "Image" => Config.get(:image_name), "Command" => [agent_name], "Mounts" => [], "User" => "root"},
       "Env" => [],
       "Placement" => {},
       "RestartPolicy" => {"Condition"=>"on-failure", "Delay"=>1, "MaxAttempts"=>3}},
    "Mode"=>{"Replicated" => {"Replicas" => replicas}},
    "UpdateConfig" => {"Delay" => 2, "Parallelism" => 2, "FailureAction" => "pause"},
    "EndpointSpec"=>
     {"Ports" => [{"Protocol"=>"tcp", "TargetPort" => 80}]},
  }
  puts "creating service: #{service_def}"
  r = swarm.create_service(service_def)
  puts "created service: #{r}"
  # TODO: block until service starts?
  state.added_names << agent_name
  { name: agent_name }
end

report 'status' do |state|
  { robogachi_names: names }
end

report 'get_status' do |state, opts|
  # return the response from the robogachi /action/status
end

report 'get_about' do |state, opts|
  # return the repsonse from the robogachi /action/about
end

def names state
  state.added_names - state.removed_names
end

def generate_random_name
  @all_words ||= File.readlines('mechanical-engineering-words.txt').map(&:chomp)
  random_words = @all_words.sample(3)
  "robogachi-#{random_words.join('-')}"
end

puts "loaded"
