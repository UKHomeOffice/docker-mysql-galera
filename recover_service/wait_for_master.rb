require_relative 'galera_sequence_server'
require_relative 'galera_sequence_client'

PORT = 8888

server = GaleraSequenceServer.new(PORT)
server.start

# TODO: argument validation
# TODO: timeout?

servers = ARGV[0].split(',')
client = GaleraSequenceClient.new(servers, PORT)

client.wait_for_master(server)

if client.is_master?
  exit 5
else
  exit 0
end
