# Building from Source

## Pre-requisites

The CLI is written entirely in [Ruby](https://www.ruby-lang.org/en/). The
supported version is 2.7.

You can also choose to use any env managers like
[rbenv](https://github.com/rbenv/rbenv), [rvm](https://rvm.io/),
[asdf](https://asdf-vm.com/), [chruby](https://github.com/postmodern/chruby),
etc.

To clone the repository, follow the steps below:

```bash
brew install ruby@2.7 # Install ruby (This only works for MacOS/Linux)
git clone https://github.com/c477y/xxx_rename.git
cd xxx_rename
```

## Environment

I cannot vouch for Windows, as this CLI is tested to work on Linux and MacOS,
but the test coverage should allow you to test for any errors.

## Build

Run the setup script to build the gem and its dependencies.

```bash
./bin/setup
```

To install the gem to your local machine.

```bash
./bin/install
```

## Run tests

Run the `rake` command to run the tests and lint the project using Rubocop.
