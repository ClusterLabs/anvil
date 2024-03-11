MAINTAINERCLEANFILES    = Makefile.in

SE_MAKEFILE_PATH	= /usr/share/selinux/devel/Makefile
SE_TYPE			= targeted

SE_SRC_SUBNODE_TE	= anvil-subnode.te

EXTRA_DIST		= \
			$(SE_SRC_SUBNODE_TE)

# Variables:
# $@ : target name
# $< : first prerequisite
# $^ : all prerequisites
#
# Command prefixes:
# - : ignore errors
# @ : don't print command

all: anvil-subnode.pp
	-@echo "Making $@: $^"

.PHONY: se-makefile
se-makefile:
	-@echo "Making $@: $^"
	if ! test -r "$(SE_MAKEFILE_PATH)"; then \
	  printf "\n*** %s\n*** %s\n\n" \
	    "Missing makefile from selinux devel." \
	    "Did you forget to install the selinux-policy-devel package?" >&2; \
	  exit 1; \
	fi

.PHONY: subnode-te
subnode-te: anvil-subnode.te
	-@echo "Making $@: $^"
	cp -r -p --no-preserve=mode "$<" "$(SE_SRC_SUBNODE_TE)"

anvil-subnode.pp: se-makefile subnode-te
	-@echo "Making $@: $^"
	-pwd
	-ls -Al "$(srcdir)"
	-ls -Al
	make -f "$(SE_MAKEFILE_PATH)" "$@"
	-ls -Al "$(srcdir)"
	-ls -Al

install-data-hook:
	-@echo "Making $@: $^"
	-pwd
	-@echo "srcdir: $(srcdir)"
	-@echo "destdir: $(destdir)"
	-@echo "DESTDIR: $(DESTDIR)"
	-@echo "datarootdir: $(datarootdir)"
	install -D -m 0644 -t "$(DESTDIR)/$(prefix)/usr/share/selinux/packages/$(SE_TYPE)/" "anvil-subnode.pp"

uninstall-hook:
	-@echo "Making $@: $^"
	-pwd
	-@echo "srcdir: $(srcdir)"
	-@echo "destdir: $(destdir)"
	-@echo "DESTDIR: $(DESTDIR)"
	rm -f "$(DESTDIR)/$(prefix)/usr/share/selinux/packages/$(SE_TYPE)/anvil-subnode.pp"

clean-local:
	-@echo "Making $@: $^"
	-pwd
	-ls -Al
	rm -f *.fc *.if *.pp *.te
	rm -rf tmp
