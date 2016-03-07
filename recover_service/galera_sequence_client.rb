require_relative 'galera_sequence_server'
require 'net/http'
require 'uri'

class GaleraSequenceClient

  attr_accessor :master,
                :server_port,
                :servers

  def initialize(servers, port)

    unless servers.class == Array
      raise 'Invalid client IPs - expecting IP'
    end
    @sequence_nos_by_host = {}
    @master = false
    @server_port = port
    @servers = servers
  end

  def is_master?
    @master
  end

  def wait_for_master(local_server)

    @servers.each do | server |
      host, seq_no = get_sequence_no(server)
      @sequence_nos_by_host[host] = seq_no
    end

    latest_sequence_no = @sequence_nos_by_host.values.sort.last
    puts "Latest UNIQUE sequence number detected:#{latest_sequence_no}"
    if local_server.my_seq_no == latest_sequence_no
      if @sequence_nos_by_host.values.select { | num | num == latest_sequence_no }.length > 1
        puts 'More than one host with latest sequence number...'
        # Decide if master based on sorted list of hosts
        master_host = get_hosts_with_sequence_no(server.my_seq_no).sort.last
        if master_host == local_server.host_key
          # We should be master!!!
          puts 'Deterministically electing as master...'
          @master = true
        else
          puts 'Deterministically NOT electing as master...'
        end
      else
        puts 'This host has latest sequence number...'
        @master = true
      end
    end
  end

  def get_hosts_with_sequence_no(seq_no)
    hosts = []
    @sequence_nos_by_host.each do | hostname, a_seq_no |
      if seq_no == a_seq_no
        hosts << hostname
      end
    end
    hosts
  end

  def get_sequence_no(server)
    uri = URI.parse("http://#{server}:#{@server_port}#{GaleraSequenceServer::LASTEST_URI}")
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(request)

    hostname = nil
    sequence_no = nil
    until sequence_no do
      case response.code.to_i
        when 200
          hostname, sequence_no = response.body.strip.split(':')
        else
          puts "Error getting sequence number from #{server}:#{response.body} - #{response.code}"
          sleep 10
      end
    end
    [hostname, sequence_no]
  end
end
