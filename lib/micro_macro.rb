class Micro_Macro
  class Immutable_Expansion < String
    #
    # Are you wondering what this class is about?  It is used for 
    # the macro definition defined on the CLI.  These definitions take
    # precedence on any definition found in the expanded file.  In order
    # to mark said definitions are "immutable", we will store them as
    # Immutable_Expansion and not as String.
    #
  end

  def initialize(options = Hash.new)
    default_options = {:open         => '%{',
                       :close        => '}%',
                       :comment      => '--',
                       :on_undefined => "" }

    default_options.keys.each do |key|
      unless options.has_key?(key)
        options[key] = default_options[key]
      end
    end

    @options=options
  end

  def expand(input, output, macros={})    
    missing = Hash.new

    if input.is_a?(String)
      input = [ input ];
    end
    
    input.each do
      |line|

      loop do
        pre, command, post = extract_command(line)

        break if command.nil?

        replacement = execute_command(command, macros, missing)

        line = pre + replacement + post
      end

      output << line
    end

    return missing.keys
  end


  private
  
  def find_delimiter(line, from)
    beyond_end = line.size

    open_position  = (line.find(options[:open]))  || beyond_end
    close_position = (line.find(options[:close])) || beyond_end

    if open_position < close_position
      return [:open, open_position]
      
    elsif close_position < open_position
      return [:close, close_position]

    else
      #
      #  If I'm herea open_position == close_position and this
      #  happens if and only if they are both beyond_end
      #

      return [nil, beyond_end]
    end

  end

  def extract_command(line)
    
    delimiter, position = find_delimiter(line, 0)

    case delimiter
    when nil
      return [line, nil, nil]

    when :close
      raise "XXXX Unmatched close"

    when :open
      # nothing to do

    else
      raise "I should never arrive here"
    end

    depth=1

    first = position + @options[:open].size
    last  = nil
    
    cursor = first

    while depth > 0
      delimiter, position = find_delimiter(line, cursor)

      case delimiter
      when nil 
        raise "XXXX"

      when :open
        depth += 1
        cursor = position + @options[:open].size

      when :close
        depth -= 1
        cursor = position + @options[:close].size

        if depth==0
          last=position-1
        end        
      else
        raise "I should never arrive here"
        
      end
    end

    return [
      line[0..first-@options[:open].size-1],
      line[first..last],
      line[last+@options[:close].size+1..-1]
    ]
  end

  def execute_command(command, macros, missing)
    return "" if command[0...@options[:comment].size] == @options[:comment]
    
    name, val=command.split('=', 2)

    if val.nil?
      if macros.has_key?(command)
        return macros[command]

      else
        case @options[:on_undefined]
        when String
          missing[command]=true
          return @options[:on_undefined]

        when :die
          raise "Macro '#{command}' undefined"

        else
          raise "I shouldn't be here"
          
        end

      end
    else
      unless macros[name].is_a?(Immutable_Expansion)
        macros[name]=val
      end

      return ""
    end
  end


  def Micro_Macro.no_override(s)
    Immutable_Expansion.new(s)
  end

  def Micro_Macro.prefill_from_cli(macros=nil, argv=ARGV)
    macros = Hash.new if macros.nil?

    argv.each do |arg|
      name, val=arg.split('=', 2)

      next if val.nil?

      macros[name]=Micro_Macro.no_override(val)
    end

    return macros
  end

end
