#!/bin/bash

# Alias ords so we don't get that annoying warning about not specifying --config
# each time.
grep 'alias ords' ~/.bashrc || echo "alias ords='ords --config /etc/ords/config'" >> ~/.bashrc
