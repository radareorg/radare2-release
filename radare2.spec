Name:           radare2
Version:        1.1.0
Release:        1%{?dist}
Summary:        Radare is a portable reversing framework

License:        LGPLv3 
URL:            https://radare.org
Source0:        http://cloud.radare.org/get/1.1.0/radare2-%{version}.tar.gz

BuildRequires:  openssl-devel
BuildRequires:  capstone-devel
BuildRequires:  gcc-c++
BuildRequires:  libzip-devel

Requires: capstone  

%description
Radare is a portable reversing framework that can
 - Disassemble (and assemble for) many different architectures
 - Debug with local native and remote debuggers (gdb, rap, webui, r2pipe, winedbg, windbg)
 - Run on Linux, *BSD, Windows, OSX, Android, iOS, Solaris and Haiku
 - Perform forensics on filesystems and data carving
 - Be scripted in Python, Javascript, Go and more
 - Support collaborative analysis using the embedded webserver
 - Visualize data structures of several file types
 - Patch programs to uncover new features or fix vulnerabilities
 - Use powerful analysis capabilities to speed up reversing
 - Aid in software exploitation

%package devel
Summary:        Development files for the %{name} package
Group:          Development/Libraries
Requires:       %{name} = %{version}-%{release}

%description devel
Development files for the %{name} package. See %{name} package for more
information.

%prep
%autosetup

%build
%configure  --with-openssl --with-ostype=auto --with-syscapstone --with-syszip --with-sysmagic #--without-gpl, currently doesnt build with this
%make_build

%install
rm -rf $RPM_BUILD_ROOT
%make_install

%files
%license COPYING COPYING.LESSER
%{_bindir}/*
%{_libdir}/libr*
%{_docdir}/radare2/*
%{_datadir}/%{name}/last
%{_datadir}/%{name}/%{version}/cons
%{_datadir}/%{name}/%{version}/fcnsign
%{_datadir}/%{name}/%{version}/format
%{_datadir}/%{name}/%{version}/magic
%{_datadir}/%{name}/%{version}/opcodes
%{_datadir}/%{name}/%{version}/syscall
%{_datadir}/%{name}/%{version}/www
%{_datadir}/%{name}/%{version}/hud
%{_mandir}/man1/*
%{_mandir}/man7/*
%doc DEVELOPERS* README*

%files devel
%license COPYING COPYING.LESSER
%{_includedir}/libr
%{_libdir}/*.so
%{_libdir}/radare2/last
%{_libdir}/radare2/%{version}/*.so
%{_libdir}/pkgconfig/*.pc
%doc DEVELOPERS* README*

%changelog
* Fri Jan 20 2017 siddharth.kde@gmail.com - 1.1.0-1
- Init New Package Radare 2 

