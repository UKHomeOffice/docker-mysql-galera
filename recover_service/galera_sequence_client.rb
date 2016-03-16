require_relative 'galera_sequence_server'
require 'net/http'
require 'uri'

class GaleraSequenceClient

  attr_accessor :master,
                :server_port,
                :servers

  LOG_PREFIX = 'INIT, GaleraSequenceClient:'
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

  def log(message)
    puts "#{LOG_PREFIX}#{message}"
  end

  def wait_for_master(local_server)

    @servers.each do | service_name |
      # Dirty hack around Kubernetes 1.1 service to this pod not working!
      if local_server.host_name.include?(service_name)
        service_name = 'localhost'
      end
      host, seq_no = get_sequence_no(service_name)
      @sequence_nos_by_host[host] = seq_no
    end

    latest_sequence_no = @sequence_nos_by_host.values.sort.last
    log "Latest UNIQUE sequence number detected:#{latest_sequence_no}"
    if local_server.my_seq_no == latest_sequence_no
      if @sequence_nos_by_host.values.select { | num | num == latest_sequence_no }.length > 1
        log 'More than one host with latest sequence number...'
        # Decide if master based on sorted list of hosts
        master_host = get_hosts_with_sequence_no(server.my_seq_no).sort.last
        if master_host == local_server.host_name
          # We should be master!!!
          log 'Deterministically electing as master...'
          @master = true
        else
          log 'Deterministically NOT electing as master...'
        end
      else
        log 'This host has latest sequence number...'
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

  def get_sequence_no(host)
    url = "http://#{host}:#{@server_port}#{GaleraSequenceServer::LASTEST_URI}"
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Get.new(uri.request_uri)
    hostname = nil
    sequence_no = nil
    until sequence_no do
      begin
        log "Requesting #{url}..."
        response = http.request(request)
        case response.code.to_i
          when 200
            hostname, sequence_no = response.body.strip.split(':')
          else
            log "Error getting sequence number from #{host}:#{response.body} - #{response.code}"
            sleep 10
        end
      rescue Timeout::Error,
          Errno::EINVAL,
          Errno::ECONNRESET,
          Errno::ETIMEDOUT,
          EOFError,
          Net::HTTPBadResponse,
          Net::HTTPHeaderSyntaxError,
          Net::ProtocolError => e
        log "HTTP Error getting sequence number from #{host}:#{e.message}"
      end
    end
    [hostname, sequence_no]
  end
end
