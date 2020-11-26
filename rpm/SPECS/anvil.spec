%define debug_package %{nil}
%define anviluser     admin
%define anvilgroup    admin
Name:           anvil
Version:        3.0
Release:        37%{?dist}
Summary:        Alteeve Anvil! complete package.

License:        GPLv2+
URL:            https://github.com/digimer/anvil
Source0:        https://www.alteeve.com/an-repo/el8b/files/anvil-3.0b.tar.gz
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
Requires:       binutils
Requires:       chrony
Requires:       cyrus-sasl
Requires:       cyrus-sasl-gssapi
Requires:       cyrus-sasl-lib
Requires:       cyrus-sasl-md5
Requires:       cyrus-sasl-plain
Requires:       bind-utils 
Requires:       dmidecode
Requires:       dnf-utils
Requires:       expect
Requires:       fence-agents-all 
Requires:       fence-agents-virsh 
Requires:       firewalld
Requires:       freeipmi
Requires:       gpm 
Requires:       hdparm
Requires:       htop
Requires:       iproute
Requires:       kernel-core
Requires:       kernel-devel
Requires:       kernel-headers
Requires:       lsscsi
Requires:       mailx
Requires:       mlocate 
Requires:       net-snmp-utils
Requires:       nvme-cli
Requires:       perl-Capture-Tiny
Requires:       perl-Data-Dumper 
Requires:       perl-Data-Validate-Domain
Requires:       perl-Data-Validate-IP
Requires:       perl-DBD-Pg 
Requires:       perl-DBI
Requires:       perl-Data-Validate-Domain
Requires:       perl-Digest-SHA
Requires:       perl-File-MimeInfo
Requires:       perl-HTML-FromText
Requires:       perl-HTML-Strip
Requires:       perl-IO-Tty
Requires:       perl-JSON 
Requires:       perl-Log-Journald 
Requires:       perl-Mail-RFC822-Address
Requires:       perl-Net-Domain-TLD
Requires:       perl-Net-SSH2 
Requires:       perl-Net-Netmask
Requires:       perl-Net-OpenSSH
Requires:       perl-NetAddr-IP 
Requires:       perl-Proc-Simple
Requires:       perl-Sys-Syslog
Requires:       perl-Sys-Virt
Requires:       perl-Text-Diff
Requires:       perl-Time-HiRes
Requires:       perl-UUID-Tiny
Requires:       perl-XML-LibXML 
Requires:       perl-XML-Simple 
Requires:       postfix
Requires:       postgresql-contrib 
Requires:       postgresql-plperl 
Requires:       rsync 
Requires:       screen
Requires:       smartmontools
Requires:       syslinux
Requires:       tmux
Requires:       unzip
Requires:       usbutils
Requires:       vim 
Requires:       wget
# iptables-services conflicts with firewalld
Conflicts:      iptables-services
# We handle interface naming
Conflicts:      biosdevname

%description core
Common base libraries required for the Anvil! system.


%package striker
Summary:        Alteeve's Anvil! Striker dashboard package
Requires:       anvil-core == %{version}-%{release}
Requires:       anvil-striker-extra
Requires:       bpg-dejavu-sans-fonts
Requires:       createrepo
Requires:       dejavu-fonts-common
Requires:       dejavu-sans-fonts
Requires:       dejavu-sans-mono-fonts
Requires:       dejavu-serif-fonts
Requires:       dhcp-server
Requires:       firefox
Requires:       gcc
Requires:       gdm
Requires:       gnome-terminal
Requires:       httpd
Requires:       nmap
Requires:       perl-CGI 
Requires:       postgresql-server 
Requires:       syslinux
Requires:       syslinux-nonlinux
Requires:       tftp-server
Requires:       virt-manager


# A Striker dashboard is not allowed to host servers or be a migration target. 
# So the node and dr packages can not be installed.
Conflicts: 	anvil-node
Conflicts:	anvil-dr
%description striker
Web interface of the Striker dashboard for Alteeve Anvil! systems

NOTE: This installs and enables Gnome desktop.

%package node 
Summary:        Alteeve's Anvil! node package
Requires:	anvil-core == %{version}-%{release}
Requires:       drbd90-utils 
Requires:       kmod-drbd90
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
Requires:       virt-top
# A node is allowed to host servers and be a live migration target. It is not 
# allowed to host a database or be a DR host.
Conflicts:      anvil-striker
Conflicts:      anvil-dr

%description node

Provides support for active node in an Anvil! pair.

NOTE: On RHEL proper, this requires the node had the "High-Availability 
Add-on".

NOTE: LINBIT customers must have access to the LINBIT repositories configured.

%package dr
Summary:        Alteeve's Anvil! DR host package
Requires:	anvil-core == %{version}-%{release}
Requires:       drbd90-utils 
Requires:       kmod-drbd90
Requires:       libvirt 
Requires:       libvirt-daemon 
Requires:       libvirt-daemon-driver-qemu 
Requires:       libvirt-daemon-kvm 
Requires:       libvirt-docs 
Requires:       qemu-kvm 
Requires:       qemu-kvm-core 
Requires:       virt-install
Requires:       virt-top
# A DR host is not allowed to be a live-migration target or host a database.
Conflicts:	anvil-striker
Conflicts:	anvil-node

%description dr

Provides support for asynchronous disaster recovery hosts in an Anvil! cluster.


%prep
%autosetup -n anvil-3.0b


%build


%install
rm -rf $RPM_BUILD_ROOT
mkdir -p %{buildroot}/%{_sbindir}/scancore-agents/
mkdir -p %{buildroot}/%{_sysconfdir}/anvil/
mkdir -p %{buildroot}/%{_localstatedir}/www/
mkdir -p %{buildroot}/%{_usr}/share/anvil/
mkdir -p %{buildroot}/%{_usr}/lib/ocf/resource.d/alteeve
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
cp -R -p ocf/alteeve/server %{buildroot}/%{_usr}/lib/ocf/resource.d/alteeve


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
### TODO: check it if was disabled (if it existed before) and, if so, leave it disabled.
systemctl enable chronyd.service 
systemctl start chronyd.service 
systemctl enable anvil-daemon.service
systemctl restart anvil-daemon.service


%post striker
### NOTE: PostgreSQL is initialized and enabled by striker-prep-database later.
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
striker-prep-database
anvil-update-states

# Touch the system type file.
echo "Touching the system type file"
if [ -e '/etc/anvil/type.node' ]
then
    rm -f /etc/anvil/type.node
elif [ -e '/etc/anvil/type.dr' ]
then 
    rm -f /etc/anvil/type.dr
fi
touch /etc/anvil/type.striker


### TODO: I don't think we need this anymore
# Open access for Striker. The database will be opened after initial setup.
echo "Opening the web and postgresql ports."
firewall-cmd --add-service=http
firewall-cmd --add-service=http --permanent
firewall-cmd --add-service=https
firewall-cmd --add-service=https --permanent
firewall-cmd --add-service=postgresql
firewall-cmd --add-service=postgresql --permanent

%pre node


%post node
# Touch the system type file.
echo "Touching the system type file"
if [ -e '/etc/anvil/type.striker' ]
then
    rm -f /etc/anvil/type.striker
elif [ -e '/etc/anvil/type.dr' ]
then 
    rm -f /etc/anvil/type.dr
fi
touch /etc/anvil/type.node


%pre dr


%post dr
# Touch the system type file.
echo "Touching the system type file"
if [ -e '/etc/anvil/type.striker' ]
then
    rm -f /etc/anvil/type.striker
elif [ -e '/etc/anvil/type.node' ]
then 
    rm -f /etc/anvil/type.node
fi
touch /etc/anvil/type.dr

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

# Remove the system type file.
if [ -e '/etc/anvil/type.striker' ]
then
    rm -f /etc/anvil/type.striker
fi

%postun node
# Remove the system type file.
if [ -e '/etc/anvil/type.node' ]
then
    rm -f /etc/anvil/type.node
fi

%postun dr
# Remove the system type file.
if [ -e '/etc/anvil/type.dr' ]
then
    rm -f /etc/anvil/type.dr
fi


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
%{_usr}/lib/ocf/resource.d/alteeve/server

%files dr
#<placeholder for node specific files>


%changelog
* tbd Madison Kelly <mkelly@alteeve.ca> 3.0-37
- Updated source.

* Tue Nov 17 2020 Madison Kelly <mkelly@alteeve.ca> 3.0-36
- Updated source.

* Thu Sep 03 2020 Madison Kelly <mkelly@alteeve.ca> 3.0-35
- Added screen as a core module dependency
- Updated source.

* Fri Aug 28 2020 Madison Kelly <mkelly@alteeve.ca> 3.0-34
- Added 'virt-top' as a requirement on nodes and dr hosts.
- Added cyrus-sasl* as requirements to core.
- Updated source.

* Thu Jul 16 2020 Madison Kelly <mkelly@alteeve.ca> 3.0-33
- Updated source.

* Tue May 26 2020 Madison Kelly <mkelly@alteeve.ca> 3.0-32
- Updated source.

* Mon Jan 6 2020 Madison Kelly <mkelly@alteeve.ca> 3.0-31
- Added perl-Mail-RFC822-Address to core requirements.
- Updated source.

* Fri Dec 13 2019 Madison Kelly <mkelly@alteeve.ca> 3.0-30
- Enabled/started chronyd in core's post.
- Updated source.

* Thu Nov 7 2019 Madison Kelly <mkelly@alteeve.ca> 3.0-29
- Added '/etc/anvil/type.X' file creation to more directly mark a system as a 
  specific type, rather than divining by name.
- Updated source.

* Mon Oct 28 2019 Madison Kelly <mkelly@alteeve.ca> 3.0-28
- Updated source

* Sun Oct 20 2019 Madison Kelly <mkelly@alteeve.ca> 3.0-27
- Updated source

* Wed Oct 02 2019 Madison Kelly <mkelly@alteeve.ca> 3.0-26
- Updated source

* Mon Sep 23 2019 Madison Kelly <mkelly@alteeve.ca> 3.0-25
- Fixed a couple bugs found in the previous release.

* Sun Sep 22 2019 Madison Kelly <mkelly@alteeve.ca> 3.0-24
- Added syslinux to core requirements.
- Added installation of ocf:alteeve:server resource agent to nodes.
- Updated the source.

* Sat Feb 02 2019 Madison Kelly <mkelly@alteeve.ca> 3.0-23
- Updated the source.

* Wed Jan 30 2019 Madison Kelly <mkelly@alteeve.ca> 3.0-22
- Finished swapping over to RHEL8. Fedora support now removed.

* Sat Jan 05 2019 Madison Kelly <mkelly@alteeve.ca> 3.0-21
- Started adding support for ScanCore.
- Updated source and renamed to anvil-3.0b.
- Updated for EL8. Lots of dependency changes!

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
- Added an explicit call to striker-prep-database in post.

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
