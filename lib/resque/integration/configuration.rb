# coding: utf-8

require 'yaml'
require 'ostruct'

require 'active_support/core_ext/hash/keys'
require 'active_support/core_ext/hash/deep_merge'

module Resque
  module Integration
    class Configuration
      # Worker entity
      class Worker < OpenStruct
        def initialize(queue, config)
          data = {:queue => queue}

          if config.is_a?(Hash)
            data.merge!(config.symbolize_keys)
          else
            data[:count] = config
          end

          super(data)
        end

        # Returns hash of ENV variables that should be associated with this worker
        def env
          env = {:QUEUE => queue}
          env[:JOBS_PER_FORK] = jobs_per_fork.to_s if jobs_per_fork
          env[:MINUTES_PER_FORK] = minutes_per_fork.to_s if minutes_per_fork

          env
        end
      end

      # Create configuration from given +paths+
      def initialize(*paths)
        @configuration = {}
        paths.each { |f| load f }
      end

      def redis
        @redis ||= OpenStruct.new :host => self['redis.host'] || 'localhost',
                                  :port => self['redis.port'] || 6379,
                                  :db => self['redis.db'] || 0,
                                  :thread_safe => self['redis.thread_safe'],
                                  :namespace => self['redis.namespace']
      end

      def workers
        @workers ||= (self[:workers] || {}).map { |k, v| Worker.new(k, v) }
      end

      def interval
        (self['resque.interval'] || 5).to_i
      end

      def verbosity
        (self['resque.verbosity'] || 0).to_i
      end

      def log_file
        self['resque.log_file']
      end

      # Returns environment variables that should be associated with this configuration
      def env
        env = {:INTERVAL => interval.to_s}

        env[:VERBOSE] = '1' if verbosity == 1
        env[:VVERBOSE] = '1' if verbosity == 2

        env
      end

      private
      def load(path)
        if File.exists?(path)
          config = YAML.load(File.read(path))

          @configuration.merge!(config)
        end
      end

      # get value from configuration
      def [](path)
        parts = path.to_s.split('.')
        result = @configuration

        parts.each do |k|
          result = result[k]

          break if result.nil?
        end

        result
      end
    end # class Configuration
  end # module Integration
end # module Resque