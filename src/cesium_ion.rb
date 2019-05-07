#-------------------------------------------------------------------------------
#
# Author:
# Copyright: Copyright (c) 2019
# License:
#
#-------------------------------------------------------------------------------

require "sketchup.rb"
require "extensions.rb"

module Cesium
  module IonExporter

    Gem.install 'aws-sdk-s3'

    PLUGIN_ID = File.basename(__FILE__, ".rb")
    PLUGIN_DIR = File.join(File.dirname(__FILE__), PLUGIN_ID)

    EXTENSION = SketchupExtension.new(
      "Export to Cesium ion",
      File.join(PLUGIN_DIR, "main")
    )
    EXTENSION.creator     = "Cesium"
    EXTENSION.description =
      "Export Models to Cesium ion."
    EXTENSION.version     = "1.0.0"
    EXTENSION.copyright   = "#{EXTENSION.creator} 2019"
    Sketchup.register_extension(EXTENSION, true)

  end
end
