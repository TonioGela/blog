# prints this list
default:
    @just --list --unsorted

# Serves the site with auto-reloading
serve:
    zola serve --drafts

# Serves the site with auto-reloading and opens it in browser
open:
    zola serve --drafts --open

# Serves the site with auto-reloading but only rebuilds the minimum on change and then opens it in browser
fastOpen:
    zola serve --drafts --fast --open
