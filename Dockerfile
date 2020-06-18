FROM ruby:2.7.1-alpine

RUN apk add --update \
  build-base \
  git \
  && rm -rf /var/cache/apk*

RUN gem update --system

RUN gem install bundler -v 2.1.4

WORKDIR /myapp

COPY Gemfile* /myapp/

RUN bundle install

COPY . /myapp/

CMD /bin/sh -c "ruby bin/run.rb"
