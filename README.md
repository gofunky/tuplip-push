# tuplip build and push action
A [GitHub Action](https://github.com/features/actions) that uses [tuplip](https://github.com/gofunky/tuplip) to build and push a single given Dockerfile 
to the Docker Hub.

## What does it do?

This action not only builds and pushes Docker images to the Docker Hub.
Unlike the default `docker push`, it uses tuplip to apply Docker tags in a transparent and convention-forming way.
In other words, tuplip creates a complete set of tags that project all dependencies (e.g. the alpine version) 
and their versions into the implicit tagging convention that is widely adopted today.
This is crucial for a reliable and transparent modeling of the security state of an image
so that insecure dependencies can be detected from day zero, given any image that includes the appropriate tags.
Most Docker images only include few dependencies in their tags or don't even provide regular updates.
Tuplip makes this detectable for all included dependencies and for any subset of dependencies that come to use.

## Examples

### tuplip build

This is a typical example for a pull request workflow - having a Dockerfile in the root of the repository.

```yaml
name: build
on:
  pull_request_target:
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
```

### tuplip build and push latest

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
    - name: build and push latest docker image
      uses: gofunky/tuplip-push@v0
      with:
        rootVersion: 'latest'
        username: ${{ secrets.DOCKER_USR }}
        password: ${{ secrets.MY_SECRET_DOCKER_TOKEN }}
```

### tuplip build and push release

This is a typical example for a release workflow - having a Dockerfile in the root of the repository.

```yaml
name: publish
on:
  release:
    types:
      - published

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - uses: satackey/action-docker-layer-caching@v0
    - name: release Docker image
      uses: gofunky/tuplip-push@v0
      with:
        rootVersion: ${{ github.ref }}
        username: ${{ secrets.DOCKER_USR }}
        password: ${{ secrets.MY_SECRET_DOCKER_TOKEN }}
```

### tuplip with all possible inputs

This lists all possible input arguments for this action.

```yaml
name: build
on:
  push:
    branches: [ alpine ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - name: cache docker layers
      uses: satackey/action-docker-layer-caching@v0
      with:
        key: docker-layers-${{ github.workflow }}-${{ hashFiles('**/alpine.Dockerfile') }}
    - name: build and push latest docker image
      uses: gofunky/tuplip-push@v0
      env:
        dep: ${{ steps.previous.outputs.dep_version }}
      with:
        sourceTag: ''
        buildOnly: ''
        buildArgs: 'dep'
        repository: 'different/repo'
        path: './subdirectory'
        dockerfile: 'alpine.Dockerfile'
        username: ${{ secrets.DOCKER_USR }}
        password: ${{ secrets.MY_SECRET_DOCKER_TOKEN }}
        excludeMajor: 'true'
        excludeMinor: ''
        excludeBase: ''
        addLatest: 'true'
        exclusiveLatest: ''
        rootVersion: 'latest'
        straight: ''
        filter: |
          dep
          alpine
```
