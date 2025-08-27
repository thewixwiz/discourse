# Discourse on Render – production image (Rails 8 + pnpm)
FROM ruby:3.2-bullseye

# OS deps Discourse needs
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
  build-essential git curl ca-certificates gnupg2 \
  postgresql-client \
  imagemagick libjpeg-dev libpng-dev libpq-dev \
  libxslt1-dev libxml2-dev zlib1g-dev \
  nodejs npm && \
  rm -rf /var/lib/apt/lists/*

# Enable pnpm via Corepack (bundled with Node)
RUN corepack enable && corepack prepare pnpm@9 --activate

WORKDIR /app

# --- Ruby deps (cache layer) ---
COPY Gemfile Gemfile.lock ./
RUN bundle config set deployment 'true' && \
    bundle config set without 'development test' && \
    bundle install --jobs=4 --retry=3

# --- JS deps (cache layer) ---
# NOTE: Discourse uses pnpm (pnpm-lock.yaml), not yarn
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

# --- App code & assets ---
COPY . .

ENV RAILS_ENV=production NODE_ENV=production \
    RAILS_LOG_TO_STDOUT=1 RAILS_SERVE_STATIC_FILES=1

# Use a dummy secret only for asset build
RUN SECRET_KEY_BASE=dummy bundle exec rake assets:precompile

# Web entrypoint (Render overrides with dockerCommand in render.yaml)
CMD ["bash", "-lc", "bundle exec puma -C config/puma.rb"]
