require 'optparse'
require 'gem_on_demand/version'
require 'gem_on_demand/server'

module GemOnDemand
  class CLI
    class << self
      def run(argv)
        parse_options(argv)
        GemOnDemand::Server.run!
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
          opts.on("-h", "--help", "Show this.") { puts opts; exit }
          opts.on("-v", "--version", "Show Version"){ puts GemOnDemand::VERSION; exit}
        end
        parser.parse!(argv)

        # force server for now ...
        unless options[:server]
          puts parser
          exit 1
        end

        options
      end
    end
  end
end
