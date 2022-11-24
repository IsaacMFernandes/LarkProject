#!/bin/bash

# Any global variables defined/modified here
PS3="> "

# Functions used in the program
# Function called when the user exits the program unexpectedly
function onExit()
{
    tput rmcup
    exit
}

# Function when the player dies
function dead()
{
    tput clear
    echo "A bright, glowing white aura surrounds you; memories flash before your eyes like a flip book."
    echo "'Is this it... am I dying?', you ponder."; read -srn 1
    echo "And without a moment to think another thought, darkness."; read -srn 1
    tput clear
    echo "Thank you for playing our game!"
    printf "\t-Isaac Fernandes\n"
    printf "\t-Nelson Suarez\n"
    exit
}

# Save screen when program is called, go back when program is Ctrl+C'd
tput smcup
tput clear
trap onExit SIGINT SIGTERM

# Starting the game
echo "Welcome to my Lark Game"
sleep 1

# Create player data file if it does not exist
if [ ! -f ./player.dat ]
    then
        echo "Data file not found, creating now..."
        sleep 1
        echo "playerName" > player.dat
        echo "Created data file!"
        sleep 1
fi

# Read user input for name
echo -n "What is your name? > "
read -r name

# Save player name, or recognize existing player
if [ "$(gawk '{print $1}' ./player.dat)" = "$name" ]
    then
        echo "Welcome back $name"
else
    echo "Hello $name"
    echo "$name" > player.dat
fi

sleep 1

#TODO
# Check if game has been started already (not a priority)
echo "Starting new game..."
echo "Press any key to continue dialogue"
read -srn 1
tput clear

echo "You open your eyes, a subtle pain lingering through your head."; read -srn 1
echo "Streaks of sunlight enter the window to your small cottage room."; read -srn 1
echo "You have an aching feeling that you are forgetting something..."; read -srn 1
echo -e "\nYou think to yourself: 'What could it be? What was I meant to do today?'"; read -srn 1
echo "'Aha!', you proclaim. 'Today is the first day of the digitron tournaments!'"; read -srn 1
echo -e "\nExcitement suddenly fills your body. Memories of watching your childhood heroes"
echo " win the championship flood your mind. Then, a wave of dread."; read -srn 1
echo -e "'I don't have a digitron yet... what am I going to do.....'\n"; read -srn 1
echo -e "Your mom enters the room: 'Honey! It's already 10:00 am! Get up, or you're gonna be late!'\n"; read -srn 1

select response in "Late to what??"  "Go away! I want to sleep!!" "Gotcha! Getting ready now!"
do
    if [ "$response" = "Late to what??" ]
        then echo "'You don't remember? You have to get your grandfather's newspaper.', she explains."
    elif [ "$response" = "Go away! I want to sleep!!" ]
        then
            sleep 1
            dead
    elif [ "$response" = "Gotcha! Getting ready now!" ]
        then
            echo "Cool, thanks"
            break
    elif [ "$response" = "" ]
        then
            echo "Please enter something"
            continue
    else
        echo "Invalid response. Please enter 1, 2, or 3"
        continue
    fi
done



echo "TODO"