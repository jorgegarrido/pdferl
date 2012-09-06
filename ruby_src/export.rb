## ==============================================================================
#
# CLASS EXPORT
#
# Copyright (c) 2012 Jorge Garrido <jorge.garrido@morelosoft.com>.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 3. Neither the name of copyright holders nor the names of its
#    contributors may be used to endorse or promote products derived
#    from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
# TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL COPYRIGHT HOLDERS OR CONTRIBUTORS
# BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
## ===============================================================================

# make easy load requires from any classpath
$: << File.dirname(__FILE__) unless $:.include? File.dirname(__FILE__)

# requires class
require 'document.rb'
require 'rubygems'
require 'erlectricity'
      
# This class create the report and store in a specific directory, the class connect
# to erlang process through 'erlectricity' and inter-change data between
# ruby script and erlang.
class Export

	# make report, send an {response, <<"ok">>} to erlang when the
	# file has been created
	def make_report(xpath, jasper_file, name, type)
		receive do |f|
			f.when([:xml, String]) do |xml|
				send_doc("#{xml}", xpath, jasper_file, name, type)
				f.send!([:response, "ok"])
                                f.receive_loop
			end
		end
	end
 
	# send doc, connect with document.rb to create IO.popen to java 
	# classpath, communicate via pipe
	def send_doc(xml, xml_start_path, report, filename, output_type)
		case output_type
			when 'rtf'
				extension = 'rtf'
				mime_type = 'application/rtf'
				jasper_type = 'rtf'
			when 'pdf'
				extension = 'pdf'
				mime_type = 'application/pdf'
				jasper_type = 'pdf'
			else # xls
				extension = 'xls'
				mime_type = 'application/vnd.ms-excel'
				jasper_type = 'xls'
		end

		doc = Document.new
		file = doc.generate_report(xml, report, jasper_type, xml_start_path)
		
		# parse classpath to gain access from any path
                path=File.expand_path(File.dirname(__FILE__))
                parsed_path=path.split("/")
                parsed_path.delete_at(parsed_path.count - 1)
                
                # save the file
                File.open(File.join(parsed_path) + "/reports/" + filename + "." + output_type, 'w') {|f| f.write(file) }  
	end
 
	# just get content file as string, read line by line (test purposes)
	# this method is deprecated
	def get_file_as_string(filename)
		data = ''
		f = File.open(filename, "r") 
		f.each_line do |line|
			data += line
		end
		return data
	end
end
 
# get the variables from erlang to configure the report
xpath, jasper_file, name, type = *ARGV
report = Export.new
report.make_report(xpath, jasper_file, name, type)
