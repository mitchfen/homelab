# Convenience script to copy the configuration.nix to draynor
scp "$(pwd)/configuration.nix" draynor.home:~/

echo "Successfully copied configuration.nix to draynor.home:~/"
