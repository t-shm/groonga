#!/bin/sh

if [ -z "$DEB_ARCHITECTURES" ]; then
    DEB_ARCHITECTURES="i386 amd64"
fi
if [ -z "$CODES" ]; then
    CODES="squeeze wheezy unstable lucid natty oneiric precise"
fi 
if [ -z "$RPM_ARCHITECTURES" ]; then
    RPM_ARCHITECTURES="i386 x86_64"
fi
if [ -z "$DISTRIBUTIONS" ]; then
    DISTRIBUTIONS="centos fedora"
fi
CHROOT_ROOT=/var/lib/chroot

echo_packages_repository_address ()
{
    root_dir=$1
    code=$2
    arch=$3
    address=`grep "packages.groonga.org" $root_dir/etc/hosts | grep -v "#"`
    if [ -z "$address" ]; then
	echo "$code-$arch: default"
    else
	echo "$code-$arch: $address"
    fi
}

check_packages_repository_address ()
{
    for code in $CODES; do
	for arch in $DEB_ARCHITECTURES; do
	    root_dir=$CHROOT_ROOT/$code-$arch
	    echo_packages_repository_address "$root_dir" "$code" "$arch"
	done
    done
    for dist in $DISTRIBUTIONS; do
	case $dist in
	    "fedora")
		DISTRIBUTIONS_VERSION="16"
		;;
	    "centos")
		DISTRIBUTIONS_VERSION="5 6"
		;;
	esac
	for ver in $DISTRIBUTIONS_VERSION; do
	    for arch in $RPM_ARCHITECTURES; do
		root_dir=$CHROOT_ROOT/$dist-$ver-$arch
		echo_packages_repository_address "$root_dir" "$dist-$ver" "$arch"
	    done
	done
    done
}

host_address ()
{
    ifconfig_result=`LANG=C /sbin/ifconfig`
    inet_addr=`echo "$ifconfig_result" | grep "inet addr:192"`
    address=`echo $inet_addr | perl -ne 'if($_=~/inet addr\:(.+?)\s/){print "$1"}'`
    HOST_ADDRESS=$address
}

check_installed_groonga_packages ()
{
    cat > check-deb-groonga.sh <<EOF
#!/bin/sh
dpkg -l | grep groonga
EOF
    cat > check-rpm-groonga.sh <<EOF
#!/bin/sh
rpm -qa | grep groonga
EOF
    for code in $CODES; do
	for arch in $DEB_ARCHITECTURES; do
	    root_dir=$CHROOT_ROOT/$code-$arch
	    CHECK_SCRIPT=check-deb-groonga.sh
	    echo "copy check script $CHECK_SCRIPT to $root_dir/tmp"
	    sudo rm -f $root_dir/tmp/$CHECK_SCRIPT
	    cp $CHECK_SCRIPT $root_dir/tmp
	    chmod 755 $root_dir/tmp/$CHECK_SCRIPT
	    sudo chname $code-$arch chroot $root_dir /tmp/$CHECK_SCRIPT
	done
    done
    for dist in $DISTRIBUTIONS; do
	case $dist in
	    "fedora")
		DISTRIBUTIONS_VERSION="16"
		;;
	    "centos")
		DISTRIBUTIONS_VERSION="5 6"
		;;
	esac
	for ver in $DISTRIBUTIONS_VERSION; do
	    for arch in $RPM_ARCHITECTURES; do
		CHECK_SCRIPT=check-rpm-groonga.sh
		root_dir=$CHROOT_ROOT/$dist-$ver-$arch
		echo "copy check script $CHECK_SCRIPT to $root_dir/tmp"
		sudo rm -f $root_dir/tmp/$CHECK_SCRIPT
		cp $CHECK_SCRIPT $root_dir/tmp
		chmod 755 $root_dir/tmp/$CHECK_SCRIPT
		sudo chname $code-$ver-$arch chroot $root_dir /tmp/$CHECK_SCRIPT
	    done
	done
    done
}

install_groonga_packages ()
{
    cat > install-debian-groonga.sh <<EOF
#!/bin/sh
sudo aptitude update
sudo aptitude -V -D -y --allow-untrusted install groonga-keyring
sudo aptitude update
sudo aptitude -V -D -y install groonga
sudo aptitude -V -D -y install groonga-tokenizer-mecab
sudo aptitude -V -D -y install groonga-munin-plugins
EOF
    cat > install-ubuntu-groonga.sh <<EOF
sudo apt-get clean
rm -f /var/lib/apt/lists/packages.groonga.org_*
rm -f /var/lib/apt/lists/partial/packages.groonga.org_*
sudo apt-get update
sudo apt-get -y --allow-unauthenticated install groonga-keyring
sudo apt-get update
sudo apt-get -y --force-yes install groonga
sudo apt-get -y --force-yes install groonga-tokenizer-mecab
sudo apt-get -y --force-yes install groonga-munin-plugins
EOF
    for code in $CODES; do
	for arch in $DEB_ARCHITECTURES; do
	    root_dir=$CHROOT_ROOT/$code-$arch
	    INSTALL_SCRIPT=""
	    case $code in
		squeeze|wheezy|unstable)
		    INSTALL_SCRIPT=install-debian-groonga.sh
		    ;;
		*)
		    INSTALL_SCRIPT=install-ubuntu-groonga.sh
		    ;;
	    esac
	    echo "copy install script $INSTALL_SCRIPT to $root_dir/tmp"
	    sudo rm -f $root_dir/tmp/$INSTALL_SCRIPT
	    cp $INSTALL_SCRIPT $root_dir/tmp
	    chmod 755 $root_dir/tmp/$INSTALL_SCRIPT
	    #sudo chname $code-$arch chroot $root_dir /tmp/$INSTALL_SCRIPT
	done
    done
    cat > install-centos5-groonga.sh <<EOF
sudo rpm -ivh http://packages.groonga.org/centos/groonga-release-1.1.0-0.noarch.rpm
sudo yum makecache
sudo yum install -y groonga
sudo yum install -y groonga-tokenizer-mecab
wget http://download.fedoraproject.org/pub/epel/5/i386/epel-release-5-4.noarch.rpm
sudo rpm -ivh epel-release-5-4.noarch.rpm
sudo yum install -y groonga-munin-plugins
EOF
    cat > install-centos6-groonga.sh <<EOF
sudo rpm -ivh http://packages.groonga.org/centos/groonga-release-1.1.0-0.noarch.rpm
sudo yum makecache
sudo yum install -y groonga
sudo yum install -y groonga-tokenizer-mecab
sudo rpm -ivh http://download.fedoraproject.org/pub/epel/6/i386/epel-release-6-7.noarch.rpm
sudo yum install -y groonga-munin-plugins
EOF
    cat > install-fedora-groonga.sh <<EOF
sudo rpm -ivh http://packages.groonga.org/centos/groonga-release-1.1.0-0.noarch.rpm
sudo yum makecache
sudo yum install -y groonga
sudo yum install -y groonga-tokenizer-mecab
sudo yum install -y groonga-munin-plugins
EOF
    for dist in $DISTRIBUTIONS; do
	case $dist in
	    "fedora")
		DISTRIBUTIONS_VERSION="16"
		;;
	    "centos")
		DISTRIBUTIONS_VERSION="5 6"
		;;
	esac
	for ver in $DISTRIBUTIONS_VERSION; do
	    for arch in $RPM_ARCHITECTURES; do
		case "$dist-$ver" in
		    centos-5)
			INSTALL_SCRIPT=install-centos5-groonga.sh
			;;
		    centos-6)
			INSTALL_SCRIPT=install-centos6-groonga.sh
			;;
		    fedora-16)
			INSTALL_SCRIPT=install-fedora-groonga.sh
			;;
		    *)
			;;
		esac
		root_dir=$CHROOT_ROOT/$dist-$ver-$arch
		echo "copy install script $INSTALL_SCRIPT to $root_dir/tmp"
		sudo rm -f $root_dir/tmp/$INSTALL_SCRIPT
		cp $INSTALL_SCRIPT $root_dir/tmp
		chmod 755 $root_dir/tmp/$INSTALL_SCRIPT
		sudo chname $code-$ver-$arch chroot $root_dir /tmp/$INSTALL_SCRIPT
	    done
	done
    done
}

enable_temporaly_groonga_repository ()
{
    cat > enable-repository.sh <<EOF
#!/bin/sh

grep -v "packages.groonga.org" /etc/hosts > /tmp/hosts
echo "$HOST_ADDRESS packages.groonga.org" >> /tmp/hosts
cp -f /tmp/hosts /etc/hosts
EOF
    for code in $CODES; do
	for arch in $DEB_ARCHITECTURES; do
	    root_dir=$CHROOT_ROOT/$code-$arch
	    today=`date '+%Y%m%d.%s'`
	    sudo cp $root_dir/etc/hosts $root_dir/etc/hosts.$today
	    sudo cp enable-repository.sh $root_dir/tmp
	    sudo chname $code-$arch chroot $root_dir /tmp/enable-repository.sh
	done
    done
    for dist in $DISTRIBUTIONS; do
	case $dist in
	    "fedora")
		DISTRIBUTIONS_VERSION="16"
		;;
	    "centos")
		DISTRIBUTIONS_VERSION="5 6"
		;;
	esac
	for ver in $DISTRIBUTIONS_VERSION; do
	    for arch in $RPM_ARCHITECTURES; do
		root_dir=$CHROOT_ROOT/$dist-$ver-$arch
		today=`date '+%Y%m%d.%s'`
		sudo cp $root_dir/etc/hosts $root_dir/etc/hosts.$today
		sudo cp enable-repository.sh $root_dir/tmp
		sudo chname $code-$arch chroot $root_dir /tmp/enable-repository.sh
		echo_packages_repository_address "$root_dir" "$dist-$ver" "$arch"
	    done
	done
    done

    check_packages_repository_address
}

host_address
echo $HOST_ADDRESS

while [ $# -ne 0 ]; do
    case $1 in
	--check-install)
	    check_installed_groonga_packages
	    shift
	    ;;
	--check-address)
	    check_packages_repository_address
	    shift
	    ;;
	--enable-repository)
	    enable_temporaly_groonga_repository
	    shift
	    ;;
	--install-groonga)
	    install_groonga_packages
	    shift
	    ;;
	*)
	    shift
	    ;;
    esac
done



