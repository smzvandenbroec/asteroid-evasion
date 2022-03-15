.data
player: .asciz "\33[1m\33[33;94m>\n\33[0m"
pPos:
    .byte 0x06
    .byte 0x02

key: .skip 8
delay: .quad 0, 200050000
meteors: .skip 108              # There are 360 possible positions, with each 2 coordinates, encoding = xyxyxyxy... + 1 null byte

emptyStr: .asciz "\33[0m\33[1m----------------------------------------\n                                        \n                                        \n                                        \n                                        \n                                        \n                                        \n                                        \n                                        \n                                        \n----------------------------------------\n                                        \n"
wavecounter: .byte 0x05
points: .skip 8
scoreOn: .byte 0x00
difficultyLevel: .byte 0x01
delayDec: .skip 8
fileAddress: .skip 16
tempName: .skip 16
name1:
    .skip 8
score1:
    .skip 8
name2:
    .skip 8
score2:
    .skip 8
name3:
    .skip 8
score3:
    .skip 8

.bss    
termios:
    .skip 36
#    c_iflag: 
#    .skip 4, 0    # input mode flags
#    c_oflag: 
#    .skip 4, 0    # output mode flags
#    c_cflag: 
#    .skip 4, 0    # control mode flags
#    c_lflag: 
#    .skip 4, 0    # local mode flags
#    c_line: 
#    .skip 1, 0     # line discipline
#    c_cc: 
#    .skip 19, 0      # control characters
termioscopy:
    .skip 36
#    c_iflagc: 
# .skip 4    # input mode flags
#    c_oflagc: 
# .skip 4    # output mode flags
#    c_cflagc: 
# .skip 4    # control mode flags
#    c_lflagc: 
# .skip 4    # local mode flags
#    c_linec: 
# .skip 1     # line discipline
#    c_ccc: 
# .skip 19      # control characters

.text
posStr: .asciz "\33[%d;%dH%s"
clearStr: .asciz "\33[2J"
noCursor: .asciz "\033[?25l"
showCursor: .asciz "\033[?25h"
meteor: .asciz "\33[1m\33[38;5;204m0\n\33[0m"
scoreStr: .asciz "\33[2;49;92mScore: "
numbForm: .asciz "%d"

menuStr: .asciz "\33[0m\33[1m\n            Aster0id Evasi0n\n\n                1. Play\n          2. Change difficulty\n                3. Help\n             4. High scores\n                5. Quit\n\n\nCredits: Senne Van den Broeck"
deadStr: .asciz "\33[0m\33[1m\n\n                You died!\n\n\n                   \n              1. Play again\n                2. Quit\n"
helpStr: .asciz "\33[0m\33[1m\n                 Help\n\n         Use Z or W to move up\n           Use S to move down\n    Press p during the game to quit\n Evade asteroids by moving up and down\n\n       Press any key, good luck!"
difficultyStr: .asciz "\33[0m\33[1m\n\n          Choose a difficulty\n         Current difficulty:   /3   \n                   \n       Press 1-3 to  change difficulty\n       Press any other key to continue\n"
hsMenuStr: .asciz "\33[2;1H\33[0m\33[1m\n              High Scores\n\n        Difficulty 1: %s %d\n        Difficulty 2: %s %d\n        Difficulty 3: %s %d\n\n            Press any key     \n"
hsStr: .asciz "\33[0m\33[1m\n\n         You have a high score!\n\n          Enter your name below\n                   \n              \n          Press enter when done     \n"
diffForm: .asciz "\33[%d;%dH%d"
pauseStr: .asciz "\33[39m\33[1m1. Continue   2. Quit   "
pressPStr: .asciz "\33[39m\33[1mPress -P- to pause"
clearAnsi: .asciz "\33[m"
file: .asciz "hs.txt"
changePos: .asciz "\33[%d;%dH"
blank: .asciz "\33[6;8H"
pressKey: .asciz "Press any key to continue"
.global main

# ----------------- #
#   Main routine    #
#   Called on boot  #
# ----------------- #
main:
    # Prologue
    pushq %rbp
    movq %rsp, %rbp

    # Get current termios settings
    movq $termios, %rdi
    call rtermios

    # Save original termios to reset at end of program
    movq $termioscopy, %rdi
    call rtermios

    movq $termios, %rax                                             # Set %rax as pointer at termios
    addq $12, %rax                                                  # Flag for canonical mode

    # Modify flags
    movl $0, (%rax)                                                 # Disable canonical mode
    addq $11, %rax                                                  # Address of c_cc flag
    movb $0, (%rax)                                                 # Set flag to 0

    # Write new termios structure back
    movq $termios, %rdi
    call wtermios

    # Clear cursor from screen
    movq $0, %rax                                                   # Clear %rax
    movq $noCursor, %rdi                                            # ANSI code to disable cursor
    call printf                                                     # Print

    # Clear screen
    movq $0, %rax                                                   # Clear %rax
    movq $clearStr, %rdi                                            # ANSI code to clear screen
    call printf                                                     # Print

    # Create file
    call readHighScore                                              # Creates the highscore file & caches saved highscores

    goMain:                                                         # Main loop of the game

    # Load main menu
    call mainMenu                                                   # Loads the main menu

    # Play game
    cmpq $1, %rax                                                   # Check if option = play
    jne twos                                                        # If not check next

    playagain:                                                      # Small loop if play again selected
    
    call game                                                       # Start actual game

    cmpq $2, %rax                                                   # Check if option = quit
    je goMain                                                       # Go to main loop

    cmpq $0, %rax                                                   # Check if option = quit
    je goMain                                                       # Go to main loop

    cmpq $1, %rax                                                   # Check if option = play again
    je playagain                                                    # Go to play again loop

    jmp goMain                                                      # In case of error, go to main loop

    # Change difficulty
    twos:
    cmpq $2, %rax                                                   # Check if option = Change difficulty
    jne threes                                                      # If not check next option

    call difficulty                                                 # Show difficulty menu
    jmp goMain                                                      # Go to main loop if finished

    # Help
    threes:
    cmpq $3, %rax                                                   # Check if option = Help
    jne fours                                                       # If not check next option

    call help                                                       # Show help menu
    jmp goMain                                                      # Go to main loop if finished

    # Highscore
    fours:
    cmpq $4, %rax                                                   # Check if option = Highscore
    jne quit                                                        # If not, option = quit

    call highscoreMenu                                              # Show highscore menu
    jmp goMain                                                      # Go to main loop

    quit:

    # Clear screen
    movq $0, %rax                                                   # Clear %rax
    movq $clearStr, %rdi                                            # ANSI code to clear screen 
    call printf                                                     # Print

    # Clear effects
    movq $0, %rax                                                   # Clear %rax
    movq $clearAnsi, %rdi                                           # Ansi code to clear effects
    call printf                                                     # Print

    # Write old termios structure back
    movq $termioscopy, %rdi                                         
    call wtermios

    # Show cursor
    movq $0, %rax                                                   # Clear %rax
    movq $showCursor, %rdi                                          # ANSI code to show cursor
    call printf                                                     # Print

    # Epilogue
    movq %rsp, %rbp
    popq %rbp

    movq $0, %rdi                                                   # Exit code 0
    call exit

# ----------------------------- #
#   Game subroutine             #
#                               #
#   Gets called when game       #
#   starts, contains gameLoop   #
#                               #
#   Uses global variables:      #
#   - $pPos                     #
#   - $pressPStr                #
#   - $waveCounter              #
#   - $scoreOn                  #
#   - $points                   #
#   - $delay                    #
#   - $key                      #
#   - $meteors                  #
#                               #
#   Returns 0, 1, 2 in %rax     #
#   0,2 = Main menu             #
#   1 = play again              #
# ----------------------------- #
game:
    # Prologue
    pushq %rbp
    movq %rsp, %rbp

    call calcDelayDec                                               # Calculate the delay decrease for each round

    gameLoop:                                                       # Main loop for the game

        call emptyScreen                                            # Clear gamescreen

        call decDelay                                               # Decrease the delay every round

        # Print player
        xor %rdx, %rdx                                              # Clear %rdx                                              
        xor %rsi, %rsi                                              # Clear %rsi

        movq $pPos, %rbx                                            # Address of player position
        movb (%rbx), %sil                                           # Y coordinate    
        incq %rbx                                                   # Next coordinate
        movb (%rbx), %dl                                            # X coordinate
        movq $player, %rdi                                          # Player string
        call pprint                                                 # Position print

        # Print score
        movq $12, %rdi                                              # Y = 12
        movq $1, %rsi                                               # X = 1
        call drawScore                                              # Draw score
        call enableScore                                            # Check to enable score

        # Print pause
        movq $pressPStr, %rdi                                       # Pause string
        movq $12, %rsi                                              # Y = 12
        movq $15, %rdx                                              # X = 15
        call pprint                                                 # Position print

        call mmet                                                   # Move asteroids

        call pcol                                                   # Check for player collision

        cmpq $1, %rax                                               # Check if collision
        je playerdead                                               # If collision then player is dead

        movq $wavecounter, %rax                                     # Load wavecounter in %rax
        cmpb $5, (%rax)                                             # Check if 5 waves have passed
        jne nogen                                                   # If not, don't generate asteroids
        movb $0x00, (%rax)                                          # If there have, clear waveCounter
  
        call gmet                                                   # Generate asteroids

        movq $scoreOn, %rax                                         # Score boolean in %rax

        cmpb $0x01, (%rax)                                          # Check if score is enabled
        jne nogen                                                   # Skip score increase

        # Increase score
        movq $points, %rax                                          # %rax Points at score
        incq (%rax)                                                 # Increase score

        nogen:
        call pmet                                                   # Print asteroids

        movq $wavecounter, %rax                                     # %rax Points at waveCounter
        incb (%rax)                                                 # Increase waveCounter

        # Delay 
        movq $35, %rax                                              # Sys_nanosleep
        movq $delay, %rdi                                           # Delay
        xor %rsi, %rsi                                              # Clear %rsi
        syscall                                                     # Syscall for sleep

        call readChar                                               # Get character input

        movq $key,%rax                                              # Set pointer at key                                          

        # Key = z
        z:
        cmpb $0x7a, (%rax)                                          # Check if key = z
        jne w                                                       # If not check w
        jmp forw                                                    # Go forward

        # Key = w
        w:
        cmpb $0x77, (%rax)                                          # Check if key = w
        jne s                                                       # If not check s

    forw:                                                           # Label for moving forward
        movb $0x00, (%rax)                                          # Clear key
        movq $pPos, %rax                                            # Load player position in %rax

        cmpb $2, (%rax)                                             # Check if Y = 2
        je gameLoop                                                 # If it does, don't move

        decb (%rax)                                                 # Else move up
        jmp gameLoop                                                # Go to game loop

        # Key = s
        s:
        cmpb $0x73, (%rax)                                          # Check ifk ey = s
        jne p                                                       # If not check p

        movb $0x00, (%rax)                                          # Clear key
        movq $pPos, %rax                                            # Load player position in %rax

        cmpb $10, (%rax)                                            # Check if Y = 10
        je gameLoop                                                 # If it does, don't move

        incb (%rax)                                                 # Move down
        jmp gameLoop                                                # Go to game loop

        # Key = p
        p:
        cmpb $0x70, (%rax)                                          # Check if key = p
        jne gameLoop                                                # If not go to game loop

        call pauseGame                                              # Pause the game

        cmpq $0, %rax                                               # Check if option = continue
        je gameLoop                                                 # Go to game loop

        pushq $0                                                    # Put return value 0 on stack
        jmp end                                                     # Go to end of subroutine

    playerdead:                                                     # Player died

        call checkIfHighScore                                       # Check if player has highscore

        cmpq $0x00, %rax                                            # Check if return value = 0
        jne hashs                                                   # If not, player has highscore 

        call dead                                                   # Show death screen

        pushq %rax                                                  # Push return value on stack
        jmp end                                                     # Go to end of subroutine

        hashs:
        call deadhs                                                 # Show highscore screen and ask name

        pushq $0                                                    # Push return value on stack

    end:                                                            # End of subroutine
        clearAll:                                                   # Clear all variables for possible next game
            
            # Score
            movq $points, %rax                                      # %rax Points at score
            movq $0, (%rax)                                         # Clear score

            # Player position
            movq $pPos, %rax                                        # %rax Points at player position
            movl $0x0206, (%rax)                                    # Reset player position to default

            # Wavecounter
            movq $wavecounter, %rax                                 # %rax Points at waveCounter
            movb $0, (%rax)                                         # Clear wavecounter

            # Score boolean
            movq $scoreOn, %rax                                     # %rax Points at scoreOn boolean
            movb $0, (%rax)                                         # Clear scoreOn boolean

            # Delay
            movq $delay, %rax                                       # %rax Points at delay
            addq $8, %rax                                           # Skip first zero's
            movq $200050000, (%rax)                                 # Reset delay to default

            # Meteors array
            movq $meteors, %rdx                                     # %rdx Points at meteors array
            xor %rbx, %rbx                                          # %rbx Is counter                 

            sl:                                                     # Loop to clear array
            movb $0, (%rdx)                                         # Clear pointer 
            incq %rbx                                               # Increase counter
            incq %rdx                                               # Increase pointer
            cmpq $108, %rbx                                         # Check if end of array has been reached
            jne sl                                                  # If not, continue loop

        popq %rax                                                   # Store return value in %rax

        # Epilogue
        movq %rsp, %rbp
        popq %rbp

        ret

# ------------------------------------- #
#   Help subroutine                     #
#                                       #
#   Displays info on the game           #
#   Waits for a key press to continue   #
#                                       #
#   Uses global variables:              #
#   - $helpStr                          #
#   - $key                              #
# ------------------------------------- #
help:

    # Prologue
    pushq %rbp
    movq %rsp, %rbp

    # Clear screen
    call emptyScreen                                                # Clears the game screen

    helpLoop:                                                       # Main loop for help menu

        movq $helpStr, %rdi                                         # %rdi Points at help string
        movq $2, %rsi                                               # Y = 2
        movq $1, %rdx                                               # X = 1
        call pprint                                                 # Position print

        call readChar                                               # Get character input

        movq $key, %rax                                             # %rax Points at key

        cmpb $0x00, (%rax)                                          # Check if key has been pressed
        je helpLoop                                                 # If not, go to main loop
        
        movb $0x00, (%rax)                                          # Clear key

        # Epilogue
        movq %rsp, %rbp
        popq %rbp

        ret

# ------------------------------------- #
#   highscoreMenu subroutine            #
#                                       #
#   Displays the highscore menu         #
#   Waits for a keypress to continue    #
#                                       #
#   Uses global variables:              #
#   - $name1                            #
#   - $name2                            #
#   - $name3                            #
#   - $score1                           #
#   - $score2                           #
#   - $score3                           #
#   - $hsMenuStr                        #
#   - $key                              #
# ------------------------------------- #
highscoreMenu:
    # Prologue
    pushq %rbp
    movq %rsp, %rbp

    call emptyScreen                                                # Clear the game screen

    movq $name1, %rdi                                               # %rdi Points at name 1
    movq $name2, %rsi                                               # %rsi Points at name 2
    movq $name3, %rdx                                               # %rdx Points at name 3

    xor %rax, %rax                                                  # Clear %rax

    entLp:                                                          # Loop to clear enter characters from strings
        
        # Name 1
        cmpb $10, (%rdi)                                            # Check if %rdi points at enter
        jne na2                                                     # If not check for name 2

        movb $0x00, (%rdi)                                          # Clear enter character

        # Name 2
        na2:                                                        
        cmpb $10, (%rsi)                                            # Check if %rsi points at enter
        jne na3                                                     # If not check name 3

        movb $0x00, (%rsi)                                          # Clear enter character

        # Name 3
        na3:
        cmpb $10, (%rdx)                                            # Check if %rdx points at enter
        jne ctLp                                                    # If not, continue loop

        movb $0x00, (%rdx)                                          # Clear enter

        ctLp:

            incq %rdi                                               # Increase name 1 pointer
            incq %rsi                                               # Increase name 2 pointer
            incq %rdx                                               # Increase name 3 pointer

            incq %rax                                               # Increase counter
            cmpq $8, %rax                                           # Check if end of strings has been reacher
            jne entLp                                               # If not, loop again

    # Write highscore menu
    movq $0, %rax                                                   # Clear %rax
    movq $hsMenuStr, %rdi                                           # Load highscore Menu String    
    movq $name1, %rsi                                               # Load name 1
    movq score1, %rdx                                               # Load score 1
    movq $name2, %rcx                                               # Load name 2
    movq score2, %r8                                                # Load score 2
    movq $name3, %r9                                                # Load name 3
    pushq score3                                                    # Load score 3
    call printf                                                     # Print

    popq %rdi                                                       # Properly clear the stack

        hsLoop:                                                     # Loop to wait for character

            call readChar                                           # Read character input

            movq $key, %rax                                         # %rax Points at key

            cmpb $0x00, (%rax)                                      # Check if key is empty
            je hsLoop                                               # If empty, keep looping

    movb $0x00, (%rax)                                              # Clear key

    # Epilogue
    movq %rsp, %rbp
    popq %rbp

    ret
    
# ------------------------------------- #
#   deadhs subroutine                   #
#                                       #
#   Asks a player to enter their name   #
#   for highscore                       #
#                                       #
#   Uses global variables:              #
#   - $termios                          #
#   - $termioscopy                      #
#   - $hsStr                            #
#   - $tempName                         #
#   - $difficultyLevel                  #
#   - $pressKey                         #
#   - $key                              #
# ------------------------------------- #
deadhs:
    # Prologue
    pushq %rbp
    movq %rsp, %rbp

    call emptyScreen                                                # Clear the game screen

    # Old termios
    movq $termioscopy, %rdi                                         # Load old termios
    call wtermios                                                   # Write old termios back

    # Write highscore screen
    movq $hsStr, %rdi                                               # Load highscore String
    movq $2, %rsi                                                   # Y = 2
    movq $1, %rdx                                                   # X = 1
    call pprint                                                     # Position print

    # Read input
    movq $0, %rax				                                    # Sys_read
    movq $0, %rdi				                                    # Read at stout
    movq $tempName, %rsi				                            # Store input at $tempName
    movq $8, %rdx                                                   # Max length = 8
	syscall                                                         # Syscall for read

    call setHighScore                                               # Change name in highscore table

    movq $tempName, %rdx                                            # %rdx Points at tempName
    xor %rdx, %rdx                                                  # Clear %rdx

    # New termios
    movq $termios, %rdi                                             # Load new termios
    call wtermios                                                   # Write new termios back

    call emptyScreen                                                # Empty game screen

    hsmLoop:                                                        # Wait for key press

        movq $pressKey, %rdi                                        # Load press key string 
        movq $8, %rsi                                               # Y = 8
        movq $8, %rdx                                               # X = 8
        call pprint                                                 # Position print

        call readChar                                               # Read character input

        movq $key, %rax                                             # %rax Points at key

        cmpb $0x00, (%rax)                                          # Check if key is empty
        je hsmLoop                                                  # If it is, keep looping

        movb $0x00, (%rax)                                          # Clear key

    # Epilogue
    movq %rsp, %rbp
    popq %rbp

    ret

# ------------------------------------- #
#   pauseGame subroutine                #
#                                       #
#   Gets called during the gameLoop     # 
#   Freezes the game                    #
#                                       #
#   Uses global variables:              #
#   - $pauseStr                         #
#   - $key                              #
#                                       #
#   Returns in %rax:                    #
#   - 0: Continue                       #
#   - 1: Main menu                      #
# ------------------------------------- #
pauseGame:
    
    # Prologue
    pushq %rbp
    movq %rsp, %rbp

    pauseLoop:                                                      # Main loop for pause screen

        movq $pauseStr, %rdi                                        # Load pause string 
        movq $12, %rsi                                              # Y = 12
        movq $15, %rdx                                              # X = 15
        call pprint                                                 # Position print

        call readChar                                               # Read character input

        movq $key, %rax                                             # %rax Points at key

        # 1 
        cmpb $0x31,(%rax)                                           # Check if key = 1
        jne twop                                                    # If not check 2

        movb $0, (%rax)                                             # Clear key
        movq $0, %rax                                               # Return code = 0

        jmp rtp                                                     # Go to end of subroutine

        # 2
        twop:
        cmpb $0x32,(%rax)                                           # Check if key = 2
        jne pauseLoop                                               # If not go to main loop

        movb $0, (%rax)                                             # Clear key

        movq $1, %rax                                               # Return code = 1

        rtp:                                                        # End of subroutine
        # Epilogue
        movq %rsp, %rbp
        popq %rbp

        ret

# ------------------------------------- #
#   difficulty subroutine               #
#                                       #
#   Shows a menu to alter the           #
#   difficulty level                    #
#                                       #
#   Uses global variables:              #
#   - $difficultyStr                    #
#   - $diffForm                         #
#   - $difficultyLevel                  #
#   - $key                              #
# ------------------------------------- #
difficulty:

    # Prologue
    pushq %rbp
    movq %rsp, %rbp

    call emptyScreen                                                # Clear game screen

    # Print difficulty menu
    movq $difficultyStr, %rdi                                       # Load difficulty menu 
    movq $2, %rsi                                                   # Y = 2
    movq $1, %rdx                                                   # X = 1
    call pprint                                                     # Position print

    difficultyLoop:                                                 # Main loop for difficulty menu

        xor %rax,%rax                                               # Clear %rax
        movq $diffForm, %rdi                                        # Load difficulty format string
        movq $5, %rsi                                               # Y = 5
        movq $30, %rdx                                              # X = 30
        xor %rcx, %rcx                                              # Clear %rcx 
        movb difficultyLevel, %cl                                   # Load difficulty level
        call printf                                                 # Print

        call readChar                                               # Read character input

        movq $key, %rax                                             # %rax Points at key
        
        movq $difficultyLevel, %rdi                                 # %rdi Points at difficulty level

        # 1
        cmpb $0x31,(%rax)                                           # Check if key = 1
        jne twod                                                    # If not check for 2

        movb $0, (%rax)                                             # Clear key
        movb $0x01, (%rdi)                                          # Set difficulty to 1
        jmp difficultyLoop                                          # Go to main loop

        # 2
        twod:
        cmpb $0x32,(%rax)                                           # Check if key = 2
        jne threed                                                  # If not check for 3

        movb $0, (%rax)                                             # Clear key
        movb $2, (%rdi)                                             # Set difficulty to 2
        jmp difficultyLoop                                          # Go to main loop

        # 3
        threed:
        cmpb $0x33,(%rax)                                           # Check if key = 3
        jne fourd                                                   # If not check if empty

        movb $0, (%rax)                                             # Clear key
        movb $3, (%rdi)                                             # Set difficulty to 3
        jmp difficultyLoop                                          # Go to main loop
        
        # Null
        fourd:
        cmpb $0x00, (%rax)                                          # Check if key is empty
        je difficultyLoop                                           # If empty go to main loop

        movb $0, (%rax)                                             # Clear key

        # Epilogue
        movq %rsp, %rbp
        popq %rbp

        ret
    
# ------------------------------------- #
#   dead subroutine                     #
#                                       #
#   Displays the death screen           # 
#                                       #
#   Uses global variables:              #
#   - $deadStr                          #
#   - $key                              #
#                                       #
#   Returns in %rax:                    #
#   - 1: play again                     #
#   - 2: main menu                      #
# ------------------------------------- #
dead:

    # Prologue
    pushq %rbp
    movq %rsp, %rbp

    call emptyScreen                                                # Clear game screen

    deadLoop:                                                       # Main loop for death screen

        # Print death screen
        movq $deadStr, %rdi                                         # Load dead screen string
        movq $2, %rsi                                               # Y = 2
        movq $1, %rdx                                               # X = 1
        call pprint                                                 # Position print

        # Draw score
        movq $6, %rdi                                               # Y = 6
        movq $18, %rsi                                              # X = 18
        call drawScore                                              # Draw score

        call readChar                                               # Read character input

        movq $key, %rax                                             # %rax Points at key

        # 1
        cmpb $0x31,(%rax)                                           # Check if key = 1
        jne twode                                                   # If not check for 2

        movb $0, (%rax)                                             # Clear key
        movq $1, %rax                                               # Set return code to 1

        jmp rtde                                                    # Go to end of subroutine

        # 2
        twode:
        cmpb $0x32,(%rax)                                           # Check if key = 2
        jne deadLoop                                                # If not go to main loop 

        movb $0, (%rax)                                             # Clear key
        movq $2, %rax                                               # Set return code to 2

        rtde:                                                       # End of subroutine

        # Epilogue
        movq %rsp, %rbp
        popq %rbp

        ret

# ------------------------------------- #
#   mainMenu subroutine                 #
#                                       # 
#   Displays the main menu              #
#   with all options                    #
#                                       #
#   Uses global variables:              # 
#   - $menuStr                          #
#   - $$key                             #
#                                       #
#   Returns in %rax:                    #
#   - 1: Play game                      #
#   - 2: Set difficulty                 #
#   - 3: Help                           #
#   - 4: Highscore                      #
#   - 5: Quit program                   #
# ------------------------------------- #
mainMenu:
    
    # Prologue
    pushq %rbp
    movq %rsp, %rbp

    call emptyScreen                                                # Clear the game screen

    mainLoop:                                                       # Main loop for main menu

        # Print main menu 
        movq $menuStr, %rdi                                             # Load menu string 
        movq $2, %rsi                                                   # Y = 2
        movq $1, %rdx                                                   # X = 1
        call pprint   

        call readChar                                               # Read character input

        movq $key, %rax                                             # %rax Points at key

        # 1
        cmpb $0x31,(%rax)                                           # check if key = 1
        jne twom                                                    # If not check for 2

        movb $0, (%rax)                                             # Clear key
        movq $1, %rax                                               # Set return code 1
        
        jmp rtm                                                     # Go to end of subroutine

        # 2 
        twom:
        cmpb $0x32,(%rax)                                           # Check if key = 2
        jne threem                                                  # If not check for 3

        movb $0, (%rax)                                             # Clear key
        movq $2, %rax                                               # Set return code to 2
        
        jmp rtm                                                     # Go to end of subroutine

        # 3
        threem:
        cmpb $0x33,(%rax)                                           # Check if key = 3
        jne four                                                    # If not check for 4

        movb $0, (%rax)                                             # Clear key
        movq $3, %rax                                               # Set return code to 3
        
        jmp rtm                                                     # Go to end of subroutine

        # 4
        four:
        cmpb $0x34,(%rax)                                           # Check if key = 4
        jne five                                                    # If not check for 5

        movb $0, (%rax)                                             # Clear key
        movq $4, %rax                                               # Set return code to 4

        jmp rtm                                                     # Go to end of subroutine

        # 5
        five:   
        cmpb $0x35,(%rax)                                           # Check if key = 5
        jne mainLoop                                                # If not go to main loop

        movb $0, (%rax)                                             # Clear key
        movq $5, %rax                                               # Set return code to 5

        rtm:                                                        # End of subroutine

        # Epilogue
        movq %rsp, %rbp
        popq %rbp

        ret

# ------------------------------------- #
#   enableScore subroutine              #
#                                       #
#   Checks if asteroids have reached    #
#   the ship to start score             #
#                                       #
#   Uses global variables:              #
#   - $meteors                          #
#   - $scoreOn                          #
# ------------------------------------- #
enableScore:

    # Prologue
    pushq %rbp
    movq %rsp, %rbp

    # Check if meteors have reached player
    movq $meteors, %rax                                             # %rax Points at array of meteors
    addq $72, %rax                                                  # Increase pointer by 72 (Last row of asteroids)
    cmpb $0x00, (%rax)                                              # Check if empty
    je no                                                           # If not, don't enable score

    movq $scoreOn, %rax                                             # %rax Points at score boolean
    movb $1, (%rax)                                                 # Set boolean to true

    no:                                                             # End of subroutine
    # Epilogue
    movq %rsp, %rbp
    popq %rbp

    ret

# ------------------------------------- #
#   drawScore subroutine                #
#                                       #
#   Draws the score at a give (x,y)     #
#                                       #
#   Parameters:                         #
#   - %rdi = y                          #
#   - %rsi = x                          #
#                                       #
#   Uses global variables:              #
#   - $scoreStr                         #
#   - $numbForm                         #
# ------------------------------------- #
drawScore:

    # Prologue
    pushq %rbp
    movq %rsp, %rbp

    # Print score string
    movq %rsi, %rdx                                                 # Load Y
    movq %rdi, %rsi                                                 # Load X
    movq $scoreStr, %rdi                                            # Load score string
    call pprint                                                     # Position print

    # Print score value
    xor %rax, %rax                                                  # Clear %rax
    movq $numbForm, %rdi                                            # Load number format
    movq points, %rsi                                               # Load points
    call printf                                                     # Print

    # Epilogue
    movq %rsp, %rbp
    popq %rbp

    ret

# ------------------------------------- #
#   pcol subroutine                     #
#                                       #
#   Checks if the player has collided   #
#   with an asteroid                    #
#                                       #
#   Uses global variables:              #
#   - $meteors                          #
#   - $pPos                             #
#                                       #
#   Returns 1 if collided and 0 if not  #
#   in %rax                             # 
# ------------------------------------- #
pcol:

    # Prologue
    pushq %rbp
    movq %rsp, %rbp

    movq $meteors, %rax                                             # %rax Points at array of meteors                                           
    addq $84, %rax                                                  # We need position 84, the only row that can collide with the player

    xor %rdx, %rdx                                                  # Clear %rdx for counter

    check:                                                          # Check for player collision

    cmpb $0x02, (%rax)                                              # Check if asteroid X = 2
    jne fin                                                         # If not go to end of subroutine

    incq %rax                                                       # Increase pointer

    movq $pPos, %rbx                                                # %rbx Points at player position
    movb (%rbx), %bl                                                # Move Y into lower byte of %rbx

    cmpb %bl, (%rax)                                                # Check if Y player = Y asteroid
    je killed                                                       # If equal player is killed

    plus:                                                           # Increase pointers
    addq $1, %rax                                                   # Increase asteroid pointer to next Y 

    incq %rdx                                                       # Increase counter

    cmpq $6, %rdx                                                   # If counter = 6 all asteroids have been checked
    je fin                                                          # Go to end of subroutine

    jmp check                                                       # Check again for collision

    killed:                                                         # Player is dead
    movq $1, %rax                                                   # Set return code to 1
    
    jmp rtc                                                         # Go to end of subroutine

    fin:                                                            # Player is not dead
    movq $0, %rax                                                   # Set return code to 0

    rtc:                                                            # End of subroutine

    # Epilogue
    movq %rsp, %rbp
    popq %rbp

    ret

# ------------------------------------- #
#   pprint subroutine                   #
#                                       #
#   Prints a string at a given (x,y )   #
#                                       #
#   Paramters:                          #
#   - %rdi = String address             #
#   - %rsi = y                          #
#   - %rdx = x                          #
#                                       #
#   Uses global variables:              #
#   - $posStr                           #
# ------------------------------------- #
pprint:

    # Prologue
    pushq %rbp
    movq %rsp, %rbp

    xor %rax, %rax                                                  # Clear %rax
    movq %rdi, %rcx                                                 # Load string
    movq $posStr, %rdi                                              # Load position string
    call printf                                                     # Print

    # Epilogue
    movq %rsp, %rbp
    popq %rbp

    ret

# ------------------------------------- #
#   mmet subroutine                     #
#                                       #
#   Moves the meteors in the array to   #
#   simulate moving objects             #
#                                       #
#   Uses global variables:              #
#   - $meteors                          #
#   - $waveCounter                      #
# ------------------------------------- #
mmet:

    # Prologue
    pushq %rbp
    movq %rsp, %rbp

    # Store callee saved registers
	pushq %R12
	pushq %R13
	pushq %r14
	pushq %r15

    movq $meteors, %r12                                             # %r12 Points at array of meteors

    movq $95, %r13                                                  # Start at first before final position

    addq %r13, %r12                                                 # Add offset to %r12

    am:                                                             # Loop check where to start

    cmpb $0x00, (%r12)                                              # Check if asteroids in this place of array
    jne change                                                      # If not change to next 6 asteroids

    subq $12, %r12                                                  # Decrease offset bye 12 (6 asteroids with 2 coordinates)
    subq $12, %r13                                                  # Decrease counter

    cmp $0, %r13                                                    # Check if counter = 0
    jle rtmm                                                        # If less or equal go to end of subroutine

    jmp am                                                          # Check next 6 asteroids

    xor %r15, %r15                                                  # Clear %r15 for counter

    change:                                                         # Move asteroids

    movq $wavecounter, %rax                                         # %rax Points at waveCounter
    cmpb $5, (%rax)                                                 # Check if waveCounter = 5
    jne decr                                                        # If not only decrease the coordinates and don't move them in array

    move:                                                           # Move and decrease asteroids

        movq %r12, %r14                                             # Load pointer into %r14
        addq $12, %r14                                              # Point at next row of 6 

        xor %rax, %rax                                              # Clear %rax
        movb (%r12), %al                                            # Move current coordinate into %rax

        cmpq $1, %r15                                               # Check if counter = 1 to determine X or Y
        jne noty                                                    # If not 1 then go to Y
        subq $2, %r15                                               # Decrease counter by 2
        subb $1, %al                                                # Decrease coordinate

        noty:   
        movb %al, (%r14)                                            # Move coordinate to next spot in array

        decq %r12                                                   # Decrease pointer
        decq %r13                                                   # Decrease counter
        incq %r15                                                   # Increase counter

        cmpq $0, %r13                                               # Check if counter 0
        jge move                                                    # If greater or equal move again

        jmp rtmm                                                    # go to end of subroutine

    decr:                                                           # Decrease coordinates instead of moving

        cmpq $1, %r15                                               # Check if counter = 1
        jne notx                                                    # If not then not X
        subq $2, %r15                                               # Substract 2 from counter
        decb (%r12)                                                 # Decrease coordinate

        notx:                                                       # Do nothing

        decq %r12                                                   # Decrease pointer
        decq %r13                                                   # Decrease counter
        incq %r15                                                   # Increase counter

        cmpq $0, %r13                                               # Check if counter is 0
        jge decr                                                    # If greater than or equal, keep decreasing

        rtmm:                                                       # End of subroutine

        # Put callee saved registers back
	    popq %R15
	    popq %R14
	    popq %R13
	    popq %R12

        # Epilogue
        movq %rsp, %rbp
        popq %rbp

        ret
    
# ------------------------------------- #
#   gmet subroutine                     #
#                                       #
#   Generates a new line of meteors     #
#   on the first six spots of the array #
#                                       #
#   Uses global variables:              #
#   - $meteors                          #
# ------------------------------------- #
gmet:
    # Prologue
    pushq %rbp
    movq %rsp, %rbp

    # Save callee saved registers
    pushq %r12
    pushq %r13

    movq $meteors, %r12                                             # %r12 Points at array of meteors

    xor %r13, %r13                                                  # Clear %r13

    lp:                                                             # Loop for generating an asteroid
        cmpq $6, %r13                                               # Check if 6 asteroids have been generated
        je done                                                     # If so, go to end of subroutine

        movb $40, (%r12)                                            # Move X coordinate to pointer
        incq %r12                                                   # Increase pointer
        
        call getrand                                                # Get random number in %rax
        movb %al, (%r12)                                            # Store random numbber in pointer
        
        incq %r12                                                   # Increase pointer
        incq %r13                                                   # Increase counter
        jmp lp                                                      # Go to loop

    done:                                                           # End of subroutine

        # Put callee saved registers back
        popq %r13
        popq %r12

        # Epilogue
        movq %rsp, %rbp
        popq %rbp

        ret

# ------------------------------------- #
#   pmet subroutine                     #
#                                       #
#   Prints all asteroids in the array   #
#                                       #
#   Uses global variables:              #
#   - $meteors                          #
#   - $meteor                           #
# ------------------------------------- #
pmet:
    # Prologue
    pushq %rbp
    movq %rsp, %rbp
    
    # Store callee saved registers
    pushq %r12
    pushq %r13

    movq $meteors, %r12                                             # Point at meteor array

    cmpb $0, (%r12)                                                 # Check if empty
    je printdone                                                    # If first row is empty go to end of subroutine

    xor %r13, %r13                                                  # Clear %r13 for counter
    
    print:                                                          # Loop for printing
        # Calc x
        movq $0, %rdx                                               # Clear %rdx
        movb (%r12), %dl                                            # Load X coordinate

        # Calc y    
        incq %r12                                                   # Increase pointer
        movq $0, %rsi                                               # Clear %rsi
        movb (%r12), %sil                                           # Load Y in %rsi
        
        movq $meteor, %rdi                                          # Load meteor string
        call pprint                                                 # Position print

        incq %r12                                                   # Increase pointer

        cmpb $0x00, (%r12)                                          # Check if empty
        je printdone                                                # If so, go to end of subroutine

        jmp print                                                   # Continue printing
    
    printdone:                                                      # End of subroutine

    # Load callee saved registers
    popq %r13
    popq %r12

    # Epilogue
    movq %rsp, %rbp
    popq %rbp

    ret

# ------------------------------------- #
#   rtermios subroutine                 #
#                                       #
#   Reads the current termios settings  #
#   saved in given address              #
#                                       #
#   Parameters:                         #
#   - %rdi = address to store at        #
# ------------------------------------- #
rtermios:

    # Prologue
    pushq %rbp
    movq %rsp, %rbp

    mov  %rdi, %rdx                                                 # Address to store at
    mov  $16, %rax                                                  # Sys_ioctl
    mov  $0, %rdi                                                   # Stdin
    mov  $0x5401, %rsi                                              # Read
    syscall                                                         # Call ioctl

    # Epilogue
    movq %rsp, %rbp
    popq %rbp

    ret

# ------------------------------------- #
#   wtermios subroutine                 #
#                                       #
#   Overwrites the current termios      #
#   settings                            #
#                                       #
#   Parameters:                         #
#   - %rdi = address of new termios     #
#     settings                          #
# ------------------------------------- #
wtermios:

    # Prologue
    pushq %rbp
    movq %rsp, %rbp

    mov  %rdi, %rdx                                                 # Address of new termios
    mov  $16, %rax                                                  # Sys_ioctl
    mov  $0, %rdi                                                   # Stdin
    mov  $0x5402, %rsi                                              # Write
    syscall                                                         # Call ioctl

    # Epilogue
    movq %rsp, %rbp
    popq %rbp

    ret

# ------------------------------------- #
#   getrand subroutine                  #
#                                       #
#   Generates a random number between   #
#   2-10                                #
#                                       #
#   Returns the number in %rax          #
# ------------------------------------- #
getrand:

    # Prologue
    pushq %rbp
    movq %rsp, %rbp

    rdtsc                                                           # Loadds value of last clock reset
    shr $2, %rax                                                    # Shift to make more random
    xor %rdx, %rdx                                                  # Clear %rdx
    movq $9, %rbx                                                   # Store divisor
    div %rbx                                                        # Divide by 9
    addq $2, %rdx                                                   # Add 2 to remainder to get 2-10
    movq %rdx, %rax                                                 # Return in %rax

    # Epilogue
    movq %rsp, %rbp
    popq %rbp

    ret

# ------------------------------------- #
#   emptyScreen subroutine              #
#                                       #
#   Clears the game screen              #
#                                       #
#   Uses global variables:              #
#   - $emptyStr                         #
# ------------------------------------- #
emptyScreen:

    # Prologue
    pushq %rbp
    movq %rsp, %rbp

    movq $emptyStr, %rdi                                            # Load empty string
    movq $1, %rsi                                                   # Y = 1
    movq $1, %rdx                                                   # X = 1
    call pprint                                                     # Position print

    # Epilogue
    movq %rsp, %rbp
    popq %rbp

    ret

# ------------------------------------- #
#   readChar subroutine                 #
#                                       #
#   Reads a character and puts it in    #
#   $key                                #
#                                       #
#   Uses global variables:              #
#   - $key                              #
# ------------------------------------- #
readChar:

    # Prologue
    pushq %rbp
    movq %rsp, %rbp

    # Read input
    movq $0, %rax				                                    # Sys_read
    movq $0, %rdi				                                    # Read at stout
    movq $key, %rsi				                                    # Store input at $key
    movq $8, %rdx                                                   # Max size = 8 bytes
	syscall                                                         # Read

    # Epilogue
    movq %rsp, %rbp
    popq %rbp

    ret

# ------------------------------------- #
#   decDelay subroutine                 #
#                                       #
#   Decreases the gameLoop delay        #
#   according to the difficulty level   #
#                                       #
#   Uses global variables:              #
#   - $delay                            #
#   - $difficultyLevel                  #
#   - $delayDec                         #
# ------------------------------------- #
decDelay:
    # Prologue
    pushq %rbp
    movq %rsp, %rbp
    
    # 3 67550000 = Cap for diff 3
    # 2 89900000 = Cap for diff 2
    # 1 100000000 = Cap for diff 1
    
    # Pointers
    movq $difficultyLevel, %rax                                     # %rax Points at difficulty level
    movq $delay, %rdi                                               # %rdi Points at delay
    addq $8, %rdi                                                   # Increase pointer to skip 0's

    # 1
    cmpb $1, (%rax)                                                 # Check if difficulty level = 1
    jne twodec                                                      # If not check 2

    cmpq $100000000, (%rdi)                                         # Check if delay has reached cap
    jle sk                                                          # If so, skip

    jmp smaller                                                     # Decrease delay

    # 2
    twodec:
    cmpb $2, (%rax)                                                 # Check if difficulty level = 2
    jne threedec                                                    # if not check 3

    cmpq $89900000, (%rdi)                                          # Check if delay has reached cap
    jle sk                                                          # If so, skip

    jmp smaller                                                     # Decrease delay

    # 3
    threedec:
    cmpq $67550000, (%rdi)                                          # Check if delay has reached cap
    jle sk                                                          # If so, skip

    smaller:                                                        # Decrease delay
    movq delayDec, %rax                                             # Load delayDec in %rax
    subq %rax, (%rdi)                                               # Decrease delay


    sk:                                                             # End of subroutine

    # Epilogue
    movq %rsp, %rbp
    popq %rbp

    ret

# ------------------------------------- #
#   calcDelayDec subroutine             #
#                                       #
#   Calculates how much the delay       #
#   decreases every round               #
#                                       #
#   Uses global variables:              #
#   - $difficultyLevel                  #
#   - $delayDec                         #
# ------------------------------------- #
calcDelayDec:
    
    # Prologue
    pushq %rbp
    movq %rsp, %rbp

    movq $300000, %rax                                              # Load value in %rax
    movq $difficultyLevel, %rdx                                     # %rdi Points at difficultyLevel
    xor %rbx, %rbx                                                  # Clear %rbx
    movb (%rdx), %bl                                                # Move difficulty level in lower byte of %rbx

    mulq %rbx                                                       # Mulltiply value by difficulty level

    movq $delayDec, %rdx                                            # %rdx Points at delayDec
    movq %rax, (%rdx)                                               # Set value in %rax as delayDec

    # Epilogue
    movq %rsp, %rbp
    popq %rbp

    ret

# ------------------------------------- #
#   getFilePointer subroutine           #
#                                       #
#   Sets the pointer to the highscore   #
#   file, also opens it                 #
#                                       #
#   Uses global variables:              #
#   - $fileAddress                      #
#   - $file                             #
# ------------------------------------- #
getFilePointer:
    # Prologue
    pushq %rbp
    movq %rsp, %rbp

    movq $2, %rax                                                   # Sys_open
    movq $file, %rdi                                                # Address of file
    movq $66, %rsi                                                  # Set flags to create new file
    movq $511, %rdx                                                 # Set permissions to read & write
    syscall                                                         # Syscall for file

    movq $fileAddress, %rdi                                         # %rdi Points at fileAddress
    movq %rax, (%rdi)                                               # Save file address in fileAddress

    # Epilogue
    movq %rsp, %rbp
    popq %rbp

    ret

# ------------------------------------- #
#   closeFile subroutine                #
#                                       #
#   Closes the highscore file           #
#   for highscore                       #
#                                       #
#   Uses global variables:              #
#   - $file                             #
# ------------------------------------- #
closeFile:

    # Prologue
    pushq %rbp
    movq %rsp, %rbp

    movq $3, %rax                                                   # Sys_close
    movq $file, %rdi                                                # Load address of file
    syscall                                                         # Syscall to close file

    # Epilogue
    movq %rsp, %rbp
    popq %rbp

    ret

# ------------------------------------- #
#   writeHighScore subroutine           #
#                                       #
#   Writes the current highscore to     #
#   the file                            #
#                                       #
#   Uses global variables:              #
#   - $fileAddress                      #
#   - $name1                            #
# ------------------------------------- #
writeHighScore:
    # Prologue
    pushq %rbp
    movq %rsp, %rbp

    call getFilePointer                                             # Open file

    # Write highscore to file
    movq fileAddress, %rdi                                          # Load fileAddress                
    movq $1, %rax                                                   # Sys_write
    movq $name1, %rsi                                               # Address of highscore
    movq $48, %rdx                                                  # Byte size of write
    syscall                                                         # Syscall to write

    call closeFile                                                  # Close file

    # Epilogue
    movq %rsp, %rbp
    popq %rbp

    ret

# ------------------------------------- #
#   readHighScore subroutine            #
#                                       #
#   Read the highscores from a file and #
#   save them in memory                 #
#                                       #
#   Uses global variables:              #
#   - $fileAddress                      #
#   - $name1                            #
# ------------------------------------- #
readHighScore:
    # Prologue
    pushq %rbp
    movq %rsp, %rbp

    call getFilePointer                                             # Open file

    movq $0, %rax                                                   # Sys_read
    movq fileAddress, %rdi                                          # Address of file
    movq $name1, %rsi                                               # Address to store
    movq $48, %rdx                                                  # Size to read
    syscall                                                         # Syscall to read

    call closeFile                                                  # Close file

    # Epilogue
    movq %rsp, %rbp
    popq %rbp

    ret

# ------------------------------------- #
#   checkIfHighScore subroutine         #
#                                       #
#   Checks if a player has a new        #
#   highscore                           #
#                                       #
#   Uses global variables:              #
#   - $difficultyLevel                  #
#   - $score1                           #
#   - $score2                           #
#   - $score3                           #
#                                       #
#   Returns 1 if highscore and 0 if not #
#   in %rax                             #
# ------------------------------------- #
checkIfHighScore:
    
    # Prologue
    pushq %rbp
    movq %rsp, %rbp

    movq points, %rbx                                               # Load score into %rbx

    movq $difficultyLevel, %rax                                     # %rax Points at difficultyLevel

    # 1
    cmpb $1, (%rax)                                                 # Check if difficultylevel = 1
    jne nd                                                          # If not check for 2

    movq $score1, %rdx                                              # %rdx Points at score 1

    cmpq %rbx, (%rdx)                                               # Check if highscore
    jge nohs                                                        # If not go to end of subroutine

    jmp cths                                                        # Set highscore

    # 2
    nd:
    cmpb $2, (%rax)                                                 # Check if difficultylevel = 2
    jne nd2                                                         # If not check 3

    movq $score2, %rdx                                              # %rdx Points at score 2
    cmpq %rbx, (%rdx)                                               # Check if highscore
    jge nohs                                                        # If not, go to end of subroutine

    jmp cths                                                        # Set highscore

    # 3
    nd2:
    movq $score3, %rdx                                              # %rdx Points at score 3
    cmpq %rbx, (%rdx)                                               # Check if highscore
    jge nohs                                                        # If not go to end of subroutine

    cths:                                                           # Set highscore

    movq %rbx, (%rdx)                                               # Overwrite highscore with new highscore
    movq $1, %rax                                                   # Set return code to 1
    jmp sch                                                         # Go to end of subroutine

    nohs:                                                           # Reached if no highscore

    movq $0, %rax                                                   # set return code to 0

    sch:                                                            # End of subroutine

    # Epilogue
    movq %rsp, %rbp
    popq %rbp

    ret

# ------------------------------------- #
#   setHighScore subroutine             #
#                                       #
#   Sets a players name in the          #
#   highscore table                     #
#                                       #
#   Uses global variables:              #
#   - $difficultyLevel                  #
#   - $tempName                         #
#   - $name1                            #
#   - $name2                            #
#   - $name3                            #
# ------------------------------------- #
setHighScore:

    # Prologue
    pushq %rbp
    movq %rsp, %rbp

    movq difficultyLevel, %rdi                                      # Move difficultylevel into %rdi
    movq tempName, %rsi                                             # Move tempname into %rsi

    # 1
    cmpb $1, %dil                                                   # Check if difficulty level = 1
    jne set2                                                        # If not, check 2

    movq $name1, %rax                                               # %rax Points at name 1
    jmp hsdon                                                       # Overwrite name

    # 2
    set2:
    cmpb $2, %dil                                                   # Check if difficulty level = 2
    jne set3                                                        # If not check 3

    movq $name2, %rax                                               # %rax Points at name 2
    jmp hsdon                                                       # Overwrite name

    # 3
    set3:

    movq $name3, %rax                                               # %rax Points at name 3

    hsdon:                                                          # Overwrite name

    movq %rsi, (%rax)                                               # Overwrite highscore name with new name

    call writeHighScore                                             # Write new highscore to file

    # Epilogue
    movq %rsp, %rbp
    popq %rbp

    ret
