FROM ruby:3.3.0-slim-bullseye

ENV DOCKER_ENV=1

RUN apt-get update -y && \
    apt-get install -y \
    git \
    build-essential

WORKDIR /app

COPY xxx_rename.gemspec Gemfile Gemfile.lock ./
COPY lib/xxx_rename/version.rb ./lib/xxx_rename/

RUN bundle install

CMD ["bash"]
