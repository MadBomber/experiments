# Need to download the latest version of LibTorch

Ruby v3.4.0-preview1 as a problem some of the dependencies
for the transformer-rb and informers-rb gems


curl -L https://download.pytorch.org/libtorch/cpu/libtorch-macos-arm64-2.4.1.zip > libtorch.zip
unzip -q libtorch.zip

The in ~/lib do ...
ln -s path/to/libtorch

bundle config build.torch-rb --with-torch-dir=~/lib/libtorch

