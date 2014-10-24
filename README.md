# HostSurvey
<pre>
 _   _           _   _____                            
| | | |         | | /  ___|                           
| |_| | ___  ___| |_\ `--. _   _ _ ____   _____ _   _ 
|  _  |/ _ \/ __| __|`--. \ | | | '__\ \ / / _ \ | | |
| | | | (_) \__ \ |_/\__/ / |_| | |   \ V /  __/ |_| |
\_| |_/\___/|___/\__\____/ \__,_|_|    \_/ \___|\__, |
                                                 __/ |
                                                |___/
./hs 0.9.X OCTOBERFEST ::Qry3v@vna~*
</pre>

A host survey script for Unix systems, though tested on Linux
Used to identify all sorts of things on a box with the help of
GNU core utilities like grep, sed, cat, tr & others.
Ran locally on a system, optionally select a subset of commands.
Can also print out the commands for other systems vs running them.

------------------

### USAGE: 
`./hs \<options\>`

### OPTIONS:
| Args        | What it does           |
|:------------- |:-------------|
| `--`      | Stop the press, no more argument parsing please |
|`-h  --help`| This cruft...(help page)|
|`-i  --initial  -1`| 1st Run basic identification commands|
|`-k --key <word>`| Sets module category to search, aka net or id or os.uname|
|`-l --list`| Lists all modules available, category:os:command|
|`-n --name <name>`| Sets name used in output of full survey report|
|`--no-color`| Turn off the pretty colors :(|
|`--os <os>`|Select OS architecture instead of autodetect. Used to force an OS if autodetect fails, or used with [-p] to print out the commands, when a remote system does not run bash.|
|`-o --out <file>`|Sets the ouput file to save the report to, else it's to the screen (STDOUT). If no file name given, this defaults to out_$DateTime. A given file will be appended to if it already exists.|
|`-p --print`| Prints the commands to the screen instead of running them.  Useful for a quick copy/paste of a set of commands.|
|`--print-self`| Prints this script in a format to easily copy then paste in a remote shell, minus the print-self function|
|`-q --quiet`| Quiet, only print raw results, no info or headers (deal with it!)|
|`-v --verbose`| Increases verbosity, a little more output. 1x more headers, 2x exit codes, 3x debug mode|
|`-V --version`| Prints versions and quits|

------------------------
### EXAMPLES:

`./hs -v -k os`
>Runs various OS detection commands and prints the results to STDOUT with verbose headers

`./hs -k net`
>Run various network information commands and prints the results with headers

`./hs -p -a freebsd -k os -q`
>Prints the raw OS detection commands for FreeBSD architecture to screen to copy and paste

`./hs --out ~/customer.report.txt --name AuditTeam12`
>Runs the full host survey and saves the results to the file ~/customer.report.txt

-------------------------

### QPFR: Questions, Problems or Feature Requests:
Open a ticket on GitHub and we'll see what can get done! :^)

-------------------------
### LICENSE:
  * [Distributed under the Apache License, Version 2.0](http://www.apache.org/licenses/LICENSE-2.0)
