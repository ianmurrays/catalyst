# Make sure RUBY_VERSION matches the Ruby version in .ruby-version
ARG RUBY_VERSION=3.4.5
FROM ghcr.io/rails/devcontainer/images/ruby:$RUBY_VERSION

RUN mkdir -p /home/vscode/.claude && \
  chown -R vscode:vscode /home/vscode/.claude
