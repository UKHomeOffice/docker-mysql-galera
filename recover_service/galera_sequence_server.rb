require 'webrick'
require 'socket'

class GaleraSequenceServer

  # Server to read the state file or the output of wsrep-recover and respond with latest sequence number...
  # See http://galeracluster.com/documentation-webpages/restartingcluster.html

  GRASTATE_FILE = '/var/lib/mysql/grastate.dat'
  REGEXP_SEQNO = '^seqno:\s+([-]\d+)$'
  REGEXP_AUDIT_SEQNO = 'Recovered position:\s+.*:(\d+)$'
  GET_STATE_CMD = 'mysqld --wsrep-recover 2>&1'
  LASTEST_URI = '/latest'

  attr_accessor :is_master,
                :my_seq_no,
                :server,
                :server_thread

  def initialize(port)
    server = WEBrick::HTTPServer.new :Port => port, :BindAddress => '0.0.0.0'

    seq_no = -1
    if File.exists?('/var/lib/mysql/grastate.dat')
      gra_data = File.read(GRASTATE_FILE)
      case gra_data
        when /#{REGEXP_SEQNO}$/m
          seq_no = $1.to_i
        else
      end
    end
    if seq_no == -1
      audit_stdout = `#{GET_STATE_CMD} `
      case audit_stdout
        when /#{REGEXP_AUDIT_SEQNO}/m
          seq_no = $1.to_i
        else
      end
    end

    @my_seq_no = seq_no
    server.mount_proc LASTEST_URI do |req, res|
      res.body = "#{host_name}:#{seq_no.to_s}"
    end

    @server = server
  end

  def host_name
    Socket.gethostname
  end

  def start
    @server_thread = Thread.new {server.start}
  end
end
