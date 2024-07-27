EXTRA_DIST		= autogen.sh \
			  .version make/release.mk \
			  make/git-version-gen make/gitlog-to-changelog \
			  m4/ax_prog_date.m4 m4/ax_prog_perl_modules.m4 \
			  anvil.conf $(SPEC).in \
			  README.md scancore.README watch_logs

AUTOMAKE_OPTIONS	= foreign

MAINTAINERCLEANFILES	= Makefile.in aclocal.m4 configure depcomp \
			  config.guess config.sub missing install-sh \
			  autoheader automake autoconf libtool libtoolize \
			  ltmain.sh compile autoscan.log configure.scan

SPEC			= $(PACKAGE_NAME).spec

TARFILES		= $(PACKAGE_NAME)-$(VERSION).tar.bz2 \
			  $(PACKAGE_NAME)-$(VERSION).tar.gz \
			  $(PACKAGE_NAME)-$(VERSION).tar.xz

ACLOCAL_AMFLAGS		= -I m4

SUBDIRS			= Anvil html journald.conf.d libvirt man ocf \
			  pxe scancore-agents scripts selinux share striker-ui \
			  striker-ui-api tools units

anvilconfdir		= ${sysconfdir}/anvil

dist_anvilconf_DATA	= anvil.conf

anvilconf_DATA		= anvil.version

clean-local:
	rm -rf $(SPEC) *.rpm $(TARFILES)

# this will get rid of "libtoolized" m4 files
distclean-local:
	rm -rf $(filter-out \
		 $(top_builddir)/m4/ax_prog_date.m4 \
		 $(top_builddir)/m4/ax_prog_perl_modules.m4, \
		 $(wildcard $(top_builddir)/m4/*.m4))

# release/versioning
BUILT_SOURCES	= .version
.version:
	echo $(VERSION) > $@-t && mv $@-t $@

dist-hook: gen-ChangeLog
	echo $(VERSION) > $(distdir)/.tarball-version
	echo $(SOURCE_EPOCH) > $(distdir)/source_epoch

gen_start_date = 2000-01-01
.PHONY: gen-ChangeLog
gen-ChangeLog:
	if test -d $(abs_srcdir)/.git; then				\
		LC_ALL=C $(top_srcdir)/make/gitlog-to-changelog	\
			--since=$(gen_start_date) > $(distdir)/cl-t;	\
		rm -f $(distdir)/ChangeLog;				\
		mv $(distdir)/cl-t $(distdir)/ChangeLog;		\
	fi

## make rpm/srpm section.
$(SPEC): $(SPEC).in .version config.status
	rm -f $@-t $@
	date="`LC_ALL=C $(UTC_DATE_AT)$(SOURCE_EPOCH) "+%a %b %d %Y"`" && \
	gvgver="`cd $(abs_srcdir); make/git-version-gen --fallback $(VERSION) .tarball-version .gitarchivever`" && \
	if [ "$$gvgver" = "`echo $$gvgver | sed 's/-/./'`" ];then \
		rpmver="$$gvgver" && \
		alphatag="" && \
		dirty="" && \
		numcomm="0"; \
	else \
		gitver="`echo $$gvgver | sed 's/\(.*\)\./\1-/'`" && \
		rpmver=`echo $$gitver | sed 's/-.*//g'` && \
		alphatag=`echo $$gvgver | sed 's/[^-]*-\([^-]*\).*/\1/'` && \
		numcomm=`echo $$gitver | sed 's/[^-]*-\([^-]*\).*/\1/'` && \
		dirty="" && \
		if [ "`echo $$gitver | sed 's/^.*-dirty$$//g'`" = "" ];then \
			dirty="dirty"; \
		fi \
	fi && \
	if [ -n "$$dirty" ]; then dirty="dirty"; else dirty=""; fi && \
	if [ "$$numcomm" = "0" ]; then \
		sed \
			-e "s#@version@#$$rpmver#g" \
			-e "s#%glo.*alpha.*##g" \
			-e "s#%glo.*numcomm.*##g" \
			-e "s#@dirty@#$$dirty#g" \
			-e "s#@date@#$$date#g" \
		$(abs_srcdir)/$@.in > $@-t; \
	else \
		sed \
			-e "s#@version@#$$rpmver#g" \
			-e "s#@alphatag@#$$alphatag#g" \
			-e "s#@numcomm@#$$numcomm#g" \
			-e "s#@dirty@#$$dirty#g" \
			-e "s#@date@#$$date#g" \
		$(abs_srcdir)/$@.in > $@-t; \
	fi; \
	if [ -z "$$dirty" ]; then sed -i -e "s#%glo.*dirty.*##g" $@-t; fi && \
	chmod a-w $@-t
	mv $@-t $@
	rm -f $@-t*

$(TARFILES):
	$(MAKE) dist

RPMBUILDOPTS    = --define "_sourcedir $(abs_top_builddir)" \
		  --define "_specdir $(abs_top_builddir)" \
		  --define "_builddir $(abs_top_builddir)" \
		  --define "_srcrpmdir $(abs_top_builddir)" \
		  --define "_rpmdir $(abs_top_builddir)"

srpm: clean
	$(MAKE) $(SPEC) $(TARFILES)
	rpmbuild $(RPMBUILDOPTS) --nodeps -bs $(SPEC)

rpm: clean
	$(MAKE) $(SPEC) $(TARFILES)
	rpmbuild $(RPMBUILDOPTS) -ba $(SPEC)
