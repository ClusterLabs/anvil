MAINTAINERCLEANFILES    = Makefile.in

compressedapi           = striker-ui-api.tar.xz
extractedapi            = striker-ui-api

EXTRA_DIST              = $(compressedapi)

# Blank target; the compressed API executable should be usable as-is.
$(compressedapi): ;

install-data-hook:
	-@echo "Extract the API executable."
	tar -xvf $(srcdir)/$(compressedapi) -C $(DESTDIR)/$(sbindir)

uninstall-hook:
	-@echo "Remove the API executable."
	rm -f $(DESTDIR)/$(sbindir)/$(extractedapi)
