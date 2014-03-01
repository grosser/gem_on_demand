require 'optparse'
require 'gem_on_demand/version'
require 'gem_on_demand/server'

module GemOnDemand
  class CLI
    class << self
      def run(argv)
        options = parse_options(argv)
        GemOnDemand::Server.run!(options)
      end

      private

      def parse_options(argv)
        options = {}
        parser = OptionParser.new do |opts|
          opts.banner = <<-BANNER.gsub(/^ {12}/, "")
            Run your own gem server that fetches from github, uses tags as version and builds gems on demand

            Usage:
                gem-on-demand --server

            Options:
          BANNER
          opts.on("-s", "--server", "Start server") { options[:server] = true }
          opts.on("-p", "--port PORT", Integer, "Port for server (default #{GemOnDemand::Server.port})") { |port| options[:port] = port }
          opts.on("-h", "--help", "Show this.") { puts opts; exit }
          opts.on("-v", "--version", "Show Version"){ puts GemOnDemand::VERSION; exit}
        end
        parser.parse!(argv)

        # force server for now ...
        unless options.delete(:server)
          puts parser
          exit 1
        end

        options
      end
    end
  end
end
