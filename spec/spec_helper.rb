BASE_DIR = File.join(File.dirname(__FILE__), '..')
$LOAD_PATH.unshift File.join(BASE_DIR, 'lib')
require 'ipaddress'

#Dir.glob(File.join(BASE_DIR, 'spec', 'helpers', '**_helper.rb')).each do |path|
#  require path
#end
