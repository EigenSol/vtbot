# vtbot

Static GitHub Pages deployment repo for the VTB frontend clone served at:

- `https://src-assistant.github.io/vtbot`

Repository flow:

- source repo: `EigenSol/vtbot`
- mirrored target: `SRC-Assistant/vtbot`
- Pages publish runs only in the mirrored target repo

Contents:

- `site/` holds the prepared static frontend bundle
- `.github/workflows/mirror.yml` mirrors this repo into `SRC-Assistant/vtbot`
- `mirror-overrides/github-pages.workflow.yml` is injected only into the mirrored repo as `.github/workflows/github-pages.yml`

Do not put the GitHub Pages workflow directly under `.github/workflows/` in this source repo. The mirror script injects it into the target repo to avoid direct workflow-file pushes from the private source repo.
