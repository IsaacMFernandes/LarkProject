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

# Function to select input and return which they picked
# Just do: selectOption "option 1" "option 2" "option 3"
# Returns 1, 2 or 3 for option selected
function selectOption()
{
    select response in "$1" "$2" "$3"
    do
        if [ "$response" = "$1" ]
            then return 1
        elif [ "$response" = "$2" ]
            then return 2
        elif [ "$response" = "$3" ]
            then return 3
        # Player did not enter anything
        elif [ "$response" = "" ]
            then
                echo "Invalid response. Please enter 1, 2, or 3"
                continue
        fi
    done
}

# Function to add a digitron
# param 1 - name of digitron    health    attribute
# param 2+ - attack name    attack damage
function addDigitron()
{
    # If directory .digitrons does not exist, create it
    if [ ! -d ./.digitrons ]
        then mkdir .digitrons
    fi

    # Getting digitron name from first line
    digitronName=$(echo "$1" | gawk '{print $1}')
    #echo "$digitronName"
    
    # If a file with the name of the digitron does not exist, create it
    if [ ! -a ./.digitrons/"$digitronName" ]
        then echo -n "" > ./.digitrons/"$digitronName".digi
    fi

    # Add each parameter to the .digi file
    for arg in "$@"
    do
        echo "$arg" >> ./.digitrons/"$digitronName".digi
    done
}

# Function to start a fight between two digitrons
# param 1 - name of player's starting digitron
# param 2 - name of enemy digitron
function fight()
{
    # Variables store health of each player
    playerHealth=$(gawk 'NR==1{print $2}' ./.digitrons/"$1".digi)
    enemyHealth=$(gawk 'NR==1{print $2}' ./.digitrons/"$2".digi)

    # Variable to keep track of which turn it is (0 for yours, 1 for opponent)
    turn=0

    # Main while loop to show digitrons and their health
    while [ "$enemyHealth" != "0" ]
    do
        tput clear
        echo "Starting fight! (type 'help' if you are stuck)"
        echo "$1 ($playerHealth) vs $2 ($enemyHealth)"
        echo "------------------------------------------------------------------"

        # Determine who's turn it is
        if [ $turn -eq 0 ]
            then 
                while true
                do
                    echo -n "Your turn: "
                    read -r command

                    # Understanding player input
                    case "$command" in
                        "help")
                            echo "------------------------------------------------------------------"
                            echo "Here is a list of available commands (they are case sensitive):"
                            echo "ls - list available moves"
                            echo "cd - change digitron, do 'cd ..' to list all digitrons"
                            echo "cat [digitron] - get the information of a provided digitron"
                            echo "./[move] - perform a move, ex. './Punch'"
                            echo "------------------------------------------------------------------"
                            ;;
                        "Punch"|"punch")
                            echo "Yah yeet"
                            break
                            ;;
                            #"Other commands TODO")
                        *) echo "Unknown command. Type 'help' if you are stuck)"
                            ;;
                    esac
                done
                turn=1
        else 
            # The opponent's turn
            echo "Opponent does something"
            turn=0
        fi

        echo "Turn ending, switching to other player"; read -srn 1
    done
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

# Story part, using read -srn 1 to let the user decide when to move on to the next dialogue
echo "You open your eyes, a subtle pain lingering through your head."; read -srn 1
echo "Streaks of sunlight enter the window to your small cottage room."; read -srn 1
echo "You have an aching feeling that you are forgetting something..."; read -srn 1
echo -e "\nYou think to yourself: 'What could it be? What was I meant to do today?'"; read -srn 1
echo "'Aha!', you proclaim. 'Today is the first day of the digitron tournaments!'"; read -srn 1
echo -e "\nExcitement suddenly fills your body. Memories of watching your childhood heroes"
echo " win the championship flood your mind. Then, a wave of dread."; read -srn 1
echo "'I don't have a digitron yet... what am I going to do.....'"; read -srn 1
echo -e "\nYour mom enters the room: 'Honey! It's already 10:00 am! Get up, or you're gonna be late!'\n"; read -srn 1

# Giving the user 3 dialogue options, my preference to that of a case selection
selectOption "Late to what??" "Go away! I want to sleep!!" "Gotcha! Getting ready now!"
x=$?

# Option 1 will not progress, as it just gives some exposition
while [ $x -eq 1 ]
do
    echo -e "\n'You don't remember? You have to get your grandfather's newspaper.', she explains."
    selectOption "Late to what??" "Go away! I want to sleep!!" "Gotcha! Getting ready now!"
    x=$?
done

# Option 2 makes the player die and option 3 progresses the story
if [ $x -eq 2 ]
    then
        sleep 1
        dead
elif [ $x -eq 3 ]
    then
        echo -e "\nYou change into some going-out clothes and brush your teeth. 'Bye Mom!', you say as you walk out of the door."; read -srn 1
fi

echo "As you make your way to your grandfather's house, you see a kid with some big goofy goggles."; read -srn 1
echo -e "'Hey, wanna f-f-fight?', he questions.\n"; read -srn 1

selectOption "Get lost, kid" "What do you mean, fight?" "I don't have a digitron yet..."
x=$?

# Option 2 gives exposition, but option 1 or 3 progress the story 
while [ $x -eq 2 ]
do
    echo -e "\n'Um... what were you born yesterday? I mean we summon our digitrons and FIGHT!', he says."
    selectOption "Get lost, kid" "What do you mean, fight?" "I don't have a digitron yet..."
    x=$?
done

if [ $x -eq 1 ]
    then echo "'Whatever... rude', he says."
elif [ $x -eq 3 ]
    then
        echo -e "\n'Well shoot, you coulda just said so. Here, have my starter one.'"; read -srn 1
        echo "From his backpack, he takes out a small, glowing ball."; read -srn 1
        echo "'Here, this is Pip. You can have him. Now let's PLAY!'"; read -srn 1
        addDigitron "Pip    100    Water" "Punch    10" "Kick    15"
        addDigitron "BasicEnemy    20    Fire" "Punch    5"
        fight "Pip" "BasicEnemy"
fi

read -srn 1

echo "TODO"