require 'session'

module Godo
  
  class MrxvtSession < Session
    
    def initialize( path )
      super( path )
      @fifo = nil
    end

    def create( label, command, exit )
      command &&= eval( %Q{\"#{command}\"}, get_binding )
      label &&= '"' + eval( %Q{\"#{label}\"} ) + '"'

      if @fifo
        macros = if exit
          ["Exec !cd #{path} && #{command}"]
        else
          ["NewTab #{label} #{command}", "Raise"]
        end

        File.open(@fifo, 'a') do |fifo|
          fifo.puts(*macros)
        end
      else
        mrxvt_command = "mrxvt --useFifo --syncTabTitle  --workingDirectory #{path} --tabTitle #{label} --command #{command}"
        pid = Process.fork {
          exec mrxvt_command
        }
        Process.detach(pid)
        @fifo = "/tmp/.mrxvt-#{pid}"
        slept_for = 0.0
        sleep_amt = 0.1
        while !File.exist?(@fifo) && slept_for < 5.0 do
          sleep sleep_amt
          slept_for += sleep_amt
        end
      end
    end
  end
end
