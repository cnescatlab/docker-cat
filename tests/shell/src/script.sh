#!env sh
# should raise SC2239

# Some bad code taken from https://github.com/koalaman/shellcheck
echo $1
rm "~/my file.txt"
touch $@
echo 'Path is $PATH'
[[ n != 0 ]]
[[ -e *.mpg ]]
[[ $foo==0 ]]
[[ -n "$foo " ]]
[[ $foo =~ "fo+" ]]
[ foo =~ re ]
[ $1 -eq "shellcheck" ]
[ $n && $m ]
(( 1 -lt 2 ))
find . -exec foo {} && bar {} \;
sudo echo 'Var=42' > /etc/profile
time --format=%s sleep 10
alias archive='mv $1 /backup'
tr -cd '[a-zA-Z0-9]'
exec foo; echo "Done!"
var = 42
$foo=42
var=(1, 2, 3)
echo $var[14]
echo "Argument 10 is $10"
[ false ]
a >> log; b >> log; c >> log
echo "The time is `date`"
cd dir; process *; cd ..;
echo $[1+2]
echo "$(date)"
cat file | grep foo
args="$@"
files=(foo bar); echo "$files"
printf '%s: %s\n' foo
printf "Hello $name"
echo hello \  
#!/bin/bash -x -e
echo $((n/180*100))
sed 's/foo/bar/' file > file
