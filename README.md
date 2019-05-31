# Cesium ion Sketchup Plugin
SketchUp extension for uploading and tiling models with Cesium ion.

## Installation and Usage

See our official extension page https://extensions.sketchup.com/en/content/cesium-ion

## Local Development

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

## Locally installing in Sketchup

Under the `Windows` menu, select `Extension Manager`

![Extension Manager](images/ExtensionManager.jpg)

Click `Install Extension`

![Extension Manager](images/FileBrowser.jpg)

Select the `build/cesium.rbz` file you built

![Extension Manager](images/ExtensionManager-2.jpg)

Once it is installed, you can `Publish` from the `Extensions`->`Cesium ion`->`Publish` menu item

![Extension Manager](images/Menu.jpg)

## Release

* Go to the [Extension Warehouse](https://extensions.sketchup.com/en)
* Select `My Extensions` from the dropdown on the right side
* Click `Manage Store` on the left side
* Click `Edit` next to the `Cesium ion` Extension
* Change whatever you need to. Be sure to update the `.rbz` file and the `What's New` section
* Click `Save Draft`
* On the next page click `Publish`
