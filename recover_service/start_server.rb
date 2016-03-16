#!/bin/env ruby
require_relative 'galera_sequence_server'

STDOUT.sync = true

server = GaleraSequenceServer.new
server.start(true)
