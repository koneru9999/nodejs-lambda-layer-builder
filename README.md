# nodejs-lambda-layer-builder

Creates an AWS Lambda Layers structure that is **optimized** for: [Lambda Layer directory structure](https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html#configuration-layers-path), compiled library compatibility, and minimal file size.

**Note: This script requires Docker and uses a container to mimic the Lambda environment.**

## Features

- Builds either a zip file or a raw directory strucutre (e.g. if you want to use frameworks like Serverless for packaging) containing Python dependencies and places the libraries into the proper directory structure for lambda layers
- Ensures compiled libraries are compatible with Lambda environment by using the [lambci/lambda](https://hub.docker.com/r/lambci/lambda) Docker container that mimics the lambda runtime environment
- Allows specifying AWS Lambda supported Node versions: 8.10, 10.x and 12.x
- Automatically searches for `package.json` file in several locations:
  - Same directory as script
  - Parent directory or script (useful when used as submodule)
  - Function sub-directory of the parent directory

## Installation

This function can be **cloned** for standalone use, into a parent repo or added as a **submodule**.

Clone for standalone use or within a repo:

``` bash
# If installing into an exisiting repo, navigate to repo dir
git clone --depth 1 https://github.com/tobilg/nodejs-lambda-layer-builder _build_layer
```

Alternatively, add as a submodule:

``` bash
cd {repo root}
git submodule add https://github.com/tobilg/nodejs-lambda-layer-builder _build_layer
# Update submodule
git submodule update --init --recursive --remote
```

## Usage

```text
$ ./build.sh -h
AWS Lambda Layer Builder for Node libraries

Usage: build.sh [-l NODEJS_RUNTIME_VERSION] [-n NAME] [-r] [-h] [-v]
  -l NODEJS_RUNTIME_VERSION     : Node runtime version to use: 8.10, 10.x, 12.x (default 10.x)
  -n NAME                       : Name of the layer
  -r                            : Raw mode, don't zip layer contents
  -h                            : Help
  -v                            : Display build.sh version
```

- Run the builder with the command `./build.sh`
  - or `_build_layer/build.sh` if installed in sub-dir
- It uses the first requirements.txt file found in these locations (in order):
  - Same directory as script
  - Parent directory of script (useful when used as submodule)
  - Function sub-directory of the parent directory (useful when used as submodule)
- Optionally specify the Node runtime Version
  - `-l NODEJS_RUNTIME_VERSION` Node runtime version to use: 8.10, 10.x, 12.x (default 10.x)

### Custom cleaning logic

You can edit the `_clean.sh` file if you want to add custom cleaning logic for the build of the Lambda layer. The above part of the file must stay intact:

```bash
#!/usr/bin/env bash
# Change to working directory
cd $1
# ----- DON'T CHANGE THE ABOVE -----

# Cleaning statements
# ----- CHANGE HERE -----
rm test.xt
```

The `_make.sh` script will then execute the commands after the Python packages have been installed.

## Uninstall

If installed as submodule and need to be removed:

```bash
# Remove the submodule entry from .git/config
git submodule deinit -f $submodulepath
# Remove the submodule directory from the superproject's .git/modules directory
rm -rf .git/modules/$submodulepath
# Remove the entry in .gitmodules and remove the submodule directory located at path/to/submodule
git rm -f $submodulepath
# remove entry in submodules file
git config -f .git/config --remove-section submodule.$submodulepath
```