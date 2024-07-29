ARG RUBY_VERSION=3.3
FROM ruby:$RUBY_VERSION

COPY Gemfile Gemfile.lock ./
RUN bundle install

WORKDIR /src/site

CMD ["bundle", "exec", "jekyll", "serve", "--livereload", "-H", "0.0.0.0", "-P", "4000"]
