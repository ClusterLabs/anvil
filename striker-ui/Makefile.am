MAINTAINERCLEANFILES	= Makefile.in

htmldir			= $(localstatedir)/www/html
nodemodulesdir		= node_modules
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
$(nodemodulesdir):
	-@echo "Install node modules (dependencies) prior to building."
	npm install --no-package-lock --ignore-scripts

# This target is for maintainers only; do not execute during CI/CD.
#
# Note: this target must **not** be renamed to the same name as the build
# output directory because it will trigger a build during the `make` implicit
# call.
#
.PHONY: build
build: clean $(nodemodulesdir)
	-@echo "Build web UI."
	npm run build
	-@echo "Stage only the build output directory."
	git reset && git add $(nextoutdir)
	-@echo "Commit the build output."
	git commit -m "chore: rebuild web UI"

# This target is for maintainers only; do not execute during CI/CD.
#
# Note: this target is strictly used in case of rebuilding; use
# maintainer-clean instead to restore the repo to a clean state.
.PHONY: clean
clean:
	-@echo "Clean up build output files to prepare for rebuild."
	rm -rf $(nextoutdir) $(nextbuilddir)

install-data-hook:
	-@echo "Place build output files."
	cp -r --no-preserve=mode $(nextoutdir)/$(outindexfile) $(nextoutdir)/$(outjsmodulesdir) $(DESTDIR)/$(htmldir)/
	-@echo "Create symlink to images to enable borrowing icon etc. without duplicating."
	(cd $(DESTDIR)/$(htmldir); $(LN_S) skins/alteeve/images $(outimagesdir))

uninstall-hook:
	-@echo "Remove all installed files of the current module."
	(cd $(DESTDIR)/$(htmldir); rm -rf $(outindexfile) $(outjsmodulesdir) $(outimagesdir))

maintainer-clean-local: clean
	-@echo "Clean up node modules."
	rm -rf $(nodemodulesdir)
	-@echo "Since the build output directory is removed, restore it to keep local repo clean."
	git restore $(nextoutdir)
