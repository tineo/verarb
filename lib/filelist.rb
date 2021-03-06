class FileList
# This class' purpose is facilitate the use of attached File Lists in the
# case of Project, Product and Costs files.
# You create a List and it consists of entries of class FileListItem, which
# are made with the purpose of readability and ease of use in code.
# I just love Ruby for making things like this possible.

  include Enumerable
  
  def initialize(path)
    c = Dir.getwd
    
    # Create the dir, if it doesn't exist
    FileUtils.mkdir_p(path) unless File.exists?(path)
    
    Dir.chdir path
    
    # I want the full, absolute path
    path = Dir.pwd + '/'
    
    # Sort them! Recent ones down! (This is cool)
    list = Dir["*"].sort{|a,b| File.mtime(a) <=> File.mtime(b)}
    
    # Ok, now we build our items list
    @files = []
    
    list.each do |f|
      @files << FileListItem.new(path, f)
    end
    
    Dir.chdir c
    
    return true
  end
  
  
  def each
    @files.each do |i|
      yield i
    end
  end
  
  
  def [](i)
    return @files[i]
  end
  
  
  def empty?
    return @files.empty?
  end
  
  def size
    return @files.size
  end
end


class FileListItem
  def initialize(path, filename)
    @path     = path
    @filename = filename
    @full     = path + filename
  end
  
  
  def filename
    return @filename
  end
  
  
  def path
    return @path
  end
  
  
  def full_filename
    return @full
  end
  
  
  def real_filename
    return File.real_filename(@filename)
  end
  
  
  def date
    return File.mtime(@full)
  end
  
  
  def size
    return File.size(@full)
  end
  
  
  def extension
    return File.extname(@filename)
  end
end


class File
  def self.real_filename(f)
    return f.slice(11, (f.size - 11))
  end
end
