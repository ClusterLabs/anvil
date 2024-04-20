MAINTAINERCLEANFILES    = Makefile.in

SE_MAKEFILE_PATH	= /usr/share/selinux/devel/Makefile

SE_SRC_SUBNODE_TE	= anvil-subnode.te

EXTRA_DIST		= \
			$(SE_SRC_SUBNODE_TE).in

selinuxdir		= $(datarootdir)/selinux/packages/targeted
selinux_DATA		= anvil-subnode.pp

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

clean-local:
	rm -f *.fc *.if *.pp *.te
	rm -rf tmp
