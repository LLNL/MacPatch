LLNL Standard Web Template Staticfiles
======================================

Maintainer: Ian Lee <ian@llnl.gov>

This repository is meant to be the base for hosting the common web template
static files (css, js, imgs, fonts, etc) for LLNL webpages. Keeping these
static files in a clearly separated fashion allows them to be re-used and
plugged into other theme and template frameworks. The following are a list of a
few such frameworks in use at the laboratory:

* [Django LLNL Theme](https://mystash.llnl.gov/projects/LWDS/repos/django-llnl-theme/browse)
* [Jekyll LLNL Theme](https://mystash.llnl.gov/projects/LWDS/repos/jekyll-llnl-theme/browse)
* [Drupal LLNL Theme](https://mystash.llnl.gov/projects/LWDS/repos/drupal-llnl-theme/browse)
* ReadTheDocs

Getting Started
---------------

The easiest way to get started using these static files is either to clone
this repository into the tree of your downstream codebase (e.g. django app), or
to copy the files from this repo into the downstream codebase.

A better, though slightly more complicated method is to use the
[git-subtree](https://help.github.com/articles/about-git-subtree-merges/)
approach to maintain consistency with this upstream repo. This approach is
preferred, as it allows each down stream dependency to decide when to migrate
to newer versions of these base static files.

A possible method to get these files incorporated into a downstream project is:

    $ cd downstream-project  # Assumed to already be a git repo
    $ git remote add -f llnl-theme ssh://git@mystash.llnl.gov:7999/lwds/llnl-theme.git
    $ git subtree add -P static/ llnl-theme master

This will create a new directory `static/` in your `downstream-project` which
will contain the history of the llnl-theme repo (this repo).

Versioning
----------

For consistency with the existing [OneLab Template](https://onelab.llnl.gov),
the initial rip from that theme of these static files is defined to be version
1.0.

Version 2.0 and above of this repository are designed to diverge and be an
evolution of the OneLab template, migrating to newer web standards, such as
Bootstrap 3.
