MAINTAINERCLEANFILES	= Makefile.in

htmldir			= $(localstatedir)/www/html
nextoutdir		= $(srcdir)/out
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

# This target is for maintainers only; do not execute during CI/CD.
#
out:
	-@echo "Install node modules (dependencies) prior to building."
	npm install --no-package-lock --ignore-scripts
	-@echo "Build front-end project."
	npm run build
	-@echo "Stage only the build output directory."
	git reset && git add $(nextoutdir)
	-@echo "Commit the build output."
	git commit -m "chore: rebuild web UI"

install-data-hook:
	-@echo "Place build output files."
	cp -r $(nextoutdir)/$(outindexfile) $(nextoutdir)/$(outjsmodulesdir) $(DESTDIR)/$(htmldir)/
	-@echo "Create symlink to images to enable borrowing icon etc. without duplicating."
	(cd $(DESTDIR)/$(htmldir); $(LN_S) skins/alteeve/images $(outimagesdir))

uninstall-hook:
	-@echo "Remove all installed files of the current module."
	(cd $(DESTDIR)/$(htmldir); rm -rf $(outindexfile) $(outjsmodulesdir) $(outimagesdir))

clean-local:
	-@echo "Clean up build output files."
	rm -rf $(nextoutdir) $(nextbuilddir)

distclean-local: clean-local
