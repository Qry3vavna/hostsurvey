#!/bin/bash 
#!/usr/bin/env bash
# A host survey script for Unix systems, though tested on Linux
# Used to identify all sorts of things on a box with the help of
# GNU core utilities like grep, sed, cat, tr & others.
# Ran locally on a system, optionally select a subset of commands.
# Can also print out the commands for other systems vs running them.

main() {
  # Main loop to start it all
  initialize
  parse_input $*
  trigger start
  identify
  parse_cmd "$key"
  trigger end
}

initialize() {
  # Setup shop
  version='0.9.3 OCTOBERFEST ::Qry3v@vna~*'
  verbose=0
  color=1
  outfile=hs # for self-replication print
  stdout="" # Default STDOUT redirect
  key=""
  def_out="out_$(date +%Y%m%d%H%M).txt" # Default report name
  tgt_os=""
  name="::Qry3v@vna~*" # Default reporter's name
  print_screen=0 # Don't print to screen, actually run the commands
  # Stuff that's printed out to make pretty...
  header_top="#=====================-=====-===-==--=-=---=----------- --- -- - -  -   -"
  header_main_L="#===============\ "
  header_main_R=" ========------- -  -"
  header_bot="#================\_ "
}

parse_input() {
  # parse the command line arguments
  while [ "$1" != "" ];do
    case $1 in
      --) shift; break;; # User needs this madness to end
      -h*|--h*) usage;; # Hilfe mich
      -i*|--i*|-1*) identify;parse_cmd os;exit 0;; # Basic 1st run id and quit
      -k*|--k*) [ -z $key ] && key="${2-os}" || key="$key\|${2-os}";; # Select a specific set of commands
      -l*|--l*) echo "Listing modules";sed -n '/^_DATA/,/^_END/{/_DATA/b;/_END/b;p}' $0;exit 0;; # Show me the options
      -n|--na*) sanitize name $2;; # Name for report header
      --no-color) color=0;; # Turn off pretty colors
      --os) sanitize tgt_os $2;; # Select alternate OS
      -o|--out*) sanity_check ${2-$def_out};stdout=">>${2-$def_out}";color=0;; # for survey saved output
      -p|--print) ((print_screen++));; # print commands to screen instead of running them
      --print-self) print_self $2;; # Self replicate?
      -q*|--q*) verbose=-1;; # Shhh...
      -v|--verbo*) ((verbose++));; # More info...
      -V|--vers*) echo $0 $version;exit 0;; # Welke versie ben je eigenlijk?
    esac
    shift
  done
  v_echo "d verbose:[$verbose] key:[$key] name:[$name] out:[$stdout] color:[$color]"
}

sanity_check() {
  # double check some things, validate given file is writable
  sanitize in "$*"
  if [ ! -e $in ];then
    touch $in
    e_check "$? sanity check touch on $in"
  else
    if [ ! -w $in ];then # exists & can't write to it
      v_echo "f error: unable to write report to file $in"
      exit 1 
    fi
  fi
}

sanitize() {
  # Sanitize given user input a little bit
  var="$1";shift
  v_echo "d PRE IN:$*"
  clean=${*//[^a-zA-Z0-9_\/]/}
  v_echo "d POST IN:$clean"
  eval "$var=\"$clean\""
}

trigger() {
  # Keep track of the start time and total time
  if [ "$1" == "start" ];then
    t_start="$(date +%s)"
    eval "v_echo 'i ### starting host survey on $(hostname) by $name at $(date) ###' $stdout"
  else
    t_diff=$(($(date +%s)-$t_start))
    t_start=
    eval "v_echo 'i ### completed host survey on $(hostname) at $(date) ###' $stdout"
    eval "v_echo 'i ### $(($t_diff/60)) minutes and $(($t_diff%60)) seconds elapsed.' $stdout"
  fi
}

identify() {
  # Basic commands on 1st run, to ensure we can run commands...
  # Make sure PATH variable is set and has something useful in it
  # Check for basic tools & version (need GNU), then try and detect the OS
  [ "$PATH" == "" ] && PATH='/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin' 
  for tool in sed grep stat cat tr;do
    which $tool 2>&1 >/dev/null
    e_check $? locating tool $tool
    $(which $tool) --version 2>/dev/null|grep GNU 2>&1 >/dev/null
    e_check $? tool $tool GNU check
  done
  detect_os
}

parse_cmd() {
  # parse command list processes the data section below
  # filtering by category keys and printing or executing the given commands
  key="$*"
  while IFS=: read -a line;do
    c_type="${line[0]}";c_os="${line[1]}";c_cmd="${line[2]}"
    v_echo "d c_type:[$c_type] tgt_os:[$tgt_os] c_os:[$c_os] c_cmd:[$c_cmd]"
    if [[ "$tgt_os" == *$c_os* ]];then
      eval "v_echo 'I $header_top' $stdout"
      eval "v_echo 'i $header_main_L $c_type $header_main_R' $stdout"
      eval "v_echo 'w $header_bot $c_cmd' $stdout"
      if [[ "$print_screen" -gt 0 ]];then # Run it or print it?
        echo "$c_cmd $stdout"
      else
        eval "$c_cmd 2>/dev/null|tr '\t' ' ' $stdout"
        e_check $? $c_type
      fi
    fi
  done< <(sed -n '/^_DATA/,/^_END/{/_DATA/b;/_END/b;p}' $0|grep "^$key")
  e_check $? parse_cmd loop
}

detect_os() {
  # Try and detect the OS
  if [[ -z "$tgt_os" ]];then # os not yet given as argument, detect it
    res="$(parse_cmd os)"
    case $(echo $res|tr [:upper:] [:lower:]) in
      arch*) tgt_os="linux/arch";;
      *darwin*) tgt_os="bsd/osx";;
      *debian*) tgt_os="linux/debian";;
      *freebsd*) tgt_os"bsd/freebsd";;
      *"red hat"*) tgt_os="linux/redhat";;
      *ubuntu*) tgt_os="linux/debian/ubuntu";;
    esac
  else
    v_echo "I Manually selected $tgt_os as OS"
  fi
  v_echo "d tgt_os:[$tgt_os]"
}

print_self() {
  # print myself with echo lines, for easier copy/paste
  # takes output file if not uses default hs
  # sed deletes line beg. w/ # and blank lines
  # then prepends echo and appends stdout redirect
  # does NOT print out this specific function print_self
  outfile=${1-$outfile}
  v_echo "I Printing self to $outfile"
  echo "echo '#!/bin/bash' >$outfile"
  sed "/^#/d;/^$/d;/print_self()/,/^}/d;s/['\"]/\\\&/g;s/^/echo $'/g;s/$/'>>$outfile/g" <$0
  echo "chmod +x $outfile;./$outfile"
  exit 0
}

v_echo() {
  # Verbose echo with colors helper function
  type="${*%% *}";msg="$(echo $*|cut -d' ' -f2-)"
  #v_echo "d Type:[$type] Msg:[$msg] Color:[$color] Verbose:[$verbose]"
  if [[ "$color" -gt 0 ]];then # Screen then color, else nope
    case $verbose in
      0|1|2|3)case $type in
        f) echo -e "\e[1;31m[-] $msg\e[0m";; # fail/red
        i) echo -e "\e[1;34m[*] $msg\e[0m";; # info/blue
        r) echo -e "$msg";; # raw/no formatting
        esac;;&
      1|2|3)case $type in
        w) echo -e "\e[1;33m[!] $msg\e[0m";; # warn/yellow
        esac;;&
      2|3)case $type in
        I) echo -e "\e[1;34m[*] $msg\e[0m";; # Extra level 3 info/blue
        s) echo -e "\e[1;32m[+] $msg\e[0m";; # success/green
        esac;;&
      3)case $type in
        d) echo -e "\e[1;35m[d] $msg\e[0m";; # debug/purple
        esac;;
    esac
  else
    case $verbose in
      0|1|2|3)case $type in
          f) echo "[-] $msg";;
          i) echo "[*] $msg";;
          w) echo "[!] $msg";;
        esac;;&
     2|3)case $type in
          I) echo "[*] $msg";;
          s) echo "[+] $msg";;
          d) echo "[d] $msg";;
          *) echo "$msg";;
        esac;;
    esac
  fi
}

e_check() {
  # Error checking helper function
  err="$(echo $1|cut -d' ' -f1)";shift
  v_echo "d e_check $err $*"
  if [ "$err" -gt 0 ];then
    v_echo "f ERROR: $err with $*"
  else
    v_echo "s GO${err}D: with $*"
  fi  
}

line() {
  # Print line, helper function
  echo '-  - --------------------------------------------------------------- -  -'
}

logo() {
  decode "IF8gICBfICAgICAgICAgICBfICAgX19fX18gICAgICAgICAgICAgICAgICAgICAgICAgICAgCnwg
fCB8IHwgICAgICAgICB8IHwgLyAgX19ffCAgICAgICAgICAgICAgICAgICAgICAgICAgIAp8IHxf
fCB8IF9fXyAgX19ffCB8X1wgYC0tLiBfICAgXyBfIF9fX18gICBfX19fXyBfICAgXyAKfCAgXyAg
fC8gXyBcLyBfX3wgX198YC0tLiBcIHwgfCB8ICdfX1wgXCAvIC8gXyBcIHwgfCB8CnwgfCB8IHwg
KF8pIFxfXyBcIHxfL1xfXy8gLyB8X3wgfCB8ICAgXCBWIC8gIF9fLyB8X3wgfApcX3wgfF8vXF9f
Xy98X19fL1xfX1xfX19fLyBcX18sX3xffCAgICBcXy8gXF9fX3xcX18sIHwKICAgICAgICAgICAg
ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIF9fLyB8CiAgICAgICAgICAgICAg
ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHxfX18vCg=="
}

decode() {
  # Try different decoders until we find a working one
  decoder=(
    'python -m base64 -d $1'
    'openssl enc -a -d'
    'base64 -d'
  )
  while [ "${#decoder[*]}" -gt 0 ];do
      echo -e "$*"|eval "${decoder[${#decoder[*]}-1]}"
    [ "$?" -eq 0 ] && break
    unset decoder[${#decoder[*]}-1]
  done
}

usage() {
  # Help page... helper function
cat << E0F
$(logo)
$0 $version

$(grep '^#' $0|grep -v '/bin/bash\|/bin/env') 

USAGE: $0 <options>

OPTIONS:
      --			Stop the press, no more argument parsing please
      -h --help			This cruft...(help page)	
      -i --initial -1 -1st	Run basic identification commands
      -k --key <word>		Sets module category to search, aka net or id or os.uname
      -l --list			Lists all modules available, category:os:command
      -n --name <name>		Sets name used in output of full survey report
      --no-color		Turn off the pretty colors :(
      --os <os>			Select OS architecture instead of autodetect.
				  Used to force an OS if autodetect fails, or 
				  used with [-p] to print out the commands,
				  when a remote system does not run bash.
      -o --out <file>		Sets the ouput file to save the report to,
				  else it's to the screen (STDOUT). 
				  If no file name given, this defaults to out_\$DateTime
      -p --print		Prints the commands to the screen instead of running them
				  Useful for a quick copy/paste of a set of commands.
      --print-self		Prints this script in a format to easily copy
				  then paste in a remote shell, minus the print-self function
      -q --quiet		Quiet, only print raw results, no info or headers (deal with it!)
      -v --verbose		Increases verbosity, a little more output like headers
				  1x more headers, 2x exit codes, 3x debug mode
      -V --version		Prints versions and quits

EXAMPLES:
	$0 -v -k os
	Runs various OS detection commands and prints them to STDOUT with verbose headers

	$0 -k net
	Run various network information commands and prints the results with headers

	$0 -p -a freebsd -k os -q
	Prints the raw OS detection commands for FreeBSD architecture to screen to copy and paste

E0F
exit 0
}

  # The data is referenced with sed/grep
  # Format:=>  category-subcategory:os,list:command
  # If os is blank, the command should apply to all POSIX systems
  # Else, narrow down as approriate aka Linux,BSD or Debian or Ubuntu-13
  # Parser does NOT like single quotes, something awk needs, so lots of cuts instead
  # If you have a simple test []&&|| be sure to add "$stdout" to the first test block
<< EoF
_DATA_
find.uid::find / -perm +4000 -uid 0:
find.writable.dir::find / -writable -type d:
find.writable.etc::find /etc/ -writable:
find.dirwalk::find /:
hw.cpu::cat /proc/cpuinfo:
hw.dmi::dmidecode|grep -i "ser\|chas\|manu\|prod\|uuid"|sort -u:
hw.drives.df::df -h:
hw.drives.fdisk::fdisk -l:
hw.drives.fstab::cat /etc/fstab:
hw.drives.fstab-uuid::for x in \$(grep "^UUID" /etc/fstab|cut -d" " -f1|cut -d= -f2);do echo -n "UUID $x = ";blkid -U $x;done:
hw.drives.lvm::for x in pvdisplay vgdisplay lvdisplay;do echo $x;$x;line;done:
hw.drives.mount::mount:
hw.drives.proc::cat /proc/mounts:
hw.export::cat /etc/exports:
hw.lshw::lshw -quiet:
hw.mem::cat /proc/meminfo:
hw.mem::free -m:
hw.pci::lspci -v:
hw.usb::lsusb -v:
id.getpid::ps -ef|grep $$|grep -v grep:
id.getuid::id:
id.pwd::pwd:
id.path::echo $PATH:
id.time.date::date:
id.time.hwclock::for x in -r --localtime;do echo "hwclock $x";hwclock $x;done:
id.time.ntp.conf::sed "/^#/d;/^$/d" /etc/ntp.conf:
id.time.timezone:debian:cat /etc/timezone:
id.upime::uptime:
log.audit:::
net.arp::arp -a:
net.config.net:bsd:cat /etc/network:
net.config.my:bsd:cat /etc/my*:
net.config.if:bsd:cat /etc/if*:
net.config.interfaces:debian:cat /etc/network/interfaces:
net.config.ifcfg:redhat:cat /etc/networking/syslog/if-cfg*:
net.dns.resolv::cat /etc/resolv.conf:
net.host::for x in \$(ls /etc/host*);do stat $x;e_check $? $x;echo;cat $x;line;done:
net.hw::for x in \$(ifconfig -a|grep "encap"|cut -d" " -f1);do ethtool $x;ethtool -i $x;done:
net.ip::ifconfig -a:
net.ip::ip add:
net.route::route -n:
net.stat::netstat -auntp:
os.hostname::hostname -f:
os.initab:linux:sed '/^#/d;/^$/d' /etc/inittab:
os.install-date::stat -c %z /var/log/installer/syslog:
os.namefile::cat /etc/hostname*:
os.runlevel:linux:runlevel:
os.runlevel-who:linux:who -r:
os.uname::uname -a:
os.ver.issue::cat /etc/issue:
os.ver.lsb::lsb_release -a:
os.ver.proc::cat /proc/version:
os.ver.rel::cat /etc/*release*:
sec.fw.iptables::[[ \$(lsmod|grep ip_t) ]] && iptables -L -v $stdout || echo iptables not loaded:
sec.fw.ufw:ubuntu:ufw numbered:
sec.mac.aastatus:linux:aa-status: # App Armor
sec.mac.selinux:linux:sestatus:
sec.mac.tomoyo-proc:linux:cat /proc/css:
sec.mac.tomoyo-log:linux:ls /var/log/tomoyo:
start.crondirs::ls -Rl /etc/cron*:
start.rcdirs::ls -Rl /etc/rc*:
start.rclocal::cat /etc/rc.local:
sw.config.sshd::sed "/^#/d;/^$/d" /etc/ssh/sshd_config:
sw.install.dpkg:debian:dpkg -l:
sw.install.pacman:arch:pacman -Qe:
sw.install.pkginfo:freebsd:pkg_info:
sw.install.pkginfo:solaris,sunos:pkginfo -l:
sw.install.pkgtool:slackware:pkgtool:
sw.install.rpm:redhat:rpm -qa:
sw.running::ps -ef:
sw.running:linux:pstree -A -d:
user.home::ls -l /home:
user.last::last:
user.passwd::cat /etc/passwd:
user.status::passwd -a -S:
user.sudoers::sed "/^ *$/d\;/^#/d" /etc/sudoers:
user.sudo.group::grep "^wheel\\|^sudo\\|^admin" /etc/group:
user.w::w:
_END_
EoF

#=---=#
main $*
