class Password < ActiveRecord::Base
  def self.read
    return YAML::load(File.open(PASSWORDS_PATH))
  end
  
  
  def self.write(p)
    f = File.open(PASSWORDS_PATH, "w")
    f.puts YAML::dump(p)
    f.close
  end
  
  
  def self.get(p, c)
    passwords = Password.read
    return passwords[p][c]
  end
  
end
