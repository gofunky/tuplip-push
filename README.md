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
    - uses: satackey/action-docker-layer-caching@master
    - name: build docker image
      uses: gofunky/tuplip-push@master
      with:
        buildOnly: true
        rootVersion: 'latest'
        exclusiveLatest: true
```

### tuplip push latest

This is a typical example for a master branch push workflow - having a Dockerfile in the root of the repository.

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
    - uses: satackey/action-docker-layer-caching@master
    - name: build docker image
      uses: gofunky/tuplip-push@master
      with:
        buildOnly: true
        rootVersion: 'latest'
        exclusiveLatest: true
```
