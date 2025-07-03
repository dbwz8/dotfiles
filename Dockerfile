# This Dockerfile builds an image to test or use the shell environment defined
# in the basnijholt/dotfiles repository (https://github.com/basnijholt/dotfiles).
# It replicates the cross-platform shell configuration described in the README.

FROM ubuntu:25.04

# Install git and zsh (only Git is required!)
RUN apt-get update && apt-get install -y git zsh

# Clone the dotfiles repository using HTTPS instead of SSH
RUN git config --global url."https://github.com/".insteadOf git@github.com:

# Clone the dotfiles repository
RUN git clone https://github.com/dbwz9/dotfiles.git ~/git/dotfiles

# Initialize submodules and skip the private 'secrets' submodule
RUN cd ~/git/dotfiles && \
    git submodule init && \
    git config submodule.secrets.update none && \
    git submodule update --init --recursive --jobs 8

# Install the dotfiles
RUN cd ~/git/dotfiles && ./install || true

# Set the working directory and entrypoint
WORKDIR /root/dotfiles
CMD ["/bin/zsh"]
