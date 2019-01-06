%define debug_package %{nil}
%define anviluser     admin
%define anvilgroup    admin
Name:           anvil
Version:        3.0
Release:        21%{?dist}
Summary:        Alteeve Anvil! complete package.

License:        GPLv2+
URL:            https://github.com/digimer/anvil
Source0:        https://github.com/digimer/anvil/archive/master.tar.gz
BuildArch:      noarch


%description
This package generates the anvil-core, anvil-striker, anvil-node and anvil-dr 
RPM's. The 'core' RPM is common to all machines in an Anvil! cluster, with the
other three used for each machine, given its roll.

WARNING: This is an alpha-stage project. Many features are missing and this 
         should not be used for anything other than development purposes! The
         first stable release will be 3.1. Anything 3.0 is UNSTABLE.

%package core
Summary:        Alteeve's Anvil! Core package
Requires:       bash-completion 
Requires:       bind-utils 
Requires:       dmidecode
Requires:       dnf-utils
Requires:       fence-agents-all 
Requires:       fence-agents-virsh 
Requires:       firewalld
Requires:       gpm 
Requires:       hdparm
Requires:       htop
Requires:       lsscsi
Requires:       mlocate 
Requires:       perl-Data-Dumper 
Requires:       perl-DBD-Pg 
Requires:       perl-DBI
Requires:       perl-Digest-SHA
Requires:       perl-HTML-FromText
Requires:       perl-HTML-Strip
Requires:       perl-JSON 
Requires:       perl-Log-Journald 
Requires:       perl-Net-SSH2 
Requires:       perl-Net-Netmask
Requires:       perl-NetAddr-IP 
Requires:       perl-Proc-Simple
Requires:       perl-Sys-Syslog
Requires:       perl-Text-Diff
Requires:       perl-Time-HiRes
Requires:       perl-UUID-Tiny
Requires:       perl-XML-Simple 
Requires:       postfix
Requires:       postgresql-contrib 
Requires:       postgresql-plperl 
Requires:       rsync 
#Requires:       screen
Requires:       vim 
# iptables-services conflicts with firewalld
Conflicts:      iptables-services
# We handle interface naming
Conflicts:      biosdevname

%description core
Common base libraries required for the Anvil! system.


%package striker
Summary:        Alteeve's Anvil! Striker dashboard package
Requires:	anvil-core
Requires:	anvil-striker-extra
Requires:       createrepo
Requires:       dhcp-server
Requires:       firefox
Requires:       httpd
Requires:       kernel-core
Requires:       nmap
Requires:       perl-CGI 
Requires:       postgresql-server 
Requires:       syslinux
Requires:       syslinux-nonlinux
Requires:       tftp-server
Requires:       virt-manager
### Desktop stuff
Requires:       GConf2
Requires:       ModemManager-glib
Requires:       NetworkManager-libnm
Requires:       NetworkManager-team
Requires:       NetworkManager-tui
Requires:       NetworkManager-wifi
Requires:       NetworkManager
Requires:       abattis-cantarell-fonts
Requires:       accountsservice-libs
Requires:       accountsservice
Requires:       acl
Requires:       adwaita-cursor-theme
Requires:       adwaita-gtk2-theme
Requires:       adwaita-icon-theme
Requires:       alsa-lib
Requires:       annobin
Requires:       at-spi2-atk
Requires:       at-spi2-core
Requires:       atk
Requires:       audit-libs
Requires:       audit
Requires:       authselect-libs
Requires:       authselect
Requires:       avahi-glib
Requires:       avahi-libs
Requires:       basesystem
Requires:       bash-completion
Requires:       bash
Requires:       bind-export-libs
Requires:       binutils
Requires:       biosdevname
Requires:       bluez-libs
Requires:       bluez-obexd
Requires:       bluez
Requires:       bolt
Requires:       brotli
Requires:       bubblewrap
Requires:       bzip2-libs
Requires:       bzip2
Requires:       c-ares
Requires:       ca-certificates
Requires:       cairo-gobject
Requires:       cairo
Requires:       cheese-libs
Requires:       chkconfig
Requires:       clutter-gst3
Requires:       clutter-gtk
Requires:       clutter
Requires:       cogl
Requires:       color-filesystem
Requires:       colord-gtk
Requires:       colord-libs
Requires:       colord
Requires:       coreutils-common
Requires:       coreutils
Requires:       cpio
Requires:       cpp
Requires:       cracklib-dicts
Requires:       cracklib
Requires:       createrepo_c-libs
Requires:       createrepo_c
Requires:       cronie-anacron
Requires:       cronie
Requires:       crontabs
Requires:       crypto-policies
Requires:       cryptsetup-libs
Requires:       cups-libs
Requires:       cups-pk-helper
Requires:       curl
Requires:       cyrus-sasl-lib
Requires:       dbus-common
Requires:       dbus-daemon
Requires:       dbus-glib
Requires:       dbus-libs
Requires:       dbus-tools
Requires:       dbus-x11
Requires:       dbus
Requires:       dconf
Requires:       desktop-file-utils
Requires:       device-mapper-event-libs
Requires:       device-mapper-event
Requires:       device-mapper-libs
Requires:       device-mapper-persistent-data
Requires:       device-mapper
Requires:       dhcp-client
Requires:       dhcp-common
Requires:       dhcp-libs
Requires:       diffutils
Requires:       dmidecode
Requires:       dnf-data
Requires:       dnf-plugin-subscription-manager
Requires:       dnf-plugins-core
Requires:       dnf
Requires:       dracut-config-rescue
Requires:       dracut-network
Requires:       dracut-squash
Requires:       dracut
Requires:       drpm
Requires:       dwz
Requires:       e2fsprogs-libs
Requires:       e2fsprogs
Requires:       efi-srpm-macros
Requires:       elfutils-default-yama-scope
Requires:       elfutils-libelf
Requires:       elfutils-libs
Requires:       elfutils
Requires:       emacs-filesystem
Requires:       enchant
Requires:       ethtool
Requires:       evolution-data-server-langpacks
Requires:       evolution-data-server
Requires:       expat
Requires:       file-libs
Requires:       file
Requires:       filesystem
Requires:       findutils
Requires:       fipscheck-lib
Requires:       fipscheck
Requires:       firewalld-filesystem
Requires:       firewalld
Requires:       flac-libs
Requires:       fontconfig
Requires:       fontpackages-filesystem
Requires:       freetype
Requires:       fribidi
Requires:       fuse-libs
Requires:       gawk
Requires:       gc
Requires:       gcc
Requires:       gcr
Requires:       gdb-headless
Requires:       gdbm-libs
Requires:       gdbm
Requires:       gdk-pixbuf2-modules
Requires:       gdk-pixbuf2
Requires:       gdm
Requires:       geoclue2-libs
Requires:       geoclue2
Requires:       geocode-glib
Requires:       geolite2-city
Requires:       geolite2-country
Requires:       gettext-libs
Requires:       gettext
Requires:       ghc-srpm-macros
Requires:       gjs
Requires:       glib-networking
Requires:       glib2
Requires:       glibc-common
Requires:       glibc-devel
Requires:       glibc-headers
Requires:       glibc-langpack-en
Requires:       glibc
Requires:       glx-utils
Requires:       gmp
Requires:       gnome-bluetooth-libs
Requires:       gnome-bluetooth
Requires:       gnome-control-center-filesystem
Requires:       gnome-control-center
Requires:       gnome-desktop3
Requires:       gnome-keyring-pam
Requires:       gnome-keyring
Requires:       gnome-online-accounts
Requires:       gnome-session-wayland-session
Requires:       gnome-session-xsession
Requires:       gnome-session
Requires:       gnome-settings-daemon
Requires:       gnome-shell
Requires:       gnome-themes-standard
Requires:       gnupg2-smime
Requires:       gnupg2
Requires:       gnutls
Requires:       go-srpm-macros
Requires:       gobject-introspection
Requires:       gpgme
Requires:       gpm-libs
Requires:       graphite2
Requires:       grep
Requires:       grilo
Requires:       groff-base
Requires:       grub2-common
Requires:       grub2-pc-modules
Requires:       grub2-pc
Requires:       grub2-tools-extra
Requires:       grub2-tools-minimal
Requires:       grub2-tools
Requires:       grubby
Requires:       gsettings-desktop-schemas
Requires:       gsm
Requires:       gstreamer1-plugins-base
Requires:       gstreamer1
Requires:       gtk-update-icon-cache
Requires:       gtk2
Requires:       gtk3
Requires:       guile
Requires:       gzip
Requires:       hardlink
Requires:       harfbuzz-icu
Requires:       harfbuzz
Requires:       hdparm
Requires:       hicolor-icon-theme
Requires:       hostname
Requires:       hunspell-en-GB
Requires:       hunspell-en-US
Requires:       hunspell-en
Requires:       hunspell
Requires:       hwdata
Requires:       hyphen
Requires:       ibus-gtk2
Requires:       ibus-gtk3
Requires:       ibus-libs
Requires:       ibus-setup
Requires:       ibus
Requires:       iio-sensor-proxy
Requires:       ima-evm-utils
Requires:       info
Requires:       initscripts
Requires:       ipcalc
Requires:       iproute
Requires:       iprutils
Requires:       ipset-libs
Requires:       ipset
Requires:       iptables-ebtables
Requires:       iptables-libs
Requires:       iptables
Requires:       iputils
Requires:       irqbalance
Requires:       isl
Requires:       iso-codes
Requires:       iwl100-firmware
Requires:       iwl1000-firmware
Requires:       iwl105-firmware
Requires:       iwl135-firmware
Requires:       iwl2000-firmware
Requires:       iwl2030-firmware
Requires:       iwl3160-firmware
Requires:       iwl3945-firmware
Requires:       iwl4965-firmware
Requires:       iwl5000-firmware
Requires:       iwl5150-firmware
Requires:       iwl6000-firmware
Requires:       iwl6000g2a-firmware
Requires:       iwl6050-firmware
Requires:       iwl7260-firmware
Requires:       jansson
Requires:       jasper-libs
Requires:       jbigkit-libs
Requires:       json-c
Requires:       json-glib
Requires:       kbd-legacy
Requires:       kbd-misc
Requires:       kbd
Requires:       kernel-headers
Requires:       kernel-modules
Requires:       kernel-tools-libs
Requires:       kernel-tools
Requires:       kernel
Requires:       kexec-tools
Requires:       keyutils-libs
Requires:       kmod-libs
Requires:       kmod
Requires:       kpartx
Requires:       krb5-libs
Requires:       langpacks-en
Requires:       lcms2
Requires:       less
Requires:       libICE
Requires:       libSM
Requires:       libX11-common
Requires:       libX11-xcb
Requires:       libX11
Requires:       libXau
Requires:       libXcomposite
Requires:       libXcursor
Requires:       libXdamage
Requires:       libXdmcp
Requires:       libXext
Requires:       libXfixes
Requires:       libXfont2
Requires:       libXft
Requires:       libXi
Requires:       libXinerama
Requires:       libXmu
Requires:       libXrandr
Requires:       libXrender
Requires:       libXt
Requires:       libXtst
Requires:       libXv
Requires:       libXxf86misc
Requires:       libXxf86vm
Requires:       libacl
Requires:       libaio
Requires:       libarchive
Requires:       libassuan
Requires:       libasyncns
Requires:       libatomic_ops
Requires:       libattr
Requires:       libbabeltrace
Requires:       libbasicobjects
Requires:       libblkid
Requires:       libcanberra-gtk3
Requires:       libcanberra
Requires:       libcap-ng
Requires:       libcap
Requires:       libcollection
Requires:       libcom_err
Requires:       libcomps
Requires:       libcroco
Requires:       libcurl
Requires:       libdaemon
Requires:       libdatrie
Requires:       libdb-utils
Requires:       libdb
Requires:       libdhash
Requires:       libdnf
Requires:       libdrm
Requires:       libedit
Requires:       libepoxy
Requires:       libestr
Requires:       libevdev
Requires:       libevent
Requires:       libfastjson
Requires:       libfdisk
Requires:       libffi
Requires:       libfontenc
Requires:       libgcc
Requires:       libgcrypt
Requires:       libgdata
Requires:       libglvnd-egl
Requires:       libglvnd-gles
Requires:       libglvnd-glx
Requires:       libglvnd
Requires:       libgnomekbd
Requires:       libgomp
Requires:       libgpg-error
Requires:       libgtop2
Requires:       libgudev
Requires:       libgusb
Requires:       libgweather
Requires:       libical
Requires:       libicu
Requires:       libidn2
Requires:       libimobiledevice
Requires:       libini_config
Requires:       libinput
Requires:       libipt
Requires:       libjpeg-turbo
Requires:       libkcapi-hmaccalc
Requires:       libkcapi
Requires:       libksba
Requires:       libldb
Requires:       libmaxminddb
Requires:       libmcpp
Requires:       libmetalink
Requires:       libmnl
Requires:       libmodman
Requires:       libmodulemd
Requires:       libmount
Requires:       libmpc
Requires:       libndp
Requires:       libnetfilter_conntrack
Requires:       libnfnetlink
Requires:       libnfsidmap
Requires:       libnftnl
Requires:       libnghttp2
Requires:       libnl3-cli
Requires:       libnl3
Requires:       libnma
Requires:       libnotify
Requires:       libnsl2
Requires:       liboauth
Requires:       libogg
Requires:       libpath_utils
Requires:       libpcap
Requires:       libpciaccess
Requires:       libpipeline
Requires:       libpkgconf
Requires:       libplist
Requires:       libpng
Requires:       libproxy
Requires:       libpsl
Requires:       libpwquality
Requires:       libquvi-scripts
Requires:       libquvi
Requires:       libref_array
Requires:       librepo
Requires:       libreport-filesystem
Requires:       librhsm
Requires:       librsvg2
Requires:       libseccomp
Requires:       libsecret
Requires:       libselinux-utils
Requires:       libselinux
Requires:       libsemanage
Requires:       libsepol
Requires:       libsigsegv
Requires:       libsmartcols
Requires:       libsmbclient
Requires:       libsndfile
Requires:       libsolv
Requires:       libsoup
Requires:       libss
Requires:       libssh
Requires:       libsss_autofs
Requires:       libsss_certmap
Requires:       libsss_idmap
Requires:       libsss_nss_idmap
Requires:       libsss_sudo
Requires:       libstdc++
Requires:       libsysfs
Requires:       libtalloc
Requires:       libtasn1
Requires:       libtdb
Requires:       libteam
Requires:       libtevent
Requires:       libthai
Requires:       libtheora
Requires:       libtiff
Requires:       libtirpc
Requires:       libtool-ltdl
Requires:       libunistring
Requires:       libusbmuxd
Requires:       libusbx
Requires:       libuser
Requires:       libutempter
Requires:       libuuid
Requires:       libverto
Requires:       libvisual
Requires:       libvorbis
Requires:       libwacom-data
Requires:       libwacom
Requires:       libwayland-client
Requires:       libwayland-cursor
Requires:       libwayland-egl
Requires:       libwayland-server
Requires:       libwbclient
Requires:       libwebp
Requires:       libxcb
Requires:       libxcrypt-devel
Requires:       libxcrypt
Requires:       libxkbcommon-x11
Requires:       libxkbcommon
Requires:       libxkbfile
Requires:       libxklavier
Requires:       libxml2
Requires:       libxshmfence
Requires:       libxslt
Requires:       libyaml
Requires:       linux-firmware
Requires:       llvm-libs
Requires:       logrotate
Requires:       lshw
Requires:       lsscsi
Requires:       lua-expat
Requires:       lua-json
Requires:       lua-libs
Requires:       lua-lpeg
Requires:       lua-socket
Requires:       lua
Requires:       lvm2-libs
Requires:       lvm2
Requires:       lz4-libs
Requires:       lzo
Requires:       man-db
Requires:       mcpp
Requires:       mesa-dri-drivers
Requires:       mesa-filesystem
Requires:       mesa-libEGL
Requires:       mesa-libGL
Requires:       mesa-libgbm
Requires:       mesa-libglapi
Requires:       microcode_ctl
Requires:       mobile-broadband-provider-info
Requires:       mozilla-filesystem
Requires:       mozjs52
Requires:       mpfr
Requires:       mtdev
Requires:       mutter
Requires:       ncurses-base
Requires:       ncurses-libs
Requires:       ncurses
Requires:       nettle
Requires:       newt
Requires:       nftables
Requires:       nm-connection-editor
Requires:       npth
Requires:       nspr
Requires:       nss-softokn-freebl
Requires:       nss-softokn
Requires:       nss-sysinit
Requires:       nss-util
Requires:       nss
Requires:       numactl-libs
Requires:       ocaml-srpm-macros
Requires:       openblas-srpm-macros
Requires:       openldap
Requires:       openssh-clients
Requires:       openssh-server
Requires:       openssh
Requires:       openssl-libs
Requires:       openssl-pkcs11
Requires:       openssl
Requires:       opus
Requires:       orc
Requires:       os-prober
Requires:       p11-kit-trust
Requires:       p11-kit
Requires:       pam
Requires:       pango
Requires:       parted
Requires:       passwd
Requires:       patch
Requires:       pciutils-libs
Requires:       pcre
Requires:       pcre2
Requires:       perl-srpm-macros
Requires:       pigz
Requires:       pinentry-gtk
Requires:       pinentry
Requires:       pipewire-libs
Requires:       pipewire
Requires:       pixman
Requires:       pkgconf-m4
Requires:       pkgconf-pkg-config
Requires:       pkgconf
Requires:       platform-python
Requires:       plymouth-core-libs
Requires:       plymouth-scripts
Requires:       plymouth
Requires:       policycoreutils
Requires:       polkit-libs
Requires:       polkit-pkla-compat
Requires:       polkit
Requires:       popt
Requires:       prefixdevname
Requires:       procps-ng
Requires:       psmisc
Requires:       publicsuffix-list-dafsa
Requires:       pulseaudio-libs-glib2
Requires:       pulseaudio-libs
Requires:       pulseaudio-module-bluetooth
Requires:       pulseaudio
Requires:       python-srpm-macros
Requires:       python3-cairo
Requires:       python3-configobj
Requires:       python3-dateutil
Requires:       python3-dbus
Requires:       python3-decorator
Requires:       python3-dmidecode
Requires:       python3-dnf-plugins-core
Requires:       python3-dnf
Requires:       python3-ethtool
Requires:       python3-firewall
Requires:       python3-gobject-base
Requires:       python3-gobject
Requires:       python3-gpg
Requires:       python3-hawkey
Requires:       python3-iniparse
Requires:       python3-inotify
Requires:       python3-libcomps
Requires:       python3-libdnf
Requires:       python3-librepo
Requires:       python3-libs
Requires:       python3-libselinux
Requires:       python3-libxml2
Requires:       python3-linux-procfs
Requires:       python3-perf
Requires:       python3-pip
Requires:       python3-pyudev
Requires:       python3-rpm-macros
Requires:       python3-rpm
Requires:       python3-schedutils
Requires:       python3-setuptools
Requires:       python3-six
Requires:       python3-slip-dbus
Requires:       python3-slip
Requires:       python3-subscription-manager-rhsm
Requires:       python3-syspurpose
Requires:       python3-unbound
Requires:       qemu-guest-agent
Requires:       qt5-srpm-macros
Requires:       readline
Requires:       redhat-backgrounds
Requires:       redhat-logos
Requires:       redhat-release
Requires:       redhat-rpm-config
Requires:       rest
Requires:       rootfiles
Requires:       rpm-build-libs
Requires:       rpm-build
Requires:       rpm-libs
Requires:       rpm-plugin-selinux
Requires:       rpm-plugin-systemd-inhibit
Requires:       rpm
Requires:       rsync
Requires:       rsyslog
Requires:       rtkit
Requires:       rust-srpm-macros
Requires:       samba-client-libs
Requires:       samba-common-libs
Requires:       samba-common
Requires:       sbc
Requires:       sed
Requires:       selinux-policy-targeted
Requires:       selinux-policy
Requires:       setup
Requires:       sg3_utils-libs
Requires:       sg3_utils
Requires:       shadow-utils
Requires:       shared-mime-info
Requires:       slang
Requires:       snappy
Requires:       sound-theme-freedesktop
Requires:       speexdsp
Requires:       sqlite-libs
Requires:       squashfs-tools
Requires:       sssd-client
Requires:       sssd-common
Requires:       sssd-kcm
Requires:       sssd-nfs-idmap
Requires:       startup-notification
Requires:       subscription-manager-rhsm-certificates
Requires:       subscription-manager
Requires:       sudo
Requires:       switcheroo-control
Requires:       systemd-libs
Requires:       systemd-pam
Requires:       systemd-udev
Requires:       systemd
Requires:       tar
Requires:       teamd
Requires:       totem-pl-parser
Requires:       trousers-lib
Requires:       trousers
Requires:       tuned
Requires:       tzdata
Requires:       unbound-libs
Requires:       unzip
Requires:       upower
Requires:       usermode
Requires:       util-linux
Requires:       vim-common
Requires:       vim-enhanced
Requires:       vim-filesystem
Requires:       vim-minimal
Requires:       vino
Requires:       virt-what
Requires:       webkit2gtk3-jsc
Requires:       webkit2gtk3-plugin-process-gtk2
Requires:       webkit2gtk3
Requires:       webrtc-audio-processing
Requires:       which
Requires:       woff2
Requires:       wpa_supplicant
Requires:       xcb-util
Requires:       xfsprogs
Requires:       xkeyboard-config
Requires:       xml-common
Requires:       xorg-x11-server-Xwayland
Requires:       xorg-x11-server-common
Requires:       xorg-x11-server-utils
Requires:       xorg-x11-xauth
Requires:       xorg-x11-xinit
Requires:       xorg-x11-xkb-utils
Requires:       xz-libs
Requires:       xz
Requires:       yum
Requires:       zenity
Requires:       zip
Requires:       zlib


# A Striker dashboard is not allowed to host servers or be a migration target. 
# So the node and dr packages can not be installed.
Conflicts: 	anvil-node
Conflicts:	anvil-dr
%description striker
Web interface of the Striker dashboard for Alteeve Anvil! systems

NOTE: This installs and enables Gnome desktop.

%package node 
Summary:        Alteeve's Anvil! node package
Requires:	anvil-core
Requires:       bridge-utils 
Requires:       drbd 
Requires:       drbd-bash-completion 
Requires:       drbd-utils 
### NOTE: Disabled only until we get drbd9 building on F28
#Requires:       drbd-kernel 
#Requires:       kmod-drbd 
Requires:       libvirt 
Requires:       libvirt-daemon 
Requires:       libvirt-daemon-driver-qemu 
Requires:       libvirt-daemon-kvm 
Requires:       libvirt-docs 
Requires:       pacemaker 
Requires:       pcs 
Requires:       qemu-kvm 
Requires:       qemu-kvm-core 
Requires:       virt-install
# A node is allowed to host servers and be a live migration target. It is not 
# allowed to host a database or be a DR host.
Conflicts:	anvil-striker
Conflicts:	anvil-dr

%description node

Provides support for active node in an Anvil! pair.

NOTE: On RHEL proper, this requires the node had the "High-Availability 
Add-on".

NOTE: LINBIT customers must have access to the LINBIT repositories configured.

%package dr
Summary:        Alteeve's Anvil! DR host package
Requires:	anvil-core
Requires:       bridge-utils 
Requires:       drbd 
Requires:       drbd-bash-completion 
Requires:       drbd-utils 
### NOTE: Disabled only until we get drbd9 building on F28
#Requires:       drbd-kernel 
#Requires:       kmod-drbd 
Requires:       libvirt 
Requires:       libvirt-daemon 
Requires:       libvirt-daemon-driver-qemu 
Requires:       libvirt-daemon-kvm 
Requires:       libvirt-docs 
Requires:       qemu-kvm 
Requires:       qemu-kvm-core 
Requires:       virt-install
# A DR host is not allowed to be a live-migration target or host a database.
Conflicts:	anvil-striker
Conflicts:	anvil-node

%description dr

Provides support for asynchronous disaster recovery hosts in an Anvil! cluster.


%prep
%autosetup -n anvil-master


%build


%install
rm -rf $RPM_BUILD_ROOT
mkdir -p %{buildroot}/%{_sbindir}/scancore-agents/
mkdir -p %{buildroot}/%{_sysconfdir}/anvil/
mkdir -p %{buildroot}/%{_localstatedir}/www/
mkdir -p %{buildroot}/%{_usr}/share/anvil/
install -d -p Anvil %{buildroot}/%{_datadir}/perl5/
install -d -p html %{buildroot}/%{_localstatedir}/www/
install -d -p cgi-bin %{buildroot}/%{_localstatedir}/www/
install -d -p units/ %{buildroot}/%{_usr}/lib/systemd/system/
install -d -p tools/ %{buildroot}/%{_sbindir}/
cp -R -p Anvil %{buildroot}/%{_datadir}/perl5/
cp -R -p html %{buildroot}/%{_localstatedir}/www/
cp -R -p cgi-bin %{buildroot}/%{_localstatedir}/www/
cp -R -p units/* %{buildroot}/%{_usr}/lib/systemd/system/
cp -R -p tools/* %{buildroot}/%{_sbindir}/
cp -R -p scancore-agents %{buildroot}/%{_sbindir}/
cp -R -p anvil.conf %{buildroot}/%{_sysconfdir}/anvil/
cp -R -p anvil.version %{buildroot}/%{_sysconfdir}/anvil/
cp -R -p share/* %{buildroot}/%{_usr}/share/anvil/


%pre core
if [ ! -d /usr/share/anvil ];
then
    mkdir /usr/share/anvil
fi
getent group %{anvilgroup} >/dev/null || groupadd -r %{anvilgroup}
getent passwd %{anviluser} >/dev/null || useradd --create-home \
    --gid %{anvilgroup}  --comment "Anvil! user account" %{anviluser}

%post core
# TODO: Remove this!! This is only for use during development, all SELinux 
#       issues must be resolved before final release!
echo "WARNING: Setting SELinux to 'permissive' during development."
sed -i.anvil 's/SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config 
setenforce 0
sed -i "1s/^.*$/%{version}-%{release}/" /%{_sysconfdir}/anvil/anvil.version
# Enable and start the anvil-daemon
systemctl enable anvil-daemon.service
systemctl start anvil-daemon.service


%post striker
### NOTE: PostgreSQL is initialized and enabled by anvil-prep-database later.
echo "Enabling and starting apache."
systemctl enable httpd.service
systemctl start httpd.service
restorecon -rv /%{_localstatedir}/www
if ! $(ls -l /etc/systemd/system/default.target | grep -q graphical); 
then 
    echo "Seting graphical interface as default on boot."
    systemctl set-default graphical.target
    systemctl enable gdm.service
fi

echo "Preparing the database"
anvil-prep-database
anvil-update-states

### TODO: I don't think we need this anymore
# Open access for Striker. The database will be opened after initial setup.
echo "Opening the web and postgresql ports."
firewall-cmd --add-service=http
firewall-cmd --add-service=http --permanent
firewall-cmd --add-service=https
firewall-cmd --add-service=https --permanent
firewall-cmd --add-service=postgresql
firewall-cmd --add-service=postgresql --permanent

### Remove stuff - Disabled for now, messes things up during upgrades
%postun core
## This is breaking on upgrades - (note: switch back to single percent sign 
##                                       when re-enabling)
#getent passwd %%{anviluser} >/dev/null && userdel %%{anviluser}
#getent group %%{anvilgroup} >/dev/null && groupdel %%{anvilgroup}
# echo "NOTE: Re-enabling SELinux."
# sed -i.anvil 's/SELINUX=permissive/SELINUX=enforcing/' /etc/selinux/config 
# setenforce 1

%postun striker
### TODO: Stopping postgres breaks the Anvil! during OS updates. Need to find a
###       way to run this only during uninstalls, and not during updates.
### TODO: This breaks the repos
# rm -rf /usr/share/anvil
# echo "Closing the postgresql ports."
#firewall-cmd --zone=public --remove-service=http
#firewall-cmd --zone=public --remove-service=http --permanent
# firewall-cmd --zone=public --remove-service=postgresql
# firewall-cmd --zone=public --remove-service=postgresql --permanent
# echo "Disabling and stopping postgresql-9.6."
# systemctl disable httpd.service
# systemctl stop httpd.service
# systemctl disable postgresql.service
# systemctl stop postgresql.service


%files core
%doc README.md notes
%config(noreplace) %{_sysconfdir}/anvil/anvil.conf
%config(noreplace) %{_datadir}/anvil/anvil.sql
%{_usr}/lib/*
%{_usr}/share/anvil/*
%{_sbindir}/*
%{_sbindir}/scancore-agents/*
%{_sysconfdir}/anvil/anvil.version
%{_datadir}/perl5/*

%files striker
%attr(0775, apache, root) %{_localstatedir}/www/*/*
%ghost %{_sysconfdir}/anvil/snmp-vendors.txt

%files node
#<placeholder for node specific files>

%files dr
#<placeholder for node specific files>


%changelog
* Sat Jan 05 2019 Madison Kelly <mkelly@alteeve.ca> 3.0-21
- Started adding support for ScanCore
- Updated source.
- Updated for EL8.

* Wed Dec 12 2018 Madison Kelly <mkelly@alteeve.ca> 3.0-20
- Updated source.

* Fri Nov 30 2018 Madison Kelly <mkelly@alteeve.ca> 3.0-19
- Added packages to anvil-striker to support PXE server / install target 
  functions.
- Updated source.

* Sat Oct 06 2018 Madison Kelly <mkelly@alteeve.ca> 3.0-18
- Updated the source to resolve a major bug introduced by the code in the .17
  release. 

* Thu Oct 04 2018 Madison Kelly <mkelly@alteeve.ca> 3.0-17
- Added 'perl-UUID-Tiny' to core dependencies.
- Updated source.

* Fri Sep 14 2018 Madison Kelly <mkelly@alteeve.ca> 3.0-16
- Added htop as a -core dependency.
- Now enables anvil-daemon.
- Disabled 'postun' for now.

* Thu Aug 30 2018 Madison Kelly <mkelly@alteeve.ca> 3.0-15
- Added perl-HTML-FromText and perl-HTML-Strip to anvil-core requires list.
- Added a check to see if /usr/share/anvil exists before trying to create it.
- Disabled postun until we can sort out how not to cause issues during 
  upgrades.

* Wed Aug 15 2018 Madison Kelly <mkelly@alteeve.ca> 3.0-14
- The new requirement for perl-Proc-Simple had a trailing semi-colon that 
  slipped past the -13 release tests. Fixed here.

* Tue Aug 14 2018 Madison Kelly <mkelly@alteeve.ca> 3.0-13
- Disabled the postun as it breaks connections to the DB during updates.

* Thu Aug 02 2018 Madison Kelly <mkelly@alteeve.ca> 3.0-12
- Added perl-Proc-Simple to core dependencies.

* Tue Jul 24 2018 Madison Kelly <mkelly@alteeve.ca> 3.0-11
- Added a check to enable the graphical target on boot.
- Updated anvil-striker dependency list to pull in gnome.

* Tue Jul 24 2018 Madison Kelly <mkelly@alteeve.ca> 3.0-10
- Began switching to Fedora 28 (as an analog for EL8)

* Fri Jul 13 2018 Madison Kelly <mkelly@alteeve.ca> 3.0-9
- Updated the source tarball.

* Fri Jul 13 2018 Madison Kelly <mkelly@alteeve.ca> 3.0-8
- Fixed the path to anvil.sql

* Thu Jul 12 2018 Madison Kelly <mkelly@alteeve.ca> 3.0-7
- Added an explicit call to anvil-prep-database in post.

* Thu Jul 12 2018 Madison Kelly <mkelly@alteeve.ca> 3.0-6
- Fixed 'pre' to actually run for 'core'.
- Added 'postun' to cleanup after removal.

* Wed Jul 11 2018 Madison Kelly <mkelly@alteeve.ca> 3.0-5
- Restored stock pacemaker/corosync. 

* Tue Jul 10 2018 Madison Kelly <mkelly@alteeve.ca> 3.0-4
- Added a check for and creation of the 'admin' user/group.
- Updated the pacemaker dependency to 'pacemaker2'.
- Added packages for anvil-striker to pull in Gnome.

* Sun Mar 18 2018 Madison Kelly <mkelly@alteeve.ca> 3.0-3
- Changed the 'Obsoletes' to 'Conflicts'.

* Sat Mar 17 2018 Madison Kelly <mkelly@alteeve.ca> 3.0-2
- Added a post task to striker to enable/start apache.

* Wed Mar 14 2018 Madison Kelly <mkelly@alteeve.ca> 3.0-1
- Dropped the 'a' from the version.
- Expanded the list of requirements.
- Added the 'node' and 'dr' packages.

* Fri Jan 26 2018 Matthew Marangoni <matthew.marangoni@senecacollege.ca> 3.0a-1
- Initial RPM release
