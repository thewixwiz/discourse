# Build a production image for the Discourse Rails app
FROM ruby:3.2-bullseye

# System deps
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
  build-essential git curl gnupg2 ca-certificates \
  postgresql-client \
  imagemagick libjpeg-dev libpng-dev libpq-dev \
  libxslt1-dev libxml2-dev zlib1g-dev \
  nodejs npm && \
  npm install -g yarn && \
  rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Cache Ruby/JS installs
COPY Gemfile Gemfile.lock package.json yarn.lock ./
RUN bundle config set deployment 'true' && \
    bundle config set without 'development test' && \
    bundle install --jobs=4 --retry=3
RUN yarn install --frozen-lockfile

# Copy app
COPY . .

# Precompile assets (Render uses ephemeral FS)
ENV RAILS_ENV=production NODE_ENV=production
RUN SECRET_KEY_BASE=dummy bundle exec rake assets:precompile

# Default command (overridden per service in render.yaml)
CMD ["bash", "-lc", "bundle exec puma -C config/puma.rb"]
