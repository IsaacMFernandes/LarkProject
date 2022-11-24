#!/bin/bash
#Set colors
BG_CYAN="$(tput setab 6)"
BG_BLACK="$(tput setab 0)"
FG_GREEN="$(tput setaf 2)"
FG_MAGENTA="$(tput setaf 5)"

#Reset game variables for new users
function resetVar()
{
	echo "Resetting Lark Environment for new game, $userName"
	sleep 2
}

#Save the screen
tput smcup

#Display menu
while [[ $REPLY != 0 ]]; do
	echo -n ${BG_CYAN} ${FG_MAGENTA}
	clear
	#Use a here document
	cat <<EOF
		Please Select:

		1. Log into Lark game
		2. Set game difficulty level
		3. Start Lark game script
		0. Quit
EOF

#Add read statement using tput to position the cursor
read -p "Enter selection [0-3] > " selection
    tput cup 10 0
	echo -n ${BG_BLACK}${FG_GREEN}
	tput ed
	tput cup 11 0

#Act on selection with case statement
case $selection in
    1)  read -p "What is your name? " userName
        if [ $(gawk '{print $1}' ./currentPlayer.dat) = $userName ]
            then
                echo "Welcome back $userName"
                sleep 2
            else
                echo $userName > ./currentPlayer.dat
                new=true
            fi
            ;;
        2)  echo "Press 1 for easy or 2 for hard "
            read -n 1 difficulty
            echo "diff=$difficulty" >> ./currentPlayer.dat # source script for this to work
            if [ $difficulty -eq 1 ]
                then echo "     You selected easy"
                sleep 2
            elif [ $difficulty -eq 2 ]
                then echo "     You selected hard"
                sleep 2
            else 
                echo "Your selection doesn't match "
                sleep 2
            fi
            ;;
        3)  if [ new ]
                then resetVar # resets game variables and settings
                echo " Welcome to Lark"
                sleep 1
            fi

            # run start up script
            echo "Lark is starting now $userName"
            sleep 1
            break
            ;;
        0)  break
            ;;
        *)  echo "Invalid entry."
            ;;
      esac

      printf "\n\nPress any key to continue."
      read -n 1
    done

#Replace saved screen
tput rmcup
echo "Program terminated."