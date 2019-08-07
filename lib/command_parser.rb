require "optparse"
require "forwardable"

class CommandParser
  extend Forwardable

  PAGES_PER_SIGNATURE = 16

  def_delegator :parser, :to_s

  attr_reader :error, :pages_per_signature

  def initialize(current_file, args)
    @current_file        = current_file
    @args                = args
    @positional_args     = []
    @pages_per_signature = PAGES_PER_SIGNATURE
    @error               = nil
  end

  def source
    @source ||= @positional_args[0]
  end

  def dest
    @dest ||= @positional_args[1]
  end

  def parse
    @parsed ||= begin
      parser.order!(@args) {|v| @positional_args << v }
      parser.parse!(@args)

      validate
    rescue *parser_exceptions => e
      @error = e.message
      false
    end
  end

  private

  def validate
    if source.to_s.length <= 0
      @error = "please supply a source filename"
      return false
    end

    if dest.to_s.length <= 0
      @error = "please supply a destination filename"
      return false
    end

    if (pages_per_signature % 8) != 0
      @error = "pages per signature must be divisible by 8"
      return false
    end

    true
  end

  def parser_exceptions
    [OptionParser::MissingArgument, OptionParser::InvalidOption]
  end

  def banner
    "Usage: #{File.basename(@current_file)} SOURCE DEST [-p PAGES]"
  end

  def parser
    @parser ||= OptionParser.new do |opts|
      opts.banner = banner

      opts.separator   ""
      opts.base.append "", [], [] # Add empty line after help text

      opts.on(
        "-p PAGES",
        "--pages-per-signature PAGES",
        OptionParser::DecimalInteger,
        "Number of pages to use per signature, must be divisible by 8"
      ) do |value|
        @pages_per_signature = value
      end
    end
  end
end
