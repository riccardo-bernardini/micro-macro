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

  class Black_Hole
    #
    # Used as default container of undefined macros.  It defines
    # only the append method << that just does nothing.  A kind of
    # /dev/null
    #
    def <<(x)
    end
  end

  
  def Micro_Macro.no_override(s)
    Immutable_Expansion.new(s)
  end

  def Micro_Macro.macros_from_array(input=ARGV, options = Hash.new)
    default_options = {:macros       => Hash.new,
                       :immutable    => true}

    default_options.keys.each do |key|
      unless options.has_key?(key)
        options[key] = default_options[key]
      end
    end

    
    macros = options[:macros]

    input.each do |arg|
      name, val=arg.split('=', 2)

      next if val.nil?

      if options[:immutable]
        macros[name]=Micro_Macro.no_override(val)
      else
        macros[name]=val
      end
    end

    return macros
  end

  def Micro_Macro.expand(input, options=Hash.new)
    wrapped_input = if input.is_a?(String)
                      [ input ]
                    else
                      input
                    end

    result = Array.new

    expander = Micro_Macro.new(options)

    expander.expand(wrapped_input, result)

    if input.is_a?(String)
      return result[0]
    else
      return result
    end
  end

  def initialize(options = Hash.new)
    default_options = {:open         => '%{',
                       :close        => '}%',
                       :comment      => '--',
                       :on_undefined => "" ,
                       :macros       => Hash.new}

    default_options.keys.each do |key|
      unless options.has_key?(key)
        options[key] = default_options[key]
      end
    end

    @options=options
    @basic_macros=options[:macros]
    @macros=nil
  end

  def expand(input, output, undefined_macros=Black_Hole.new)
    @macros=@basic_macros
    
    input.each do
      |line|

      loop do
        pre, command, post = extract_command(line)

        break if command.nil?

        replacement = execute_command(command, macros, undefined_macros)

        line = pre + replacement + post
      end

      output << line
    end
  end

  def consolidate
    @basic_macros=@macros
  end

  private
  
  def find_delimiter(line, from)
    beyond_end = line.size

    open_position  = (line.index(@options[:open]))  || beyond_end
    close_position = (line.index(@options[:close])) || beyond_end

    if open_position < close_position
      return [:open, open_position]
      
    elsif close_position < open_position
      return [:close, close_position]

    else
      #
      #  If I'm herea open_position == close_position and this
      #  happens if and only if they are both beyond_end
      #
      raise "This should not happen" unless open_position==beyond_end
      
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
          missing << command
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
end
