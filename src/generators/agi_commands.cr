module Asterisk
  module Generator
    class AGICommand
      struct Docs
        property command     : String
        property method      : String
        property syntax      : String
        property description : String
        property summary     : String # Synopsis
        property runs_dead   : Bool?
        property see_also    : String
        property method_def  : String

        def initialize(@command = "", @method = "", @syntax = "", @description = "", @summary = "", @runs_dead = nil, @see_also = "", @method_def = "")
        end
      end

      getter agi_commands = Hash(String, Docs).new

      def initialize
        summary
      end

      # Generates summary of known asterisk AGI commands. Asterisk PBX should be
      # installed in the same host and available from command-line; check it
      # with following command
      # ```bash
      # asterisk -rx "agi show commands"
      # ```
      def summary
        agi_commands_list = `asterisk -rx "agi show commands"`.chomp.split("\n")
        agi_commands_list.each do |agi_command|
          runs_dead, command, summary = agi_command.strip.split(/  +/)

          next if runs_dead =~ /Dead/i
          runs_dead = if runs_dead =~ /Yes/i
                        true
                      elsif runs_dead =~ /No/i
                        false
                      else
                        nil
                      end

          # replace space for some commands, like: "set extension" => "set_extension"
          # see also:
          # ```bash
          # agi show commands topic set extension
          # ```
          method = command.gsub(" ", "_")

          @agi_commands[method] = Docs.new command:   command,
                                           method:    method,
                                           summary:   summary,
                                           runs_dead: runs_dead
        end
      end

      def build_method(agi_command)
        agi_command = agi_commands[agi_command]
        sections = `asterisk -rx "agi show commands topic #{agi_command.command}"`.chomp
          .gsub(/\e\[\d;\d+m|\e\[0m/, "")
          .gsub("\n  -= Info about agi '#{agi_command.command}' =- \n\n", "")
          .chomp.split("\n\n")

        sections.each do |section|
          section = section.split("\n")
          header = section.shift.gsub(/\[|\]/, "")
          body = if header =~ /Description/i
                  section.join("\n")
                else
                  section.join(" ").gsub("  ", " ").strip
                end

          next if header =~ /Runs Dead|Synopsis/i

          if header =~ /Syntax/i
            agi_command.syntax = body.strip

            method_def = "#{agi_command.method}("
            args = ""
            vars = body.scan /(\[?<[a-z0-9\s_-]+>\]?)/
            vars.each do |var|
              klass = if var[1] =~ /\[<[a-z0-9\s_-]+>\]/
                        "String? = nil"
                      else
                        "String"
                      end
              var[1] =~ /\[?<([a-z0-9\s_-]+)>\]?/
              varname = $1.to_s.gsub(/\s|\-/, "_")
              varname = "moh_class" if varname == "class" && agi_command.method == "set_music"
              method_def += "#{varname} : #{klass}, "
              args += "\#{#{varname}} "
            end
            method_def += ")"
            method_def = method_def.gsub(", )", ")")
            method_def = method_def.gsub("()", "")
            args = args.gsub(/\s$/, "")
            method_def = if args.empty?
                          <<-METHOD_DEF
                          def #{method_def}
                            execute "#{agi_command.command.upcase}"
                          end
                          METHOD_DEF
                        else
                          <<-METHOD_DEF
                          def #{method_def}
                            command_str = "#{args}".gsub(/\\s+/, " ")
                            execute "#{agi_command.command.upcase} \#{command_str}"
                          end
                          METHOD_DEF
                        end
            agi_command.method_def = method_def
          end

          if header =~ /Description/i
            agi_command.description = body
          end

          if header =~ /See Also/i
            see_also = body.gsub(/,?\s?(?:AGI|GoSub)\(\)/i, "").strip
            if see_also.empty?
              agi_command.see_also = ""
            else
              see_also = see_also.split(", ").map { |reference| %(`##{reference.gsub(" ", "_")}`) }.join(", ")
              agi_command.see_also = see_also
            end
          end
        end

        result = <<-END
                # **Synopsis:**
                # #{agi_command.summary}
                #
                # **Description:**
                #{agi_command.description.gsub(/^/m, "# ")}
                #
                # **Runs on dead channel?**
                # #{agi_command.runs_dead ? "Yes" : "No"}
                #
                # **Syntax:**
                # #{agi_command.syntax}
                END
        unless agi_command.see_also.empty?
          result += "\n#\n# **See also:**\n# #{agi_command.see_also}"
        end
        result += "\n"
        result += agi_command.method_def
        result += "\n"
        result = result.gsub(/^/m, "    ")
        result
      end

      def generate!(command : String? = nil)
        if command.nil?
          klass = <<-END_OF_HEADER
                  #------------------------------------------------------------------------------
                  #
                  #  WARNING !
                  #
                  #  This is a generated file. DO NOT EDIT THIS FILE! Your changes will
                  #  be lost the next time this file is regenerated.
                  #
                  #  This file was generated using ctiapps/asterisk crystal shard from the
                  #  Asterisk PBX version #{`asterisk -rx "core show version"`.split[1]}.
                  #
                  #------------------------------------------------------------------------------

                  module Asterisk
                    class AGI
                  END_OF_HEADER
          last = agi_commands.keys.last
          agi_commands.each do |k, _|
            klass += %(#{build_method(k)}#{k != last ? "\n\n" : ""})
          end
          klass += "\n  end\nend"
          klass
        else
          klass = "module Asterisk\n  class AGI\n"
          klass += build_method(command)
          klass += "\n  end\nend"
          klass
        end
      end
    end
  end
end
