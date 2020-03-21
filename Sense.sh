#! /bin/bash



##### sets default parameters (user must change this for their custom prefrence and needs):

path="./"				# path chosen to store results directory.
big_dir_file="bigDIR.gobuster"		# name of big.txt results file.
nmap_file="tcpALLscan.nmap"		# name of nmap full scan results file.

#------------------------------------------------------------------------------------------



##### sets up termination interrupt:

trap Terminate INT; function Terminate() { kill -- -$$; }



##### checks file names to be valid. exits if not:

! [[ -d  $path ]] && { echo -e "\\n\\n Default path for the results is invalid. please edit the script to fix this.\\n\\n"; exit 1; }

[[ "$nmap_file" =~ [\ \/] || "$big_dir_file" =~ [\ \/] ]] && { echo -e "\\n\\n Invalid file name selected. please edit the script to fix this.\\n\\n"; exit 1; }



##### checks for correct usage (correct number of arguments, correct ip format):

if ! (( $# == 2 )) || ! [[ $2 =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]
then
	echo -e "\\n\\n\\t######################################################"
	
	echo -e "\\t  'Sense' Target Discovery and Enumeration Tool v1.0 "
	
	echo -e "\\t######################################################"
	
	echo -e "\\n\\t  Usage: '$0' <target_nickname>  <target_ip> \\n\\n"
	exit 1
fi



##### renames input arguments:

target_nickname="$1"
target_ip="$2"



##### pings target to check for connection. exit if fails:

echo -e "\\n Checking if target is live...\\n"

ping "$target_ip" -c 2 -t4 >/dev/null 2>&1 || { echo -e "\\n Connection failed. Target out of reach or invalid ip.\\n" && exit 1; }



##### probes ports 80,443. exits if connection fails: 

echo -e "\\n Target is live. checking for web applications...\\n"

nmap_output=$(nmap -T4 -p 80,443 "$target_ip" -Pn && sleep 2)

echo "$nmap_output" | grep "(0 hosts up)" > /dev/null 2>&1 &&

{ echo -e "\\n Nmap Scan Failed.\\n" & sleep 1 &&

echo -e "\\n Nmap error:\\n" && echo -e " $nmap_output\\n\\n" && exit 1; }



##### selects correct protocol for web port (http, https):

{ echo "$nmap_output" | grep "80/tcp  open" > /dev/null; } && protocol="http://"

{ echo "$nmap_output" | grep "443/tcp open" > /dev/null; } && protocol="https://"



##### prepares directory for result files. exits if directory write fails:

directory="$path$target_nickname-$target_ip/"

if [[ -d "$directory" ]]
then
	while true
	do

		echo -e "\\n *** WARNING: directory exists. do you want to overwrite? [ 'Y' => overwrite  / 'N' => exit ] "
		
		read userInput
		
		[[ "$userInput" =~ ^[yYnN]$ ]] && break
	
	done 

	[[ $userInput =~ ^[nN]$ ]] && { echo -e "\\n Operation cancelled to prevent accidental file loss.\\n\\n"; exit 0; }

	rm -rf "$directory" > /dev/null 2>&1 || 
		
		{ echo -e "\\n Failed to overwrite directory."
		
		  echo -e "\\n You could be unauthorised to do this."
		  
		  echo -e "\\n Operation cancelled to prevent accidental file loss.\\n\\n"
		  
		  exit 1; }
fi

mkdir "$directory" > /dev/null 2>&1



##### all tests and user interaction is over. scanning phase starts:

echo -e "\\n Initiating discovery sequence...\\n"; sleep 2;



##### checks if web scanning is needed, depending on either port 80 or 443 is open:

if ! [ -z ${protocol+non} ]
then
	echo -e "\\n Web application found.\\n"; sleep 2;
	
	echo -e "\\n Directory fuzzing has started...\\n";
	
	{ gobuster dir -w /usr/share/wordlists/dirb/big.txt -k -t 50 -u "$protocol$target_ip" -o "$directory$big_dir_file" -x php,html,txt > /dev/null 2>&1 &&
	
		echo -e "\\n Directory fuzzing complete. check '$directory$big_dir_file' for results. waiting of other scans to finish..\\n"; sleep 2; }&
fi	



##### starts nmap full scan:

{ sleep 4
  
  echo -e "\\n Full nmap scan has started...\\n" ; sleep 3;
  
  nmap -T4 -A "$target_ip" -p- -Pn -o "$directory$nmap_file" > /dev/null 2>&1 &&

	 echo -e "\\n ==> Full nmap scan complete. check '$directory$nmap_file' for results. waiting for other scans to finish...\\n"; sleep 2; }&



##### starts nmap quick scan for temporary, on-screen results:

{ sleep 8

  echo -e "\\n printing nmap initial findings:\\n\\n\\n"; sleep 3;
  
  nmap -T4 "$target_ip" -Pn -v && sleep 2; echo -e "\\n\\n\\n NOTE: only partial results are showns. Full scan ongoing...\\n"
  
  sleep 2
  
  echo -e "\\n NOTE: Full scans could take a while, meanwhile you can begin examinaion.\\n"; sleep 2; }&



##### waits for all processes to complete, then exits with a message:

wait

echo -e "\\n ==> Other scans finished.\\n"; sleep 1;

echo -e "\\n \\n \\n \\n \\n \\n \\n scan complete. Results can be found in '$directory'.\\n\\n";

exit 0


