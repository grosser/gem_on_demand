module GemOnDemand
  class FileCache
    def initialize(dir)
      @dir = dir
    end

    def expire(key)
      key = "#{@dir}/#{key}"
      File.unlink(key) if File.exist?(key)
    end

    # read, write, fetch all in one method ... TODO split em up!
    def cache(file, value = nil, &block)
      Utils.ensure_directory(@dir)
      file = "#{@dir}/#{file}"
      if block
        if File.exist?(file)
          Marshal.load(File.read(file))
        else
          result = yield
          File.write(file, Marshal.dump(result))
          result
        end
      else
        if value.nil?
          Marshal.load(File.read(file)) if File.exist?(file)
        else
          File.write(file, Marshal.dump(value))
        end
      end
    end
  end
end
