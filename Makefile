
include config.mk

# version = master
# gcc-version = master, trunk, gcc-8-branch gcc-7-branch, gcc-7_2_0-release
# prefix = /usr/local/gnat, /usr/gnat, etc.

release ?= 0.1.0-20181101
gcc-version ?= gcc-8-branch
adacore-version ?= master
libadalang-version ?= master
prefix ?= /usr/local/gnat

# Ubuntu bionic configuration
#
llvm-version ?= 6.0
iconv-opt ?= "-lc"

# gcc configuration
#
host  ?= x86_64-linux-gnu
build ?= $(host)
target ?= $(build)
gcc-jobs ?= 8
gcc-bootstrap ?= enable

# release location and naming details
#
release-loc = release
release-url = https://github.com/steve-cs/gnat-builder/releases/download
release-tag = v$(release)
release-name = gnat-build_tools-$(release)

.PHONY: default
default: all

.PHONY: install
install: all-install

##############################################################
#
# P A T C H E S
#

#
# E N D   P A T C H E S
#
##############################################################

.PHONY: prerequisites-install
prerequisites-install:
	apt-get -qq -y install \
	ubuntu-standard build-essential gnat gawk git flex bison \
	libgmp-dev zlib1g-dev libreadline-dev postgresql libpq-dev 
	pkg-config libglib2.0-dev libpango1.0-dev libatk1.0-dev libgtk-3-dev \
	python-dev python-pip python-gobject-2-dev python-cairo-dev \
	libclang-dev

.PHONY: release
release: $(release-name)

.PHONY: $(release-name)
$(release-name):
	mkdir -p $(release-loc)
	cd $(release-loc) && rm -rf $@ $@.tar.gz
	mkdir -p $(release-loc)/$@
	cp -r $(prefix)/* $(release-loc)/$@/
	cd $(release-loc) && tar czf $@.tar.gz $@

.PHONY: release-install
release-install: prefix-clean
	cp -a $(release-loc)/$(release-name)/* $(prefix)/

.PHONY: release-download
release-download: $(release-loc)/$(release-name)

$(release-loc)/$(release-name):
	rm -rf $@ $@.tar.gz
	mkdir -p $(@D)
	cd $(@D) && wget -q $(release-url)/$(release-tag)/$(@F).tar.gz
	cd $(@D) && tar xf $(@F).tar.gz

.PHONY: clean
clean: 
	rm -rf *-src *-build

.PHONY: dist-clean
dist-clean : clean
	rm -rf downloads github-repo build-cache release

%-clean:
	rm -rf $(@:%-clean=%)-src $(@:%-clean=%)-build

.PHONY: bootstrap-clean
bootstrap-clean: clean prefix-clean build-cache-clean

.PHONY: prefix-clean
prefix-clean:
	rm -rf $(prefix)/*
	mkdir -p $(prefix)

.PHONY: bootstrap-install
bootstrap-install: |                                      \
gcc-bootstrap-install                                     \
gprbuild-bootstrap-install                                \
gnatcoll-bootstrap-install                                \
gps-bootstrap-install

.PHONY: gcc-bootstrap-install
gcc-bootstrap-install: |                                  \
gcc gcc-install

.PHONY: gprbuild-bootstrap-install
gprbuild-bootstrap-install: |                             \
gprbuild-bootstrap                                        \
xmlada xmlada-install                                     \
gprbuild gprbuild-install

.PHONY: gnatcoll-bootstrap-install
gnatcoll-bootstrap-install: |                             \
gnatcoll-core gnatcoll-core-install                       \
gnatcoll-bindings gnatcoll-bindings-install               \
gnatcoll-sql gnatcoll-sql-install                         \
gnatcoll-gnatcoll_db2ada gnatcoll-gnatcoll_db2ada-install \
gnatcoll-sqlite gnatcoll-sqlite-install                   \
gnatcoll-xref gnatcoll-xref-install                       \
gnatcoll-gnatinspect gnatcoll-gnatinspect-install         \
gnatcoll-db

.PHONY: gps-bootstrap-install
gps-bootstrap-install: |                                  \
libadalang libadalang-install                             \
gtkada gtkada-install                                     \
gps gps-install

.PHONY: all
all: |                   \
xmlada                   \
gprbuild                 \
gnatcoll-core            \
gnatcoll-bindings        \
gnatcoll-db              \
libadalang               \
gtkada                   \
gps

.PHONY: all-src
all-src: |               \
gcc-src                  \
xmlada-src               \
gprbuild-src             \
gnatcoll-core-src        \
gnatcoll-bindings-src    \
gnatcoll-db-src          \
langkit-src              \
quex-src                 \
libadalang-src           \
gtkada-src               \
gps-src

.PHONY: all-install
all-install: |                   \
xmlada-install                   \
gprbuild-install                 \
gnatcoll-core-install            \
gnatcoll-bindings-install        \
gnatcoll-db-install              \
libadalang-install               \
gtkada-install                   \
gps-install

##############################################################
#
# * - S R C
#

# most %-src are just symbolic links to their dependents

%-src:
	if [ "x$<" = "x" ]; then false; fi
	ln -s $< $@

# downloads

downloads/quex-0.65.4:
	mkdir -p $(@D)
	cd $(@D) && rm -rf $(@F) $(@F).tar.gz
	cd $(@D) && wget https://phoenixnap.dl.sourceforge.net/project/quex/HISTORY/0.65/$(@F).tar.gz
	cd $(@D) && tar xf $(@F).tar.gz

# from github

gcc-src: github-src/gcc-mirror/gcc/$(gcc-version)
	ln -s $(PWD)/$< $@
	cd $@ && ./contrib/download_prerequisites

xmlada-src: github-src/adacore/xmlada/$(adacore-version)
gprbuild-src: github-src/adacore/gprbuild/$(adacore-version)
gtkada-src: github-src/adacore/gtkada/$(adacore-version)
gnatcoll-core-src: github-src/adacore/gnatcoll-core/$(adacore-version)
gnatcoll-bindings-src: github-src/adacore/gnatcoll-bindings/$(adacore-version)
gnatcoll-db-src: github-src/adacore/gnatcoll-db/$(adacore-version)
langkit-src: github-src/adacore/langkit/$(libadalang-version)
libadalang-src: github-src/adacore/libadalang/$(libadalang-version)
libadalang-tools-src: github-src/adacore/libadalang-tools/$(libadalang-version)
gps-src: github-src/adacore/gps/$(adacore-version)

quex-src: downloads/quex-0.65.4

# aliases to other %-src

xmlada-bootstrap-src: xmlada-src
gprbuild-bootstrap-src: gprbuild-src

# linking github-src/<account>/<repository>/<branch> from github
# get the repository, update it, and checkout the requested branch

# github branches where we want to pull updates if available
#
github-src/%/stable-gps        \
github-src/%/0.65.4            \
github-src/%/gcc-7-branch      \
github-src/%/gcc-8-branch      \
github-src/%/trunk             \
github-src/%/master: github-repo/%
	cd github-repo/$(@D:github-src/%=%) && git checkout -f $(@F)
	cd github-repo/$(@D:github-src/%=%) && git pull
	rm -rf $(@D)/*
	mkdir -p $(@D)
	ln -sf $(PWD)/github-repo/$(@D:github-src/%=%) $@

# github tags, e.g. releases, which don't have updates to pull
#
github-src/%/gcc-7_2_0-release: github-repo/%
	cd github-repo/$(@D:github-src/%=%) && git checkout -f $(@F)
	rm -rf $(@D)/*
	mkdir -p $(@D)
	ln -sf $(PWD)/github-repo/$(@D:github-src/%=%) $@


# Clone github-repo/<account>/<repository> from github.com

.PRECIOUS: github-repo/%
github-repo/%:
	rm -rf $@
	mkdir -p $(@D)
	cd $(@D) && git clone https://github.com/$(@:github-repo/%=%).git
	touch $@

#
# * - S R C
#
##############################################################
#
# * - B U I L D
#

.PHONY: build-cache-clean
build-cache-clean:
	rm -rf build-cache

.PRECIOUS: build-cache/%
build-cache/%: 
	mkdir -p $@

%-build: build-cache/% %-src
	mkdir -p $@
	rsync -a --delete $</ $@
	rsync -aL --exclude='.*' $(@:%-build=%)-src/* $@

gcc-build: gcc-src
	mkdir -p $@

#
# * - B U I L D
#
##############################################################
#
#

.PHONY: %-install
%-install: %-build
	make -C $< prefix=$(prefix) install

.PHONY: gcc
gcc: gcc-build gcc-src
	rm -rf $</*
	cd $< && ../gcc-src/configure \
	--host=$(host) --build=$(build) --target=$(target) \
	--prefix=$(prefix) --enable-languages=c,c++,ada \
	--$(gcc-bootstrap)-bootstrap --disable-multilib \
	--enable-shared --enable-shared-host
	cd $<  && make -j$(gcc-jobs)

.PHONY: gprbuild-bootstrap
gprbuild-bootstrap: gprbuild-bootstrap-build xmlada-bootstrap-build
	cd $<  && ./bootstrap.sh \
	--with-xmlada=../xmlada-bootstrap-build --prefix=$(prefix)

.PHONY: xmlada
xmlada: xmlada-build
	cd $< && ./configure --prefix=$(prefix)
	make -C $< all
	rsync -a --delete $</ build-cache/$@

.PHONY: gprbuild
gprbuild: gprbuild-build
	make -C $< prefix=$(prefix) setup
	make -C $< all
	make -C $< libgpr.build
	rsync -a --delete $</ build-cache/$@

.PHONY: gprbuild-install
gprbuild-install: gprbuild-build
	make -C $< install
	make -C $< libgpr.install

.PHONY: gnatcoll-core
gnatcoll-core: gnatcoll-core-build
	make -C $< setup
	make -C $<
	rsync -a --delete $</ build-cache/$@

.PHONY: gnatcoll-core-install
gnatcoll-core-install: gnatcoll-core-build
	make -C $< prefix=$(prefix) install

.PHONY: gnatcoll-bindings
gnatcoll-bindings: gnatcoll-bindings-build
	cd $</gmp && ./setup.py build
	cd $</iconv && export GNATCOLL_ICONV_OPT=$(iconv-opt) && ./setup.py build
	cd $</python && ./setup.py build
	cd $</readline && ./setup.py build --accept-gpl
	cd $</syslog && ./setup.py build
	rsync -a --delete $</ build-cache/$@

.PHONY: gnatcoll-bindings-install
gnatcoll-bindings-install: gnatcoll-bindings-build
	cd $</gmp && ./setup.py install
	cd $</iconv && export GNATCOLL_ICONV_OPT=$(iconv-opt) && ./setup.py install
	cd $</python && ./setup.py install
	cd $</readline && ./setup.py install
	cd $</syslog && ./setup.py install

.PHONY: gnatcoll-db
gnatcoll-db: |                \
gnatcoll-sql                  \
gnatcoll-gnatcoll_db2ada      \
gnatcoll-sqlite               \
gnatcoll-xref                 \
gnatcoll-gnatinspect
	rsync -a --delete $@-build/ build-cache/$@

.PHONY: gnatcoll-db-install
gnatcoll-db-install: |           \
gnatcoll-sql-install             \
gnatcoll-gnatcoll_db2ada-install \
gnatcoll-sqlite-install          \
gnatcoll-xref-install            \
gnatcoll-gnatinspect-install

.PHONY: \
gnatcoll-sql gnatcoll-sql-install                         \
gnatcoll-gnatcoll_db2ada gnatcoll-gnatcoll_db2ada-install \
gnatcoll-sqlite gnatcoll-sqlite-install                   \
gnatcoll-xref gnatcoll-xref-install                       \
gnatcoll-gnatinspect gnatcoll-gnatinspect-install

gnatcoll-sql             \
gnatcoll-gnatcoll_db2ada \
gnatcoll-sqlite          \
gnatcoll-xref            \
gnatcoll-gnatinspect: gnatcoll-db-build
	make -C $</$(@:gnatcoll-%=%) setup
	make -C $</$(@:gnatcoll-%=%)

gnatcoll-sql-install             \
gnatcoll-gnatcoll_db2ada-install \
gnatcoll-sqlite-install          \
gnatcoll-xref-install            \
gnatcoll-gnatinspect-install: gnatcoll-db-build
	make -C $</$(@:gnatcoll-%-install=%) install

.PHONY: libadalang
libadalang: libadalang-build langkit-build quex-src
	cd $< && virtualenv lal-venv
	cd $< && . lal-venv/bin/activate \
	&& pip install -r REQUIREMENTS.dev \
	&& mkdir -p lal-venv/src/langkit \
	&& rm -rf lal-venv/src/langkit/* \
	&& cp -a ../langkit-build/* lal-venv/src/langkit \
	&& export QUEX_PATH=$(PWD)/quex-src \
	&& ada/manage.py make \
	&& deactivate
	rsync -a --delete $@-build/ build-cache/$@

.PHONY: libadalang-install
libadalang-install: libadalang-build clean-libadalang-prefix
	cd $< && . lal-venv/bin/activate \
	&& export QUEX_PATH=$(PWD)/quex-src \
	&& ada/manage.py install $(prefix) \
	&& deactivate


.PHONY: clean-libadalang-prefix
clean-libadalang-prefix:
	# clean up old langkit install if there
	rm -rf $(prefix)/include/langkit*
	rm -rf $(prefix)/lib/langkit*
	rm -rf $(prefix)/share/gpr/langkit*
	rm -rf $(prefix)/share/gpr/manifests/langkit*
	# clean up old libadalang install if there
	rm -rf $(prefix)/include/libadalang*
	rm -rf $(prefix)/lib/libadalang*
	rm -rf $(prefix)/share/gpr/libadalang*
	rm -rf $(prefix)/share/gpr/manifests/libadalang*
	rm -rf $(prefix)/python/libadalang*
	# clean up old Mains project if there
	rm -rf $(prefix)/share/gpr/manifests/mains
	rm -rf $(prefix)/bin/parse
	rm -rf $(prefix)/bin/navigate
	rm -rf $(prefix)/bin/gnat_compare
	rm -rf $(prefix)/bin/nameres

.PHONY: gtkada
gtkada: gtkada-build
	cd $< && ./configure --prefix=$(prefix)
	make -C $< PROCESSORS=0
	rsync -a --delete $</ build-cache/$@

.PHONY: gps
gps: gps-build
	cd $< && ./configure \
	--prefix=$(prefix) \
	--with-clang=/usr/lib/llvm-$(llvm-version)/lib/ 
	make -C $< PROCESSORS=0
	mkdir -p build-cache/$@
	rsync -a --delete $</ build-cache/$@

gps-build: build-cache/gps gps-src libadalang-tools-build
	mkdir -p $@  $@/laltools
	rsync -a --delete $</ $@
	rsync -aL --exclude='.*' $(@:%-build=%)-src/* $@
	rsync -aL libadalang-tools-build/ $@/laltools

.PHONY: gps-install
gps-install: gps-build
	make -C $< prefix=$(prefix) install
	# patch to disable lal support at runtime
	cd $(prefix)/share/gps/support/core/                \
	&& rm -rf lal.py-disable                            \
	&& mv lal.py lal.py-disable
	# patch to disable clang support at runtime
	cd $(prefix)/share/gps/support/languages/           \
	&& rm -rf clang_support.py-disable                  \
	&& mv clang_support.py clang_support.py-disable

.PHONY: gps-run
gps-run:
	export PYTHONPATH=/usr/lib/python2.7:/usr/lib/python2.7/plat-x86_64-linux-gnu:/usr/lib/python2.7/dist-packages \
	&& gps

#
# * - C L E A N ,  * ,  * - I N S T A L L
#
##############################################################
