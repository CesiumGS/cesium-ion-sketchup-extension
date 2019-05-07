# ion-sketchup-exporter
SketchUp extension for uploading and tiling models with Cesium ion.

## Prerequisites

### Install Ruby

Instruction can be found [here](https://www.ruby-lang.org/en/documentation/installation/).

### Install modules

```
gem install rubyzip
```

## Building Plugin

Run the following command

```
ruby ./build.rb
```

The plugin file will be located at `./build/cesium_ion.rbz`.