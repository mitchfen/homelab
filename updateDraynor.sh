#!/bin/bash
sudo nix-channel --update
sudo nixos-rebuild switch
sudo k3s crictl rmi --prune
