# GOAL: manage robogachis running on docker swarm

require 'docker-swarm-api'
require_relative 'simpleagent'

set :name, 'playpen_api'
set :http_port, (ENV['HTTP_PORT'] || 80).to_i
set :state_root, ENV['STATE_DIR'] || './state'
set :swarm_connection_string, ENV['DOCKER_HOST']

state_field :added_names, []
state_field :removed_names, []

# we are going to abuse report
action 'add_new' do |state, opts|
  name = generate_random_name
  master_connection = Docker::Swarm::Connection.new()
  # spin up a new instance of the docker imgage on the swarm
  state.added_names << name
  { name: name }
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
  @all_words ||= File.readlines('mechanical-engineering-words.txt')
  random_words = @all_words.sample(3)
  "robogachi-#{random_words.join('-')}"
end
