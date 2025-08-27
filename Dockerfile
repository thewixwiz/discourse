# Discourse on Render (Rails + Node w/ Corepack)
FROM ruby:3.2-bullseye

# OS deps
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
  build-essential git curl ca-certificates gnupg2 \
  postgresql-client \
  imagemagick libjpeg-dev libpng-dev libpq-dev \
  libxslt1-dev libxml2-dev zlib1g-dev

# Install official Node 20 (includes Corepack)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
 && apt-get install -y nodejs

# Enable pnpm via Corepack
RUN corepack enable && corepack prepare pnpm@9 --activate

WORKDIR /app

# Ruby deps
COPY Gemfile Gemfile.lock ./
RUN bundle config set deployment 'true' \
 && bundle config set without 'development test' \
 && bundle install --jobs=4 --retry=3

# JS deps (pnpm)
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

# App & assets
COPY . .
ENV RAILS_ENV=production NODE_ENV=production RAILS_LOG_TO_STDOUT=1 RAILS_SERVE_STATIC_FILES=1
RUN SECRET_KEY_BASE=dummy bundle exec rake assets:precompile

CMD ["bash", "-lc", "bundle exec puma -C config/puma.rb"]
