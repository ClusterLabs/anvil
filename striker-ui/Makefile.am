MAINTAINERCLEANFILES    = Makefile.in

htmldir                 = $(localstatedir)/www/html

build:
    -@echo "Install node modules (dependencies) prior to building."
    npm clean-install
    -@echo "Build front-end project."
    npm run build
