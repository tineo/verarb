def redirect_to_show_project(p = nil)
  p = @project if p.nil?
  
  return redirect_to(:controller => "projects", :action => "show", :id => p.uid, :type => p.type)
end


def max_in(a, b)
  # Returns the highest number of the two. Read the code.
  return (a > b ? a : b)
end


def get_igv_for(date)
  if date.nil?
    return 1.19
  elsif date <= Time.mktime(2011, 3, 1, 0, 0, 0)
    return 1.19
  else
    return 1.18
  end
end


class Numeric
  def to_words

    words = Array.new

    number = self.to_i

    if number.to_i == 0
     words << self.zero_string
    else

      number = number.to_s.rjust(33,'0')
      groups = number.scan(/.{3}/).reverse


      words << number_to_words(groups[0])

      (1..10).each do |number|
        if groups[number].to_i > 0
          case number
          when 1,3,5,7,9
            words << "mil"
          else
            words << (groups[number].to_i > 1 ? "#{self.quantities[number]}ones" : "#{self.quantities[number]}ón")
          end
          words << number_to_words(groups[number])
        end
      end

    end

    return "#{words.reverse.join(' ')}"
  end

  protected

  def and_string
    "y"
  end

  def zero_string
    "cero"
  end

  def units
    %w[ ~ uno dos tres cuatro cinco seis siete ocho nueve ]
  end

  def tens
    %w[ ~ diez veinte treinta cuarenta cincuenta sesenta setenta ochenta noventa ]
  end

  def hundreds
    %w[ cien ciento doscientos trescientos cuatrocientos quinientos seiscientos setecientos ochocientos novecientos ]
  end

  def teens
    %w[ diez once doce trece cartoce quince dieciseis diecisiete dieciocho diecinueve ]
  end

  def twenties
    %w[ veinte veintiun veintidos veintitres veinticuatro veinticinco veintiseis veintisiete veintiocho veintinueve ]
  end

  def quantities
    %w[ ~ ~ mill ~ bill ~ trill ~ cuatrill ~ quintill ~ ]
  end

  def number_to_words(number)

    hundreds = number[0,1].to_i
    tens = number[1,1].to_i
    units = number[2,1].to_i

    text = Array.new

    if hundreds > 0
      if hundreds == 1 && (tens + units == 0)
        text << self.hundreds[0]
      else
        text << self.hundreds[hundreds]
      end
    end

    if tens > 0
      case tens
        when 1
          text << (units == 0 ? self.tens[tens] : self.teens[units])
        when 2
          text << (units == 0 ? self.tens[tens] : self.twenties[units])
        else
          text << self.tens[tens]
      end
    end

    if units > 0
      if tens == 0
        text << self.units[units]
      elsif tens > 2
        text << "#{self.and_string} #{self.units[units]}"
      end
    end

    return text.join(' ')

  end
end


class Float
  def round2
    return (self * 100).round / 100.0
  end
  
  def round3
    return (self * 1000).round / 1000.0
  end
end


class String
  def pad(length, str = " ")
    self.strip.ljust(length, str)[0..(length -1)]
  end
  
  
  def factura_format(maxlength, maxlines)
  # Formats the text and truncates it according to the length specified
    # First, we divide it by lines
    lines = self.gsub("\r", "").split("\n")
    
    # Then, we split by the max length
    newlines = []
    
    lines.each do |l|
      if l.length > maxlength
        while l.size > 0 do
          newlines << l.slice!(0...maxlength)
        end
      else
        newlines << l
      end
    end
    
    newlines = newlines[0...maxlines] if newlines.size > maxlines
    
    # Iconv! We do this here because I'm not sure the length of an UTF-8
    # string will be calculated correctly via String#length before
    newlines.each_with_index do |l, i|
      newlines[i] = Iconv.iconv("UTF-8//IGNORE", "ISO-8859-1", l)
    end
    
    return newlines.join("\n")
  end
end


class Time
  def long_format
    return self.strftime("%d/%m/%Y %I:%M %p")
  end
  
  
  def short_format
    return self.strftime("%d/%m/%Y")
  end
  
  
  def self.today
    return self.now.beginning_of_day
  end
end


class Date
  def long_format
    return self.strftime("%d/%m/%Y %I:%M %p")
  end
  
  
  def short_format
    return self.strftime("%d/%m/%Y")
  end
end

