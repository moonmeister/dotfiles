#!/bin/bash
set -e
set -o pipefail

# install.sh
#	This script installs my basic setup for a debian laptop

export DEBIAN_FRONTEND=noninteractive

# Choose a user account to use for this installation
get_user() {
	if [ -z "${TARGET_USER-}" ]; then
		mapfile -t options < <(find /home/* -maxdepth 0 -printf "%f\\n" -type d)
		# if there is only one option just use that user
		if [ "${#options[@]}" -eq "1" ]; then
			readonly TARGET_USER="${options[0]}"
			echo "Using user account: ${TARGET_USER}"
			return
		fi

		# iterate through the user options and print them
		PS3='Which user account should be used? '

		select opt in "${options[@]}"; do
			readonly TARGET_USER=$opt
			break
		done
	fi
}

check_is_sudo() {
	if [ "$EUID" -ne 0 ]; then
		echo "Please run as root."
		exit
	fi
}


setup_sources_min() {
	apt update || true
	apt install -y \
		apt-transport-https \
		ca-certificates \
		curl \
		dirmngr \
		gnupg2 \
		lsb-release \
		--no-install-recommends

	# hack for latest git (don't judge)
	cat <<-EOF > /etc/apt/sources.list.d/git-core.list
	deb http://ppa.launchpad.net/git-core/ppa/ubuntu bionic main
	deb-src http://ppa.launchpad.net/git-core/ppa/ubuntu bionic main
	EOF

	# neovim
	# cat <<-EOF > /etc/apt/sources.list.d/neovim.list
	# deb http://ppa.launchpad.net/neovim-ppa/unstable/ubuntu xenial main
	# deb-src http://ppa.launchpad.net/neovim-ppa/unstable/ubuntu xenial main
	# EOF

	# iovisor/bcc-tools
	cat <<-EOF > /etc/apt/sources.list.d/iovisor.list
	deb https://repo.iovisor.org/apt/xenial xenial main
	EOF

	# add the git-core ppa gpg key
	apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys E1DD270288B4E6030699E45FA1715D88E1DF1F24

	# add the neovim ppa gpg key
	# apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 9DBB0BE9366964F134855E2255F96FCF8231B6DD

	# add the iovisor/bcc-tools gpg key
	apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 648A4A16A23015EEF4A66B8E4052245BD4284CDD

	# turn off translations, speed up apt update
	mkdir -p /etc/apt/apt.conf.d
	echo 'Acquire::Languages "none";' > /etc/apt/apt.conf.d/99translations
}

# sets up apt sources
# assumes you are going to use Ubuntu Bionic Beaver
setup_sources() {
	setup_sources_min;

	cat <<-EOF > /etc/apt/sources.list
	#Ubuntu Bionic
	deb http://us.archive.ubuntu.com/ubuntu/ bionic main restricted
	deb http://us.archive.ubuntu.com/ubuntu/ bionic-updates main restricted
	
	deb http://us.archive.ubuntu.com/ubuntu/ bionic universe
	deb http://us.archive.ubuntu.com/ubuntu/ bionic-updates universe
	
	deb http://us.archive.ubuntu.com/ubuntu/ bionic multiverse
	deb http://us.archive.ubuntu.com/ubuntu/ bionic-updates multiverse

	deb http://security.ubuntu.com/ubuntu bionic-security main restricted
	deb http://security.ubuntu.com/ubuntu bionic-security universe
	deb http://security.ubuntu.com/ubuntu bionic-security multiverse
	EOF

	#keepassxc
	cat <<-EOF > /etc/apt/sources.list.d/keepassxc.list
	deb http://ppa.launchpad.net/phoerious/keepassxc/ubuntu bionic main 
	deb-src http://ppa.launchpad.net/phoerious/keepassxc/ubuntu bionic main 
	EOF

	# yubico
	cat <<-EOF > /etc/apt/sources.list.d/yubico.list
	deb http://ppa.launchpad.net/yubico/stable/ubuntu bionic main
	deb-src http://ppa.launchpad.net/yubico/stable/ubuntu bionic main
	EOF

	# tlp: Advanced Linux Power Management
	cat <<-EOF > /etc/apt/sources.list.d/tlp.list
	# tlp: Advanced Linux Power Management
	# http://linrunner.de/en/tlp/docs/tlp-linux-advanced-power-management.html
	deb http://repo.linrunner.de/debian sid main
	EOF

	# # Create an environment variable for the correct distribution
	# CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)"
	# export CLOUD_SDK_REPO

	# # Add the Cloud SDK distribution URI as a package source
	# echo "deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" > /etc/apt/sources.list.d/google-cloud-sdk.list

	# Import the Google Cloud Platform public key
	# curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

	# Add the Cloud SDK for Azure
	# echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ wheezy main" > /etc/apt/sources.list.d/azure-cloud-sdk.list

	# Add the Azure Cloud public key
	# apt-key adv --keyserver packages.microsoft.com --recv-keys 52E16F86FEE04B979B07E28DB02C46DF417A0893

	# Add the Google Chrome distribution URI as a package source
	cat <<-EOF > /etc/apt/sources.list.d/google-chrome.list
	deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main
	EOF

	# Import the Google Chrome public key
	curl https://dl.google.com/linux/linux_signing_key.pub | apt-key add -

	# Add the VS code distribution URI as a package source
	echo "deb [arch=amd64] http://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list

	# Import the vscode public key
	curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -

	# add docker gpg key
	apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D

	# add the yubico ppa gpg key
	apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 3653E21064B19D134466702E43D5C49532CBA1A9

	# add the tlp apt-repo gpg key
	apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 6B283E95745A6D903009F7CA641EED65CD4E8809
	
	# add the keepassxc gpg key
	apt-key adv --keyserver hkp://keyserver.ubuntu.com --recv-keys D89C66D0E31FEA2874EBD20561922AB60068FCD6

}

base_min() {
	apt update || true
	apt -y upgrade

	apt install -y \
		adduser \
		automake \
		bash-completion \
		bc \
		bzip2 \
		ca-certificates \
		coreutils \
		curl \
		dnsutils \
		file \
		findutils \
		gcc \
		git \
		gnupg \
		gnupg2 \
		grep \
		gzip \
		hostname \
		indent \
		iptables \
		jq \
		less \
		libc6-dev \
		locales \
		lsof \
		make \
		mount \
		net-tools \
		ssh \
		strace \
		sudo \
		tar \
		tree \
		tzdata \
		rxvt-unicode \
		unzip \
		xz-utils \
		zip \
		--no-install-recommends

	apt autoremove
	apt autoclean
	apt clean

	install_scripts
}

# installs base packages
# the utter bare minimal shit
base() {
	base_min;

	apt update || true
	apt -y upgrade

	apt install -y \
		alsa-utils \
		apparmor \
		bridge-utils \
		cgroupfs-mount \
		fwupd \
		fwupdate \
		gnupg-agent \
		iwd \
		libapparmor-dev \
		libimobiledevice6 \
		libltdl-dev \
		libpam-systemd \
		libseccomp-dev \
		pinentry-curses \
		rxvt-unicode-256color \
		scdaemon \
		systemd \
		usbmuxd \
		xclip \
		xcompmgr \
		network-manager \
		google-chrome-stable \
		keepassxc \
		code \

		--no-install-recommends

	setup_sudo

	apt autoremove
	apt autoclean
	apt clean
}

# install and configure dropbear
install_dropbear() {
	apt update || true
	apt -y upgrade

	apt install -y \
		dropbear-initramfs \
		--no-install-recommends

	apt autoremove
	apt autoclean
	apt clean

	# change the default port and settings
	echo 'DROPBEAR_OPTIONS="-p 4748 -s -j -k -I 60"' >> /etc/dropbear-initramfs/config

	# update the authorized keys
	cp "/home/${TARGET_USER}/.ssh/authorized_keys" /etc/dropbear-initramfs/authorized_keys
	sed -i 's/ssh-/no-port-forwarding,no-agent-forwarding,no-X11-forwarding,command="\/bin\/cryptroot-unlock" ssh-/g' /etc/dropbear-initramfs/authorized_keys

	echo "Dropbear has been installed and configured."
	echo "You will now want to update your initramfs:"
	printf "\\tupdate-initramfs -u\\n"
}

# setup sudo for a user
# because fuck typing that shit all the time
# just have a decent password
# and lock your computer when you aren't using it
# if they have your password they can sudo anyways
# so its pointless
# i know what the fuck im doing ;)
setup_sudo() {
	# add user to sudoers
	adduser "$TARGET_USER" sudo

	# add user to systemd groups
	# then you wont need sudo to view logs and shit
	gpasswd -a $TARGET_USER systemd-journal
	gpasswd -a $TARGET_USER systemd-network

	# create docker group
	sudo groupadd docker
	sudo gpasswd -a $TARGET_USER docker

	# add go path to secure path
	{ \
		echo -e "Defaults	secure_path=\"/usr/local/go/bin:/home/${TARGET_USER}/.go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/share/bcc/tools\""; \
		echo -e 'Defaults	env_keep += "ftp_proxy http_proxy https_proxy no_proxy GOPATH EDITOR"'; \
		echo -e "${TARGET_USER} ALL=(ALL) NOPASSWD:ALL"; \
		echo -e "${TARGET_USER} ALL=NOPASSWD: /sbin/ifconfig, /sbin/ifup, /sbin/ifdown, /sbin/ifquery"; \
	} >> /etc/sudoers

	# setup downloads folder as tmpfs
	# that way things are removed on reboot
	# i like things clean but you may not want this
	mkdir -p "/home/$TARGET_USER/Downloads"
	echo -e "\\n# tmpfs for downloads\\ntmpfs\\t/home/${TARGET_USER}/Downloads\\ttmpfs\\tnodev,nosuid,size=2G\\t0\\t0" >> /etc/fstab
}

# installs docker master
# and adds necessary items to boot params
install_docker() {
	# create docker group
	if grep -q "docker" /etc/group
		then
			echo "group exists"
		else
			sudo groupadd docker
			sudo gpasswd -a "$TARGET_USER" docker
	fi

	# Include contributed completions
	mkdir -p /etc/bash_completion.d
	curl -sSL -o /etc/bash_completion.d/docker https://raw.githubusercontent.com/docker/docker-ce/master/components/cli/contrib/completion/bash/docker


	# get the binary
	local tmp_tar=/tmp/docker.tgz
	local binary_uri="https://download.docker.com/linux/static/edge/x86_64"
	local docker_version
	docker_version=$(curl -sSL "https://api.github.com/repos/docker/docker-ce/releases/latest" | jq --raw-output .tag_name)
	docker_version=${docker_version#v}
	# local docker_sha256
	# docker_sha256=$(curl -sSL "${binary_uri}/docker-${docker_version}.tgz.sha256" | awk '{print $1}')
	(
	set -x
	curl -fSL "${binary_uri}/docker-${docker_version}.tgz" -o "${tmp_tar}"
	# echo "${docker_sha256} ${tmp_tar}" | sha256sum -c -
	tar -C /usr/local/bin --strip-components 1 -xzvf "${tmp_tar}"
	rm "${tmp_tar}"
	docker -v
	)
	chmod +x /usr/local/bin/docker*

	curl -sSL https://raw.githubusercontent.com/moonmeister/dotfiles/master/etc/systemd/system/docker.service > /etc/systemd/system/docker.service
	curl -sSL https://raw.githubusercontent.com/moonmeister/dotfiles/master/etc/systemd/system/docker.socket > /etc/systemd/system/docker.socket

	systemctl daemon-reload
	systemctl enable docker

	# update grub with docker configs and power-saving items
	sed -i.bak 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="cgroup_enable=memory swapaccount=1 apparmor=1 security=apparmor page_poison=1 slab_nomerge vsyscall=none"/g' /etc/default/grub
	echo "Docker has been installed. If you want memory management & swap"
	echo "run update-grub & reboot"
}

# install/update golang from source
install_golang() {
	export GO_VERSION
	GO_VERSION=$(curl -sSL "https://golang.org/VERSION?m=text")
	export GO_SRC=/usr/local/go

	# if we are passing the version
	if [[ ! -z "$1" ]]; then
		GO_VERSION=$1
	fi

	# purge old src
	if [[ -d "$GO_SRC" ]]; then
		sudo rm -rf "$GO_SRC"
		sudo rm -rf "$GOPATH"
	fi

	GO_VERSION=${GO_VERSION#go}

	# subshell
	(
	kernel=$(uname -s | tr '[:upper:]' '[:lower:]')
	curl -sSL "https://storage.googleapis.com/golang/go${GO_VERSION}.${kernel}-amd64.tar.gz" | sudo tar -v -C /usr/local -xz
	local user="$USER"
	# rebuild stdlib for faster builds
	sudo chown -R "${user}" /usr/local/go/pkg
	CGO_ENABLED=0 go install -a -installsuffix cgo std
	)

	# get commandline tools
	(
	set -x
	set +e
	go get github.com/golang/lint/golint
	# go get golang.org/x/tools/cmd/cover
	# go get golang.org/x/review/git-codereview
	# go get golang.org/x/tools/cmd/goimports
	# go get golang.org/x/tools/cmd/gorename
	# go get golang.org/x/tools/cmd/guru

	# go get github.com/genuinetools/amicontained
	# go get github.com/genuinetools/apk-file
	go get github.com/genuinetools/audit
	go get github.com/genuinetools/bpfd
	go get github.com/genuinetools/bpfps
	go get github.com/genuinetools/certok
	# go get github.com/genuinetools/img
	# go get github.com/genuinetools/netns
	go get github.com/genuinetools/pepper
	go get github.com/genuinetools/reg
	go get github.com/genuinetools/udict
	go get github.com/genuinetools/weather

	go get github.com/jessfraz/junk/sembump
	go get github.com/jessfraz/secping
	go get github.com/jessfraz/ship
	go get github.com/jessfraz/tdash

	go get github.com/axw/gocov/gocov
	go get honnef.co/go/tools/cmd/staticcheck
	# go get github.com/google/gops

	# Tools for vimgo.
	# go get github.com/jstemmer/gotags
	# go get github.com/nsf/gocode
	# go get github.com/rogpeppe/godef

	# aliases=( genuinetools/contained.af docker/docker moby/buildkit opencontainers/runc jessfraz/binctr )
	# for project in "${aliases[@]}"; do
	# 	owner=$(dirname "$project")
	# 	repo=$(basename "$project")
	# 	if [[ -d "${HOME}/${repo}" ]]; then
	# 		rm -rf "${HOME:?}/${repo}"
	# 	fi

	# 	mkdir -p "${GOPATH}/src/github.com/${owner}"

	# 	if [[ ! -d "${GOPATH}/src/github.com/${project}" ]]; then
	# 		(
	# 		# clone the repo
	# 		cd "${GOPATH}/src/github.com/${owner}"
	# 		git clone "https://github.com/${project}.git"
	# 		# fix the remote path, since our gitconfig will make it git@
	# 		cd "${GOPATH}/src/github.com/${project}"
	# 		git remote set-url origin "https://github.com/${project}.git"
	# 		)
	# 	else
	# 		echo "found ${project} already in gopath"
	# 	fi

	# 	# make sure we create the right git remotes
	# 	if [[ "$owner" != "jessfraz" ]]; then
	# 		(
	# 		cd "${GOPATH}/src/github.com/${project}"
	# 		git remote set-url --push origin no_push
	# 		git remote add jessfraz "https://github.com/jessfraz/${repo}.git"
	# 		)
	# 	fi
	# done

	# do special things for k8s GOPATH
	# mkdir -p "${GOPATH}/src/k8s.io"
	# kubes_repos=( community kubernetes release test-infra )
	# for krepo in "${kubes_repos[@]}"; do
	# 	git clone "https://github.com/kubernetes/${krepo}.git" "${GOPATH}/src/k8s.io/${krepo}"
	# 	cd "${GOPATH}/src/k8s.io/${krepo}"
	# 	git remote set-url --push origin no_push
	# 	git remote add jessfraz "https://github.com/jessfraz/${krepo}.git"
	# done
	)

	# symlink weather binary for motd
	sudo ln -snf "${GOPATH}/bin/weather" /usr/local/bin/weather
}

# install graphics drivers
install_graphics() {
	local system=$1

	if [[ -z "$system" ]]; then
		echo "You need to specify whether it's intel, geforce or optimus"
		exit 1
	fi

	local pkgs=( xorg xserver-xorg xserver-xorg-input-libinput xserver-xorg-input-synaptics )

	case $system in
		"intel")
			pkgs+=( xserver-xorg-video-intel )
			;;
		"geforce")
			pkgs+=( nvidia-driver )
			;;
		"optimus")
			pkgs+=( nvidia-kernel-dkms bumblebee-nvidia primus )
			;;
		*)
			echo "You need to specify whether it's intel, geforce or optimus"
			exit 1
			;;
	esac

	apt update || true
	apt -y upgrade

	apt install -y "${pkgs[@]}" --no-install-recommends
}

# install custom scripts/binaries
install_scripts() {
	# install speedtest
	curl -sSL https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py  > /usr/local/bin/speedtest
	chmod +x /usr/local/bin/speedtest

	# install icdiff
	curl -sSL https://raw.githubusercontent.com/jeffkaufman/icdiff/master/icdiff > /usr/local/bin/icdiff
	curl -sSL https://raw.githubusercontent.com/jeffkaufman/icdiff/master/git-icdiff > /usr/local/bin/git-icdiff
	chmod +x /usr/local/bin/icdiff
	chmod +x /usr/local/bin/git-icdiff

	# install lolcat
	curl -sSL https://raw.githubusercontent.com/tehmaze/lolcat/master/lolcat > /usr/local/bin/lolcat
	chmod +x /usr/local/bin/lolcat


	local scripts=( have light )

	for script in "${scripts[@]}"; do
		curl -sSL "https://misc.j3ss.co/binaries/$script" > "/usr/local/bin/${script}"
		chmod +x "/usr/local/bin/${script}"
	done
}

# install stuff for i3 window manager
install_wmapps() {
	local pkgs=( feh i3 i3lock i3status scrot suckless-tools )

	apt update || true
	apt install -y "${pkgs[@]}" --no-install-recommends

	# update clickpad settings
	mkdir -p /etc/X11/xorg.conf.d/
	curl -sSL https://raw.githubusercontent.com/moonmeister/dotfiles/master/etc/X11/xorg.conf.d/50-synaptics-clickpad.conf > /etc/X11/xorg.conf.d/50-synaptics-clickpad.conf

	# add xorg conf
	curl -sSL https://raw.githubusercontent.com/moonmeister/dotfiles/master/etc/X11/xorg.conf > /etc/X11/xorg.conf

	# get correct sound cards on boot
	# curl -sSL https://raw.githubusercontent.com/moonmeister/dotfiles/master/etc/modprobe.d/intel.conf > /etc/modprobe.d/intel.conf

	# pretty fonts
	curl -sSL https://raw.githubusercontent.com/moonmeister/dotfiles/master/etc/fonts/local.conf > /etc/fonts/local.conf

	echo "Fonts file setup successfully now run:"
	echo "	dpkg-reconfigure fontconfig-config"
	echo "with settings: "
	echo "	Autohinter, Automatic, No."
	echo "Run: "
	echo "	dpkg-reconfigure fontconfig"
}

get_dotfiles() {
	# create subshell
	(
	cd "$HOME"

	if [[ ! -d "${HOME}/dotfiles" ]]; then
		# install dotfiles from repo
		git clone git@github.com:mooonmeister/dotfiles.git "${HOME}/dotfiles"
	fi

	cd "${HOME}/dotfiles"

	# installs all the things
	make

	# enable dbus for the user session
	# systemctl --user enable dbus.socket

	sudo systemctl enable "i3lock@${TARGET_USER}"
	sudo systemctl enable suspend-sedation.service

	sudo systemctl enable systemd-networkd systemd-resolved
	sudo systemctl start systemd-networkd systemd-resolved

	cd "$HOME"
	mkdir -p ~/Pictures/Screenshots
	)

}

# install_vim() {
# 	# create subshell
# 	(
# 	cd "$HOME"

# 	# install .vim files
# 	git clone --recursive git@github.com:jessfraz/.vim.git "${HOME}/.vim"
# 	ln -snf "${HOME}/.vim/vimrc" "${HOME}/.vimrc"
# 	sudo ln -snf "${HOME}/.vim" /root/.vim
# 	sudo ln -snf "${HOME}/.vimrc" /root/.vimrc

# 	# alias vim dotfiles to neovim
# 	mkdir -p "${XDG_CONFIG_HOME:=$HOME/.config}"
# 	ln -snf "${HOME}/.vim" "${XDG_CONFIG_HOME}/nvim"
# 	ln -snf "${HOME}/.vimrc" "${XDG_CONFIG_HOME}/nvim/init.vim"
# 	# do the same for root
# 	sudo mkdir -p /root/.config
# 	sudo ln -snf "${HOME}/.vim" /root/.config/nvim
# 	sudo ln -snf "${HOME}/.vimrc" /root/.config/nvim/init.vim

# 	# update alternatives to neovim
# 	sudo update-alternatives --install /usr/bin/vi vi "$(which nvim)" 60
# 	sudo update-alternatives --config vi
# 	sudo update-alternatives --install /usr/bin/vim vim "$(which nvim)" 60
# 	sudo update-alternatives --config vim
# 	sudo update-alternatives --install /usr/bin/editor editor "$(which nvim)" 60
# 	sudo update-alternatives --config editor

# 	# install things needed for deoplete for vim
# 	sudo apt update

# 	sudo apt install -y \
# 		python3-pip \
# 		python3-setuptools \
# 		--no-install-recommends

# 	pip3 install -U \
# 		setuptools \
# 		wheel \
# 		neovim
# 	)
# }

install_virtualbox() {
	# check if we need to install libvpx1
	# PKG_OK=$(dpkg-query -W --showformat='${Status}\n' libvpx1 | grep "install ok installed")
	# echo "Checking for libvpx1: $PKG_OK"
	# if [ "" == "$PKG_OK" ]; then
	# 	echo "No libvpx1. Installing libvpx1."
	# 	alex_sources=/etc/apt/sources.list.d/alex.list
	# 	echo "deb http://httpredir.debian.org/debian jessie main contrib non-free" > "$jessie_sources"

	# 	apt update
	# 	apt install -y -t jessie libvpx1 \
	# 		--no-install-recommends

	# 	# cleanup the file that we used to install things from jessie
	# 	rm "$alex_sources"
	# fi

	echo "deb http://download.virtualbox.org/virtualbox/debian bionic contrib" >> /etc/apt/sources.list.d/virtualbox.list

	curl -sSL https://www.virtualbox.org/download/oracle_vbox.asc | apt-key add -

	apt update
	apt install -y \
		virtualbox \
	--no-install-recommends
}

install_vagrant() {
	VAGRANT_VERSION=1.8.1

	# if we are passing the version
	if [[ ! -z "$1" ]]; then
		export VAGRANT_VERSION=$1
	fi

	# check if we need to install virtualbox
	PKG_OK=$(dpkg-query -W --showformat='${Status}\n' virtualbox | grep "install ok installed")
	echo "Checking for virtualbox: $PKG_OK"
	if [ "" == "$PKG_OK" ]; then
		echo "No virtualbox. Installing virtualbox."
		install_virtualbox
	fi

	tmpdir=$(mktemp -d)
	(
	cd "$tmpdir"
	curl -sSL -o vagrant.deb "https://releases.hashicorp.com/vagrant/${VAGRANT_VERSION}/vagrant_${VAGRANT_VERSION}_x86_64.deb"
	dpkg -i vagrant.deb
	)

	rm -rf "$tmpdir"

	# install plugins
	vagrant plugin install vagrant-vbguest
}


usage() {
	echo -e "install.sh\\n\\tThis script installs my basic setup for a debian laptop\\n"
	echo "Usage:"
	echo "  base                                - setup sources & install base pkgs"
	echo "  basemin                             - setup sources & install base min pkgs"
	echo "  graphics {intel, geforce, optimus}  - install graphics drivers"
	echo "  wm                                  - install window manager/desktop pkgs"
	echo "  dotfiles                            - get dotfiles"
	# echo "  vim                                 - install vim specific dotfiles"
	echo "  golang                              - install golang and packages"
	echo "  rust                                - install rust"
	echo "  scripts                             - install scripts"
	echo "  dropbear                            - install and configure dropbear initramfs"
	echo "  vagrant                             - install vagrant and virtualbox"
	echo "  docker                              - install docker"
}

main() {
	local cmd=$1

	if [[ -z "$cmd" ]]; then
		usage
		exit 1
	fi

	if [[ $cmd == "base" ]]; then
		check_is_sudo
		get_user

		# setup /etc/apt/sources.list
		setup_sources

		base
	elif [[ $cmd == "basemin" ]]; then
		check_is_sudo
		get_user

		# setup /etc/apt/sources.list
		setup_sources_min

		base_min
		install_docker
	elif [[ $cmd == "graphics" ]]; then
		check_is_sudo

		install_graphics "$2"
	elif [[ $cmd == "wm" ]]; then
		check_is_sudo

		install_wmapps
	elif [[ $cmd == "dotfiles" ]]; then
		get_user
		get_dotfiles
	# elif [[ $cmd == "vim" ]]; then
	# 	install_vim
	# elif [[ $cmd == "rust" ]]; then
	# 	install_rust
	elif [[ $cmd == "golang" ]]; then
		install_golang "$2"
	elif [[ $cmd == "scripts" ]]; then
		install_scripts
	elif [[ $cmd == "dropbear" ]]; then
		check_is_sudo

		get_user

		install_dropbear
	elif [[ $cmd == "vagrant" ]]; then
	install_vagrant "$2"
	elif [[ $cmd == "docker" ]]; then
	check_is_sudo

	install_docker
	else
		usage
	fi
}

main "$@"
