module GemOnDemand
  module Utils
    class << self
      def sh(command, options = { })
        puts command
        result = `#{command}`
        if $?.success?
          result
        elsif options[:fail] == :allow
          false
        else
          raise "Command failed: #{result}"
        end
      end

      def ensure_directory(dir)
        FileUtils.mkdir_p(dir) unless File.directory?(dir)
      end

      def remove_directory(dir)
        FileUtils.rm_rf(dir) if File.exist?(dir)
      end

      # ERROR:  While executing gem ... (Gem::Security::Exception)
      # certificate /CN=michael/DC=grosser/DC=it not valid after 2014-02-03 18:13:11 UTC
      def remove_signing(gemspec)
        File.write(gemspec, File.read(gemspec).gsub(/.*\.(signing_key|cert_chain).*/, ""))
      end
    end
  end
end
