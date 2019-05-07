require 'zip'

srcDir = File.join(File.dirname(__FILE__), 'src')
pluginDir = File.join(srcDir, 'cesium_ion')
buildDir = File.join(File.dirname(__FILE__), 'build')
Dir.mkdir(buildDir) unless File.exists?(buildDir)

zipPath = File.join(buildDir, 'cesium_ion.rbz')
File.delete(zipPath) if File.exists?(zipPath) 

Zip::File.open(zipPath, Zip::File::CREATE) do |zipfile|
    zipfile.add('cesium_ion.rb', File.join(srcDir, 'cesium_ion.rb'))
    Dir.foreach(pluginDir) do |filename|
        next if filename == '.' || filename == '..'
        zipfile.add("cesium_ion/#{filename}", File.join(pluginDir, filename))
    end
end
