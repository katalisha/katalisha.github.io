ARG RUBY_VERSION=3.3
FROM ruby:$RUBY_VERSION

COPY Gemfile Gemfile.lock ./
RUN bundle install

WORKDIR /src/site

CMD ["bundle", "exec", "jekyll", "serve", "--livereload", "-H", "0.0.0.0", "-P", "4000"]


# docker run --rm -it -p 4000:4000 --volume="$(pwd):/src/site"  9e3abcad35a5cb8e bash
