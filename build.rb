require 'zip'

pluginName = 'cesium_ion'

srcDir = File.join(File.dirname(__FILE__), 'src')
pluginDir = File.join(srcDir, pluginName);
buildDir = File.join(File.dirname(__FILE__), 'build')
thirdpartyDir = File.join(File.dirname(__FILE__), 'thirdparty')
Dir.mkdir(buildDir) unless File.exists?(buildDir)

# Adds a directory
def add_directory(zipfile, relativeDirectory, absoluteDirectory)
    Dir.foreach(absoluteDirectory) do |filename|
        next if filename == '.' || filename == '..'
        relative = File.join(relativeDirectory, filename);
        absolute = File.join(absoluteDirectory, filename);

        if (File.directory?(absolute))
            add_directory(zipfile, relative, absolute)
        else
            zipfile.add(relative, absolute)
        end
    end
end

# Create Zip file
zipPath = File.join(buildDir, 'cesium_ion.rbz')
File.delete(zipPath) if File.exists?(zipPath) 

# Populate Zip file
Zip::File.open(zipPath, Zip::File::CREATE) do |zipfile|
    # Add main extension file
    zipfile.add('cesium_ion.rb', File.join(srcDir, 'cesium_ion.rb'))

    # Add Extension directory
    add_directory(zipfile, pluginName, pluginDir)

    # Add some data files needed by AWS
    zipfile.add(File.join(pluginName, 'VERSION'), File.join(thirdpartyDir, 'aws-sdk-core-3.53.1', 'VERSION'))
    zipfile.add(File.join(pluginName, 'partitions.json'), File.join(thirdpartyDir, 'aws-partitions-1.166.0', 'partitions.json'))
end
