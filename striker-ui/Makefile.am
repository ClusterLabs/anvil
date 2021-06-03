MAINTAINERCLEANFILES	= Makefile.in

# The files listed under EXTRA_DIST is only used for building, they should not
# be included in the installation process.
#
# It is recommended to use the following command to regenerate the file list
# as files get added/removed:
#
# find . \
#	-not \( -name node_modules -prune \) \	# Ignore ./node_modules directory
#	-not \( -name *git* -prune \) \		# Ignore git related files
#	-not \( -name *husky* -prune \) \	# Ignore husky related files
#	-not \( -name public -prune \) \	# Ignore ./public directory
#	-not \( -name *[Mm]ake* -prune \) \	# Ignore make related files
#	-not \( -name *.md -prune \) \		# Ignore all markdown files
#	-type f \				# Only print file paths
#	| sed -E 's@^./(.+)$@\1 \\@'		# Remove leading "./" and append "\"
#
EXTRA_DIST		= \
			next.config.js \
			next-env.d.ts \
			tsconfig.json \
			theme/index.ts \
			styles/globals.css \
			.lintstagedrc.json \
			env.development \
			package.json \
			lib/extended_date/ExtendedDate.ts \
			lib/fetchers/putJSON.ts \
			lib/fetchers/fetchJSON.ts \
			lib/fetchers/periodicFetch.ts \
			lib/sanitizers/hostsSanitizer.ts \
			lib/consts/ICONS.ts \
			lib/consts/DEFAULT_THEME.ts \
			lib/consts/SERVERS.ts \
			lib/consts/ANVILS.ts \
			lib/consts/API_BASE_URL.ts \
			lib/consts/IS_DEV_ENV.ts \
			lib/consts/NODES.ts \
			.prettierrc.json \
			types/AnvilServers.d.ts \
			types/GetAllAnvilResponse.d.ts \
			types/AnvilMemory.d.ts \
			types/FetchResponse.d.ts \
			types/AnvilSharedStorage.d.ts \
			types/AnvilNetwork.d.ts \
			types/AnvilTypes.d.ts \
			types/GetResponse.d.ts \
			types/AnvilNodeStatus.d.ts \
			types/AnvilList.d.ts \
			types/AnvilCPU.d.ts \
			types/GetOneAnvilResponse.d.ts \
			types/AnvilSet.d.ts \
			types/AnvilStatus.d.ts \
			types/AnvilReplicatedStorage.d.ts \
			types/AnvilFileSystems.d.ts \
			types/NodeSet.d.ts \
			components/Memory.tsx \
			components/Decorator.tsx \
			components/Hosts/index.tsx \
			components/Hosts/AnvilHost.tsx \
			components/Spinner.tsx \
			components/AnvilDrawer.tsx \
			components/Text/HeaderText.tsx \
			components/Text/index.tsx \
			components/Text/BodyText.tsx \
			components/FileSystem/index.tsx \
			components/FileSystem/FileSystemsHost.tsx \
			components/FileSystem/FileSystems.tsx \
			components/Anvils/index.tsx \
			components/Anvils/sortAnvils.ts \
			components/Anvils/Anvil.tsx \
			components/Anvils/AnvilList.tsx \
			components/Anvils/SelectedAnvil.tsx \
			components/Panels/index.tsx \
			components/Panels/InnerPanel.tsx \
			components/Panels/PanelHeader.tsx \
			components/Panels/Panel.tsx \
			components/Servers.tsx \
			components/Storage.tsx \
			components/AnvilContext.tsx \
			components/SharedStorage/SharedStorage.tsx \
			components/SharedStorage/index.tsx \
			components/SharedStorage/SharedStorageHost.tsx \
			components/Header.tsx \
			components/Network/index.tsx \
			components/Network/Network.tsx \
			components/Network/processNetwork.ts \
			components/CPU.tsx \
			components/Bars/index.tsx \
			components/Bars/ProgressBar.tsx \
			components/Bars/AllocationBar.tsx \
			pages/index.tsx \
			pages/_app.tsx \
			pages/_document.tsx \
			.eslintrc.json \
			commitlint.config.js \
			.eslintignore \
			package-lock.json

htmldir			= $(localstatedir)/www/html
outdir			= out

# Trigger build target on make call without parameters.
all: build

# Note: the input file to the generate endpoint prefix step must exist in
#       EXTRA_DIST.
#
build:
	-@echo "Print working directory."
	pwd
	-@echo "Install node modules (dependencies) prior to building."
	npm clean-install --ignore-scripts
	-@echo "Generate endpoint prefix."
	sed 's@=.*@=/cgi-bin@' <env.development >.env.local
	-@echo "Build front-end project."
	npm run build

install-data-hook:
	-@echo "Print working directory."
	pwd
	-@echo "Place build output files."
	cp -r $(outdir)/index.html $(outdir)/_next $(DESTDIR)/$(htmldir)/
	-@echo "Create symlink to images to enable borrowing icon etc. without duplicating."
	(cd $(DESTDIR)/$(htmldir); $(LN_S) skins/alteeve/images pngs)

uninstall-hook:
	-@echo "Remove all installed files of the current module."
	(cd $(DESTDIR)/$(htmldir); rm -rf index.html _next pngs)
