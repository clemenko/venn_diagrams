#!/bin/bash
docker run --rm -i -v $HOME/pki:$HOME/pki -v $HOME/.supernova:/.supernova -v /opt:/opt supernova "$@"
