# Process this file with autoconf to produce a configure script.

AC_PREREQ([2.63])

AC_INIT([anvil],
	m4_esyscmd([make/git-version-gen .tarball-version]),
	[digimer@alteeve.com])

AC_CONFIG_AUX_DIR([.])

AM_INIT_AUTOMAKE([dist-bzip2 dist-xz -Wno-portability tar-pax])

AC_CONFIG_MACRO_DIR([m4])
AC_CONFIG_SRCDIR([anvil.conf])

AC_CANONICAL_HOST

# AC_LANG([C])

# Sanitize path

if test "$prefix" = "NONE"; then
	prefix="/usr"
	if test "$localstatedir" = "\${prefix}/var"; then
		localstatedir="/var"
	fi
	if test "$sysconfdir" = "\${prefix}/etc"; then
		sysconfdir="/etc"
	fi
	if test "$libdir" = "\${exec_prefix}/lib"; then
		if test -e /usr/lib64; then
			libdir="/usr/lib64"
		else
			libdir="/usr/lib"
		fi
	fi
fi

case $exec_prefix in
  NONE)   exec_prefix=$prefix;;
  prefix) exec_prefix=$prefix;;
esac

# need to expand a bunch of paths to make sure
# the embedded values in files are absolute paths
eval SBINDIR="`eval echo ${sbindir}`"
AC_SUBST([SBINDIR])
eval LOCALSTATEDIR="`eval echo ${localstatedir}`"
AC_SUBST([LOCALSTATEDIR])
eval LIBDIR="`eval echo ${libdir}`"

# Checks for programs.

# check stolen from gnulib/m4/gnu-make.m4
if ! ${MAKE-make} --version /cannot/make/this >/dev/null 2>&1; then
	AC_MSG_ERROR([you don't seem to have GNU make; it is required])
fi

AC_PROG_LN_S
AC_PROG_INSTALL
AC_PROG_MAKE_SET
AC_PROG_AWK
AC_PROG_MKDIR_P

# check for perl
AC_PATH_PROG([PERL], [perl])
if test x$PERL = x; then
	AC_MSG_ERROR([Unable to find perl binary])
fi

PKG_PROG_PKG_CONFIG

# use a wrapper to call into PKG_CHECK_VAR to allow to set a default
AC_DEFUN([ANVIL_PKG_CHECK_VAR], [
	 varname=$1
	 default=$4
	 AC_MSG_CHECKING([for pkg-conf $2 var $3])
	 PKG_CHECK_VAR([$1], [$2], [$3])
	 AS_VAR_IF([$1], [""],
		   [AS_VAR_IF([default], [""],
			      AC_MSG_ERROR([not found]),
			      [AS_VAR_COPY([$varname], [default]) && AC_MSG_RESULT([not found, using default ${!varname}])])],
		   [AC_MSG_RESULT([yes (detected: ${!varname})])])
])

# check for systemd
PKG_CHECK_MODULES([systemd], [systemd])
ANVIL_PKG_CHECK_VAR([SYSTEMD_UNIT_DIR_TMP], [systemd], [systemdsystemunitdir], [${prefix}/lib/systemd/system])
if test "${prefix}" != "/usr"; then
	SYSTEMD_UNIT_DIR="${prefix}/$SYSTEMD_UNIT_DIR_TMP"
else
	SYSTEMD_UNIT_DIR="$SYSTEMD_UNIT_DIR_TMP"
fi
AC_SUBST([SYSTEMD_UNIT_DIR])

ANVIL_PKG_CHECK_VAR([OCFROOT_TMP], [resource-agents], [ocfrootdir], [${prefix}/lib/ocf])
if test "${prefix}" != "/usr"; then
	OCFROOT="${prefix}/$OCFROOT_TMP"
else
	OCFROOT="$OCFROOT_TMP"
fi
AC_SUBST([OCFROOT])

ANVIL_PKG_CHECK_VAR([FASEXECPREFIX_TMP], [fence-agents], [exec_prefix], [${prefix}])
if test "${prefix}" != "/usr"; then
	FASEXECPREFIX="${prefix}/${FASEXECPREFIX_TMP}"
else
	FASEXECPREFIX="${FASEXECPREFIX_TMP}"
fi
AC_SUBST([FASEXECPREFIX])

# required for man page and spec file generation
AX_PROG_DATE
AS_IF([test "$ax_cv_prog_date_gnu_date:$ax_cv_prog_date_gnu_utc" = yes:yes],
	[UTC_DATE_AT="date -u -d@"],
	[AS_IF([test "x$ax_cv_prog_date_bsd_date" = xyes],
		[UTC_DATE_AT="date -u -r"],
		[AC_MSG_ERROR([date utility unable to convert epoch to UTC])])])
AC_SUBST([UTC_DATE_AT])

AC_ARG_VAR([SOURCE_EPOCH],[last modification date of the source])
AC_MSG_NOTICE([trying to determine source epoch])
AC_MSG_CHECKING([for source epoch in \$SOURCE_EPOCH])
AS_IF([test -n "$SOURCE_EPOCH"],
	[AC_MSG_RESULT([yes])],
	[AC_MSG_RESULT([no])
	 AC_MSG_CHECKING([for source epoch in source_epoch file])
	 AS_IF([test -e "$srcdir/source_epoch"],
		[read SOURCE_EPOCH <"$srcdir/source_epoch"
		 AC_MSG_RESULT([yes])],
		[AC_MSG_RESULT([no])
		 AC_MSG_CHECKING([for source epoch baked in by gitattributes export-subst])
		 SOURCE_EPOCH='$Format:%at$' # template for rewriting by git-archive
		 AS_CASE([$SOURCE_EPOCH],
			[?Format:*], # was not rewritten
				[AC_MSG_RESULT([no])
				 AC_MSG_CHECKING([for source epoch in \$SOURCE_DATE_EPOCH])
				 AS_IF([test "x$SOURCE_DATE_EPOCH" != x],
					[SOURCE_EPOCH="$SOURCE_DATE_EPOCH"
					 AC_MSG_RESULT([yes])],
					[AC_MSG_RESULT([no])
					 AC_MSG_CHECKING([whether git log can provide a source epoch])
					 SOURCE_EPOCH=f${SOURCE_EPOCH#\$F} # convert into git log --pretty format
					 SOURCE_EPOCH=$(cd "$srcdir" && git log -1 --pretty=${SOURCE_EPOCH%$} 2>/dev/null)
					 AS_IF([test -n "$SOURCE_EPOCH"],
						[AC_MSG_RESULT([yes])],
						[AC_MSG_RESULT([no, using current time and breaking reproducibility])
						 SOURCE_EPOCH=$(date +%s)])])],
			[AC_MSG_RESULT([yes])]
		 )])
	])
AC_MSG_NOTICE([using source epoch $($UTC_DATE_AT$SOURCE_EPOCH +'%F')])
UTC_DATE=$($UTC_DATE_AT$SOURCE_EPOCH +'%F')
AC_SUBST([UTC_DATE])

AC_CONFIG_FILES([Makefile
		 anvil.version
		 Anvil/Makefile
		 html/Makefile
		 journald.conf.d/Makefile
		 libvirt/Makefile
		 man/Makefile
		 ocf/Makefile
		 pxe/Makefile
		 scancore-agents/Makefile
		 scripts/Makefile
		 selinux/Makefile
		 share/Makefile
		 striker-ui/Makefile
		 striker-ui-api/Makefile
		 tools/Makefile
		 units/Makefile])

AC_OUTPUT
