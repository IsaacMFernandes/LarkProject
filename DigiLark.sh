#!/bin/bash

# Clear .digitrons if it exists already
if [ -d .digitrons ]
    then rm -r .digitrons
fi

# Any global variables defined/modified here
PS3="> "
animate=1
fightWithGramps=0
hasNewspaper=0

function punchAnimation()
{
    # If the terminal is too small, tell user
    if [ "$(tput lines)" -lt 30 ] || [ "$(tput cols)" -lt 100 ]
        then echo -e "\nCould not load animation. Please increase your terminal size.\n"
        return
    # If terminal is big enough for the smaller animation, use that instead of the large animation
    elif [ "$(tput lines)" -lt 43 ] || [ "$(tput cols)" -lt 150 ]
        then size="Small"
    else
        size="Large"
    fi

    # Check if folder exists
    if [ ! -d .asciiArt/.punch"$size" ]
        then echo -e "\nError: $size punch folder not found.\n"
        return
    fi

    # Save the screen
    tput smcup

    # Start displaying each ascii text file with 0.1 delay in between
    for frame in .asciiArt/.punch"$size"/*
    do
        tput clear
        cat "$frame"
        sleep 0.1
    done

    # Restore screen afterwards
    echo "Press any button to continue."
    read -srn 1
    tput rmcup
}

function kickAnimation()
{
    # Follows the same logic as punch animation
    if [ "$(tput lines)" -lt 30 ] || [ "$(tput cols)" -lt 100 ]
        then echo -e "\nCould not load animation. Please increase your terminal size.\n"
        return
    elif [ "$(tput lines)" -lt 43 ] || [ "$(tput cols)" -lt 150 ]
        then size="Small"
    else
        size="Large"
    fi

    if [ ! -d .asciiArt/.kick"$size" ]
        then echo -e "\nError: $size kick folder not found.\n"
        return
    fi

    tput smcup
    for frame in .asciiArt/.kick"$size"/*
    do
        tput clear
        cat "$frame"
        sleep 0.1
    done
    echo "Press any button to continue."
    read -srn 1
    tput rmcup
}

# Functions used in the program
# Function called when the user exits the program unexpectedly
function onExit()
{
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
    # Choose starting digitron
    digisOwned=$(gawk 'NR!=1' ./player.dat | wc -l)
    if [ "$digisOwned" -gt 1 ]
        then
            echo -en "\nWhich digitron would you like to start with?\n(Type 'ls' to see your available digitrons) > "
            read -r playerDigi
            while [ "$(grep -c "$playerDigi" < ./player.dat)" -eq 0 ]
            do
                if [ "$playerDigi" = "ls" ]
                    then
                        gawk 'NR!=1{print $1}' ./player.dat
                fi
                echo -n "Enter digitron you would like to start with > "
                read -r playerDigi
            done
    else
        playerDigi="$1"
    fi

    # Variables store health of each player
    # My editor was yelling at me to separate the declaration and assignment
    local playerHealth
    local enemyHealth
    levelAdjustment=$((level*5))

    # Adjusting player health by their level - starting at 0, going up by 15
    playerHealth=$(gawk 'NR==1{print int($2)}' ./.digitrons/"$playerDigi".digi)
    enemyHealth=$(gawk 'NR==1{print int($2)}' ./.digitrons/"$2".digi)

    # Variable to keep track of which turn it is (0 for yours, 1 for opponent)
    turn=0

    # Main while loop to show digitrons and their health
    while [ "$enemyHealth" -gt "0"  ]
    do
        tput clear
        echo "$name - level $level"
        echo "$playerDigi ($playerHealth) vs $2 ($enemyHealth)"
        echo "Fight! (type 'help' if you are stuck)"

        # Remind user to increase terminal size
        if [ $animate -eq 1 ]
            then
                if [ "$(tput lines)" -lt 43 ] || [ "$(tput cols)" -lt 150 ]
                    then echo -e "Reminder: Increase your terminal size for better animations.\nIt is currently $(tput lines)x$(tput cols)"
                fi
        fi

        echo "------------------------------------------------------------------"

        # Determine who's turn it is
        if [ $turn -eq 0 ]
            then 
                while true
                do
                    # Check if you're not dead yet
                    #echo "$playerHealth"
                    if [ "$playerHealth" -le 0 ]
                        then
                            echo "$2 has defeated you :("; read -srn 1
                            if [ $fightWithGramps -eq 1 ]
                                then
                                    sed -i "1 s/$playerHealth/100/" ./.digitrons/"$playerDigi".digi
                                    fightWithGramps=0
                                    return
                            fi
                            dead
                    fi

                    # Clear input
                    read -t 1 -srn 10000 d

                    echo -n "Your turn: "
                    read -r command
                    #echo "$command"

                    # Understanding player input
                    case "$command" in
                        "help")
                            echo "------------------------------------------------------------------"
                            echo "Here is a list of available commands:"
                            echo "ls - list available moves"
                            if [ "$digisOwned" -gt 1 ]
                                then echo "cd - change digitron"
                            fi
                            echo "cat [digitron] - get the information of a provided digitron"
                            echo "continue - do nothing, end turn"
                            echo "./[move] - perform a move, ex. './Punch'"
                            echo "------------------------------------------------------------------"
                            ;;
                        # List each move available to the player
                        "ls")
                            echo "Available moves are: $(gawk 'NR!=1{printf "%s ", $1}' ./.digitrons/"$playerDigi".digi)"
                            ;;
                        # Cat command - to get info about a digitron
                        "cat $playerDigi")
                            cat ./.digitrons/"$playerDigi".digi
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
                            punchPower=$(gawk 'NR==2{print int($2)}' ./.digitrons/"$playerDigi".digi)
                            punchPower=$((punchPower+levelAdjustment))

                            # Showing the punch animation if it is still enabled
                            if [ $animate -eq 1 ]
                                then punchAnimation
                            fi

                            echo "$playerDigi launches a right hook dealing $punchPower damage!"

                            #lower enemy health by attack amount and edit the .digi file
                            newHealth="$((enemyHealth-punchPower))"
                            sed -i "1 s/$enemyHealth/$newHealth/" ./.digitrons/"$2".digi
                            enemyHealth=$newHealth; sleep 1
                            echo "$2's health is now: $enemyHealth"; sleep 1

                            break
                            ;;
                        # Kick move
                        "./Kick"|"./kick")
                            kickPower=$(gawk 'NR==3{print int($2)}' ./.digitrons/"$playerDigi".digi)
                            kickPower=$((kickPower+levelAdjustment))

                            if [ $animate -eq 1 ]
                                then kickAnimation
                            fi

                            echo "$playerDigi deals a massive kick to $2's midsection, dealing $kickPower damage!"

                            #lower enemy health by attack amount
                            newHealth="$((enemyHealth-kickPower))"
                            sed -i "1 s/$enemyHealth/$newHealth/" ./.digitrons/"$2".digi
                            enemyHealth=$newHealth; sleep 1
                            echo "$2's health is now: $enemyHealth"; sleep 1

                            break
                            ;;
                        # Heal move
                        "./Heal"|"./heal")
                            healPower=$(gawk '/Heal/{print int($2)}' ./.digitrons/"$playerDigi".digi)
                            healPower=$((healPower+levelAdjustment))
                            newHealth="$((playerHealth+healPower))"
                            sed -i "1 s/$playerHealth/$newHealth/" ./.digitrons/"$playerDigi".digi
                            playerHealth=$newHealth
                            echo "You have healed $healPower points"

                            break
                            ;;
                        # Stun move
                        "./Stun"|"./stun")
                            echo ""
                            chance=$(( 1 + RANDOM % 2 ))
                            if [ $chance -eq 1 ]
                                then
                                    echo "You have stunned $2!"
                            else   
                                    echo "Your stun has failed"
                                    break
                            fi
                            ;;
                        "./Charged"|"./charged")
                            echo ""
                            chance2=$(( 1 + RANDOM % 2 ))
                            if [ $chance2 -eq 1 ]
                                then
                                    chargedPower=$(gawk '/Charged/{print int($2)}' ./.digitrons/"$playerDigi".digi)
                                    chargedPower=$((chargedPower+levelAdjustment))

                                    echo "$1 charges at $2, causing $chargedPower damage!"

                                    #lower enemy health by attack amount
                                    newHealth="$((enemyHealth-chargedPower))"
                                    sed -i "1 s/$enemyHealth/$newHealth/" ./.digitrons/"$2".digi
                                    enemyHealth=$newHealth; sleep 1
                                    echo "$2's health is now: $enemyHealth"; sleep 1

                            break
                            else   
                                    echo "Your Charged Attack has failed"
                                    break
                            fi
                            ;;
                            #"Other commands TODO")
                        "DebugPunch"|"dp")
                            enemyHealth="$((enemyHealth-1000000))"
                            break
                            ;;
                        # Change digitron option
                        "cd")
                            # Making sure the player doesn't try to cd 
                            if [ ! "$digisOwned" -gt 1 ]
                                then echo "Unfortunately, you're down to your last digitron!"
                                    continue
                            fi

                            # Printing options
                            gawk 'NR!=1{print $1}' ./player.dat

                            # Asking player
                            echo -n "Which would you like to switch to? > "
                            read -r changeDigi

                            # Checking input (whole words)
                            while [ "$(grep -wc "$changeDigi" < ./player.dat)" -eq 0 ]
                            do
                                echo -n "Digitron not found. Try again > "
                                read -r changeDigi
                            done

                            # Change to that digitron
                            playerDigi="$changeDigi"
                            echo "Switching to $playerDigi!"; sleep 1

                            # Fixing health variables
                            playerHealth=$(gawk 'NR==1{print int($2)}' ./.digitrons/"$playerDigi".digi)

                            break
                            ;;
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
            newHealth="$((playerHealth-movePower))"
            sed -i "1 s/$playerHealth/$newHealth/" ./.digitrons/"$playerDigi".digi
            playerHealth=$newHealth
            echo "$playerDigi's health is now: $playerHealth"; sleep 1

            # Ending turn
            turn=0
        fi

        # When one digi dies, and you have others, switch to another, unless you're fighting grandpa
        if [ "$playerHealth" -le "0" ] && [ "$digisOwned" -gt "1" ] && [ $fightWithGramps -eq 0 ]
            then
                echo -e "\n$playerDigi has fainted..."; sleep 1

                # Remove it from player.dat
                sed -i "/$playerDigi/d" ./player.dat

                # Switch to the first digitron
                echo "Switching to another digitron"
                playerDigi=$(gawk 'NR==2{print $1}' ./player.dat)
                playerHealth=$(gawk 'NR==1{print int($2)}' ./.digitrons/"$playerDigi".digi)
                digisOwned="$((digisOwned-1))"
                sleep 1
        fi

        # If neither digitron are dead
        if [ "$enemyHealth" -gt "0" ] && [ "$playerHealth" -gt "0" ]
            then
            if [ $turn -eq 1 ]
                then echo -e "\nTurn ending, switching to other player"
                echo "Tip: On your opponents turn, you do not need to press anything."; read -srn 1
            else
                echo -e "\nTurn ending, switching to other player"; read -srn 1
            fi
        fi
    done

    tput clear
    echo -e "~~~ Press any key to continue ~~~\n"

    # Win condition
    echo "Congrats, you've won"
    levelUp
}

# Function to level up
function levelUp()
{
    level=$((level+1))
    for (( index=0; index < digisOwned; index++ ))
    do
        d=$(gawk -v i="$index" 'NR==((i+2)){print $1}' ./player.dat)
        oldHealth=$(gawk 'NR==1{print int($2)}' ./.digitrons/"$d".digi)
        newHealth=$((oldHealth+25))
        sed -i "1 s/$oldHealth/$newHealth/" ./.digitrons/"$d".digi
    done
    echo -e "\n~~~~~ You have leveled up! You are now level $level ~~~~~"; read -srn 1
    echo "~~~~~~~ Your digitrons have all healed by 25! ~~~~~~~"; read -srn 1
    echo "~~~~~~ and their attacks will do 5 more damage ~~~~~~"; read -srn 1
}

# Function to add a move to all digitrons player owns
# param 1 - move to add
function addMove()
{
    for (( index=0; index < digisOwned; index++ ))
    do
        d=$(gawk -v i="$index" 'NR==((i+2)){print $1}' ./player.dat)
        echo "$1" >> ./.digitrons/"$d".digi
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
    sleep 1
    exit
}

# Save screen when program is called, go back when program is Ctrl+C'd
tput clear
trap onExit SIGINT SIGTERM

# Starting the game
echo "Welcome to DigiLark!"
sleep 1

if [ ! -d ./.asciiArt ]
    then echo -e "\nWarning: the art folder (.asciiArt) is missing.\nVisual elements will not load.\n"
    sleep 1
fi

# Asking the user if they want to disable animation
echo -e "\nAt some points in this game, there will be flashing ascii art."
echo "Would you like to disable these animations? (y/n)"
read -r response

while [ "$response" = "" ]
do
    echo -n "Please enter something: "
    read -r response
done
while [ ! "$response" = "y" ] && [ ! "$response" = "Y" ] && [ ! "$response" = "N" ] && [ ! "$response" = "n" ] && [ ! "$response" = "Yes" ] && [ ! "$response" = "yes" ] && [ ! "$response" = "no" ] && [ ! "$response" = "No" ]
do
    echo -n "Response unknown. Would you like to disable flashing text: "
    read -r response
done
if [ "$response" = "y" ] || [ "$response" = "Y" ] || [ "$response" = "yes" ] || [ "$response" = "Yes" ]
    then animate=0
else
    echo "We recommend increasing your terminal size to 45x150 for the best animations"
    echo "Your current terminal size is $(tput lines)x$(tput cols)"; sleep 0.5
fi

# Create player data file if it does not exist
if [ ! -f ./player.dat ]
    then
        echo -e "\nData file not found, creating now..."
        sleep 1
        echo "playerName" > player.dat
        echo "Created data file!"
        sleep 1
fi

# Read user input for name
echo -ne "\nWhat is your name? > "
read -r name

# Save player name, or recognize existing player
if [ "$(gawk 'NR==1{print $1}' ./player.dat)" = "$name" ]
    then
        echo "Welcome back $name"
else
    echo "Hello $name"
fi

# Erasing everything in the player.dat file, to start over with owned digitrons
echo "$name" > player.dat

# Resetting brackets
cat ./.asciiArt/bracket_clean > ./.asciiArt/bracket
cat ./.asciiArt/bracket2_clean > ./.asciiArt/bracket2
cat ./.asciiArt/bracket3_clean > ./.asciiArt/bracket3

# Bracket 1
sed -i "1 c $name" ./.asciiArt/bracket

# Bracket 2
sed -i "1 c $name" ./.asciiArt/bracket2
sed -i "3 s/$/$name/" ./.asciiArt/bracket2

# Bracket 3
sed -i "1 c $name" ./.asciiArt/bracket3
sed -i "3 s/$/$name/" ./.asciiArt/bracket3
sed -i "6 s/$/$name/" ./.asciiArt/bracket3

level=0
sleep 1

#TODO
# Check if game has been started already (not a priority)
echo "Starting new game..."
echo "When this game pauses, press any key to continue"
read -srn 1
tput clear

# I moved this line next to dialogue
echo -e "~~~ Press any key to continue dialogue ~~~\n"

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

# I made it impossible to not get Pip, as it didn't make sense later on in the story
while [ $x -eq 1 ] || [ $x -eq 2 ]
do
    if [ $x -eq 1 ]
        then echo -e "\n'Ah-ah-ahhh, not so fast. You won't get away that easily!', he goofs."
    elif [ $x -eq 2 ]
        then echo -e "\n'Um... what were you born yesterday? I mean we summon our digitrons and FIGHT!', he says."
    fi
    selectOption "Get lost, kid" "What do you mean, fight?" "I don't have a digitron yet..."
    x=$?
done

if [ $x -eq 3 ]
    then
        echo -e "\n'Well shoot, you coulda just said so. Here, have my starter one.'"; read -srn 1
        echo "From his backpack, he takes out a small, glowing ball."; read -srn 1
        echo "'Here, this is Pip. You can have him. Now let's PLAY!'"; read -srn 1
        addDigitron "Pip    100    Water" "Punch    10"
        echo "Pip" >> ./player.dat
        addDigitron "Goofy    20    Fire" "Punch    5" "Kick    10" "Flame    15"
        fight "$(gawk 'NR==2{print $1}' ./player.dat)" "Goofy"
fi

# Unlocking a new move
addMove "Kick    15"
echo -e "\n~~~ You have unlocked a new move: Kick ~~~\n"; read -srn 1

# Kid runs away, drops digitron ball
echo "'Well, I don't know how, but you beat me...'"; read -srn 1
echo -e "\nKid with big goofy goggles runs away crying."; read -srn 1
echo "Hmm... Seems like in his despair, the kid has dropped something."; read -srn 1

# Loading digitron ball art if it exists
if [ -f ./.asciiArt/digitronBall ]
    then cat ./.asciiArt/digitronBall; read -srn 1
fi

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
        echo -e "\nNow you have his Digitron! This might come in handy later"
        echo -n "What would you like to name your new digitron? > "
        read -r digiName
        while [ "$digiName" = "" ]
        do
            echo -n "Please enter a name: "
            read -r digiName
        done
        addDigitron "$digiName    20    Fire" "Punch    5" "Kick    10"
        echo "$digiName" >> ./player.dat
        echo -e "\n~~~ Now that you have more than one digitron, you can use the 'cd' command in a battle! ~~~"; read -srn 1
# Fighting a very difficult boss
elif [ $x -eq 3 ]
    then
        echo "This has caused the digitron to break lose!"; read -srn 1
        addDigitron "Unknown    300    ?" "Punch    50" "Kick    75" "Nuclear_Explosion    150"
        fight "$(gawk 'NR==2{print $1}' ./player.dat)" "Unknown"
fi

# Finding a wild digitron
echo -e "\n'Alright, lets keep going to gramps', you say."; read -srn 1
echo "As you make your way to grandpa-pa, you see a shortcut."; read -srn 1
echo "You decide to take it and, all of a sudden, a digitron jumps out at you (...this seems to happen often)."; read -srn 1
addDigitron "Croncher    40    Water" "Punch    20" "Kick    20" "Wave    30"
fight "$(gawk 'NR==2{print $1}' ./player.dat)" "Croncher"

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
        echo -e "\n~~~ You've added Croncher! ~~~\n"; read -srn 1
        addDigitron "Croncher    35    Water" "Punch    20" "Kick    20"
        echo "Croncher" >> ./player.dat
        digisOwned=$(("$digisOwned"+1))
# Leaving the wild digi
elif [ $x -eq 2 ]
    then echo "'I'm sure someone will find good use in this one, but not me.'"
fi

# Getting to grandpa's
echo "You finally make it to your grandpa's and... "; read -srn 1
echo "You forgot his newspaper."; read -srn 1
echo -e "\n'Golly dangit, child. Where is my newspaper? Well? What do you have to say for yourself?'"; read -srn 1

# Responding to a newspaperless grandpa
selectOption "Go back and get it" "Make up a lie" "Just tell the truth"
x=$?

# Go back and get it
if [ $x -eq 1 ]
    then 
        echo -e "\nYou go into town and get his newspaper ... In the distance you see the goofy goggles kid frolicking in a meadow."; read -srn 1
        echo "You go back to your grandpa's and once again a digitron jumps at you ('This is great training' you think to yourself.)"; read -srn 1
        addDigitron "Circuit    50    Earth" "Punch    25" "Kick    25" "Shock    35"
        fight "$(gawk 'NR==2{print $1}' ./player.dat)" "Circuit"
        hasNewspaper=1
        #TODO if you fight this digi you get an upgrade to your digi somehow.... this is the reward for going to get the paper
# Lie
elif [ $x -eq 2 ]
    then echo "Sorry grandpa! A digitron ate it"; read -srn 1
# Loading grandpa! A digitron ate it"; read -srn 1
# Tell the truth
elif [ $x -eq 3 ]
    then echo "I forgot, sorry! The digitron tournament has taken over my head"; read -srn 1
fi

if [ "$hasNewspaper" -eq 1 ]
    then
        echo -e "\nYou finally arrive to your grandpa's (again) and hand him his newspaper"; read -srn 1
        echo "'What's got you looking so worried?'"; read -srn 1
        echo "Today is the digitron tournament! but I dont think I am prepared for it"; read -srn 1
        
elif [ "$hasNewspaper" -eq 0 ]
    then    
        echo "'Oh.. That's alright boy whats got you so worked up?'"; read -srn 1
        echo "Today is the digitron tournament! but I dont think I am prepared for it"; read -srn 1
fi

echo "'Oh how I remember the good old days. I'll teach you some of what I know, but not without teaching you some digi history first...'"; read -srn 1
echo "You see grandpa dusting off his old laptop and when he turns it on, an odd creature appears"; read -srn 1
cat ./.asciiArt/linuxLaptop; read -srn 1
echo "'Here it is, the origin of it all'"; read -srn 1
echo "'Back in my day, digitrons only existed inside this program called L.I.N.U.X'"; read -srn 1
echo "'The same commands you'd use for your digi, you'd use here!, let me show you'"; read -srn 1
cat ./.asciiArt/linuxLaptopex; read -srn 1
echo "'cd would change what directory you are working on'"; read -srn 1
echo "'ls would show you which files you can access in the directory'"; read -srn 1
echo "'vim would let you see the file and edit'"; read -srn 1
echo "'and last but not least, cat would let you peek at a file'"; read -srn 1
echo "'There's many, many more commands but these are the basics, make sure to come back to learn more if you want'"; read -srn 1
echo "'Now, where was I? Oh yes, one day, a LINUX scientist managed to bring the programs to life with the use of quantum tunneling and shelling.'"; read -srn 1
echo "'That explains why they are called digitrons!'"; read -srn 1
echo "'Yes, my child... '"; read -srn 1
echo "'Whats wrong grandpa?'"; read -srn 1
echo "'The creature you saw... that was TUX, the first digitron.'"; read -srn 1
echo "'No one has seen them in a long, long time. I've got bad feeling about this tournament...'"; read -srn 1
echo "'This is why I will teach you a new move'"; read -srn 1
echo "Which move would you like to learn?"; read -srn 1

selectOption "Heal" "Stun" "Charged attack"
x=$?

if [ $x -eq 1 ]
    then 
        addMove "Heal    20"
        echo -e "\n~~~ You have unlocked a new move: Heal ~~~\n"; read -srn 1
elif [ $x -eq 2 ]
    then
        addMove "Stun    20"
        echo -e "\n~~~ You have unlocked a new move: Stun ~~~\n"; read -srn 1
elif [ $x -eq 3 ]
    then
        addMove "Charged   40"
        echo -e "\n~~~ You have unlocked a new move: Charged Attack ~~~\n"; read -srn 1
fi

# Begin fight with grandpa
echo -e "\n'Alright boy, let's try your new move'"; read -srn 1
fightWithGramps=1
addDigitron "Grandpa's_Legendary    1000    Divine" "Punch    100" "Kick    120" "Vaporize    200"
fight "$(gawk 'NR==2{print $1}' ./player.dat)" "Grandpa's_Legendary"

# Grandpa destroys player, heals digitron
echo "Good job $name, now you are ready to go to the tournament"; read -srn 1
echo "'Oh, and don't worry about your digitron. I've healed him to 100 health.'"; read -srn 1
echo "Now, with your new move and knowledge your grand-pa-pa gave you, you head over to Shell Stadium"; read -srn 1

echo -e "\nAs you approach the stadium, you start hearing chants and you are wowed by it"; read -srn 1

# Loading stadium art
if [ -f ./.asciiArt/stadium ]
    then cat ./.asciiArt/stadium; read -srn 1
fi

# Continuing story at stadium
echo -e "\nLADIES AND GENTLEMEN! WELCOME, TO THE 32nd ANNUAL BASH BATTLES TOURNAMENT!"; read -srn 1
echo "I HOPE EACH AND EVERYONE OF YOU HAD A SAFE JOURNEY TO SHELL STADIUM."; read -srn 1
echo "BUT, NOW! IT IS TIME TO SEE WHO IS THE BEST DIGITRON DUELER!"; read -srn 1
echo -e "\nYou make your way over the concession stand and hand over your ID."; read -srn 1
echo -e "The lady hands back a laminated poster showing the brackets for the tournament.\n"; read -srn 1

# Loading tournament bracket
if [ -f ./.asciiArt/bracket ]
    then cat ./.asciiArt/bracket; read -srn 1
fi

echo -e "\nYou make your way over to your booth and you see someone in the opponent's section."; read -srn 1
echo "Sitting there is a man with an eye patch and wooden leg."; read -srn 1
echo -e "\n'Arrghgh...', he mutters"; read -srn 1
echo "'So yer the kid they gave me...'"; read -srn 1
echo "'Prreparrrre... to be plunderred!'"; read -srn 1
echo -e "\nATTENTION ALL PARTICIPANTS! MATCH ONE WILL BEGIN SHORTLY!"; read -srn 1

# First fight of match 1
addDigitron "BlackPearl    50    Fire" "Cannon    20" "Bomb    25" "TNT    30"
fight "$(gawk 'NR==2{print $1}' ./player.dat)" "BlackPearl"

# Second fight of match 1
echo -e "\n'Arrrghgh... how bout ye try this one 'nstead!'"; read -srn 1
addDigitron "Fortune    60    Fire" "Cannon    25" "Bomb    20" "TNT    30"
fight "$(gawk 'NR==2{print $1}' ./player.dat)" "Fortune"

# Third fight of match 1
echo -e "\n'ARRRGHHGH... I KNOW YE CANT BEAT THIS ONE!'"; read -srn 1
addDigitron "JollyRoger    70    Fire" "Cannon    30" "Bomb    25" "Raid    35"
fight "$(gawk 'NR==2{print $1}' ./player.dat)" "JollyRoger"

echo -e "\n'arr... I havn't a clue how ye beat me, but yu'v errn'd my rrrespect!'\n"; read -srn 1
echo "CONGRATULATIONS TO OUR MATCH 1 WINNERS! MOVING ON TO MATCH 2! HERE ARE YOUR STANDINGS!"; read -srn 1

# Loading updated tournament bracket
if [ -f ./.asciiArt/bracket2 ]
    then cat ./.asciiArt/bracket2; read -srn 1
fi

echo -e "\nYou walk over to your second battle booth, gleaming with joy from the previous win."; read -srn 1
echo "As you get closer, you see a small child in the opponent's booth."; read -srn 1
echo "'Excuse me, little girl. Are you lost?', you ask."; read -srn 1
echo -e "\n'How DARE you! I'm your opponent, idiot, and I'm gonna take you down, loser!'"; read -srn 1
echo "'I apologize, I thought...'"; sleep 0.5
echo "'Whatever. Let's just battle. And I'm not a little girl by the way. I'm 13.'"; read -srn 1
echo -e "\nATTENTION ALL PLAYERS. MATCH TWO IS STARTING NOW. BEGIN!"; read -srn 1

# First fight of match 2
addDigitron "Barbietron    80    Wind" "Jab    20" "Slap    25" "Yell    10"
fight "$(gawk 'NR==2{print $1}' ./player.dat)" "Barbietron"

# Second fight of match 2
echo -e "\n'Ughh whatever. Let's see if you can beat this!'"; read -srn 1
addDigitron "Ponytron    90    Wind" "Headbutt    30" "Trample    35" "Stampede    40"
fight "$(gawk 'NR==2{print $1}' ./player.dat)" "Ponytron"

# Third fight of match 2
echo -e "\n'UGHHH I HATE YOU. There's no way you can defeat this next one!'"; read -srn 1
addDigitron "Elsa    100    Wind" "IceShard    40" "Blizzard    45" "Hail    50"
fight "$(gawk 'NR==2{print $1}' ./player.dat)" "Elsa"

echo -e "\n'This is just lame.. good job.. I guess...'\n"; read -srn 1
echo "GREAT JOB CONTESTANTS AND GOOD FIGHTS ALL AROUND! MOVING ON TO THE GRAND FINALE!"; read -srn 1
echo -e "HERE IS THE FINAL BRACKET!\n"; read -srn 1

# Loading final tournament bracket
if [ -f ./.asciiArt/bracket3 ]
    then cat ./.asciiArt/bracket3; read -srn 1
fi

echo -e "\nAs you make your way to the final booth, you see no light coming from the opponent's booth."; read -srn 1
echo "You look closer inside, and there you find a dimly lit computer with a mouse and keyboard."; read -srn 1
echo -e "You shake the mouse a bit, and on the screen pops up a face that you swear you've seen before.\n"; read -srn 1

if [ -f ./.asciiArt/linuxLaptop ]
    then cat ./.asciiArt/linuxLaptop
fi

echo -e "\n'TUX! What are you doing here!', you ask."; read -srn 1
echo "'Why, I am here to beat YOU, $name.', he replys."; read -srn 1
echo "'I'm afraid I won't let that happen, TUX."; read -srn 1
echo "I am going to be the best digitron battler in the WORLD!', you reply, confidence growing by the second."; read -srn 1
echo "'You better put your actions where your mouth is, not that I would know where it is... You get what I mean'"; read -srn 1
echo -e "\nFINALISTS, GET READY. FIGHT!"; read -srn 1

# First battle of third match
addDigitron "TUX    150    Divine" "rm    40" "rmdir    45" "delete    50"
fight "$(gawk 'NR==2{print $1}' ./player.dat)" "TUX"

# Second battle of third match
echo -e "\n'You're gonna have to be better than that if you're gonna beat me!'"; read -srn 1
addDigitron "TUX    200    Divine" "delete    40" "backspace    45" "ctrl+a    55"
fight "$(gawk 'NR==2{print $1}' ./player.dat)" "TUX"

# Second battle of third match
echo -e "\n'Not bad... but I'm not done yet!'"; read -srn 1
addDigitron "TUX    300    Divine" "lost_connection    75" "high_ping    65" "packet_loss    70"
fight "$(gawk 'NR==2{print $1}' ./player.dat)" "TUX"

echo -e "'Well, I'm not sure how, but you defeated me... Well done. You truly are the greatest digitron dueler.'"; read -srn 1
echo "THERE YOU HAVE IT, FOLKS. $name IS THE GREATEST IN THE WORLD!!!"; read -srn 1
echo -e "\nIn the distance, you can feel your grandpop's presence."; read -srn 1
echo "In fact, you see him in the f bleachers waving down."; read -srn 1

if [ $hasNewspaper -eq 1 ]
    then echo "'THANK YOU FOR GETTING MY PAPER, MY GRANDCHILD!!', he calls."; read -srn 1
fi

echo -n "You smile, and think to yourself: 'Wow..."; read -srn 1
echo -n " I did it..."; read -srn 1
echo -e " I am the greatest digitron battler.\n"; read -srn 1

# End screen
echo -e "\nThank you for playing!"
if [ -f ./.asciiArt/DigiLark.txt ]
    then cat ./.asciiArt/DigiLark.txt
fi
echo "  By: Isaac Fernandes and Nelson Suarez"