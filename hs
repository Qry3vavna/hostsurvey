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
  version='0.9.8 OCTOBERFEST ::Qry3v@vna~*'
  verbose=0
  identify=0
  color=1
  outfile=hs # for self-replication print
  stdout="" # Default STDOUT redirect
  key=""
  def_out="out_$(date +%Y%m%d%H%M).txt" # Default report name
  tgt_os=""
  name="::Qry3v@vna~*" # Default reporter's name
  print_screen=0 # Don't print to screen, actually run the commands
  # Stuff that's printed out to make pretty...
  header_top="#==========================================================================#"
  header_main_L="#=====================\ "
  header_main_R=" /==#"
  header_bot="#======================\_ "
  col_blu="";col_grn="";col_red="";col_pur="";col_yel="";end_col=""
}

parse_input() {
  # parse the command line arguments
  while [ "$1" != "" ];do
    case $1 in
      --) shift; break;; # User needs this madness to end
      -h*|--h*) usage;; # Hilfe mich
      -i*|--i*|-1*) ((identify++));; # Basic 1st run id and quit
      -k*|--k*) [ -z $key ] && key="^${2-os}" || key="$key\|^${2-os}";; # Select a specific set of commands
      -l*|--l*) echo "Listing modules";sed -n '/^_DATA/,/^_END/{/_DATA/d;/_END/d;p;}' $0;exit 0;; # Show me the options
      -n|--na*) sanitize name $2;; # Name for report header
      --no-color) color=0;; # Turn off pretty colors
      -O|--os|--op*) sanitize tgt_os $2;; # Select alternate OS
      -o|--out*) sanity_check ${2-$def_out};stdout=">>${2-$def_out}";color=0;; # for survey saved output
      -p|--print) ((print_screen++));; # print commands to screen instead of running them
      --print-self) print_self $2;; # Self replicate?
      -q*|--q*) verbose=-1;; # Shhh...
      -v|--verbo*) ((verbose++));; # More info...
      -V|--vers*) echo $0 $version;exit 0;; # Welke versie ben je eigenlijk?
    esac
    shift
  done
  post_parse
  v_echo "d verbose:[$verbose] key:[$key] name:[$name] out:[$stdout] color:[$color]"
}

post_parse() {
  # Stuff to do after parsing input
  # You too can add stuff here for one off macros
  if [ "$identify" -gt 0 ];then # If -1 or -i was selected, do this: 
      identify;parse_cmd '^id';exit 0 # Basic 1st run id and quit
  fi
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
    e_check "$? locating tool $tool"
    #$(which $tool) --version 2>/dev/null|grep GNU 2>&1 >/dev/null
    #e_check "$? tool $tool GNU check"
  done
  detect_os
  set_colors
}

parse_cmd() {
  # parse command list processes the data section below
  # filtering by category keys and printing or executing the given commands
  key="$*"
  while IFS=: read -a line;do
    c_type="${line[0]}";c_os="${line[1]}";c_cmd="${line[2]}";c_alt="${line[3]}"
    v_echo "d c_type:[$c_type] tgt_os:[$tgt_os] c_os:[$c_os] c_cmd:[$c_cmd]"
    if [[ "$tgt_os" == *$c_os* ]];then
      eval "v_echo 'I $header_top' $stdout"
      eval "v_echo 'i $header_main_L $c_type $header_main_R' $stdout"
      eval "v_echo 'w $header_bot $c_cmd' $stdout"
      if [[ "$print_screen" -gt 0 ]];then # Run it or print it?
        if [ "$c_alt" != "" ];then
          echo "$c_alt $stdout"
        else
          echo "$c_cmd $stdout"
        fi
      else
        eval "$c_cmd 2>/dev/null|tr '\t' ' ' $stdout"
        e_check "$? $c_type"
      fi
    fi
  done< <(sed -n '/^_DATA/,/^_END/{/_DATA/d;/_END/d;p;}' $0|grep "$key")
}

detect_os() {
  # Try and detect the OS
  # Runs through the OS commands from the survey and save all the results,
  # then searches for OS specific strings within the total results for a match.
  if [[ -n "$tgt_os" ]];then # os given as argument, set it
    v_echo "i Manually selected $tgt_os as OS"
    res="$tgt_os"
  else # os not yet given as argument, detect it
    res="$(parse_cmd os)"
  fi
  case $(echo $res|tr [:upper:] [:lower:]) in
    *aix*) tgt_os="sysv/aix";;
    *android*) tgt_os="linux/android";;
    arch*) tgt_os="linux/arch";;
    *centos*) tgt_os="linux/redhat/centos";;
    *cygwin*) tgt_os="linux/cygwin";; # Windows
    *darwin*|*osx*) tgt_os="bsd/mach/osx";;
    *debian*) tgt_os="linux/debian";;
    *dragonfly*) tgt_os="bsd/dragonfly";;
    *fedora*) tgt_os="linux/redhat/fedora";;
    *freebsd*) tgt_os="bsd/freebsd";;
    *gentoo*) tgt_os="linux/gentoo";;
    *hp-ux*) tgt_os="sysv/hp-ux";;
    *irix*) tgt_os="sysv/bsd/irix";;
    *knoppix*) tgt_os="linux/debian/knoppix";;
    *mach*|*hurd*) tgt_os="bsd/mach/hurd";;
    *mandrake*) tgt_os="linux/redhat/mandrake";;
    *mingw*) tgt_os="linux/mingw";; # Windows
    *minix*) tgt_os="posix/minix";;
    *netbsd*) tgt_os="bsd/netbsd";;
    *openbsd*) tgt_os="bsd/openbsd";;
    *openwrt*) tgt_os="linux/openwrt";;
    *qnx*) tgt_os="posix/qnx";;
    *"red hat"*) tgt_os="linux/redhat";;
    *slackware*) tgt_os="linux/slackware";;
    *solaris*) tgt_os="sysv/bsd/solaris";;
    *sunos*) tgt_os="bsd/sunos";;
    *suse*) tgt_os="linux/slackware/suse";;
    *true64*) tgt_os="sysv/mach/hp-alpha";;
    *ubuntu*) tgt_os="linux/debian/ubuntu";;
    *windows*) tgt_os="linux/win-bash";; # Windows
    *linux*) tgt_os="linux";; # Artificial fall through
  esac
  v_echo "w Detected $tgt_os as OS"
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
  sed "/^#/d;/^$/d;/print_self()/,/^}/d;s/['\"]/\\\&/g;s/^/echo $'/g;s/$/'>>$outfile/g;" <$0
  echo "chmod +x $outfile;./$outfile"
  exit 0
}

set_colors(){
  # Set colors helper function
  # Sets bash echo colors dependent on the OS
  col_select="$tgt_os"
  [ "$color" == 0 ] && col_select="nocolor" 
  case $col_select in
    *osx*|*bsd*) col_blu=$'\e[01;34m'
           col_grn=$'\e[01;32m' 
           col_red=$'\e[01;31m'
           col_pur=$'\e[01;35m'
           col_yel=$'\e[01;33m'
           end_col=$'\e[0m';;
    *lin*) col_blu="\e[1;34m"
           col_grn="\e[1;32m" 
           col_red="\e[1;31m"
           col_pur="\e[1;35m"
           col_yel="\e[1;33m"
           end_col="\e[0m";;
    *) col_blu="";col_grn="";col_red=""
       col_pur="";col_yel="";end_col="";;
  esac
  v_echo "d COLORS:$color, OS:$tgt_os ${col_red}RED${end_col}${col_yel}YEL${end_col}${col_grn}GRN${end_col}${col_blu}BLU${end_col}${col_pur}PUR${end_col}"
}

v_echo() {
  # Verbose echo with colors helper function
  # Now backwards compatible with Bash 3
  # Checks verbosity level, followed by msg type
  # Selects which msg type/format is allowed at which verbosity level
  type="${*%% *}";msg="$(echo $*|cut -d' ' -f2-)"
  local v="$verbose"
  # echo ":: Type:[$type] Msg:[$msg] Color:[$color] Verbose:[$v]"
  [[ -z "$type" ]] && type="d" # If type was not found, set it to debug
  if (( v >= 3 ));then # verbose 3 or greater
   [[ $(echo finrwWFISsd|grep "$type") ]] && ve_print $type $msg # Echo out the msg types allowed at this verbosity and search for match
  elif (( v <= 3 )) && (( v >= 2 ));then # verbose 2 or greater
   [[ $(echo finrwWFISs|grep "$type") ]] && ve_print $type $msg
  elif (( v <= 3 )) && (( v >= 1 ));then # verbose 1 or greater
   [[ $(echo finrwWF|grep "$type") ]] && ve_print $type $msg
  elif (( v <= 3 )) && (( v >= 0 ));then # verbose 0 or greater
   [[ $(echo finrF|grep "$type") ]] && ve_print $type $msg
  fi 
}

ve_print() {
  # Verbose echo print handler
  # Does the actual formatting and printing to stdout given msg type and msg
  type="$1";shift;msg="$*"
  case $type in
    f) echo -e "${col_red}[-]${end_col} $msg";; # fail/red
    i) echo -e "${col_blu}[*]${end_col} $msg";; # info/blue
    n) echo -ne "$msg";; # raw/no formatting/no new-line
    r) echo -e "$msg";; # raw/no formatting
    w) echo -e "${col_yel}[!]${end_col} $msg";; # warn/yellow
    W) echo -e "${col_yel}[!] $msg${end_col}";; # warn/yellow - whole line
    F) echo -e "${col_red}[-] $msg${end_col}";; # fail/red - whole line
    I) echo -e "${col_blu}[*] $msg${end_col}";; # Extra level 3 info/blue - whole line
    S) echo -e "${col_grn}[+] $msg${end_col}";; # success/green
    s) echo -e "${col_grn}[+]${end_col} $msg";; # success/green
    d) echo -e "${col_pur}[d]${end_col} $msg";; # debug/purple
  esac
}

e_check() {
  # Error checking helper function
  # Checks if given exit code is greater than 0,
  # then notifies with a message
  # called with: e_check "<EXIT_CODE> <MESSAGE>" <- note the double quotes
  local err="$(echo $1|cut -d' ' -f1)"
  local msg="$(echo $1|cut -d' ' -f2-)"
  v_echo "d e_check $err $msg"
  if [ "$err" -gt 0 ];then
    v_echo "f [ERROR]: $err with $msg"
  else
    v_echo "s [GO${err}D]: with $msg"
  fi
}

f_check() {
  # File checking helper function
  # f_check File Checks Action
  # Check are comma separated tests, see "man test", zbs: e (exist), d (directory)
  # Action is command to run against file if it past the test, bvb: cat, sed
  f="$1";c=( $(echo "$2"|tr ',' ' ') );shift;shift;a="$*"
  v_echo "d f_check File:$f Checks:$c Action:$a"
  while [ "${#c[*]}" -gt 0 ];do # Loop through 2nd argument which are single letter tests
    check="${c[${#c[*]}-1]}"
    case $check in
      d) e="a directory";;
      e) e="exists";;
      f) e="a file";;
      x) e="executable";;
      z) e="zeroed";;
      *) e="$check";;
    esac
  # check=$(man [|grep -i -- "true if"|grep -w -- "-${c[${#c[*]}-1]}"|head -1|tr -s " \t"|cut -d" " -f4-) # Only works on some Linux
    if [ ! "-$check" $f ];then
      if [ "${a:0:1}" == '!' ];then
        "${a:1}" $stdout # Were we given a fail action?
      fi
      e_check "1 File $f $e [ No ]"
      return 1
    else
      v_echo "s File $f $e [ Yes ]"
      if [ "$a" != "" ] && [ "${a:0:1}" != '!' ];then
        $a $f $stdout # Run action against given file
        e_check "$? $a $f"
      fi
    fi
    unset c[${#c[*]}-1] # Iterate through list, pop element
  done
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

strip_cat() {
  # Strip cat helper function, displays files minus comments or blank lines
  # Optional tail to cut down lines shown, defaults 1000 lines
  f="$1";l="${2-1000}"
  v_echo "d strip_cat File:$f Line:$l"
  f_check $f e !exit
  sed "/^#/d;/^\;/d;/^$/d;" $f | tail -${l}
  e_check "$? strip_cat $f"
}

stat_cat() {
  # stat cat helper function, prints stats info, then calls strip_cat
  # Arg 1=file, 2=line-count
  f="$1";l="$2"
  v_echo "d stat_cat File:$f Line:$l"
  f_check $f e stat # Does the file exist? If so run stat
  if [[ $? -eq 0 ]];then
    line
    strip_cat $f $l
  fi
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
      -i --initial -1  		Run basic identification commands
      -k --key <word>		Sets module category to search, aka net or id or os.uname
      -l --list			Lists all modules available, category:os:command
      -n --name <name>		Sets name used in output of full survey report
      --no-color		Turn off the pretty colors :(
      -O --os <os>		Select OS architecture instead of autodetect.
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

	$0 -p --os freebsd -k os -q
	Prints the raw OS detection commands for FreeBSD architecture to screen to copy and paste

        $0 --out ~/customer.report.txt --name AuditTeam12
	Runs the full host survey and saves the result to the file ~/customer.report.txt

LICENSE: Apache 2.0 :

	Required:	- Include license and copyright notice
			- State any changes made from this code

        Permitted:	- Use commercially	- Grant patents
			- Ditribute		- Use privately
			- Modify		- Sublicense

	Forbidden:	- Hold us liable
			- Use trademark
E0F
exit 0
}

  # The data is referenced with sed/grep
  # Format:=>  category.subcategory:os,list:command:alternate
  # Alternates are used to display actual cmds vs internal shortcuts in case they're printed
  # If os is blank, the command should apply to all POSIX systems
  # Else, narrow down as approriate aka Linux, BSD or Debian or Ubuntu-13
  # Parser does NOT like single quotes, something awk needs, so lots of cuts instead
  # If you have a simple test []&&|| be sure to add "$stdout" to the first test block
<< EoF
_DATA_
find.suid::find / -perm +4000 -uid 0::
find.writable.dir::find / -writable -type d::
find.writable.etc::find /etc -writable -type f::
find.dirwalk::find /::
hw.cpu::cat /proc/cpuinfo::
hw.dmi::dmidecode|grep -i "ser\|chas\|manu\|prod\|uuid"|sort -u::
hw.drives.df::df -h::
hw.drives.du::du -h --max-depth=1 /::
hw.drives.fdisk::fdisk -l::
hw.drives.fstab::strip_cat /etc/fstab:cat /etc/fstab:
hw.drives.fstab.uuid::for x in \$(grep "^UUID" /etc/fstab|cut -d" " -f1|cut -d= -f2);do echo -n "UUID $x = ";blkid -U $x;done::
hw.drives.lvm::for x in pvdisplay vgdisplay lvdisplay;do echo [*] $x;$x;line;done::
hw.drives.mount::mount::
hw.drives.proc::cat /proc/mounts::
hw.export::strip_cat /etc/exports:cat /etc/exports:
hw.lshw::lshw -quiet::
hw.mem.proc::cat /proc/meminfo::
hw.mem.free::free -m::
hw.pci::lspci -v::
hw.usb::lsusb -v::
id.time.date::date::
id.getuid::id::
id.getpid::echo -n "PID\: ";ps -ef|grep $$|grep -v grep|head -1|tr -s [\:space\:]|cut -d" " -f2::
id.getpid.parent::ps -ef|grep \$(ps -ef|grep $$|tr -s [\:space\:]|cut -d" " -f3|head -1)|tr -s [\:space\:]::
id.pwd::pwd::
id.path::echo $PATH::
id.upime::uptime::
log.auth::stat_cat /var/log/auth.log 10:tail -10 /var/log/auth.log:
log.msg::stat_cat /var/log/messages 25:tail -25 /var/log/messages:
log.sec::stat_cat /var/log/secure 10:tail -10 /var/log/secure:
net.arp::arp -a::
net.config.net:bsd:strip_cat /etc/network:cat /etc/network:
net.config.my:bsd:strip_cat /etc/my*:cat /etc/my*:
net.config.if:bsd:cat /etc/if*::
net.config.interfaces:debian:strip_cat /etc/network/interfaces:cat /etc/network/interfaces:
net.config.ifcfg:redhat:strip_cat /etc/networking/syslog/if-cfg*:cat /etc/networking/syslog/if-cfg*:
net.dns.resolv::strip_cat /etc/resolv.conf:cat /etc/resolv.conf:
net.host::for x in \$(ls /etc/host*);do stat $x;e_check "$? $x";echo;cat $x;line;done::
net.hw::for x in \$(ifconfig -a|grep "encap"|cut -d" " -f1);do ethtool $x;ethtool -i $x;done::
net.ip::ifconfig -a::
net.ip::ip add::
net.route::route -n::
net.stat::netstat -auntp::
os.banner.motd::strip_cat /etc/motd:cat /etc/motd:
os.banner.issue::strip_cat /etc/issue:cat /etc/issue:
os.boot:linux:cat /proc/cmdline::
os.hostname:linux:hostname -f::
os.hostname:sysv:hostname::
os.initab.fcheck:linux:strip_cat /etc/inittab:cat /etc/inittab:
os.install-date::stat -c %z /var/log/installer/syslog:
os.namefile::cat /etc/hostname*::
os.runlevel:linux:runlevel::
os.runlevel-who:linux:who -r::
os.uname::uname -a::
os.ver.issue::strip_cat /etc/issue:cat /etc/issue:
os.ver.lsb::lsb_release -a::
os.ver.ostype::echo $OSTYPE::
os.ver.proc::cat /proc/version::
os.ver.rel::cat /etc/*release*::
sec.virt.lxc::cat /proc/1/cgroup::
sec.virt.vmw::dmidecode|grep -i "virt"::
sec.fw.arptables::if [[ \$(lsmod|grep arpt) ]];then arptables -L -v -n $stdout;else echo arptables not loaded;fi::
sec.fw.ebtables::if [[ \$(lsmod|grep ebta) ]];then ebtables -L $stdout;else echo ebtables not loaded;fi::
sec.fw.iptables::if [[ \$(lsmod|grep ip_t) ]];then for x in filter mangle nat raw;do echo "[*] Type\: $x";iptables -t $x -L -n -v;line;done;else echo iptables not loaded;fi::
sec.fw.ip6tables::if [[ \$(lsmod|grep ip6) ]];then ip6tables -L -v -n $stdout;else echo ip6tables not loaded;fi::
sec.fw.nftables::if [[ \$(lsmod|grep nf_t) ]];then nftables -L -v -n $stdout;else echo nftables not loaded;fi::
sec.fw.ufw:ubuntu:ufw numbered::
sec.mac.aastatus:linux:aa-status::# App Armor
sec.mac.selinux:linux:sestatus::
sec.mac.tomoyo-proc:linux:cat /proc/css::
sec.mac.tomoyo-log:linux:ls /var/log/tomoyo::
sec.sw.acct::service acct status::
sec.sw.tcpdump::ps -ef|grep -i tcpdump::
sec.sw.snoop:solaris:ps -ef|grep -i snoop::
start.crondirs::ls -Rl /etc/cron*::
start.crontab::strip_cat /etc/crontab:cat /etc/crontab:
start.dmesg::dmesg::
start.rcdirs::ls -Rl /etc/rc*::
start.rclocal::strip_cat /etc/rc.local:cat /etc/rc.local:
start.init.start:redhat:chkconfig --list::
start.systemd.start::systemctl list-unit-files --type=service::
sw.config.samba::strip_cat /etc/samba/smb.conf:cat /etc/samba/smb.conf:
sw.config.ssh::strip_cat /etc/ssh/ssh_config:cat /etc/ssh/ssh_config:
sw.config.sshd::strip_cat /etc/ssh/sshd_config:cat /etc/ssh/sshd_config:
sw.config.sysctl::strip_cat /etc/sysctl.conf:cat /etc/sysctl.conf:
sw.install.dpkg:debian:dpkg -l::
sw.install.pacman:arch:pacman -Qe::
sw.install.pkginfo:freebsd:pkg_info::
sw.install.pkginfo:solaris,sunos:pkginfo -l::
sw.install.pkgtool:slackware:pkgtool::
sw.install.rpm:redhat:rpm -qa::
sw.kernel.lsmod::for x in \$(lsmod|cut -d" " -f1);do echo "[*] $x";modinfo $x;line;done::
sw.running::ps -ef::
sw.running:linux:pstree -A -d::
sw.running.init.services::service --status-all 2>&1|grep "\+\\|run"::
sw.running.systemd.services::systemctl::
time.date::date::
time.hwclock:linux:for x in -r --localtime;do echo "hwclock $x";hwclock $x;done::
time.ntp.conf::strip_cat /etc/ntp.conf:cat /etc/ntp.conf:
time.ntp.ntpq::ntpq -pn::
time.timezone:debian:strip_cat /etc/timezone:cat /etc/timezone:
user.home::ls -l /home::
user.history::for x in \$(cut -d\: -f6 </etc/passwd|sort -u);do if [[ -e "$x/.bashrc" ]]||[[ -e "$x/.profile" ]];then echo [*] $x;cat $x/.*history;line;fi;done::
user.ssh.authorizedkeys::for x in \$(cut -d\: -f6 </etc/passwd|sort -u);do if [[ -d "$x/.ssh" ]];then echo [*] $x;ls -la $x/.ssh;line;cat $x/.ssh/authorized_keys;line;fi;done::
user.ssh.privkeys::find / -regex ".*\\(id_dsa\\|id_ecdsa\\|id_rsa\\)" -exec echo "[*]" {} \\; -exec stat {} \\; -exec cat {} \\;::
user.last::last::
user.lastlog:linux:lastlog::
user.lastlogin:bsd:lastlogin::
user.passwd::strip_cat /etc/passwd:cat /etc/passwd:
user.shadow::strip_cat /etc/shadow:cat /etc/shadow:
user.status::passwd -a -S::
user.sudoers::strip_cat /etc/sudoers:cat /etc/sudoers:
user.sudo.group::grep "^wheel\\|^sudo\\|^admin" /etc/group::
user.w::w::
_END_
EoF

#=---=#
main $*
