MAINTAINERCLEANFILES	= Makefile.in

# The build output directory listed under EXTRA_DIST contains the files to be
# installed; there is no build process required.
#
EXTRA_DIST		= out

htmldir			= $(localstatedir)/www/html
outdir			= out

# Trigger build target on make call without parameters.
all: out

# Note: the input file to the generate endpoint prefix step must exist in
#       EXTRA_DIST.
#
out:
	-@echo "Copying required build files to build (current) directory."
	rsync -av --exclude "[Mm]ake*" $(srcdir)/ ./
	-@echo "Allow tools to write to files in the build directory."
	chmod -R +w .
	-@echo "Install node modules (dependencies) prior to building."
	npm install --no-package-lock --ignore-scripts
	-@echo "Generate endpoint prefix."
	sed 's@=.*@=/cgi-bin@' <env.development >.env.local
	-@echo "Build front-end project."
	npm run build

install-data-hook:
	-@echo "Place build output files."
	cp -r $(outdir)/index.html $(outdir)/_next $(DESTDIR)/$(htmldir)/
	-@echo "Create symlink to images to enable borrowing icon etc. without duplicating."
	(cd $(DESTDIR)/$(htmldir); $(LN_S) skins/alteeve/images pngs)

uninstall-hook:
	-@echo "Remove all installed files of the current module."
	(cd $(DESTDIR)/$(htmldir); rm -rf index.html _next pngs)

clean-local:
	-@echo "Clean up build output files."
	test $(srcdir) == . && rm -rf $(outdir) .next || find . -mindepth 1 -maxdepth 1 -exec rm -rf {} +

distclean-local: clean-local
