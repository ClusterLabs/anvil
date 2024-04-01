MAINTAINERCLEANFILES    = Makefile.in

SE_DIR			= /usr/share/selinux
SE_MAKEFILE_PATH	= $(SE_DIR)/devel/Makefile
SE_TYPE			= targeted

SE_SRC_SUBNODE_TE	= anvil-subnode.te

EXTRA_DIST		= \
			$(SE_SRC_SUBNODE_TE).in

# Magic variables:
# $@ : target name
# $< : first prerequisite
# $^ : all prerequisites
#
# Command prefixes:
# - : ignore errors
# @ : don't print command
#
# Notes:
# - Environment variable DESTDIR is set at make call.

.PHONY: se-makefile
se-makefile:
	if ! test -r "$(SE_MAKEFILE_PATH)"; then \
	  printf "\n*** %s\n*** %s\n\n" \
	    "Missing makefile from selinux devel." \
	    "Did you forget to install the selinux-policy-devel package?" >&2; \
	  exit 1; \
	fi

$(SE_SRC_SUBNODE_TE): $(SE_SRC_SUBNODE_TE).in
	cp --preserve=ownership,timestamps "$<" "$@"

anvil-subnode.pp: se-makefile $(SE_SRC_SUBNODE_TE)
	make -f "$(SE_MAKEFILE_PATH)" "$@"

install-data-hook: anvil-subnode.pp
	install -D -m 0644 -t "$(DESTDIR)/$(SE_DIR)/packages/$(SE_TYPE)/" "anvil-subnode.pp"

uninstall-hook:
	rm -f "$(DESTDIR)/$(SE_DIR)/packages/$(SE_TYPE)/anvil-subnode.pp"

clean-local:
	rm -f *.fc *.if *.pp *.te
	rm -rf tmp
