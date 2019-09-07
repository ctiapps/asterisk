module Asterisk
  class AGI
    module Commands
      # Extends syntax of the `exec` command
      #
      # **Examples:**
      #
      # Asterisk native AGI command synbtax:
      # ```
      # exec "Dial", "SIP/200,30,tT"
      # ```
      #
      # Command options as an array:
      # ```
      # exec "Dial", "SIP/200", "30", "tT"
      # ```
      #
      # Options as named tuple or hash:
      # NOTE: key name in such cas it not important; basically following
      # implementation of `exec` just make it user-friendly. What is important is
      # the order of options, they should follow syntax of the calling Asterisk
      # command.
      # ```
      # exec "Dial", {destination: "SIP/200", duration: 30, options: "tT"}
      # exec "Dial", {destination => "SIP/200", duration => 30, options => "tT"}
      # ```
      def exec(application : String, options : Array(String | Int64 | Float64))
        exec application, options.join(parameters_delimiter)
      end

      def exec(application : String, **options)
        exec application, options.values.join(parameters_delimiter)
      end

      def exec(application : String, options : Hash(String, String | Int64 | Float64))
        exec application, options.values.join(parameters_delimiter)
      end
    end
  end
end
