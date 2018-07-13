%define debug_package %{nil}
%define anviluser     admin
%define anvilgroup    admin
Name:           anvil
Version:        3.0
Release:        7%{?dist}
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
Requires:       fence-agents-all 
Requires:       fence-agents-virsh 
Requires:       firewalld
Requires:       gpm 
Requires:       mlocate 
Requires:       perl-Data-Dumper 
Requires:       perl-DBD-Pg 
Requires:       perl-DBI
Requires:       perl-Digest-SHA
Requires:       perl-JSON 
Requires:       perl-Log-Journald 
Requires:       perl-Net-SSH2 
Requires:       perl-NetAddr-IP 
Requires:       perl-Time-HiRes
Requires:       perl-XML-Simple 
Requires:       postgresql96-contrib 
Requires:       postgresql96-plperl 
Requires:       rsync 
Requires:       screen 
Requires:       vim 
# iptables-services conflicts with firewalld
Conflicts:      iptables-services
# We handle interface naming
Conflicts:      biosdevname

%description core
Common base libraries required for the Anvil! system.


%package striker
Summary:        Alteeve's Anvil! Striker dashboard package
BuildRequires:  httpd
Requires:	anvil-core
Requires:       httpd
Requires:       nmap
Requires:       perl-CGI 
Requires:       postgresql96-server 
Requires:       firefox
Requires:       virt-manager
### Gnome Desktop group
Requires:       abrt-desktop
Requires:       at-spi2-atk
Requires:       at-spi2-core
# Requires:       avahi
# Requires:       baobab
Requires:       caribou
Requires:       caribou-gtk2-module
Requires:       caribou-gtk3-module
# Requires:       cheese
# Requires:       compat-cheese314
Requires:       control-center
Requires:       dconf
# Requires:       empathy
# Requires:       eog
Requires:       evince
Requires:       evince-nautilus
Requires:       file-roller
Requires:       file-roller-nautilus
# Requires:       firewall-config
# Requires:       firstboot
# Requires:       fprintd-pam
Requires:       gdm
Requires:       gedit
Requires:       glib-networking
Requires:       gnome-bluetooth
# Requires:       gnome-boxes
Requires:       gnome-calculator
Requires:       gnome-classic-session
Requires:       gnome-clocks
# Requires:       gnome-color-manager
# Requires:       gnome-contacts
Requires:       gnome-dictionary
Requires:       gnome-disk-utility
Requires:       gnome-font-viewer
# Requires:       gnome-getting-started-docs
Requires:       gnome-icon-theme
Requires:       gnome-icon-theme-extras
Requires:       gnome-icon-theme-symbolic
# Requires:       gnome-initial-setup
Requires:       gnome-packagekit
Requires:       gnome-packagekit-updater
Requires:       gnome-screenshot
Requires:       gnome-session
Requires:       gnome-session-xsession
Requires:       gnome-settings-daemon
Requires:       gnome-shell
Requires:       gnome-software
Requires:       gnome-system-log
Requires:       gnome-system-monitor
Requires:       gnome-terminal
Requires:       gnome-terminal-nautilus
Requires:       gnome-themes-standard
Requires:       gnome-tweak-tool
Requires:       gnome-user-docs
Requires:       gnome-weather
Requires:       gucharmap
Requires:       gvfs-afc
Requires:       gvfs-afp
Requires:       gvfs-archive
Requires:       gvfs-fuse
Requires:       gvfs-goa
Requires:       gvfs-gphoto2
Requires:       gvfs-mtp
Requires:       gvfs-smb
# Requires:       initial-setup-gui
Requires:       libcanberra-gtk2
Requires:       libcanberra-gtk3
Requires:       libproxy-mozjs
Requires:       librsvg2
Requires:       libsane-hpaio
Requires:       metacity
Requires:       mousetweaks
Requires:       nautilus
# Requires:       nautilus-sendto
# Requires:       NetworkManager-libreswan-gnome
Requires:       nm-connection-editor
Requires:       orca
Requires:       PackageKit-command-not-found
Requires:       PackageKit-gtk3-module
# Requires:       redhat-access-gui
# Requires:       sane-backends-drivers-scanners
# Requires:       seahorse
Requires:       setroubleshoot
Requires:       sushi
# Requires:       totem
# Requires:       totem-nautilus
Requires:       vinagre
# Requires:       vino
Requires:       xdg-user-dirs-gtk
Requires:       yelp
Requires:       qgnomeplatform
Requires:       xdg-desktop-portal-gtk
Requires:       alacarte
Requires:       dconf-editor
# Requires:       dvgrab
Requires:       fonts-tweak-tool
Requires:       gconf-editor
Requires:       gedit-plugins
Requires:       gnome-shell-browser-plugin
Requires:       gnote
Requires:       libappindicator-gtk3
# Requires:       seahorse-nautilus
# Requires:       seahorse-sharing
# Requires:       vim-X11
# Requires:       xguest
### x11 group
Requires:       glx-utils
Requires:       initial-setup-gui
Requires:       mesa-dri-drivers
Requires:       plymouth-system-theme
Requires:       spice-vdagent
Requires:       xorg-x11-drivers
Requires:       xorg-x11-server-Xorg
Requires:       xorg-x11-utils
Requires:       xorg-x11-xauth
Requires:       xorg-x11-xinit
Requires:       xvattr
Requires:       tigervnc-server
# Requires:       wayland-protocols-devel
Requires:       xorg-x11-drv-keyboard
Requires:       xorg-x11-drv-libinput
Requires:       xorg-x11-drv-mouse
Requires:       xorg-x11-drv-openchrome

# A Striker dashboard is not allowed to host servers or be a migration target. 
# So the node and dr packages can not be installed.
Conflicts: 	anvil-node
Conflicts:	anvil-dr
%description striker
Web interface of the Striker dashboard for Alteeve Anvil! systems


%package node 
Summary:        Alteeve's Anvil! node package
Requires:	anvil-core
Requires:       bridge-utils 
Requires:       drbd 
Requires:       drbd-bash-completion 
Requires:       drbd-kernel 
Requires:       drbd-utils 
Requires:       kernel-doc 
Requires:       kmod-drbd 
Requires:       libvirt 
Requires:       libvirt-daemon 
Requires:       libvirt-daemon-driver-qemu 
Requires:       libvirt-daemon-kvm 
Requires:       libvirt-docs 
Requires:       pacemaker 
Requires:       pcs 
Requires:       qemu-kvm 
Requires:       qemu-kvm-common 
Requires:       qemu-kvm-tools 
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
Requires:       drbd-kernel 
Requires:       drbd-utils 
Requires:       kernel-doc 
Requires:       kmod-drbd 
Requires:       libvirt 
Requires:       libvirt-daemon 
Requires:       libvirt-daemon-driver-qemu 
Requires:       libvirt-daemon-kvm 
Requires:       libvirt-docs 
Requires:       qemu-kvm 
Requires:       qemu-kvm-common 
Requires:       qemu-kvm-tools 
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
mkdir -p %{buildroot}/%{_sbindir}/anvil/
mkdir -p %{buildroot}/%{_sysconfdir}/anvil/
mkdir -p %{buildroot}/%{_localstatedir}/www/
install -d -p Anvil %{buildroot}/%{_datadir}/perl5/
install -d -p html %{buildroot}/%{_localstatedir}/www/
install -d -p cgi-bin %{buildroot}/%{_localstatedir}/www/
install -d -p units/ %{buildroot}/usr/lib/systemd/system/
install -d -p tools/ %{buildroot}/%{_sbindir}/
cp -R -p Anvil %{buildroot}/%{_datadir}/perl5/
cp -R -p html %{buildroot}/%{_localstatedir}/www/
cp -R -p cgi-bin %{buildroot}/%{_localstatedir}/www/
cp -R -p units/* %{buildroot}/usr/lib/systemd/system/
cp -R -p tools/* %{buildroot}/%{_sbindir}
cp -R -p anvil.conf %{buildroot}/%{_sysconfdir}/anvil/
cp -R -p anvil.version %{buildroot}/%{_sysconfdir}/anvil/
mv %{buildroot}/%{_sbindir}/anvil.sql %{buildroot}/%{_datadir}/anvil.sql


%pre core
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

%post striker
### NOTE: PostgreSQL is initialized and enabled by anvil-prep-database later.
echo "Enabling and starting apache."
systemctl enable httpd.service
systemctl start httpd.service
restorecon -rv /%{_localstatedir}/www
echo "Preparing the database"
anvil-prep-database

# Open access for Striker. The database will be opened after initial setup.
echo "Opening the web and postgresql ports."
firewall-cmd --zone=public --add-service=http
firewall-cmd --zone=public --add-service=http --permanent
firewall-cmd --zone=public --add-service=postgresql
firewall-cmd --zone=public --add-service=postgresql --permanent

### Remove stuff
%postun core
getent passwd %{anviluser} >/dev/null && userdel %{anviluser}
getent group %{anvilgroup} >/dev/null && groupdel %{anvilgroup}
echo "NOTE: Re-enabling SELinux."
sed -i.anvil 's/SELINUX=permissive/SELINUX=enforcing/' /etc/selinux/config 
setenforce 1

%postun striker
### TODO: This breaks the repos
echo "Closing the postgresql ports."
#firewall-cmd --zone=public --remove-service=http
#firewall-cmd --zone=public --remove-service=http --permanent
firewall-cmd --zone=public --remove-service=postgresql
firewall-cmd --zone=public --remove-service=postgresql --permanent
echo "Disabling and stopping postgresql-9.6."
# systemctl disable httpd.service
# systemctl stop httpd.service
systemctl disable postgresql-9.6.service
systemctl stop postgresql-9.6.service


%files core
%doc README.md notes
%config(noreplace) %{_sysconfdir}/anvil/anvil.conf
%config(noreplace) %{_datadir}/anvil.sql
%{_usr}/lib/*
%{_sbindir}/*
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
* Thu Jul 12 2018 Madison Kelly <mkelly@alteeve.ca> 3.0-7
- Fixed the postgresql dependencies to v9.6
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
