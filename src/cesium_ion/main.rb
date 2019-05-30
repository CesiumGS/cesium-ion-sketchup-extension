require 'base64'
require 'digest'
require 'json'
require 'net/http'
require 'socket'
require 'uri'

require_relative 'thirdparty/aws-sdk-s3.rb'
require_relative 'thirdparty/zip.rb'

module Cesium
  module IonExporter

    @@debug = false
    @@local = false

    @@clientId = 14

    @@baseServer = 'https://cesium.com/'
    @@apiServer = 'https://api.cesium.com/'
    if @@local
      @@baseServer = 'http://composer.test:8081/'
      @@apiServer = 'http://api.composer.test:8081/'
    end

    @@callbackHost = 'localhost'
    @@callbackPort = 10101
    @@callbackDomain = "#{@@callbackHost}:#{@@callbackPort}"
    @@callbackPath = '/oauth'
    @@callbackUri = "http://#{@@callbackDomain}#{@@callbackPath}"

    @@modelExportOptions = {
      :triangulated_faces => true,
      :doublesided_faces => true,
      :edges => false,
      :author_attribution => false,
      :texture_maps => true,
      :selectionset_only => false,
      :preserve_instancing => false
    }

    @tokenFile = "#{Dir.home}/.sketchup_cesium_ion";

    ## OAUTH2

    def self.get_http(uri)
      http = Net::HTTP.new(uri.host, uri.port)

      if (uri.port == 443)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      end

      return http
    end

    def self.get_token
      if File.exist?(@tokenFile)
        return File.read(@tokenFile)
      end

      state = [*('a'..'z'),*('0'..'9')].shuffle[0,8].join
      codeVerifier = [*('a'..'z'),*('0'..'9')].shuffle[0,32].join

      # Ruby only return a digest as a hex string, so convert that back to a binary string with pack
      # Then base64 encode it and replace the non alpha-numeric characters
      codeChallenge = Base64.encode64(Array(Digest::SHA256.hexdigest codeVerifier).pack('H*'))
                        .gsub('+', '-')
                        .gsub('/', '_')
                        .gsub('=', '')
                        .gsub("\n", '');
      query = {
        'client_id' => @@clientId,
        'scope' => 'assets:read%20assets:write',
        'state' => state,
        'response_type' => 'code',
        'redirect_uri' => @@callbackUri,
        'code_challenge' => codeChallenge,
        'code_challenge_method' => 'S256'
      }

      querystring = '';
      query.each do |key, value|
        querystring += (querystring.length == 0) ? '?' : '&'
        querystring += "#{key}=#{value}"
      end

      UI.openURL("#{@@baseServer}ion/oauth#{querystring}")

      # Start a TCP server and block waiting for a single request
      params = {}
      begin
        server = TCPServer.open(@@callbackHost, @@callbackPort)

        socket = nil
        count = 0
        begin
          sleep 1
          socket = server.accept_nonblock
        rescue IO::WaitReadable, Errno::EINTR
          count += 1
          if (count < 60) #Retry for a minute
            retry
          end
        end

        if socket.nil?
          raise 'Connection Timeout'
        end

        line = socket.gets || ''
        method, path = line.split
        path ||= ''
        path, query = path.split('?')
        query ||= ''
        while line = socket.gets
          parts = line.split(' ', 2)
          break if parts[0] == ""
          if parts[0].downcase == 'host:'
            host = parts[1].strip
            break
          end
        end

        query.split('&').each do |param|
          key, value = param.split('=')
          params[key] = value
        end

        if method != 'GET' || host.nil? || host != @@callbackDomain ||
            path != @@callbackPath || params['state'] != state || params['code'].nil?
            raise 'Invalid callback'
        end
      rescue => e
        if @@debug
          puts e
        end
      ensure
        unless socket.nil?
          socket.puts 'HTTP/1.1 200 OK'
          socket.puts "Content-type: text/html"
          socket.puts ''
          socket.puts %{
            <html>
              <head>
                <title>Authorization Complete</title>
              </head>
              <body>
                Sketchup has been authorized to use your Cesium ion account.

                You can close this window and go back to Sketchup.
              </body>
            </html>}

          socket.close
        end
        server.close
      end

      # No code, so no point in moving forward
      if params['code'].nil?
        return
      end

      uri = URI.parse("#{@@apiServer}oauth/token")
      http = get_http(uri)

      request = Net::HTTP::Post.new(uri.request_uri)
      tokenOptions = {
        'client_id' => @@clientId,
        'code' => params['code'],
        'redirect_uri' => @@callbackUri,
        'grant_type' => 'authorization_code',
        'code_verifier' => codeVerifier
      }
      request.body = tokenOptions.to_json
      request['Content-Type'] = 'application/json'

      response = http.request(request)

      resultJson = {}
      if response.code == '200' && !response.body.nil?
        resultJson = JSON.parse(response.body)

        File.write(@tokenFile, resultJson['access_token'])
      end

      return resultJson['access_token']
    end

    ## END OAUTH2

    ## OPTIONS DIALOG

    def self.show_dialog(modelname, description, attribution, position)
      html_file =  File.join(__dir__, 'dialog.html')
      options = {
        :dialog_title => 'Publish to Cesium ion',
        :width => 600,
        :height => 400,
        :style => UI::HtmlDialog::STYLE_DIALOG
      }
      dialog = UI::HtmlDialog.new(options)
      dialog.set_file(html_file)
      dialog.center

      webP = false
      canceled = true
      dialog.add_action_callback('close') do |action_context|
        dialog.close
      end

      dialog.add_action_callback('export') do |action_context, n, d, a, w|
        canceled = false
        modelname = n
        description = d
        attribution = a
        webP = w
        dialog.close
      end

      dialog.add_action_callback('initializeFields') do |action_context|
        script = %{
          document.getElementById('name').value = "#{modelname}";
          document.getElementById('description').value = "#{description}";
          document.getElementById('attribution').value = "#{attribution}";
        }

        dialog.execute_script(script)
      end

      dialog.show_modal

      if canceled
        return
      end

      return {
        'name' => modelname,
        'type' => '3DTILES',
        'description' => description,
        'attribution' => attribution,
        'options' => {
          'sourceType' => '3D_MODEL',
          'position' => position,
          'textureFormat' => webP ? 'WEBP' : 'AUTO'
        }
      }
    end

    ## END OPTIONS DIALOG

    ## EXPORT MODEL TO DISK

    def self.recurse_dir(rootDir, base, zio)
      dir = base.nil? ? rootDir : File.join(rootDir, base)

      Dir.foreach(dir) do |file|
        next if file == '.' || file == '..'
        relative = base.nil? ? file : File.join(base, file)
        absolute = File.join(dir, file)

        if File.file?(absolute)
          zio.put_next_entry(relative)
          zio.write File.binread(absolute)
        else
          recurse_dir(dir, relative, zio)
        end
      end
    end

    def self.get_model_data(model)
      Dir.mktmpdir do |dir|
        modelpath = "#{dir}/model.dae"

        status = model.export(modelpath, @@modelExportOptions)

        unless status
          return
        end

        stringio = Zip::OutputStream.write_buffer do |zio|
          recurse_dir(dir, nil, zio)
        end

        return stringio.string
      end
    end

    ## END EXPORT MODEL TO DISK

    def self.get_attribution(attrdicts)
      if attrdicts.nil?
        return ''
      end

      result = ''
      attrdicts.each do | dict |
        unless dict['NicknamesKey'].nil?
          dict['NicknamesKey'].each do | name |
            if result.length > 0
              result += ', '
            end
            result += " #{name}"
          end
        end
      end

      return result
    end

    def self.add_ion_asset(model, token)
      # Figure out best name
      modelname = model.name
      if modelname.nil? || modelname.empty?
        modelpath = model.path
        if !modelpath.nil? && !modelpath.empty?
          modelname = Pathname.new(modelpath).basename
        else
          modelname = 'Untitled Sketchup Model'
        end
      end

      # Description
      description = model.description
      description = 'Exported from Sketchup' if description.nil? || description.empty?

      # Attribution
      attribution = get_attribution(model.attribute_dictionaries)
      model.definitions.each do | definition |
        componentAttribution = get_attribution(definition.attribute_dictionaries)
        if componentAttribution.length > 0
          if attribution.length > 0
            attribution += ', '
          end
          attribution += componentAttribution
        end
      end

      # Geolocation
      position = nil
      if (model.georeferenced?)
        worldPoint = model.point_to_latlong(Geom::Point3d.new(0, 0, 0))
        position = [worldPoint.x.to_f, worldPoint.y.to_f, worldPoint.z.to_f]
      end

      # Prompt User
      options = show_dialog(modelname, description, attribution, position)

      # Check if user cancelled the export
      if options.nil?
        return -1
      end

      uri = URI.parse("#{@@apiServer}v1/assets?access_token=#{token}")
      http = get_http(uri)

      request = Net::HTTP::Post.new(uri.request_uri)
      request.body = options.to_json
      request['Content-Type'] = 'application/json'

      response = http.request(request)

      if response.code != '200' || response.body.nil?
        return
      end

      compressedModel = get_model_data(model)
      if compressedModel.nil?
        return
      end

      resultJson = JSON.parse(response.body)
      successfulUpload = uploadModel(resultJson['uploadLocation'], compressedModel)
      if successfulUpload
        assetMetadata = resultJson['assetMetadata']
        onComplete = resultJson['onComplete']

        uriComplete = URI.parse("#{onComplete['url']}?access_token=#{token}")
        httpComplete = get_http(uriComplete)

        requestComplete = Net::HTTP::Post.new(uriComplete.request_uri)
        requestComplete.body = onComplete['fields'].to_json
        requestComplete['Content-Type'] = 'application/json'

        responseComplete = httpComplete.request(requestComplete)
        return (responseComplete.code == '204') ? assetMetadata['id'] : nil
      end
    end

    def self.uploadModel(uploadInfo, compressedModel)
      options = {
        :region => 'us-east-1',
        :credentials => Aws::Credentials.new(
          uploadInfo['accessKey'],
          uploadInfo['secretAccessKey'],
          uploadInfo['sessionToken']),
        :force_path_style => true
      }

      unless uploadInfo['endpoint'].nil?
        options[:endpoint] = uploadInfo['endpoint']
      end

      s3 = Aws::S3::Client.new(options)

      begin
        resp = s3.put_object({
          body: compressedModel,
          bucket: uploadInfo['bucket'],
          key: "#{uploadInfo['prefix']}model.zip"
        })
      rescue Exception => e
        if @@debug
          puts e
        end
        return false
      end

      return true
    end

    def self.export_model
      token = get_token()
      if token.nil?
        UI.messagebox('Could not access Cesium ion account', MB_OK)
        return
      end

      assetId = add_ion_asset(Sketchup.active_model, token)
      if assetId.nil?
        UI.messagebox('Failed to export to Cesium ion', MB_OK)
        return
      elsif assetId == -1
        return # Cancelled by user
      end

      # Upload succeeded
      notification = UI::Notification.new(EXTENSION, "Successfully uploaded model to Cesium ion as asset #{assetId}")
      notification.show
      UI.openURL("#{@@baseServer}ion/assets/#{assetId}");
    end

    def self.logout
      result = UI.messagebox('Are you sure you want to log out of Cesium ion?', MB_YESNO)
      if result == IDYES
        File.delete(@tokenFile)
      end
    end

    unless(file_loaded?(__FILE__))
      file_loaded(__FILE__)
      menu = UI.menu("Plugins")
      cesiumMenu = menu.add_submenu(EXTENSION.name)
      cesiumMenu.add_item('Publish') { export_model }
      logOutItem = cesiumMenu.add_item('Log out') { logout }

      cesiumMenu.set_validation_proc(logOutItem) do
        File.exist?(@tokenFile) ? MF_ENABLED : MF_GRAYED
      end
    end
  end
end
