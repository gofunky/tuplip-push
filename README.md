# tuplip build and push action
[GitHub Action](https://github.com/features/actions) that uses [tuplip](https://github.com/gofunky/tuplip) to build and push a single given Dockerfile 
to the Docker hub.

## Examples

### tuplip build

This is a typical example for a pull request workflow - having a Dockerfile in the root of the repository.

```yaml
name: build
on:
  pull_request:
    branches: [ master ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - uses: satackey/action-docker-layer-caching@v0
    - name: build docker image
      uses: gofunky/tuplip-push@v0
      with:
        buildOnly: true
        cacheFile: 'cache.tar'
```

### tuplip push latest

This is a typical example for a master branch push workflow - having a Dockerfile in the root of the repository.

```yaml
name: build
on:
  push:
    branches: [ master ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - uses: satackey/action-docker-layer-caching@v0
    - name: cache internal layers
      uses: actions/cache@v2
      with:
        path: 'cache.tar'
        key: docker-internal-layers-${{ github.workflow }}-
    - name: build docker image
      uses: gofunky/tuplip-push@v0
      with:
        cacheFile: 'cache.tar'
        rootVersion: 'latest'
        exclusiveLatest: true
```
