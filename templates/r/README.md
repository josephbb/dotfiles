# R + Quarto template

Occasional **R** workflow: nix provides `R` + `quarto`; **renv** manages project packages. RStudio is already installed via the machine flake (Homebrew).

## Create a project

```bash
nix flake new -t ~/dotfiles#r ~/Projects/tidyverse-scratch
cd ~/Projects/tidyverse-scratch
direnv allow
```

Then in R (or RStudio opened on this folder):

```r
renv::init()
install.packages(c("tidyverse", "here", "rmarkdown"))
renv::snapshot()
```

```bash
quarto preview analysis.qmd
```

## Layout

```text
analysis.qmd
.Rprofile          # sources renv/activate.R after renv::init()
renv/              # created by renv::init()
flake.nix
```

Keep large data under `~/Datasets`, not in the repo.
