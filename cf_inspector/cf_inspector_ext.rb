require 'rubygems'
require 'nats/client'


#Common Utility
class InspectUtil
  class << self
    #get the component's name required from.
    def called_by?(component)
      caller.map do |c|
        c.include?(component)
      end.include?(true)
    end
  end
end

#Logger Definition
module InspectLogger
  INSPECT_LOGGER = Logger.new('/tmp/cf_inspector.log')
  INSPECT_LOGGER.formatter = proc { |severity, datetime, progname, msg|
    "#{msg}\n"
  }
  
  #log method for common
  def log(type, *args, &blk)
    log_with_caller(type, caller.dup, *args, &blk)
  end
  
  #log method for original caller
  def log_with_caller(type, caller_array, *args, &blk)
    logging_obj = {
      :node => get_node(caller_array),
      :type => type,
      :key => args[0],
      :detail => [
#          caller_array,
        args,
        blk.to_s
      ]
    }
    unless heartbeat?(logging_obj)  
      INSPECT_LOGGER.info(logging_obj.to_json)
    end 
  end
  
  #get component's name from the caller array.
  def get_node(caller_array)
    caller_array.each do |caller_path|
      %w(cloud_controller router dea health_manager services stager staging dev_setup vmc).each do |component_name|
        return component_name if caller_path.include?(component_name)
      end
    end
    return caller_array.join('/')
  end
  
  def heartbeat?(logging_obj)
     false
#    return %w(dea.heartbeat healthmanager.nats.ping).include?(logging_obj[:key]) 
  end
end


# NATS Extension
module NATS
  extend InspectLogger
  include InspectLogger
  class << self
    alias publish_original publish
    alias subscribe_original subscribe
    alias unsubscribe_original unsubscribe
    alias timeout_original timeout
    alias request_original request
    
    def publish(*args, &blk)
      log(:nats_publish, *args, &blk)
      publish_original(*args, &blk)
    end

    def subscribe(*args, &blk)
      log(:nats_subscribe, *args, &blk)
      subscribe_original(*args, &blk)
    end

    def unsubscribe(*args)
      log(:nats_unsubscribe, *args, &blk)
      unsubscribe_original(*args)
    end

    def timeout(*args, &blk)
      log(:nats_timeout, *args, &blk)
      timeout_original(*args, &blk)
    end

    def request(*args, &blk)
      log(:nats_request, *args, &blk)
      request_original(*args, &blk)
    end
    
  end
  
  alias subscribe_original subscribe
  
  def subscribe(subject, opts={}, &callback)
    caller_array = caller.dup
    loggable_callback = Proc.new do |msg, reply|
      log_with_caller(:nats_receive, caller_array, subject, msg, reply, &callback)
      callback.call(msg,reply)
    end
    subscribe_original(subject, opts, &loggable_callback)
  end
end

# cloud controller extension
if InspectUtil.called_by?("cloud_controller")
  require "action_controller/railtie"
  class ApplicationController < ActionController::Base
    include InspectLogger
    before_filter :write_sequence_log
    
    def write_sequence_log
      log(:http_receive, "#{params[:controller]}/#{params[:action]}", params)
    end
  end
end

# sqlite3 extension
begin
  require 'sqlite3'
  
  module SQLite3
    class Database
      include InspectLogger
      alias prepare_original prepare
      def prepare(sql, &blk)
        words = sql.split(" ")
        summary = if words.first == "SELECT"
          table_name = words[words.index("FROM") + 1].gsub('"', '')
          "SELECT #{table_name}"
        elsif words.first == "INSERT"
          table_name = words[words.index("INTO") + 1].gsub('"', '')
          "INSERT #{table_name}"
        elsif words.first == "UPDATE"
          table_name = words[1].gsub('"', '')
          "UPDATE #{table_name}"
        elsif words.first == "DELETE"
          table_name = words[words.index("FROM") + 1].gsub('"', '')
          "DELETE #{table_name}"
        else
          words.first
        end
        log(:sqlite, summary, sql)
        prepare_original(sql, &blk)
      end
    end
  end
rescue Exception
end

# service gateway extension
if InspectUtil.called_by?("services")
  require 'services/lib/base/base'
  class VCAP::Services::AsynchronousServiceGateway < Sinatra::Base
    include InspectLogger
    before do
      log(:http_receive, "#{request.script_name}/#{request.path_info}", params)
    end
  end
end

#rest client extension
begin
  require 'rest_client'
  
  module RestClient
    class Request
      class << self
        include InspectLogger
        alias execute_original execute
        
        def execute(args, & block)
          args_url = args[:url]
          log(:http_request, args_url, args)
          execute_original(args, &block)
        end
      end
    end
  end
rescue Exception
end

#vmc extension
if InspectUtil.called_by?("vmc")
  class VMC::Cli::Runner
    class << self
      include InspectLogger
      alias run_original run
      
      def run(args)
        log(:vmc_start, ARGV[0], ARGV)
        begin
          run_original(args)
        ensure
          log(:vmc_end, ARGV[0], ARGV)
        end
      end
    end
  end
end
