require "sketchup.rb"
require "extensions.rb"

module Cesium
  module IonExporter
    Gem.install 'aws-sdk-s3'
    Gem.install 'rubyzip'

    PLUGIN_ID = File.basename(__FILE__, ".rb")
    PLUGIN_DIR = File.join(File.dirname(__FILE__), PLUGIN_ID)

    EXTENSION = SketchupExtension.new(
      "Cesium ion",
      File.join(PLUGIN_DIR, "main")
    )
    EXTENSION.creator     = "Analytical Graphics, Inc."
    EXTENSION.description = 
      "This plugin allows users to upload models directly into their Cesium ion accounts. If you already have an account, you can just publish directly to it from Sketchup. If not you can sign up at https://cesium.com/ion."
    EXTENSION.version     = "1.0.0"
    EXTENSION.copyright   = "#{EXTENSION.creator} 2019"
    Sketchup.register_extension(EXTENSION, true)
  end
end
