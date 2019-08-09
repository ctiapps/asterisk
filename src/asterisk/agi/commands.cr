module Asterisk
  class AGI
    # **Synopsis:**
    # Answer channel
    #
    # **Description:**
    # Answers channel if not already in answer state. Returns '-1' on channel
    # failure, or '0' if successful.
    #
    # **Runs on dead channel?**
    # No
    #
    # **Syntax of AGI command:**
    # answer 
    #
    # **See also:**
    # `#hangup`
    def answer
      execute "ANSWER"
    end


    # **Synopsis:**
    # Interrupts Async AGI
    #
    # **Description:**
    # Interrupts expected flow of Async AGI commands and returns control to previous
    # source (typically, the PBX dialplan).
    #
    # **Runs on dead channel?**
    # Yes
    #
    # **Syntax of AGI command:**
    # asyncagi break 
    #
    # **See also:**
    # `#hangup`
    def asyncagi_break
      execute "ASYNCAGI BREAK"
    end


    # **Synopsis:**
    # Returns status of the connected channel.
    #
    # **Description:**
    # Returns the status of the specified <channelname>. If no channel name is given
    # then returns the status of the current channel.
    # Return values:
    #     0 - Channel is down and available.
    #     1 - Channel is down, but reserved.
    #     2 - Channel is off hook.
    #     3 - Digits (or equivalent) have been dialed.
    #     4 - Line is ringing.
    #     5 - Remote end is ringing.
    #     6 - Line is up.
    #     7 - Line is busy.
    #
    # **Runs on dead channel?**
    # No
    #
    # **Syntax of AGI command:**
    # channel status [<channelname>] 
    def channel_status(channelname : String? = nil)
      command_str = "#{channelname}".gsub(/\s+/, " ")
      response = execute "CHANNEL STATUS #{command_str}"
    end


    # **Synopsis:**
    # Removes database key/value
    #
    # **Description:**
    # Deletes an entry in the Asterisk database for a given <family> and <key>.
    # Returns '1' if successful, '0' otherwise.
    #
    # **Runs on dead channel?**
    # Yes
    #
    # **Syntax of AGI command:**
    # database del <family> <key> 
    #
    # **See also:**
    # `#database_get`, `#database_put`, `#database_deltree`
    def database_del(family : String, key : String)
      command_str = "#{family} #{key}".gsub(/\s+/, " ")
      response = execute "DATABASE DEL #{command_str}"
    end


    # **Synopsis:**
    # Removes database keytree/value
    #
    # **Description:**
    # Deletes a <family> or specific <keytree> within a <family> in the Asterisk
    # database.
    # Returns '1' if successful, '0' otherwise.
    #
    # **Runs on dead channel?**
    # Yes
    #
    # **Syntax of AGI command:**
    # database deltree <family> [<keytree>] 
    #
    # **See also:**
    # `#database_get`, `#database_put`, `#database_del`
    def database_deltree(family : String, keytree : String? = nil)
      command_str = "#{family} #{keytree}".gsub(/\s+/, " ")
      response = execute "DATABASE DELTREE #{command_str}"
    end


    # **Synopsis:**
    # Gets database value
    #
    # **Description:**
    # Retrieves an entry in the Asterisk database for a given <family> and <key>.
    # Returns '0' if <key> is not set. Returns '1' if <key> is set and returns the
    # variable in parenthesis.
    # Example return code: 200 result=1 (testvariable)
    #
    # **Runs on dead channel?**
    # Yes
    #
    # **Syntax of AGI command:**
    # database get <family> <key> 
    #
    # **See also:**
    # `#database_put`, `#database_del`, `#database_deltree`
    def database_get(family : String, key : String)
      command_str = "#{family} #{key}".gsub(/\s+/, " ")
      response = execute "DATABASE GET #{command_str}"
    end


    # **Synopsis:**
    # Adds/updates database value
    #
    # **Description:**
    # Adds or updates an entry in the Asterisk database for a given <family>, <key>,
    # and <value>.
    # Returns '1' if successful, '0' otherwise.
    #
    # **Runs on dead channel?**
    # Yes
    #
    # **Syntax of AGI command:**
    # database put <family> <key> <value> 
    #
    # **See also:**
    # `#database_get`, `#database_del`, `#database_deltree`
    def database_put(family : String, key : String, value : String)
      command_str = "#{family} #{key} #{value}".gsub(/\s+/, " ")
      response = execute "DATABASE PUT #{command_str}"
    end


    # **Synopsis:**
    # Executes a given Application
    #
    # **Description:**
    # Executes <application> with given <options>.
    # Returns whatever the <application> returns, or '-2' on failure to find
    # <application>.
    #
    # **Runs on dead channel?**
    # Yes
    #
    # **Syntax of AGI command:**
    # exec <application> <options> 
    def exec(application : String, options : String)
      command_str = "#{application} #{options}".gsub(/\s+/, " ")
      response = execute "EXEC #{command_str}"
    end


    # **Synopsis:**
    # Prompts for DTMF on a channel
    #
    # **Description:**
    # Stream the given <file>, and receive DTMF data.
    # Returns the digits received from the channel at the other end.
    #
    # **Runs on dead channel?**
    # No
    #
    # **Syntax of AGI command:**
    # get data <file> [<timeout>] [<maxdigits>] 
    def get_data(file : String, timeout : String? = nil, maxdigits : String? = nil)
      command_str = "#{file} #{timeout} #{maxdigits}".gsub(/\s+/, " ")
      response = execute "GET DATA #{command_str}"
    end


    # **Synopsis:**
    # Evaluates a channel expression
    #
    # **Description:**
    # Returns '0' if <variablename> is not set or channel does not exist. Returns '1'
    # if <variablename> is set and returns the variable in parenthesis. Understands
    # complex variable names and builtin variables, unlike GET VARIABLE.
    # Example return code: 200 result=1 (testvariable)
    #
    # **Runs on dead channel?**
    # Yes
    #
    # **Syntax of AGI command:**
    # get full variable <variablename> [<channel name>] 
    #
    # **See also:**
    # `#get_variable`, `#set_variable`
    def get_full_variable(variablename : String, channel_name : String? = nil)
      command_str = "#{variablename} #{channel_name}".gsub(/\s+/, " ")
      response = execute "GET FULL VARIABLE #{command_str}"
    end


    # **Synopsis:**
    # Stream file, prompt for DTMF, with timeout.
    #
    # **Description:**
    # Behaves similar to STREAM FILE but used with a timeout option.
    #
    # **Runs on dead channel?**
    # No
    #
    # **Syntax of AGI command:**
    # get option <filename> <escape_digits> [<timeout>] 
    #
    # **See also:**
    # `#stream_file`, `#control_stream_file`
    def get_option(filename : String, escape_digits : String, timeout : String? = nil)
      command_str = "#{filename} #{escape_digits} #{timeout}".gsub(/\s+/, " ")
      response = execute "GET OPTION #{command_str}"
    end


    # **Synopsis:**
    # Gets a channel variable.
    #
    # **Description:**
    # Returns '0' if <variablename> is not set. Returns '1' if <variablename> is set
    # and returns the variable in parentheses.
    # Example return code: 200 result=1 (testvariable)
    #
    # **Runs on dead channel?**
    # Yes
    #
    # **Syntax of AGI command:**
    # get variable <variablename> 
    #
    # **See also:**
    # `#get_full_variable`, `#set_variable`
    def get_variable(variablename : String)
      command_str = "#{variablename}".gsub(/\s+/, " ")
      response = execute "GET VARIABLE #{command_str}"
    end


    # **Synopsis:**
    # Hangup a channel.
    #
    # **Description:**
    # Hangs up the specified channel. If no channel name is given, hangs up the
    # current channel
    #
    # **Runs on dead channel?**
    # No
    #
    # **Syntax of AGI command:**
    # hangup [<channelname>] 
    def hangup(channelname : String? = nil)
      command_str = "#{channelname}".gsub(/\s+/, " ")
      response = execute "HANGUP #{command_str}"
    end


    # **Synopsis:**
    # Does nothing.
    #
    # **Description:**
    # Does nothing.
    #
    # **Runs on dead channel?**
    # Yes
    #
    # **Syntax of AGI command:**
    # noop 
    def noop
      execute "NOOP"
    end


    # **Synopsis:**
    # Receives one character from channels supporting it.
    #
    # **Description:**
    # Receives a character of text on a channel. Most channels do not support the
    # reception of text. Returns the decimal value of the character if one is
    # received, or '0' if the channel does not support text reception. Returns '-1'
    # only on error/hangup.
    #
    # **Runs on dead channel?**
    # No
    #
    # **Syntax of AGI command:**
    # receive char <timeout> 
    #
    # **See also:**
    # `#receive_text`
    def receive_char(timeout : String)
      command_str = "#{timeout}".gsub(/\s+/, " ")
      response = execute "RECEIVE CHAR #{command_str}"
    end


    # **Synopsis:**
    # Receives text from channels supporting it.
    #
    # **Description:**
    # Receives a string of text on a channel. Most channels do not support the
    # reception of text. Returns '-1' for failure or '1' for success, and the string
    # in parenthesis.
    #
    # **Runs on dead channel?**
    # No
    #
    # **Syntax of AGI command:**
    # receive text <timeout> 
    #
    # **See also:**
    # `#receive_char`, `#send_text`
    def receive_text(timeout : String)
      command_str = "#{timeout}".gsub(/\s+/, " ")
      response = execute "RECEIVE TEXT #{command_str}"
    end


    # **Synopsis:**
    # Records to a given file.
    #
    # **Description:**
    # Record to a file until a given dtmf digit in the sequence is received. Returns
    # '-1' on hangup or error.  The format will specify what kind of file will be
    # recorded. The <timeout> is the maximum record time in milliseconds, or '-1' for
    # no <timeout>. <offset samples> is optional, and, if provided, will seek to the
    # offset without exceeding the end of the file. <beep> can take any value, and
    # causes Asterisk to play a beep to the channel that is about to be recorded.
    # <silence> is the number of seconds of silence allowed before the function
    # returns despite the lack of dtmf digits or reaching <timeout>. <silence> value
    # must be preceded by 's=' and is also optional.
    #
    # **Runs on dead channel?**
    # No
    #
    # **Syntax of AGI command:**
    # record file <filename> <format> <escape_digits> <timeout> [<offset_samples>] [<beep>] [<s=silence>] 
    def record_file(filename : String, format : String, escape_digits : String, timeout : String, offset_samples : String? = nil, beep : String? = nil)
      command_str = "#{filename} #{format} #{escape_digits} #{timeout} #{offset_samples} #{beep}".gsub(/\s+/, " ")
      response = execute "RECORD FILE #{command_str}"
    end


    # **Synopsis:**
    # Says a given character string.
    #
    # **Description:**
    # Say a given character string, returning early if any of the given DTMF digits
    # are received on the channel. Returns '0' if playback completes without a digit
    # being pressed, or the ASCII numerical value of the digit if one was pressed or
    # '-1' on error/hangup.
    #
    # **Runs on dead channel?**
    # No
    #
    # **Syntax of AGI command:**
    # say alpha <number> <escape_digits> 
    #
    # **See also:**
    # `#say_digits`, `#say_number`, `#say_phonetic`, `#say_date`, `#say_time`, `#say_datetime`
    def say_alpha(number : String, escape_digits : String)
      command_str = "#{number} #{escape_digits}".gsub(/\s+/, " ")
      response = execute "SAY ALPHA #{command_str}"
    end


    # **Synopsis:**
    # Says a given digit string.
    #
    # **Description:**
    # Say a given digit string, returning early if any of the given DTMF digits are
    # received on the channel. Returns '0' if playback completes without a digit
    # being pressed, or the ASCII numerical value of the digit if one was pressed or
    # '-1' on error/hangup.
    #
    # **Runs on dead channel?**
    # No
    #
    # **Syntax of AGI command:**
    # say digits <number> <escape_digits> 
    #
    # **See also:**
    # `#say_alpha`, `#say_number`, `#say_phonetic`, `#say_date`, `#say_time`, `#say_datetime`
    def say_digits(number : String, escape_digits : String)
      command_str = "#{number} #{escape_digits}".gsub(/\s+/, " ")
      response = execute "SAY DIGITS #{command_str}"
    end


    # **Synopsis:**
    # Says a given number.
    #
    # **Description:**
    # Say a given number, returning early if any of the given DTMF digits are
    # received on the channel.  Returns '0' if playback completes without a digit
    # being pressed, or the ASCII numerical value of the digit if one was pressed or
    # '-1' on error/hangup.
    #
    # **Runs on dead channel?**
    # No
    #
    # **Syntax of AGI command:**
    # say number <number> <escape_digits> [<gender>] 
    #
    # **See also:**
    # `#say_alpha`, `#say_digits`, `#say_phonetic`, `#say_date`, `#say_time`, `#say_datetime`
    def say_number(number : String, escape_digits : String, gender : String? = nil)
      command_str = "#{number} #{escape_digits} #{gender}".gsub(/\s+/, " ")
      response = execute "SAY NUMBER #{command_str}"
    end


    # **Synopsis:**
    # Says a given character string with phonetics.
    #
    # **Description:**
    # Say a given character string with phonetics, returning early if any of the
    # given DTMF digits are received on the channel. Returns '0' if playback
    # completes without a digit pressed, the ASCII numerical value of the digit if
    # one was pressed, or '-1' on error/hangup.
    #
    # **Runs on dead channel?**
    # No
    #
    # **Syntax of AGI command:**
    # say phonetic <string> <escape_digits> 
    #
    # **See also:**
    # `#say_alpha`, `#say_digits`, `#say_number`, `#say_date`, `#say_time`, `#say_datetime`
    def say_phonetic(string : String, escape_digits : String)
      command_str = "#{string} #{escape_digits}".gsub(/\s+/, " ")
      response = execute "SAY PHONETIC #{command_str}"
    end


    # **Synopsis:**
    # Says a given date.
    #
    # **Description:**
    # Say a given date, returning early if any of the given DTMF digits are received
    # on the channel. Returns '0' if playback completes without a digit being
    # pressed, or the ASCII numerical value of the digit if one was pressed or '-1'
    # on error/hangup.
    #
    # **Runs on dead channel?**
    # No
    #
    # **Syntax of AGI command:**
    # say date <date> <escape_digits> 
    #
    # **See also:**
    # `#say_alpha`, `#say_digits`, `#say_number`, `#say_phonetic`, `#say_time`, `#say_datetime`
    def say_date(date : String, escape_digits : String)
      command_str = "#{date} #{escape_digits}".gsub(/\s+/, " ")
      response = execute "SAY DATE #{command_str}"
    end


    # **Synopsis:**
    # Says a given time.
    #
    # **Description:**
    # Say a given time, returning early if any of the given DTMF digits are received
    # on the channel. Returns '0' if playback completes without a digit being
    # pressed, or the ASCII numerical value of the digit if one was pressed or '-1'
    # on error/hangup.
    #
    # **Runs on dead channel?**
    # No
    #
    # **Syntax of AGI command:**
    # say time <time> <escape_digits> 
    #
    # **See also:**
    # `#say_alpha`, `#say_digits`, `#say_number`, `#say_phonetic`, `#say_date`, `#say_datetime`
    def say_time(time : String, escape_digits : String)
      command_str = "#{time} #{escape_digits}".gsub(/\s+/, " ")
      response = execute "SAY TIME #{command_str}"
    end


    # **Synopsis:**
    # Says a given time as specified by the format given.
    #
    # **Description:**
    # Say a given time, returning early if any of the given DTMF digits are received
    # on the channel. Returns '0' if playback completes without a digit being
    # pressed, or the ASCII numerical value of the digit if one was pressed or '-1'
    # on error/hangup.
    #
    # **Runs on dead channel?**
    # No
    #
    # **Syntax of AGI command:**
    # say datetime <time> <escape_digits> [<format>] [<timezone>] 
    #
    # **See also:**
    # `#say_alpha`, `#say_digits`, `#say_number`, `#say_phonetic`, `#say_date`, `#say_time`
    def say_datetime(time : String, escape_digits : String, format : String? = nil, timezone : String? = nil)
      command_str = "#{time} #{escape_digits} #{format} #{timezone}".gsub(/\s+/, " ")
      response = execute "SAY DATETIME #{command_str}"
    end


    # **Synopsis:**
    # Sends images to channels supporting it.
    #
    # **Description:**
    # Sends the given image on a channel. Most channels do not support the
    # transmission of images. Returns '0' if image is sent, or if the channel does
    # not support image transmission.  Returns '-1' only on error/hangup. Image names
    # should not include extensions.
    #
    # **Runs on dead channel?**
    # No
    #
    # **Syntax of AGI command:**
    # send image <image> 
    def send_image(image : String)
      command_str = "#{image}".gsub(/\s+/, " ")
      response = execute "SEND IMAGE #{command_str}"
    end


    # **Synopsis:**
    # Sends text to channels supporting it.
    #
    # **Description:**
    # Sends the given text on a channel. Most channels do not support the
    # transmission of text. Returns '0' if text is sent, or if the channel does not
    # support text transmission. Returns '-1' only on error/hangup.
    #
    # **Runs on dead channel?**
    # No
    #
    # **Syntax of AGI command:**
    # send text <text to send> 
    #
    # **See also:**
    # `#receive_text`
    def send_text(text_to_send : String)
      command_str = "#{text_to_send}".gsub(/\s+/, " ")
      response = execute "SEND TEXT #{command_str}"
    end


    # **Synopsis:**
    # Autohangup channel in some time.
    #
    # **Description:**
    # Cause the channel to automatically hangup at <time> seconds in the future. Of
    # course it can be hungup before then as well. Setting to '0' will cause the
    # autohangup feature to be disabled on this channel.
    #
    # **Runs on dead channel?**
    # No
    #
    # **Syntax of AGI command:**
    # set autohangup <time> 
    def set_autohangup(time : String)
      command_str = "#{time}".gsub(/\s+/, " ")
      response = execute "SET AUTOHANGUP #{command_str}"
    end


    # **Synopsis:**
    # Sets callerid for the current channel.
    #
    # **Description:**
    # Changes the callerid of the current channel.
    #
    # **Runs on dead channel?**
    # No
    #
    # **Syntax of AGI command:**
    # set callerid <number> 
    def set_callerid(number : String)
      command_str = "#{number}".gsub(/\s+/, " ")
      response = execute "SET CALLERID #{command_str}"
    end


    # **Synopsis:**
    # Sets channel context.
    #
    # **Description:**
    # Sets the context for continuation upon exiting the application.
    #
    # **Runs on dead channel?**
    # No
    #
    # **Syntax of AGI command:**
    # set context <desired context> 
    #
    # **See also:**
    # `#set_extension`, `#set_priority`
    def set_context(desired_context : String)
      command_str = "#{desired_context}".gsub(/\s+/, " ")
      response = execute "SET CONTEXT #{command_str}"
    end


    # **Synopsis:**
    # Changes channel extension.
    #
    # **Description:**
    # Changes the extension for continuation upon exiting the application.
    #
    # **Runs on dead channel?**
    # No
    #
    # **Syntax of AGI command:**
    # set extension <new extension> 
    #
    # **See also:**
    # `#set_context`, `#set_priority`
    def set_extension(new_extension : String)
      command_str = "#{new_extension}".gsub(/\s+/, " ")
      response = execute "SET EXTENSION #{command_str}"
    end


    # **Synopsis:**
    # Enable/Disable Music on hold generator
    #
    # **Description:**
    # Enables/Disables the music on hold generator. If <class> is not specified, then
    # the 'default' music on hold class will be used. This generator will be stopped
    # automatically when playing a file.
    # Always returns '0'.
    #
    # **Runs on dead channel?**
    # No
    #
    # **Syntax of AGI command:**
    # set music {on|off} <class> 
    def set_music(moh_class : String)
      command_str = "#{moh_class}".gsub(/\s+/, " ")
      response = execute "SET MUSIC #{command_str}"
    end


    # **Synopsis:**
    # Set channel dialplan priority.
    #
    # **Description:**
    # Changes the priority for continuation upon exiting the application. The
    # priority must be a valid priority or label.
    #
    # **Runs on dead channel?**
    # No
    #
    # **Syntax of AGI command:**
    # set priority <priority> 
    #
    # **See also:**
    # `#set_context`, `#set_extension`
    def set_priority(priority : String)
      command_str = "#{priority}".gsub(/\s+/, " ")
      response = execute "SET PRIORITY #{command_str}"
    end


    # **Synopsis:**
    # Sets a channel variable.
    #
    # **Description:**
    # Sets a variable to the current channel.
    #
    # **Runs on dead channel?**
    # Yes
    #
    # **Syntax of AGI command:**
    # set variable <variablename> <value> 
    #
    # **See also:**
    # `#get_variable`, `#get_full_variable`
    def set_variable(variablename : String, value : String)
      command_str = "#{variablename} #{value}".gsub(/\s+/, " ")
      response = execute "SET VARIABLE #{command_str}"
    end


    # **Synopsis:**
    # Sends audio file on channel.
    #
    # **Description:**
    # Send the given file, allowing playback to be interrupted by the given digits,
    # if any. Returns '0' if playback completes without a digit being pressed, or the
    # ASCII numerical value of the digit if one was pressed, or '-1' on error or if
    # the channel was disconnected. If musiconhold is playing before calling stream
    # file it will be automatically stopped and will not be restarted after
    # completion.
    # It sets the following channel variables upon completion:
    # ${PLAYBACKSTATUS}: The status of the playback attempt as a text string.
    #     SUCCESS
    #     FAILED
    #
    # **Runs on dead channel?**
    # No
    #
    # **Syntax of AGI command:**
    # stream file <filename> <escape_digits> [<sample offset>] 
    #
    # **See also:**
    # `#control_stream_file`, `#get_option`
    def stream_file(filename : String, escape_digits : String, sample_offset : String? = nil)
      command_str = "#{filename} #{escape_digits} #{sample_offset}".gsub(/\s+/, " ")
      response = execute "STREAM FILE #{command_str}"
    end


    # **Synopsis:**
    # Sends audio file on channel and allows the listener to control the stream.
    #
    # **Description:**
    # Send the given file, allowing playback to be controlled by the given digits, if
    # any. Use double quotes for the digits if you wish none to be permitted. If
    # offsetms is provided then the audio will seek to offsetms before play starts.
    # Returns '0' if playback completes without a digit being pressed, or the ASCII
    # numerical value of the digit if one was pressed, or '-1' on error or if the
    # channel was disconnected. Returns the position where playback was terminated as
    # endpos.
    # It sets the following channel variables upon completion:
    # ${CPLAYBACKSTATUS}: Contains the status of the attempt as a text string
    #     SUCCESS
    #     USERSTOPPED
    #     REMOTESTOPPED
    #     ERROR
    # ${CPLAYBACKOFFSET}: Contains the offset in ms into the file where playback was
    # at when it stopped. '-1' is end of file.
    # ${CPLAYBACKSTOPKEY}: If the playback is stopped by the user this variable
    # contains the key that was pressed.
    #
    # **Runs on dead channel?**
    # No
    #
    # **Syntax of AGI command:**
    # control stream file <filename> <escape_digits> [<skipms>] [<ffchar>] [<rewchr>] [<pausechr>] [<offsetms>] 
    #
    # **See also:**
    # `#get_option`, `#control_stream_file`
    def control_stream_file(filename : String, escape_digits : String, skipms : String? = nil, ffchar : String? = nil, rewchr : String? = nil, pausechr : String? = nil, offsetms : String? = nil)
      command_str = "#{filename} #{escape_digits} #{skipms} #{ffchar} #{rewchr} #{pausechr} #{offsetms}".gsub(/\s+/, " ")
      response = execute "CONTROL STREAM FILE #{command_str}"
    end


    # **Synopsis:**
    # Toggles TDD mode (for the deaf).
    #
    # **Description:**
    # Enable/Disable TDD transmission/reception on a channel. Returns '1' if
    # successful, or '0' if channel is not TDD-capable.
    #
    # **Runs on dead channel?**
    # No
    #
    # **Syntax of AGI command:**
    # tdd mode {|} 
    def tdd_mode
      execute "TDD MODE"
    end


    # **Synopsis:**
    # Logs a message to the asterisk verbose log.
    #
    # **Description:**
    # Sends <message> to the console via verbose message system. <level> is the
    # verbose level (1-4). Always returns '1'
    #
    # **Runs on dead channel?**
    # Yes
    #
    # **Syntax of AGI command:**
    # verbose <message> <level> 
    def verbose(message : String, level : String)
      command_str = "#{message} #{level}".gsub(/\s+/, " ")
      response = execute "VERBOSE #{command_str}"
    end


    # **Synopsis:**
    # Waits for a digit to be pressed.
    #
    # **Description:**
    # Waits up to <timeout> milliseconds for channel to receive a DTMF digit. Returns
    # '-1' on channel failure, '0' if no digit is received in the timeout, or the
    # numerical value of the ascii of the digit if one is received. Use '-1' for the
    # <timeout> value if you desire the call to block indefinitely.
    #
    # **Runs on dead channel?**
    # No
    #
    # **Syntax of AGI command:**
    # wait for digit <timeout> 
    def wait_for_digit(timeout : String)
      command_str = "#{timeout}".gsub(/\s+/, " ")
      response = execute "WAIT FOR DIGIT #{command_str}"
    end


    # **Synopsis:**
    # Creates a speech object.
    #
    # **Description:**
    # Create a speech object to be used by the other Speech AGI commands.
    #
    # **Runs on dead channel?**
    # No
    #
    # **Syntax of AGI command:**
    # speech create <engine> 
    #
    # **See also:**
    # `#speech_set`, `#speech_destroy`, `#speech_load_grammar`, `#speech_unload_grammar`, `#speech_activate_grammar`, `#speech_deactivate_grammar`, `#speech_recognize`
    def speech_create(engine : String)
      command_str = "#{engine}".gsub(/\s+/, " ")
      response = execute "SPEECH CREATE #{command_str}"
    end


    # **Synopsis:**
    # Sets a speech engine setting.
    #
    # **Description:**
    # Set an engine-specific setting.
    #
    # **Runs on dead channel?**
    # No
    #
    # **Syntax of AGI command:**
    # speech set <name> <value> 
    #
    # **See also:**
    # `#speech_create`, `#speech_destroy`, `#speech_load_grammar`, `#speech_unload_grammar`, `#speech_activate_grammar`, `#speech_deactivate_grammar`, `#speech_recognize`
    def speech_set(name : String, value : String)
      command_str = "#{name} #{value}".gsub(/\s+/, " ")
      response = execute "SPEECH SET #{command_str}"
    end


    # **Synopsis:**
    # Destroys a speech object.
    #
    # **Description:**
    # Destroy the speech object created by 'SPEECH CREATE'.
    #
    # **Runs on dead channel?**
    # Yes
    #
    # **Syntax of AGI command:**
    # speech destroy 
    #
    # **See also:**
    # `#speech_create`, `#speech_set`, `#speech_load_grammar`, `#speech_unload_grammar`, `#speech_activate_grammar`, `#speech_deactivate_grammar`, `#speech_recognize`
    def speech_destroy
      execute "SPEECH DESTROY"
    end


    # **Synopsis:**
    # Loads a grammar.
    #
    # **Description:**
    # Loads the specified grammar as the specified name.
    #
    # **Runs on dead channel?**
    # No
    #
    # **Syntax of AGI command:**
    # speech load grammar <grammar name> <path to grammar> 
    #
    # **See also:**
    # `#speech_create`, `#speech_set`, `#speech_destroy`, `#speech_unload_grammar`, `#speech_activate_grammar`, `#speech_deactivate_grammar`, `#speech_recognize`
    def speech_load_grammar(grammar_name : String, path_to_grammar : String)
      command_str = "#{grammar_name} #{path_to_grammar}".gsub(/\s+/, " ")
      response = execute "SPEECH LOAD GRAMMAR #{command_str}"
    end


    # **Synopsis:**
    # Unloads a grammar.
    #
    # **Description:**
    # Unloads the specified grammar.
    #
    # **Runs on dead channel?**
    # Yes
    #
    # **Syntax of AGI command:**
    # speech unload grammar <grammar name> 
    #
    # **See also:**
    # `#speech_create`, `#speech_set`, `#speech_destroy`, `#speech_load_grammar`, `#speech_activate_grammar`, `#speech_deactivate_grammar`, `#speech_recognize`
    def speech_unload_grammar(grammar_name : String)
      command_str = "#{grammar_name}".gsub(/\s+/, " ")
      response = execute "SPEECH UNLOAD GRAMMAR #{command_str}"
    end


    # **Synopsis:**
    # Activates a grammar.
    #
    # **Description:**
    # Activates the specified grammar on the speech object.
    #
    # **Runs on dead channel?**
    # No
    #
    # **Syntax of AGI command:**
    # speech activate grammar <grammar name> 
    #
    # **See also:**
    # `#speech_create`, `#speech_set`, `#speech_destroy`, `#speech_load_grammar`, `#speech_unload_grammar`, `#speech_deactivate_grammar`, `#speech_recognize`
    def speech_activate_grammar(grammar_name : String)
      command_str = "#{grammar_name}".gsub(/\s+/, " ")
      response = execute "SPEECH ACTIVATE GRAMMAR #{command_str}"
    end


    # **Synopsis:**
    # Deactivates a grammar.
    #
    # **Description:**
    # Deactivates the specified grammar on the speech object.
    #
    # **Runs on dead channel?**
    # No
    #
    # **Syntax of AGI command:**
    # speech deactivate grammar <grammar name> 
    #
    # **See also:**
    # `#speech_create`, `#speech_set`, `#speech_destroy`, `#speech_load_grammar`, `#speech_unload_grammar`, `#speech_activate_grammar`, `#speech_recognize`
    def speech_deactivate_grammar(grammar_name : String)
      command_str = "#{grammar_name}".gsub(/\s+/, " ")
      response = execute "SPEECH DEACTIVATE GRAMMAR #{command_str}"
    end


    # **Synopsis:**
    # Recognizes speech.
    #
    # **Description:**
    # Plays back given <prompt> while listening for speech and dtmf.
    #
    # **Runs on dead channel?**
    # No
    #
    # **Syntax of AGI command:**
    # speech recognize <prompt> <timeout> [<offset>] 
    #
    # **See also:**
    # `#speech_create`, `#speech_set`, `#speech_destroy`, `#speech_load_grammar`, `#speech_unload_grammar`, `#speech_activate_grammar`, `#speech_deactivate_grammar`
    def speech_recognize(prompt : String, timeout : String, offset : String? = nil)
      command_str = "#{prompt} #{timeout} #{offset}".gsub(/\s+/, " ")
      response = execute "SPEECH RECOGNIZE #{command_str}"
    end


    # **Synopsis:**
    # Cause the channel to execute the specified dialplan subroutine.
    #
    # **Description:**
    # Cause the channel to execute the specified dialplan subroutine, returning to
    # the dialplan with execution of a Return().
    #
    # **Runs on dead channel?**
    # No
    #
    # **Syntax of AGI command:**
    # gosub <context> <extension> <priority> [<optional-argument>] 
    def gosub(context : String, extension : String, priority : String, optional_argument : String? = nil)
      command_str = "#{context} #{extension} #{priority} #{optional_argument}".gsub(/\s+/, " ")
      response = execute "GOSUB #{command_str}"
    end

  end
end
