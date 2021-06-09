MAINTAINERCLEANFILES	= Makefile.in

htmldir			= $(localstatedir)/www/html
nodemodulesdir		= node_modules
nextoutdir		= out
nextbuilddir		= .next

# List of paths relative to the build output directory.
#
outindexfile		= index.html
outjsmodulesdir		= _next
outimagesdir		= pngs

# The build output directory listed under EXTRA_DIST contains the files to be
# installed; there is no build process required.
#
EXTRA_DIST		= $(nextoutdir)

# Blank target; the build output directory should be usable as-is.
$(nextoutdir): ;

# This target is for maintainers only; do not execute during CI/CD.
#
$(nodemodulesdir):
	-@echo "Install node modules (dependencies) prior to building."
	npm install --no-package-lock --ignore-scripts

# This target is for maintainers only; do not execute during CI/CD. In
# addition, this target can only be used if the local git repository exists.
#
# Note: this target must **not** be renamed to the same name as the build
# output directory because it will trigger a build during the `make` implicit
# call.
#
.PHONY: build
build: $(nodemodulesdir)
	-@echo "Remove build output files to prepare for rebuild."
	rm -rf $(nextoutdir) $(nextbuilddir)
	-@echo "Build web UI."
	npm run build
	-@echo "Stage only the build output directory and commit the build output."
	git reset \
		&& git add $(nextoutdir) \
		&& git commit -m "chore: rebuild web UI"

install-data-hook:
	-@echo "Place build output files."
	cp -r --no-preserve=mode $(srcdir)/$(nextoutdir)/$(outindexfile) $(srcdir)/$(nextoutdir)/$(outjsmodulesdir) $(DESTDIR)/$(htmldir)/
	-@echo "Create symlink to images to enable borrowing icon etc. without duplicating."
	(cd $(DESTDIR)/$(htmldir); $(LN_S) skins/alteeve/images $(outimagesdir))

uninstall-hook:
	-@echo "Remove all installed files of the current module."
	(cd $(DESTDIR)/$(htmldir); rm -rf $(outindexfile) $(outjsmodulesdir) $(outimagesdir))

clean-local:
	-@echo "Clean up node modules."
	rm -rf $(nodemodulesdir)

distclean-local: clean-local

maintainer-clean-local: clean-local
