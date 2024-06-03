INCLUDE Irvine32.inc

.data

welcomeMsg       BYTE "========== WELCOME TO THE EXCITING CASINO GAME! ==========", 0
promptName       BYTE "Please enter your name: ", 0
names            BYTE 5 DUP(20 DUP(?))  ; Array to store names of 5 users
promptBalance    BYTE "Please enter your starting balance: $", 0
balances         DWORD 5 DUP(0)         ; Array to store balance of 5 users
rulesTitle       BYTE "========== CASINO NUMBER GUESSING RULES! ==========", 0
rule1            BYTE "1. Choose a number between 1 to 10", 0
rule2            BYTE "2. Winner gets 5 times the money bet", 0
rule3            BYTE "3. If you guess wrong, you lose the amount you bet", 0
casinoBalance    DWORD 0                ; Balance of the casino
betPrompt        BYTE "Enter your betting amount: $", 0
casinoBalanceMsg BYTE "Casino balance is: $", 0
guessPrompt      BYTE "Guess a number between 1 and 10: ", 0
winMsg           BYTE "Congratulations ", 0
winMsg2          BYTE "! You won $", 0
loseMsg          BYTE "Sorry ", 0
loseMsg2         BYTE ", you lost $", 0
reenterNumMsg    BYTE "Number should be between 1 to 10. Please re-enter: ", 0
compGeneratedNum DWORD ?

winNumberMsg     BYTE "The winning number was: ", 0

continuePrompt   BYTE "Do you want to continue playing? (0 for yes & 1 for no): ", 0
currentBalance   BYTE "Your current balance is: $", 0
casinoWinMsg     BYTE "No winners this round. The amount has been added to the casino balance.", 0
endGameMsg       BYTE "Thank you for playing! Your final balance is: $", 0

totalBetAmount   DWORD ?
userGuesses      DWORD 5 DUP(?)
betAmount        DWORD 5 DUP(?)
anyWinner        DWORD 0
continueGame     DWORD 0

.code
main PROC
   ; Display Welcome Message
    mov edx, OFFSET welcomeMsg
    call WriteString
    call Crlf
    call Crlf

   ; Prompt for Names and Starting Balances
    mov ecx, 5                ; Loop for 5 users
    xor esi, esi              ; Index for arrays

GetNamesAndBalances:
    mov edx, OFFSET promptName
    call WriteString
    mov eax, esi
    mov edx, OFFSET names
    imul eax, 20                ; Calculate offset (esi * 20)
    add edx, eax
    mov ecx, 20
    call ReadString

    mov edx, OFFSET promptBalance
    call WriteString
    call ReadInt
    mov [balances + esi*4], eax  ; Store balance in array

    inc esi                     ; Move to the next user
    cmp esi, 5                  ; Check if we have taken input for 5 users
    jl GetNamesAndBalances      ; If not, loop again
    
    ; Initialize continueGame to 0 (to continue the game)
    mov continueGame, 0

    .WHILE continueGame == 0
     ; Display Game Rules
    call Crlf
    mov edx, OFFSET rulesTitle
    call WriteString
    call Crlf

    mov edx, OFFSET rule1
    call WriteString
    call Crlf

    mov edx, OFFSET rule2
    call WriteString
    call Crlf

    mov edx, OFFSET rule3
    call WriteString
    call Crlf

    ; Game loop
    call GameLoop

    ; Prompt to Continue or Not
    call Crlf
    mov edx, OFFSET continuePrompt
    call WriteString
    call ReadInt
    mov continueGame, eax

    .ENDW

    ; Display end game message and final balances
    call Crlf
    mov edx, OFFSET endGameMsg
    call WriteString
    call Crlf
    call DisplayBalances

    ; Exit the program
    INVOKE ExitProcess, 0

main ENDP

GameLoop PROC
    ; Collect betting amounts and calculate total bet amount
    mov totalBetAmount, 0  ; Reset total bet amount
    call CollectBetsAndCalculateTotal
    
    ; Collect guessing numbers from users
    call CollectGuessesFromUsers
    
    ; Generate random number between 1 and 10
    call Randomize
    mov eax, 10
    call RandomRange
    inc eax
    mov compGeneratedNum, eax

    ; Evaluate guesses and distribute winnings
    call EvaluateGuesses

    ; Display updated balances
    call DisplayBalances

    ret
GameLoop ENDP

; Procedure to collect betting amounts from all users and calculate total bet amount
CollectBetsAndCalculateTotal PROC
    mov esi, 0             ; Initialize index for looping through users

CollectBetsLoop:
    ; Prompt for bet amount
    mov eax, esi
    imul eax, 20
    lea edx, names[eax]
    call WriteString
    mov edx, OFFSET betPrompt
    call WriteString
    call ReadInt
    add totalBetAmount, eax     ; Add bet amount to total bet
    mov [betAmount + esi*4], eax   ; Store bet amount for user
    inc esi
    cmp esi, 5                  ; Check if we have collected bets from all users
    jl CollectBetsLoop
    ret
CollectBetsAndCalculateTotal ENDP

; Procedure to collect guessing numbers from all users and store them in an array
CollectGuessesFromUsers PROC
    mov esi, 0             ; Initialize index for looping through users

CollectGuessesLoop:
    ; Prompt for guess number
    mov eax, esi
    imul eax, 20
    lea edx, names[eax]
    call WriteString
    mov edx, OFFSET guessPrompt
    call WriteString
    call ReadInt
    mov [userGuesses + esi*4], eax   ; Store guess number for user
    inc esi
    cmp esi, 5                  ; Check if we have collected guesses from all users
    jl CollectGuessesLoop
    ret
CollectGuessesFromUsers ENDP

; Procedure to evaluate guesses, distribute winnings, and update balances
EvaluateGuesses PROC
    mov ecx, 5            ; Loop for 5 users
    mov anyWinner, 0      ; Reset winner flag
    xor esi, esi          ; Initialize index for looping through users

EvaluateGuessesLoop:
    ; Compare guess with generated number
    mov eax, [userGuesses + esi*4]
    cmp eax, compGeneratedNum
    je CorrectGuess        ; Jump if correct guess
    jne IncorrectGuess    ; Jump if incorrect guess

CorrectGuess:
    ; User won, add total winnings
    mov eax, [betAmount + esi*4]
    imul eax, 5          ; Multiply bet amount by 5
    add [balances + esi*4], eax   ; Add winnings to user balance
    mov anyWinner, 1      ; Set winner flag
    call DisplayWinMsg
    jmp NextUser

IncorrectGuess:
    ; User lost, subtract bet amount
    mov eax, [betAmount + esi*4]
    sub [balances + esi*4], eax   ; Subtract bet amount from user balance
    call DisplayLoseMsg

NextUser:
    inc esi
    loop EvaluateGuessesLoop

    ; Check if there were no winners
    cmp anyWinner, 0
    jne EndEvaluateGuesses

    ; No winners, add total bet amount to casino balance
    mov eax, totalBetAmount
    add casinoBalance, eax
    ; Display casino win message
    call Crlf
    mov edx, OFFSET casinoWinMsg
    call WriteString
    call Crlf

EndEvaluateGuesses:
    ret
EvaluateGuesses ENDP

; Procedure to display a win message for the user
DisplayWinMsg PROC
    call Crlf
    mov eax, esi
    imul eax, 20
    lea edx, names[eax]
    call WriteString
    mov edx, OFFSET winMsg
    call WriteString
    lea edx, names[eax]
    call WriteString
    mov edx, OFFSET winMsg2
    call WriteString
    mov eax, [betAmount + esi*4]
    imul eax, 5
    call WriteInt
    call Crlf
    ret
DisplayWinMsg ENDP

; Procedure to display a lose message for the user
DisplayLoseMsg PROC
    call Crlf
    mov eax, esi
    imul eax, 20
    lea edx, names[eax]
    call WriteString
    mov edx, OFFSET loseMsg
    call WriteString
    lea edx, names[eax]
    call WriteString
    mov edx, OFFSET loseMsg2
    call WriteString
    mov eax, [betAmount + esi*4]
    call WriteInt
    call Crlf
    ret
DisplayLoseMsg ENDP

; Procedure to display updated balances for all users and the casino balance
DisplayBalances PROC
    mov esi, 0             ; Initialize index for looping through users

DisplayBalancesLoop:
    ; Display user name and balance
    call Crlf
    mov eax, esi
    imul eax, 20
    lea edx, names[eax]
    call WriteString
    mov edx, OFFSET currentBalance
    call WriteString
    mov eax, [balances + esi*4]
    call WriteInt
    call Crlf
    inc esi
    cmp esi, 5                  ; Check if we have displayed balances for all users
    jl DisplayBalancesLoop

    ; Display casino balance
    call Crlf
    mov edx, OFFSET casinoBalanceMsg
    call WriteString
    mov eax, casinoBalance
    call WriteInt
    call Crlf

    ret
DisplayBalances ENDP

END main
