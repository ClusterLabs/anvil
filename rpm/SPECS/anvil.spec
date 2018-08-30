%define debug_package %{nil}
%define anviluser     admin
%define anvilgroup    admin
Name:           anvil
Version:        3.0
Release:        15%{?dist}
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
Requires:       fence-agents-all 
Requires:       fence-agents-virsh 
Requires:       firewalld
Requires:       gpm 
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
Requires:       perl-NetAddr-IP 
Requires:       perl-Proc-Simple
Requires:       perl-Sys-Syslog
Requires:       perl-Time-HiRes
Requires:       perl-XML-Simple 
Requires:       postgresql-contrib 
Requires:       postgresql-plperl 
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
Requires:       httpd
Requires:	anvil-core
Requires:       httpd
Requires:       nmap
Requires:       perl-CGI 
Requires:       postgresql-server 
Requires:       firefox
Requires:       virt-manager
### Desktop stuff
Requires:       aajohan-comfortaa-fonts
Requires:       abattis-cantarell-fonts
Requires:       adobe-source-han-sans-cn-fonts
Requires:       adobe-source-han-sans-tw-fonts
Requires:       adobe-source-han-serif-cn-fonts
Requires:       adobe-source-han-serif-tw-fonts
Requires:       adwaita-gtk2-theme
Requires:       adwaita-icon-theme
Requires:       alsa-plugins-pulseaudio
Requires:       alsa-ucm
Requires:       alsa-utils
Requires:       awesome
Requires:       dconf
Requires:       dconf-editor
Requires:       dejavu-sans-fonts
Requires:       dejavu-sans-mono-fonts
Requires:       dejavu-serif-fonts
Requires:       dwm
Requires:       fedora-icon-theme
Requires:       gdm
Requires:       glx-utils
Requires:       gnu-free-mono-fonts
Requires:       gnu-free-sans-fonts
Requires:       gnu-free-serif-fonts
Requires:       google-noto-emoji-color-fonts
Requires:       google-noto-emoji-fonts
Requires:       google-noto-sans-lisu-fonts
Requires:       google-noto-sans-mandaic-fonts
Requires:       google-noto-sans-meetei-mayek-fonts
Requires:       google-noto-sans-sinhala-fonts
Requires:       google-noto-sans-tagalog-fonts
Requires:       google-noto-sans-tai-tham-fonts
Requires:       google-noto-sans-tai-viet-fonts
Requires:       gnome-screenshot
Requires:       gnome-shell
Requires:       gnome-terminal
Requires:       gnome-autoar
Requires:       gnome-backgrounds
Requires:       gnome-calculator
Requires:       gnome-characters
Requires:       gnome-classic-session
Requires:       gnome-clocks
Requires:       gnome-color-manager
Requires:       gnome-disk-utility
Requires:       gnome-documents
Requires:       gnome-documents-libs
Requires:       gnome-font-viewer
Requires:       gnome-logs
Requires:       gnome-menus
Requires:       gnome-shell-extension-alternate-tab
Requires:       gnome-shell-extension-apps-menu
Requires:       gnome-shell-extension-common
Requires:       gnome-shell-extension-launch-new-instance
Requires:       gnome-shell-extension-places-menu
Requires:       gnome-shell-extension-window-list
Requires:       gnome-software
Requires:       gnome-system-monitor
Requires:       gnome-user-docs
Requires:       gnome-user-share
Requires:       hyperv-daemons
Requires:       i3
Requires:       isdn4k-utils
Requires:       jomolhari-fonts
Requires:       julietaula-montserrat-fonts
Requires:       khmeros-base-fonts
Requires:       liberation-mono-fonts
Requires:       liberation-sans-fonts
Requires:       liberation-serif-fonts
Requires:       lightdm-gtk
Requires:       linux-atm
Requires:       lohit-assamese-fonts
Requires:       lohit-bengali-fonts
Requires:       lohit-devanagari-fonts
Requires:       lohit-gujarati-fonts
Requires:       lohit-gurmukhi-fonts
Requires:       lohit-kannada-fonts
Requires:       lohit-odia-fonts
Requires:       lohit-tamil-fonts
Requires:       lohit-telugu-fonts
Requires:       lrzsz
Requires:       mesa-dri-drivers
Requires:       metacity
Requires:       minicom
Requires:       naver-nanum-gothic-fonts
Requires:       NetworkManager-adsl
Requires:       NetworkManager-ppp
Requires:       open-vm-tools-desktop
Requires:       openbox
Requires:       PackageKit-gstreamer-plugin
Requires:       paktype-naskh-basic-fonts
Requires:       paratype-pt-sans-fonts
Requires:       plymouth-system-theme
Requires:       ppp
Requires:       qtile
Requires:       ratpoison
Requires:       rp-pppoe
Requires:       setroubleshoot
Requires:       sil-abyssinica-fonts
Requires:       sil-mingzat-fonts
Requires:       sil-nuosu-fonts
Requires:       sil-padauk-fonts
Requires:       smc-meera-fonts
Requires:       spice-vdagent
Requires:       stix-fonts
Requires:       tabish-eeyek-fonts
Requires:       thai-scalable-waree-fonts
Requires:       tigervnc-server
Requires:       vlgothic-fonts
Requires:       wvdial
Requires:       xmonad-basic
Requires:       xorg-x11-drv-ati
Requires:       xorg-x11-drv-evdev
Requires:       xorg-x11-drv-fbdev
Requires:       xorg-x11-drv-intel
Requires:       xorg-x11-drv-libinput
Requires:       xorg-x11-drv-nouveau
Requires:       xorg-x11-drv-openchrome
Requires:       xorg-x11-drv-qxl
Requires:       xorg-x11-drv-vesa
Requires:       xorg-x11-drv-vmware
Requires:       xorg-x11-drv-wacom
Requires:       xorg-x11-server-Xorg
Requires:       xorg-x11-utils
Requires:       xorg-x11-xauth
Requires:       xorg-x11-xinit


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
mkdir -p %{buildroot}/%{_sbindir}/anvil/
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
cp -R -p tools/* %{buildroot}/%{_sbindir}
cp -R -p anvil.conf %{buildroot}/%{_sysconfdir}/anvil/
cp -R -p anvil.version %{buildroot}/%{_sysconfdir}/anvil/
cp -R -p share/* %{buildroot}/%{_usr}/share/anvil/
mv %{buildroot}/%{_sbindir}/anvil.sql %{buildroot}/%{_datadir}/anvil/anvil.sql


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

# Open access for Striker. The database will be opened after initial setup.
echo "Opening the web and postgresql ports."
firewall-cmd --add-service=http
firewall-cmd --add-service=http --permanent
firewall-cmd --add-service=https
firewall-cmd --add-service=https --permanent
firewall-cmd --add-service=postgresql
firewall-cmd --add-service=postgresql --permanent

### Remove stuff
%postun core
getent passwd %{anviluser} >/dev/null && userdel %{anviluser}
getent group %{anvilgroup} >/dev/null && groupdel %{anvilgroup}
echo "NOTE: Re-enabling SELinux."
sed -i.anvil 's/SELINUX=permissive/SELINUX=enforcing/' /etc/selinux/config 
setenforce 1

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
* Wed Aug 29 2018 Madison Kelly <mkelly@alteeve.ca> 3.0-15
- Added perl-HTML-FromText and perl-HTML-Strip to anvil-core requires list.
- Added a check to see if /usr/share/anvil exists before trying to create it.

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
