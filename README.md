# Cesium ion Sketchup Plugin
SketchUp extension for uploading and tiling models with Cesium ion.

## Prerequisites

### Sign up for a Cesium ion account

Go to https://cesium.com/ion/ and create an account

### Install Ruby and required modules

Instructions can be found [here](https://www.ruby-lang.org/en/documentation/installation/).

#### Install bundler (it may already be installed)
```
gem install bundler
```

#### Install required modules
```
bundler install
```

## Building Plugin

Run the following command

```
ruby ./build.rb
```

The plugin file will be located at `./build/cesium_ion.rbz`.

## Installing in Sketchup

Under the `Windows` menu, select `Extension Manager`

![Extension Manager](images/ExtensionManager.jpg)

Click `Install Extension`

![Extension Manager](images/FileBrowser.jpg)

Select the `build/cesium.rbz` file you built

![Extension Manager](images/ExtensionManager-2.jpg)

Once it is installed, you can `Publish` from the `Extensions`->`Cesium ion`->`Publish` menu item

![Extension Manager](images/Menu.jpg)
