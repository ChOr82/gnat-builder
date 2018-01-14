# version = master
# gcc-version = master, trunk, gcc-7-branch, gcc-7_2_0-release
# prefix = /usr/local/gnat, /usr/gnat, etc.

release ?= 0.1.0-20180109
gcc-version ?= gcc-7-branch
adacore-version ?= master
prefix ?= $(PWD)/gnat

# release location and naming details
#
release-loc = release
release-url = https://github.com/steve-cs/gnat-builder/releases/download
release-tag = v$(release)
release-name = gnat-build_tools-$(release)


# Debian stable configuration
#
llvm-version ?= 3.8
iconv-opt ?= "-lc"

.PHONY: default
default: all

.PHONY: install
install: all-install

##############################################################
#
# P A T C H E S
#

gnatcoll-db-build: gnatcoll-db-src
	mkdir -p $@
	cp -r $</* $@
	# patch to enable gnatcoll-gnatinspect build
	cd $@ && patch -p1 < ../patches/gnatcoll-db-src-patch-1

langkit-build: langkit-src
	mkdir -p $@
	cp -r $</* $@
	# patch to move from old gnatcoll_* to new gnatcoll-*
	cd $@ && patch -p1 < ../patches/langkit-src-patch-1

gps-build: gps-src libadalang-tools-build
	mkdir -p $@
	cp -r $</* $@
	ln -sf $(PWD)/libadalang-tools-build $</laltools
	# patch to disable libadalang from the build
	cd $@ && patch -p1 < ../patches/gps-src-patch-1
	# patch to move from old gnatcoll_* to new gnatcoll-*
	cd $@ && patch -p1 < ../patches/gps-src-patch-2

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
	# patch to run time environment that fixes bad RPATH in gps
	rm  -f ../gnat
	ln -s $(PWD)/gnat ../gnat

#
# E N D   P A T C H E S
#
##############################################################

.PHONY: prerequisites-install
prerequisites-install:
	apt-get -y install \
	build-essential gnat gawk git flex bison \
	libgmp-dev lib1g-dev libreadline-dev postgresql libpq-dev \
	virtualenv \
	pkg-config libglib2.0-dev libpango1.0-dev libatk1.0-dev libgtk-3-dev \
	python-dev python-pip python-gobject-dev python-cairo-dev \
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
	cp -r $(release-loc)/$(release-name)/* $(prefix)/

.PHONY: release-download
release-download: $(release-loc)/$(release-name)

$(release-loc)/$(release-name):
	rm -rf $@ $@.tar.gz
	mkdir -p $(@D)
	cd $(@D) && wget $(release-url)/$(release-tag)/$(@F).tar.gz
	cd $(@D) && tar xf $(@F).tar.gz

.PHONY: clean
clean: 
	rm -rf *-src *-build

.PHONY: dist-clean
dist-clean : clean
	rm -rf github-repo gnat release

%-clean:
	rm -rf $(@:%-clean=%)-src $(@:%-clean=%)-build

.PHONY: bootstrap-clean
bootstrap-clean: clean prefix-clean

.PHONY: prefix-clean
prefix-clean:
	rm -rf $(prefix)/*
	mkdir -p $(prefix)

.PHONY: bootstrap-install
bootstrap-install: |                                      \
gcc-bootstrap gcc-install                                 \
gprbuild-bootstrap-install                                \
xmlada xmlada-install                                     \
gprbuild gprbuild-install                                 \
gnatcoll-core gnatcoll-core-install                       \
gnatcoll-bindings gnatcoll-bindings-install               \
gnatcoll-gnatcoll_db2ada gnatcoll-gnatcoll_db2ada-install \
gnatcoll-sqlite gnatcoll-sqlite-install                   \
gnatcoll-xref gnatcoll-xref-install                       \
gnatcoll-gnatinspect gnatcoll-gnatinspect-install         \
libadalang libadalang-install                             \
gtkada gtkada-install                                     \
gps gps-install

.PHONY: all
all: |                   \
xmlada                   \
gprbuild                 \
gnatcoll-core            \
gnatcoll-bindings        \
gnatcoll-gnatcoll_db2ada \
gnatcoll-sqlite          \
gnatcoll-xref            \
gnatcoll-gnatinspect     \
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
gnatcoll-gnatcoll_db2ada-install \
gnatcoll-sqlite-install          \
gnatcoll-xref-install            \
gnatcoll-gnatinspect             \
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

# from github

gcc-src: github-src/gcc-mirror/gcc/$(gcc-version)
	ln -s $< $@
	cd $@ && ./contrib/download_prerequisites

xmlada-src: github-src/adacore/xmlada/$(adacore-version)
gprbuild-src: github-src/adacore/gprbuild/$(adacore-version)
gtkada-src: github-src/adacore/gtkada/$(adacore-version)
gnatcoll-core-src: github-src/adacore/gnatcoll-core/$(adacore-version)
gnatcoll-bindings-src: github-src/adacore/gnatcoll-bindings/$(adacore-version)
gnatcoll-db-src: github-src/adacore/gnatcoll-db/$(adacore-version)
langkit-src: github-src/adacore/langkit/$(adacore-version)
libadalang-src: github-src/adacore/libadalang/$(adacore-version)
libadalang-tools-src: github-src/adacore/libadalang-tools/$(adacore-version)
gps-src: github-src/adacore/gps/$(adacore-version)

quex-src: github-src/steve-cs/quex/0.65.4

# aliases to other %-src

xmlada-bootstrap-src: xmlada-src
gprbuild-bootstrap-src: gprbuild-src

# linking github-src/<account>/<repository>/<branch> from github
# get the repository, update it, and checkout the requested branch

# github branches where we want to pull updates if available
#
github-src/%/0.65.4            \
github-src/%/gcc-7-branch      \
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

%-build: %-src
	mkdir -p $@
	cp -r $</* $@

gcc-build:
	mkdir -p $@

gnatcoll-gnatcoll_db2ada-build \
gnatcoll-sqlite-build \
gnatcoll-xref-build \
gnatcoll-gnatinspect-build \
: gnatcoll-db-build
	ln -sf $< $@

#
# * - B U I L D
#
##############################################################
#
#

.PHONY: gnatcoll-%-install
gnatcoll-%-install: gnatcoll-%-build
	# % = $(<:gnatcoll-%-build=%)
	make -C $</$(<:gnatcoll-%-build=%) install

.PHONY: gnatcoll-%
gnatcoll-%: gnatcoll-%-build
	# % = $(<:gnatcoll-%-build=%)
	make -C $</$(<:gnatcoll-%-build=%) setup
	make -C $</$(<:gnatcoll-%-build=%)

.PHONY: %-install
%-install: %-build
	make -C $< prefix=$(prefix) install

.PHONY: gcc-bootstrap
gcc-bootstrap: gcc-build gcc-src
	cd $< && ../gcc-src/configure \
	--prefix=$(prefix) --enable-languages=c,c++,ada \
	--enable-bootstrap --disable-multilib \
	--enable-shared --enable-shared-host
	cd $<  && make -j4

.PHONY: gcc
gcc: gcc-build gcc-src
	cd $< && ../gcc-src/configure \
	--prefix=$(prefix) --enable-languages=c,c++,ada \
	--disable-bootstrap --disable-multilib \
	--enable-shared --enable-shared-host
	cd $<  && make -j4

.PHONY: gprbuild-bootstrap-install        
gprbuild-bootstrap-install: gprbuild-bootstrap-build xmlada-bootstrap-build
	cd $<  && ./bootstrap.sh \
	--with-xmlada=../xmlada-bootstrap-build --prefix=$(prefix)

.PHONY: xmlada
xmlada: xmlada-build
	cd $< && ./configure --prefix=$(prefix)
	make -C $< all

.PHONY: gprbuild
gprbuild: gprbuild-build
	make -C $< prefix=$(prefix) setup
	make -C $< all
	make -C $< libgpr.build

.PHONY: gprbuild-install
gprbuild-install: gprbuild-build
	make -C $< install
	make -C $< libgpr.install

.PHONY: gnatcoll-core
gnatcoll-core: gnatcoll-core-build
	make -C $< setup
	make -C $<

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

.PHONY: gnatcoll-bindings-install
gnatcoll-bindings-install: gnatcoll-bindings-build
	cd $</gmp && ./setup.py install
	cd $</iconv && export GNATCOLL_ICONV_OPT=$(iconv-opt) && ./setup.py install
	cd $</python && ./setup.py install
	cd $</readline && ./setup.py install
	cd $</syslog && ./setup.py install

.PHONY: libadalang
libadalang: libadalang-build langkit-build quex-src
	cd $< && virtualenv lal-venv
	cd $< && . lal-venv/bin/activate \
	&& pip install -r REQUIREMENTS.dev \
	&& mkdir -p lal-venv/src/langkit \
	&& rm -rf lal-venv/src/langkit/* \
	&& cp -r ../langkit-build/* lal-venv/src/langkit \
	&& export QUEX_PATH=$(PWD)/quex-src \
	&& ada/manage.py make \
	&& deactivate

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

.PHONY: gps
gps: gps-build
	cd $< && ./configure \
	--prefix=$(prefix) \
	--with-clang=/usr/lib/llvm-$(llvm-version)/lib/ 
	make -C $< PROCESSORS=0
#
# below is the hack that allowed the gpl-2017 branch to run on Debian
#
.PHONY: gps-run
gps-run:
	export PYTHONPATH=/usr/lib/python2.7:/usr/lib/python2.7/plat-x86_64-linux-gnu:/usr/lib/python2.7/dist-packages \
	&& gps

#
# * - C L E A N ,  * ,  * - I N S T A L L
#
##############################################################
