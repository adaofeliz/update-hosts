#!/bin/bash

# If this is our first run, save a copy of the system's original hosts file and set to read-only for safety
if [ ! -f ~/hosts-system ]
then
 echo "Saving copy of system's original hosts file..."
 cp /etc/hosts ~/hosts-system
 chmod 444 ~/hosts-system
fi

# Perform work in temporary files
temphosts1=`mktemp`
temphosts2=`mktemp`

# Obtain various hosts files and merge into one
echo "Downloading ad-blocking hosts files..."
wget -nv -O - http://winhelp2002.mvps.org/hosts.txt >> $temphosts1
wget -nv -O - http://hosts-file.net/download/hosts.txt >> $temphosts1
wget -nv -O - http://someonewhocares.org/hosts/hosts >> $temphosts1
wget -nv -O - "http://pgl.yoyo.org/as/serverlist.php?hostformat=hosts&showintro=1&mimetype=plaintext" >> $temphosts1
wget -nv -O - "https://spyeyetracker.abuse.ch/blocklist.php?download=hostfile" >> $temphosts1
wget -nv -O - "https://zeustracker.abuse.ch/blocklist.php?download=hostfile" >> $temphosts1
wget -nv -O - "http://www.malware.com.br/cgi/submit?action=list_hosts_win_127001" >> $temphosts1
wget -nv -O - http://www.malwaredomainlist.com/hostslist/hosts.txt >> $temphosts1

# Do some work on the file:
# 1. Remove MS-DOS carriage returns
# 2. Delete all lines that don't begin with 127.0.0.1
# 3. Delete any lines containing the word localhost because we'll obtain that from the original hosts file
# 4. Delete any lines containing the word dropbox.com.
# 5. Replace 127.0.0.1 with 0.0.0.0 because then we don't have to wait for the resolver to fail
# 6. Scrunch extraneous spaces separating address from name into a single tab
# 7. Delete any comments on lines
# 8. Clean up leftover trailing blanks
# Pass all this through sort with the unique flag to remove duplicates and save the result
echo "Parsing, cleaning, de-duplicating, sorting..."
sed -e 's/\r//' -e '/^127.0.0.1/!d' -e '/localhost/d' -e '/dropbox.com/d' -e 's/127.0.0.1/0.0.0.0/' -e 's/ \+/\t/' -e 's/#.*$//' -e 's/[ \t]*$//' < $temphosts1 | sort -u > $temphosts2


# Combine system hosts with adblocks
echo Merging with original system hosts...
echo -e "\n# Ad blocking hosts generated "`date` | cat ~/hosts-system - $temphosts2 > ~/hosts-block

# Clean up temp files and remind user to copy new file
echo "Cleaning up..."
rm $temphosts1 $temphosts2
echo "Done."
echo
echo "Copy ad-blocking hosts file with this command:"
cp ~/hosts-block /etc/hosts
echo
echo "You can always restore your original hosts file with this command:"
echo " sudo cp ~/hosts-system /etc/hosts"
echo "so don't delete that file! (It's saved read-only for your protection.)"