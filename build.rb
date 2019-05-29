require 'zip'

pluginName = 'cesium_ion'

srcDir = File.join(File.dirname(__FILE__), 'src')
pluginDir = File.join(srcDir, pluginName);
buildDir = File.join(File.dirname(__FILE__), 'build')
thirdpartyDir = File.join(File.dirname(__FILE__), 'thirdparty')
Dir.mkdir(buildDir) unless File.exists?(buildDir)

#packerPath = 'C:\Users\tfili\Downloads\sketchup-dev-tools-and-examples-master\tools\ruby-packer\src\RubyPacker\bin\Release\RubyPacker.exe';

#destinationThirdPartyDir = File.join(buildDir, 'thirdparty')
#Dir.mkdir(destinationThirdPartyDir) unless File.exists?(destinationThirdPartyDir)

# system("#{packerPath} #{File.join(sourceThirdPartyDir, 'jmespath-1.4.0/lib/jmespath.rb')} #{File.join(destinationThirdPartyDir, 'jmespath.rb')}")
# system("#{packerPath} #{File.join(sourceThirdPartyDir, 'rubyzip-1.2.3/lib/zip.rb')} #{File.join(destinationThirdPartyDir, 'zip.rb')}")
# system("#{packerPath} #{File.join(sourceThirdPartyDir, 'aws-eventstream-1.0.3/lib/aws-eventstream.rb')} #{File.join(destinationThirdPartyDir, 'aws-eventstream.rb')}")
# system("#{packerPath} #{File.join(sourceThirdPartyDir, 'aws-partitions-1.166.0/lib/aws-partitions.rb')} #{File.join(destinationThirdPartyDir, 'aws-partitions.rb')}")
# system("#{packerPath} #{File.join(sourceThirdPartyDir, 'aws-sigv4-1.1.0/lib/aws-sigv4.rb')} #{File.join(destinationThirdPartyDir, 'aws-sigv4.rb')}")
# system("#{packerPath} #{File.join(sourceThirdPartyDir, 'aws-sdk-core-3.53.1/lib/aws-sdk-core.rb')} #{File.join(destinationThirdPartyDir, 'aws-sdk-core.rb')}")
# system("#{packerPath} #{File.join(sourceThirdPartyDir, 'aws-sdk-kms-1.21.0/lib/aws-sdk-kms.rb')} #{File.join(destinationThirdPartyDir, 'aws-sdk-kms.rb')}")
# system("#{packerPath} #{File.join(sourceThirdPartyDir, 'aws-sdk-s3-1.40.0/lib/aws-sdk-s3.rb')} #{File.join(destinationThirdPartyDir, 'aws-sdk-s3.rb')}")

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
