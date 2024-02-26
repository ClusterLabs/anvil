MAINTAINERCLEANFILES    = Makefile.in

SE_MAKEFILE_PATH	= /usr/share/selinux/devel/Makefile
SE_TYPE			= targeted

anvil-node.pp: anvil-node.te
	-@echo "Target: anvil-node.pp"
	-@if ! test -r $(SE_MAKEFILE_PATH); then \
	  -@echo "Missing makefile from selinux devel. \
	    Did you forget to install the selinux-policy-devel package?"
	fi
	make -f $(SE_MAKEFILE_PATH) $@

install:
	-@echo "Target: install"
	install -D -m 0644 -t $(DESTDIR)/usr/share/selinux/packages/$(SE_TYPE)/ anvil-node.pp

clean:
	-@echo "Target: clean"
	rm -f *.pp
