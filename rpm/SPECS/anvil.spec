%define debug_package %{nil}
Name:           anvil
Version:        3.0
Release:        3%{?dist}
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
BuildRequires:  httpd
Requires:	anvil-core
Requires:       httpd
Requires:       nmap
Requires:       perl-CGI 
Requires:       postgresql-server 
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
mv %{buildroot}/%{_sbindir}/snmp-models.json %{buildroot}/%{_sysconfdir}/anvil/snmp-models.json
sed -i "1s/^.*$/%{version}/" %{buildroot}/%{_sysconfdir}/anvil/anvil.version


%post
restorecon -rv %{buildroot}/%{_localstatedir}/www

%post striker
systemctl enable httpd.service
systemctl start httpd.service
# Open access for Striker. The database will be opened after initial setup.
firewall-cmd --zone=public --add-service=http
firewall-cmd --zone=public --add-service=http --permanent
firewall-cmd --zone=public --add-service=postgresql
firewall-cmd --zone=public --add-service=postgresql --permanent

%files core
%doc README.md notes
%config(noreplace) %{_sysconfdir}/anvil/anvil.conf
%config(noreplace) %{_datadir}/anvil.sql
%{_usr}/lib/*
%{_sbindir}/*
%{_sysconfdir}/anvil/anvil.version
%{_datadir}/perl5/*
# TODO: Remove this!! This is only for use during development, all SELinux 
#       issues must be resolved before final release!
sed -i.anvil 's/SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config 

%files striker
%attr(0775, apache, root) %{_localstatedir}/www/*/*
%{_sysconfdir}/anvil/snmp-models.json
%ghost %{_sysconfdir}/anvil/snmp-vendors.txt

%files node
#<placeholder for node specific files>

%files dr
#<placeholder for node specific files>


%changelog
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
