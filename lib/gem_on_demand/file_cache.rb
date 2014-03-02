module GemOnDemand
  class FileCache
    def initialize(dir)
      @dir = dir
    end

    def write(file, value)
      Utils.ensure_directory(@dir)
      file = "#{@dir}/#{file}"
      File.write(file, Marshal.dump(value))
      value
    end

    def read(file)
      file = "#{@dir}/#{file}"
      Marshal.load(File.read(file)) if File.exist?(file)
    end

    def delete(file)
      file = "#{@dir}/#{file}"
      File.unlink(file) if File.exist?(file)
    end

    def fetch(file, &block)
      read(file) || write(file, yield)
    end
  end
end
