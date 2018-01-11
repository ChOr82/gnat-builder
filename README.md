# gnat-builder
Makefile for downloading and building gnat from github source.

## Overview

This is a Makefile and a set of patches to build a gcc/gnat tool chain including gcc compiler, libraries, and GPS IDE.

## Typical usage

### Starting from scratch, download and install a recent release
* \# install debian stretch with desktop and standard package options
* \#(other debian based linux distributions may work also)
* sudo mkdir -p /usr/local/gnat
* \# change ownership so that we don't have to deal with sudo and secured path. Replace steve with a local user name.
* sudo chown steve/steve /usr/local/gnat
* sudo apt-get install build-essential git
* git clone https://github.com/steve-cs/gnat-builder.git
* cd gnat-builder
* sudo make prerequisites-install
* \# prerequisites done, let's do the actual work.
* make release-download
* make release-install

### Bootstrap from source (not requiring a prexisting release or gpl-2017 binaries)

This starts from linux distribution gcc/gnat compiler and bootstraps a new compiler, ada tool chain, and gps.  The first time you bootstrap the gcc compiler it may take some time as it downloads the entire github/gcc-mirror/gcc repository and then does an enable-bootstrap (build the compiler three times) build.

After doing the prerequisites above it should be as simple as:

* make bootstrap-clean
* make bootstrap-install

### Build and install the development trunk of gcc

After doing (at least) the prerequisites above:

* make gcc-version=trunk gcc
* make gcc-install

### Build and install Adacore open source

After installing a release or bootstrap:

* make all
* make all-install

-or simply-

* make
* make install

### Saving and installing a local release/snapshot

Save a snapshot of the contents of the prefix as a locally defined release.  Change \<my-release-id\>.  It ends up being both part of a directory name and part of a filename, so no spaces, "/", or other special characters. If release= isn't specified it will repace the default release in the local cache.

* \# save a release
* make release=\<my-release-id\> release

* \# re-install a release
* make release=\<my-release-id\> release-install

## Variables and their current defaults

### release ?= \<latest-release\>, e.g. 0.1.0-20180109

This is used by the release, release-download, and release-install targets.

### gcc-version ?= gcc-7-branch

This is either a tag or a branch of gcc as it exists in the github.com gcc-mirror/gcc repository.
Currently this is limited to: master, trunk, gcc-7-branch, gcc-7_2_0-release.

### adacore-version ?= master

Currently this is limited to master.

### prefix ?= /usr/local/gnat

This specifies where the build tools directory is or will be located.  Its contents are deleted by a number of targets including prefix-clean, bootstrap-clean and release-install.

## Main make targets

### default, all, install, all-install, bootstrap-install

### prerequisites-install

### release, release-install, release-download

### clean, dist-clean, bootstrap-clean, prefix-clean

## Individual component make targets 

### gcc, gcc-bootstrap, gcc-install, gcc-clean

### gprbuild-bootstrap-install, xmlada-bootstrap-clean, gprbuild-bootstrap-clean

### xmlada, xmlada-install, xmlada-clean

### gprbuild, gprbuild-install, gprbuild-clean

### gnatcoll-core, gnatcoll-core-install, gnatcoll-core-clean

### gnatcoll-bindings, gnatcoll-bindings-install, gnatcoll-bindings-clean

### gnatcoll-gnatcoll_db2ada, gnatcoll-gnatcoll_db2ada-install, gnatcoll-gnatcoll_db2ada-clean

### gnatcoll-sqlite, gnatcoll-sqlite-install, gnatcoll-sqlite-clean

### gnatcoll-xref, gnatcoll-xref-install, gnatcoll-xref-clean

### gnatcoll-gnatinspect, gnatcoll-gnatinspect-install, gnatcoll-gnatinspect-clean

### libadalang, libadalang-install, libadalang-clean

### gtkada, gtkada-install, gtkada-clean

### gps, gps-install, gps-clean
