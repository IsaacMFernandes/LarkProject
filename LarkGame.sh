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
    # My editor was yelling at me to separate the declaration and assignment
    local playerHealth
    local enemyHealth
    local punchPower
    playerHealth=$(gawk 'NR==1{print int($2)}' ./.digitrons/"$1".digi)
    enemyHealth=$(gawk 'NR==1{print int($2)}' ./.digitrons/"$2".digi)
    punchPower=$(gawk 'NR==2{print int($2)}' ./.digitrons/"$1".digi)

    # Variable to keep track of which turn it is (0 for yours, 1 for opponent)
    turn=0

    # Main while loop to show digitrons and their health
    while [ "$enemyHealth" -gt "0"  ]
    do
        tput clear
        echo "$1 ($playerHealth) vs $2 ($enemyHealth)"
        echo "Fight! (type 'help' if you are stuck)"
        echo "------------------------------------------------------------------"

        # Determine who's turn it is
        if [ $turn -eq 0 ]
            then 
                while true
                do
                    if [ "$playerHealth" -le 0 ] #cheks if you're not ded yet
                        then
                            echo "$2 has defeated you :("; read -srn 1
                            dead
                    fi    
                    echo -n "Your turn: "
                    read -r command

                    # Understanding player input
                    case "$command" in
                        "help")
                            echo "------------------------------------------------------------------"
                            echo "Here is a list of available commands:"
                            echo "ls - list available moves"
                            #echo "cd - change digitron, do 'cd ..' to list all digitrons"
                            echo "cat [digitron] - get the information of a provided digitron"
                            echo "continue - do nothing, end turn"
                            echo "./[move] - perform a move, ex. './Punch'"
                            echo "------------------------------------------------------------------"
                            ;;
                        # List each move available to the player
                        "ls")
                            echo "Available moves are: $(gawk 'NR!=1{printf "%s ", $1}' ./.digitrons/"$1".digi)"
                            ;;
                        # Cat command - to get info about a digitron
                        "cat $1")
                            cat ./.digitrons/"$1".digi
                            ;;
                        "cat $2")
                            cat ./.digitrons/"$2".digi
                            ;;
                        "continue")
                            echo "You do nothing for the turn"
                            break
                            ;;
                        # Punch move
                        "./Punch"|"./punch")
                            echo "$1 swings his arm and launches a right hook right at his opponent!"

                            #lower enemy health by attack amount
                            enemyHealth="$((enemyHealth-punchPower))"; sleep 1
                            echo "$2's health is now: $enemyHealth"; sleep 1

                            break
                            ;;
                        "./Stun"|"./stun")
                            echo ""
                            chance=$(( 1 + $RANDOM % 2 )) 
                            if [ $chance -eq 1 ]
                                then
                                    echo "You have stunned $2!"
                            else   
                                    echo "Your stun has failed"
                                    break
                            fi
                            ;;
                            #"Other commands TODO")
                        *) echo "Unknown command. Type 'help' if you are stuck)"
                            ;;
                    esac
                done
                turn=1
        else 
            # The opponent's turn
            # Random from 2-4 lets give each digi 3 attacks to choose from
            move=$(( 2 + RANDOM % 3 ))
            
            # Useful move variables
            moveUsed=$(gawk 'NR=='$move'{print $1}' ./.digitrons/"$2".digi)
            movePower=$(gawk 'NR=='$move'{print int($2)}' ./.digitrons/"$2".digi)

            # Displaying move
            echo -n "Opponent uses..."; sleep 1
            echo " $moveUsed!"; sleep 1
            echo "Opponent has knocked $movePower points of health"; sleep 1
            
            # Changing player's health
            playerHealth="$((playerHealth-movePower))"
            echo "$1's health is now: $playerHealth"; sleep 1

            # Ending turn
            turn=0
        fi

        # If enemy is still not dead
        if [ "$enemyHealth" -gt "0"  ]
            then echo "Turn ending, switching to other player"; read -srn 1
        fi
    done

    # Win condition
    echo "Congrats, you've won"
    echo "------------------------------------------------------------------"
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
    sleep 1
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
        echo "It's all a dream..."
        dead
elif [ $x -eq 3 ]
    then
        echo -e "\nYou change into some going-out clothes and brush your teeth. 'Bye Mom!', you say as you walk out of the door."; read -srn 1
fi

# Meeting the goofy kid
echo "As you make your way to your grandfather's house, you see a kid with some big goofy goggles."; read -srn 1
echo -e "'Hey, wanna f-f-fight?', he questions.\n"; read -srn 1

# Reply to goofy kid
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
    then echo "'W..wha...whatever... rude', he says."
elif [ $x -eq 3 ]
    then
        echo -e "\n'Well shoot, you coulda just said so. Here, have my starter one.'"; read -srn 1
        echo "From his backpack, he takes out a small, glowing ball."; read -srn 1
        echo "'Here, this is Pip. You can have him. Now let's PLAY!'"; read -srn 1
        addDigitron "Pip    100    Water" "Punch    10" "Kick    15"
        addDigitron "Goofy    20    Fire" "Punch    5" "Kick   10" "Fireth     15"
        fight "Pip" "Goofy"
        echo "'Well, I don't know how, but you beat me...'"; read -srn 1
fi

# Kid runs away whether player says get lost or we beat him
echo -e "\nKid with big goofy goggles runs away crying."; read -srn 1
echo "Hmm... Seems like in his despair, the kid has dropped something."; read -srn 1

# Loading digitron ball art
cat ./.asciiArt/digitronBall; read -srn 1

# Getting/inspecting/kicking digitron ball
echo -e "\nDo you ..."
selectOption "Grab his digitron" "Take a closer look" "Kick it away"
x=$?

# Inspecting ball (does not continue story)
while [ $x -eq 2 ]
do
    echo -e "\nIt looks like it hasn't been named yet."
    selectOption "Grab his digitron" "Take a closer look" "Kick it away"
    x=$?
done

# Getting a custom digitron
if [ $x -eq 1 ]
    then 
        echo -e "Now you have his Digitron! This might come in handy later"
        echo -n "What would you like to name your new digitron? > "
        read -r digiName
        addDigitron "$digiName    20    Fire" "Punch    5"
# Fighting a very difficult boss
elif [ $x -eq 3 ]
    then
        echo "This has caused the digitron to break lose!"; read -srn 1
        addDigitron "Unknown    200    ?" "Punch    50" "Kick    75"
        fight "Pip" "Unknown"
fi

# Finding a wild digitron
echo "'Alright, lets keep going to gramps.'"; read -srn 1
echo "As you make your way to grandpa-pa, you see a shortcut."; read -srn 1
echo "You decide to take it and, all of a sudden, a digitron jumps out at you (...this seems to happen often)."; read -srn 1
addDigitron "BasicEnemyStrong    40    Water" "Punch    20" "Kick    20" "Waterth    30"
fight "Pip" "BasicEnemyStrong"

# When the enemy gets beaten
echo -e "\nWhew, that was close. What should you do with the defeated digitron?"
selectOption "Grab digitron" "Let it be free" "Pet it"
x=$?

# Petting the digi
while [ $x -eq 3 ]
do
    echo -e "\nThey liked it; in return, they pee on your shoe ... womp womp"
    selectOption "Grab digitron" "Let it be free" "Pet it"
    x=$?
done

# Adding the wild digi
if [ $x -eq 1 ]
    then 
        echo -e "Now you have a new Digitron! This might come in handy later"
        echo -n "What would you like to name your new digitron? > "
        read -r digiName
        addDigitron "$digiName    40    Fire" "Punch    10"
# Leaving the wild digi
elif [ $x -eq 2 ]
    then
        echo "'I'm sure someone will find good use in this one, but not me.'"
fi

# Getting to grandpa's
echo "Alright, you finally make it to your grandpa's and... "; read -srn 1
echo "You forgot his newspaper."; read -srn 1
echo "Golly dangit, boy. Where is my newspaper? Well? What do you have to say for yourself?"; read -srn 1

# Responding to a newspaperless grandpa
selectOption "'Sorry pops... I'll go back and grab it.'" "Make up a lie" "Just tell the truth"
x=$?

# Go back and get it
if [ $x -eq 1 ]
    then 
        echo -e "You go into town and get his newspaper ... In the distance you see goofy goggles shining with the sun"; read -srn 1
        echo "You go back to your grandpa's and once again a digitron jumps at you ('This is great training' you think to yourself.)"
        fight "Pip" "Basic Enemy"
        #TODO if you fight this digi you get an upgrade to your digi somehow.... this is the reward for going to get the paper
# Lie
elif [ $x -eq 2 ]
    then
        echo "Alright, let's keep going!"
# Tell the truth
elif [ $x -eq 3 ]
    then
        echo "They liked it, in return they pee on your shoe ... womp womp"
        sleep 1
fi

#TODO
#to continue, go back to gramps if gotten paper then gramps says ddint have to but thanks then talks about linux from his old computer????
#if didnt get paper then he says dont worry about it go to the tournament, I used to be the very best (quirky funny reference)
#gives you a choice of three random digis?
#also need to figure out a count like after x amnt of fights then digi evolves or whatever? --Secondary, not priority or maybe? idk