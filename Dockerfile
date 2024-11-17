FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y \
    ruby-full \
    build-essential \
    zlib1g-dev

RUN echo "# Install Ruby Gems to ~/gem'" >> ~/.bashrc && \
    echo "export GEM_HOME='$HOME/gems'" >> ~/.bashrc && \
    echo "export PATH='$HOME/gems/bin:$PATH'" >> ~/.bashrc && \
    . ~/.bashrc

RUN gem install jekyll bundler