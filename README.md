# Building unix-like operating systems the nix way

Presentation for OpenFest 2025

## Build presentation

```sh
nix build
```

## Run locally

```sh
python -m http.server 8000 -d result/
```

open http://localhost:8000 in your browser and press `s` to activate 'speaker notes'

## GitHub Pages Deployment

This repository is configured with GitHub Actions to automatically build and deploy the presentation to GitHub Pages on every push to the `main` branch.

The presentation will be available at: 
[https://gotha.github.io/building-unixlike-os-nix-way-openfest-2025-presentation](https://gotha.github.io/building-unixlike-os-nix-way-openfest-2025-presentation)
