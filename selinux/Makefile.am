MAINTAINERCLEANFILES    = Makefile.in

SE_DIR			= /usr/share/selinux
SE_MAKEFILE_PATH	= $(SE_DIR)/devel/Makefile
SE_TYPE			= targeted

SE_SRC_SUBNODE_TE	= anvil-subnode.te

EXTRA_DIST		= \
			$(SE_SRC_SUBNODE_TE).in

# Variables:
# $@ : target name
# $< : first prerequisite
# $^ : all prerequisites
#
# Command prefixes:
# - : ignore errors
# @ : don't print command

.PHONY: se-makefile
se-makefile:
	-@echo "Making $@: $^"
	if ! test -r "$(SE_MAKEFILE_PATH)"; then \
	  printf "\n*** %s\n*** %s\n\n" \
	    "Missing makefile from selinux devel." \
	    "Did you forget to install the selinux-policy-devel package?" >&2; \
	  exit 1; \
	fi

$(SE_SRC_SUBNODE_TE): $(SE_SRC_SUBNODE_TE).in
	-@echo "Making $@: $^"
	-pwd
	-ls -Al "$(srcdir)"
	-ls -Al
	cp -r -p --no-preserve=mode "$<" "$@"
	-ls -Al "$(srcdir)"
	-ls -Al

anvil-subnode.pp: se-makefile $(SE_SRC_SUBNODE_TE)
	-@echo "Making $@: $^"
	-pwd
	-ls -Al "$(srcdir)"
	-ls -Al
	make -f "$(SE_MAKEFILE_PATH)" "$@"
	-ls -Al "$(srcdir)"
	-ls -Al

install-data-hook: anvil-subnode.pp
	-@echo "Making $@: $^"
	-pwd
	-@echo "srcdir: $(srcdir)"
	-@echo "destdir: $(destdir)"
	-@echo "DESTDIR: $(DESTDIR)"
	-@echo "datarootdir: $(datarootdir)"
	install -D -m 0644 -t "$(DESTDIR)/$(SE_DIR)/packages/$(SE_TYPE)/" "anvil-subnode.pp"

uninstall-hook:
	-@echo "Making $@: $^"
	-pwd
	-@echo "srcdir: $(srcdir)"
	-@echo "destdir: $(destdir)"
	-@echo "DESTDIR: $(DESTDIR)"
	rm -f "$(DESTDIR)/$(SE_DIR)/packages/$(SE_TYPE)/anvil-subnode.pp"

clean-local:
	-@echo "Making $@: $^"
	-pwd
	-ls -Al
	rm -f *.fc *.if *.pp *.te
	rm -rf tmp
