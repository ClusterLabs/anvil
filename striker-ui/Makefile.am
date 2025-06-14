MAINTAINERCLEANFILES	= Makefile.in

htmldir			= $(localstatedir)/www/html
nodemodulesdir		= node_modules
nextoutdir		= out
nextbuilddir		= .next

# List of paths relative to the build output directory.
#
outpages		= \
			anvil.html \
			config.html \
			file-manager.html \
			host.html \
			index.html \
			init.html \
			login.html \
			mail-config.html \
			manage-element.html \
			server.html
outjsmodulesdir		= _next
outimagesdir		= pngs

# The build output directory listed under EXTRA_DIST contains the files to
# include in the release/source tarball.
#
# It is recommended to use the lsxdist script to regenerate the file list
# as files get added/removed.
#
EXTRA_DIST	= \
		$(nextoutdir) \
		commitlint.config.mjs \
		components \
		.env \
		eslint.config.mjs \
		hooks \
		lib \
		lint-staged.config.mjs \
		next.config.mjs \
		next-env.d.ts \
		package.json \
		package-lock.json \
		pages \
		prettier.config.mjs \
		README.md \
		styles \
		theme \
		tsconfig.json \
		types

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
	(cd $(srcdir)/$(nextoutdir); \
		cp -r --no-preserve=mode $(outpages) $(outjsmodulesdir) $(DESTDIR)/$(htmldir)/ \
	)
	-@echo "Create symlink to images to enable borrowing icon etc. without duplicating."
	(cd $(DESTDIR)/$(htmldir); $(LN_S) skins/alteeve/images $(outimagesdir))

uninstall-hook:
	-@echo "Remove all installed files of the current module."
	(cd $(DESTDIR)/$(htmldir); \
		rm -rf $(outpages) $(outjsmodulesdir) $(outimagesdir) \
	)

clean-local:
	-@echo "Clean up node modules."
	rm -rf $(nodemodulesdir)
