MAINTAINERCLEANFILES	= Makefile.in

htmldir			= $(localstatedir)/www/html
nodemodulesdir		= node_modules
nextoutdir		= out
nextbuilddir		= .next

# List of paths relative to the build output directory.
#
outindexpage		= index.html
outserverpage		= server.html
outjsmodulesdir		= _next
outimagesdir		= pngs

# The build output directory listed under EXTRA_DIST contains the files to
# include in the release/source tarball.
#
# It is recommended to use the following command to regenerate the file list
# as files get added/removed:
#
# find . \
#      -mindepth 1 -maxdepth 1 \
#      -not \( -name node_modules -prune \) \
#      -not \( -name *git* -prune \) \
#      -not \( -name *husky* -prune \) \
#      -not \( -name public -prune \) \
#      -not \( -name *[Mm]ake* -prune \) \
#      | sed -E 's@^./(.+)$@\1 \\@'
#
# The find command:
# * ignores ./node_modules directory,
# * ignores git related files,
# * ignores husky related files
# * ignores ./public directory
# * ignores make related files, and
# * removes leading "./" and append "\"
#
# Note: This only works when we want to include all files within the listed
# subdirectories. It is recommended to run a similar find command on a
# subdirectory to skip undesired files in the subdirectory.
#
EXTRA_DIST		= \
			$(nextoutdir) \
			next.config.js \
			next-env.d.ts \
			tsconfig.json \
			theme \
			styles \
			.lintstagedrc.json \
			README.md \
			package.json \
			lib \
			.prettierrc.json \
			types \
			components \
			pages \
			.eslintrc.json \
			commitlint.config.js \
			.eslintignore \
			.env \
			package-lock.json

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
		cp -r --no-preserve=mode \
			$(outindexpage) $(outserverpage) $(outjsmodulesdir) \
			$(DESTDIR)/$(htmldir)/ \
	)
	-@echo "Create symlink to images to enable borrowing icon etc. without duplicating."
	(cd $(DESTDIR)/$(htmldir); $(LN_S) skins/alteeve/images $(outimagesdir))

uninstall-hook:
	-@echo "Remove all installed files of the current module."
	(cd $(DESTDIR)/$(htmldir); \
		rm -rf $(outindexpage) $(outserverpage) $(outjsmodulesdir) $(outimagesdir) \
	)

clean-local:
	-@echo "Clean up node modules."
	rm -rf $(nodemodulesdir)
