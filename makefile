PKGNAME	          = ldap # Edit to adapt
LIBNAME	          = ldap4kno
KNOCONFIG         = knoconfig
KNOBUILD          = knobuild

prefix		::= $(shell ${KNOCONFIG} prefix)
libsuffix	::= $(shell ${KNOCONFIG} libsuffix)
CMODULES	::= $(DESTDIR)$(shell ${KNOCONFIG} cmodules)
KNO_VERSION	::= $(shell ${KNOCONFIG} version)
KNO_MAJOR	::= $(shell ${KNOCONFIG} major)
KNO_MINOR	::= $(shell ${KNOCONFIG} minor)
PKG_VERSION     ::= $(shell u8_gitversion etc/knomod_version)
PKG_MAJOR       ::= $(shell echo ${PKG_VERSION} | cut -d. -f1)
PKG_MINOR       ::= $(shell echo ${PKG_VERSION} | cut -d. -f2)
PKG_PATCHLEVEL  ::= $(shell echo ${PKG_VERSION} | cut -d. -f3)
FULL_VERSION    ::= ${KNO_MAJOR}.${PKG_VERSION}

INIT_CFLAGS  	::= ${CFLAGS}
INIT_LDFLAGS 	::= ${LDFLAGS}
KNO_CFLAGS	::= -I. -fPIC $(shell ${KNOCONFIG} cflags)
KNO_LDFLAGS	::= -fPIC $(shell ${KNOCONFIG} ldflags)
KNO_LIBS	::= $(shell ${KNOCONFIG} libs)
MODULE_CFLAGS   ::= $(shell ./etc/getcflags libpq)
MODULE_LDFLAGS  ::= $(shell ./etc/getlibflags libpq)
SUDO  		::= $(shell which sudo)

CFLAGS		  = ${INIT_CFLAGS} ${MODULE_CFLAGS} ${KNO_CFLAGS} ${XCFLAGS}
LDFLAGS		  = ${INIT_LDFLAGS} ${MODULE_LDFLAGS} ${KNO_LDFLAGS} ${XLDFLAGS}
MKSO		  = $(CC) -shared $(CFLAGS) $(LDFLAGS) $(LIBS)
SYSINSTALL        = /usr/bin/install -c
MSG		  = echo
MACLIBTOOL	  = $(CC) -dynamiclib -single_module -undefined dynamic_lookup \
			$(LDFLAGS)

# Meta targets

# .buildmode contains the default build target (standard|debugging)
# debug/normal targets change the buildmode
# module build targets depend on .buildmode

default build: .buildmode
	make $(shell cat .buildmode)

module: ${LIBNAME}.${libsuffix}

standard:
	make module
debugging:
	make XCFLAGS="-O0 -g3" module

.buildmode:
	echo standard > .buildmode

debug:
	echo debugging > .buildmode
	make
normal:
	echo standard > .buildmode
	make

# Basic targets (Edit to adapt)

ldap4kno.o: ldap4kno.c makefile
	@$(CC) $(CFLAGS) -D_FILEINFO="\"$(shell u8_fileinfo ./$< $(dirname $(pwd))/)\"" -o $@ -c $<
	@$(MSG) CC "(LDAP4KNO)" $@
ldap4kno.so: ldap4kno.o
	@$(MKSO) $(LDFLAGS) -o $@ ldap4kno.o ${LDFLAGS}
	@$(MSG) MKSO  $@ $<
	@ln -sf $(@F) $(@D)/$(@F).${KNO_MAJOR}
ldap4kno.dylib: ldap4kno.c makefile
	@$(MACLIBTOOL) -install_name \
		`basename $(@F) .dylib`.${KNO_MAJOR}.dylib \
		${CFLAGS} ${LDFLAGS} -o $@ $(DYLIB_FLAGS) \
		ldap4kno.c
	@$(MSG) MACLIBTOOL  $@ $<

TAGS: ldap4kno.c ldap.scm
	etags -o TAGS ldap4kno.c ldap.scm

# Other targets

${CMODULES}:
	install -d $@

install: build ${CMODULES}
	${SUDO} u8_install_shared ${LIBNAME}.${libsuffix} ${CMODULES} ${FULL_VERSION} "${SYSINSTALL}"
	${SUDO} $(SYSINSTALL) ldap.scm $(shell knoconfig installmods)

clean:
	rm -f *.o *.${libsuffix}
fresh:
	make clean
	make default

gitup gitup-trunk:
	git checkout trunk && git pull

buildinfo:
	@echo "PKGNAME=$(PKGNAME) LIBNAME=$(LIBNAME)";
	@echo "  PKG_VERSION=$(PKG_VERSION)";
	@echo "  FULL_VERSION=$(FULL_VERSION)";
	@echo "  CFLAGS=$(CFLAGS)";
	@echo "  LDFLAGS=$(LDFLAGS)";
	@echo "  libsuffix=$(libsuffix)";
	@echo "  prefix=$(prefix)";
	@echo "  MKSO=$(MKSO)";
	@echo "  MACLIBTOOL=$(MACLIBTOOL)";
	@echo "  SYSINSTALL=$(SYSINSTALL)";

all_buildinfo: buildinfo
	@echo "FULL_VERSION=$(FULL_VERSION)";
	@echo "  PKG_VERSION=$(PKG_VERSION)";
	@echo "  KNO_VERSION=$(KNO_VERSION)";
	@echo "  PKG_MAJOR=$(PKG_MAJOR)";
	@echo "  PKG_MINOR=$(PKG_MINOR)";
	@echo "  PKG_PATCHLEVEL=$(PKG_PATCHLEVEL)";
	@echo "  KNO_MAJOR=$(KNO_MAJOR)";
	@echo "  KNO_MINOR=$(KNO_MINOR)";
	@echo "KNOCONFIG=$(KNOCONFIG)";
	@echo "  KNOBUILD=$(KNOBUILD)";
	@echo "  CMODULES=$(CMODULES)";
	@echo "  INIT_CFLAGS=$(INIT_CFLAGS)";
	@echo "  INIT_LDFLAGS=$(INIT_LDFLAGS)";
	@echo "  KNO_CFLAGS=$(KNO_CFLAGS)";
	@echo "  KNO_LDFLAGS=$(KNO_LDFLAGS)";
	@echo "  KNO_LIBS=$(KNO_LIBS)";
	@echo "  MODULE_CFLAGS=$(MODULE_CFLAGS)";
	@echo "  MODULE_LDFLAGS=$(MODULE_LDFLAGS)";
	@echo "  SUDO=$(SUDO)";

