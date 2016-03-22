#!/bin/env ruby
require_relative 'galera_sequence_server'
require_relative 'galera_sequence_client'

# TODO: argument validation
# TODO: timeout?
# TODO: monitor server whilst starting...

STDOUT.sync = true

SCRIPT_DIR = File.expand_path(File.dirname(__FILE__))

pid = fork do
  exec("#{SCRIPT_DIR}/start_server.rb")
end
puts "Server started, pid:#{pid}"

servers = ARGV[0].split(',')
client = GaleraSequenceClient.new(servers, GaleraSequenceServer::PORT)

client.wait_for_master(GaleraSequenceServer.host_name)

if client.is_master?
  exit 5
else
  exit 0
end
