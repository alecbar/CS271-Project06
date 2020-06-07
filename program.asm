TITLE Program 6    (program.asm)

; Author: Alec Barnard
; Last Modified: 6/5/20
; OSU email address: barnaral@oregonstate.edu
; Course number/section: 400
; Project Number: 06                Due Date: 6/7/20
; Description: Asks user to enter 10 signed integers, used ReadVal procedure to store characters as signed integer in array
; displays all integers in array using WriteVal procedure to display signed integer as string of characters

INCLUDE Irvine32.inc

ARRAYSIZE = 10

getString MACRO prompt, string, len
	push ecx ; save ecx, edx
	push edx

	; display prompt
	mov edx, prompt
	call WriteString

	; get string input
	mov edx, string
	mov ecx, len
	call ReadString

	pop edx ; restore ecx, edx
	pop ecx
	
ENDM

displayString MACRO string
	push edx ; save edx

	; display string
	mov edx, string
	call WriteString

	pop edx ; restore edx
ENDM

displayInt MACRO num
	push eax ; save eax

	;display dec
	mov eax, num
	call WriteInt

	pop eax ; restore eax
ENDM

.data
intro_1 BYTE "Program 6: Alec Barnard", 0
prompt_1 BYTE "Enter a number: ", 0
error_1 BYTE "Error - you did not enter a signed number or it was too large. Please try again.", 0

numbers_result BYTE "The numbers are: ", 0
sum_result BYTE "The sum is: ", 0
average_result BYTE "The average is: ", 0

space BYTE " ", 0
comma BYTE ",", 0

input BYTE 11 DUP(0)
output BYTE 11 DUP(0)

sum DWORD ?
average DWORD ?

array DWORD ARRAYSIZE DUP(0)

.code
main PROC
	; Program Title and Intro
	displayString OFFSET intro_1
	call Crlf

	; Fill array with values
	push OFFSET error_1
	push OFFSET prompt_1
	push OFFSET input
	push SIZEOF input
	push ARRAYSIZE
	push OFFSET array
	call FillArray

	; Display numers result
	call Crlf
	displayString OFFSET numbers_result
	call Crlf

	; Display array values
	push OFFSET comma
	push OFFSET space
	push OFFSET output
	push ARRAYSIZE
	push OFFSET array
	call DisplayArray

	; Calculate sum
	push ARRAYSIZE
	push OFFSET array
	call CalculateSum

	; Display sum
	call Crlf
	displayString OFFSET sum_result
	displayInt sum
	call Crlf

	; Calcaulate average
	push ARRAYSIZE
	push sum
	call CalculateAverage

	; Display Average
	displayString OFFSET average_result
	displayInt average

 	exit	; exit to operating system
main ENDP

;Reads string of characters and stores as signed integer
;receives: Prompt, outstring, string length 
;returns: Signed integer in eax
;preconditions: 
;registers changed: eax, ebx, ecx, esi
ReadVal PROC
	push ebp
	mov ebp, esp

	push ebx
	push ecx
	push esi

	string_input:
		; Get input
		getString [ebp+16], [ebp+12], [ebp+8]

		; Setup string for loop
		mov esi, [ebp+12]
		cld

		; Running total
		mov ecx, 0

		jmp validate

	validate:
		; Load string byte
		lodsb

		; If zero this is end of string or invalid
		cmp al, 0
		je end_string

		; Check in range for valid number
		cmp al, 48
		jb sign_check
		cmp al, 57
		ja input_error

		; Convert to number
		sub al, 48

		; Save current number
		push eax

		; Move existing number and multiple by 10
		mov eax, ecx
		mov ebx, 10
		mul ebx

		; Add current number back
		pop ebx
		add eax, ebx

		; Check carry for too large number
		jo input_error

		; Put new number back in ecx
		mov ecx, eax

		jmp validate

	end_string:
		; If running total is zero so then input is invalid
		cmp ecx, 0
		je input_error

		; Otherwise this is end of the string
		jmp end_input

	sign_check:
		cmp al, 43
		jb input_error
		cmp al, 45
		ja input_error
		cmp al, 44
		je input_error
		jmp validate

	input_error:
		; prompt to try again and jump back to loop
		displayString [ebp+20]
		call Crlf
		jmp string_input

	end_input:
		; Go back for sign
		mov esi, [ebp+12]
		cld
		lodsb

		cmp al, 45
		je negative
		jmp return

	negative:
		neg ecx

	return:
		; final number in eax
		mov eax, ecx

		;restore registers
		pop esi
		pop ecx
		pop ebx

		pop ebp
		ret 16

ReadVal ENDP

;Reads signed integer and writes as string of characters
;receives: Signed integer, outstring
;returns: 
;preconditions: Signed integer must be provided and outstring initalized
;registers changed: eax, ebx, ecx, edx, edi
WriteVal PROC
	push ebp
	mov ebp, esp

	push edi
	push edx
	push ecx
	push ebx
	push eax

	; setup out string for loop
	mov edi, [ebp+12]
	cld

	; int in eax
	mov eax, [ebp+8]

	; digit counter
	mov ecx, 1 

	negative_check:
		cmp eax, 0
		jl negative
		jmp convert

	negative:
		neg eax

	convert:
		; increment counter
		;inc ecx

		; setup division
		mov ebx, 10
		cdq
		idiv ebx

		; If eax is 0 then this is the last digit
		cmp eax, 0
		je last_digit

		; Convert result to ASCII and push on stack 
		add edx, 48
		push edx

		; Continue dividing
		inc ecx
		jmp convert

	last_digit:
		; Convert last digit
		add edx, 48
		push edx
	
	; This isn't working when using both positive and negative, or negative before positive
	; I think this is because the extra byte is still in the outstring, but I can't get a working way
	; to erase the whole string var everytime and start fresh
	sign_check:
		mov eax, [ebp+8]
		cmp eax, 0
		jl add_sign
		jmp reverse

	add_sign:
		push 45
		inc ecx
		jmp reverse


	reverse:
		; Pop all values off stack to store in correct order
		pop eax
		stosb
		loop reverse

	displayString [ebp+12]

	pop eax
	pop ebx
	pop ecx
	pop edx
	pop edi

	pop ebp
	ret 8

WriteVal ENDP
	
; Fills array withs integers
;receives: Arrray address, array size
;returns: 
;preconditions: Array has been initalized
;registers changed: eax, ecx, edi
FillArray PROC
	push ebp
	mov ebp, esp

	; array address
	mov edi, [ebp+8]

	; setup to loop through array
	mov ecx, [ebp+12]

	fill:

		push [ebp+28]
		push [ebp+24]
		push [ebp+20]
		push [ebp+16]
		call ReadVal

		mov [edi], eax
		add edi, 4

		loop fill


	pop ebp
	ret 24
FillArray ENDP

;Reads all integers in array and displays
;receives: Array and aray size
;returns: 
;preconditions: Array has been initalized with values
;registers changed: eax, ecx, edi
DisplayArray PROC

	push ebp
	mov ebp, esp

	push eax
	push ecx
	push edi

	; array address
	mov edi, [ebp+8]

	; setup to loop through array
	mov ecx, [ebp+12]


	display:
		mov eax, [edi]

		push [ebp+16]
		push eax

		call writeVal

		cmp ecx, 1
		je continue

		add_space:
			displayString [ebp+24]
			displayString [ebp+20]

	
		continue:
		add edi, 4
		loop display
	
	pop edi
	pop ecx
	pop eax

	pop ebp
	ret 20

DisplayArray ENDP

;Calcautes sum of values in array
;receives: Array, array size
;returns: sum in sum variable
;preconditions: Array initalized with values and sum var initialized
;registers changed: eax, ecx, edi
CalculateSum PROC
	push ebp 
	mov ebp, esp

	push eax
	push ecx
	push edi

	; array address
	mov edi, [ebp+8]

	; setup to loop through array
	mov ecx, [ebp+12]

	mov eax, 0

	sum_loop:
		add eax, [edi]

		add edi, 4
		loop sum_loop

	mov sum, eax

	pop edi
	pop ecx
	pop eax

	pop ebp
	ret 8
CalculateSum ENDP

;Calculate average of array values
;receives: Sum, array size
;returns: Average in average variable
;preconditions: Sum calculated 
;registers changed: eax, ebx, edx
CalculateAverage PROC
	push ebp
	mov ebp, esp

	push eax
	push ebx
	push edx

	mov eax, [ebp+8]
	mov ebx, [ebp+12]
	cdq

	idiv ebx
	mov average, eax

	pop edx
	pop ebx
	pop eax

	pop ebp
	ret 8
CalculateAverage ENDP


END main