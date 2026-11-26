INCLUDE Irvine32.inc

MAX_ITEMS = 50
NLEN = 20
CLEN = 15
LLEN = 20

.data

itemIDs     DWORD MAX_ITEMS DUP(0)
itemStatus  BYTE  MAX_ITEMS DUP(0)
itemNames   BYTE  MAX_ITEMS * NLEN DUP(0)
itemCats    BYTE  MAX_ITEMS * CLEN DUP(0)
itemLocs    BYTE  MAX_ITEMS * LLEN DUP(0)

itemCount   DWORD 0
nextID      DWORD 1000
matchCount  DWORD 0
fieldChoice DWORD 0
cntLost     DWORD 0
cntFound    DWORD 0
cntReturned DWORD 0
keyBuf      BYTE  32 DUP(0)

stLost      BYTE "LOST", 0
stFound     BYTE "FOUND", 0
stReturned  BYTE "RETURNED", 0
sep         BYTE " | ", 0

title1      BYTE "======================================", 0Dh, 0Ah
            BYTE "  CAMPUS LOST AND FOUND MANAGEMENT", 0Dh, 0Ah
            BYTE "======================================", 0
menu1       BYTE "1. Register Lost Item", 0
menu2       BYTE "2. Register Found Item", 0
menu3       BYTE "3. Search Items", 0
menu4       BYTE "4. Match Lost Items With Found Items", 0
menu5       BYTE "5. Update Item Status", 0
menu6       BYTE "6. Display All Records", 0
menu7       BYTE "7. Summary Report", 0
menu8       BYTE "8. Exit", 0
msgChoice   BYTE "Enter your choice: ", 0
msgInvalid  BYTE "Invalid choice. Try again.", 0
msgName     BYTE "Enter item name: ", 0
msgCat      BYTE "Enter category: ", 0
msgLoc      BYTE "Enter location: ", 0
msgDone     BYTE "Item registered successfully. Unique ID: ", 0
msgFull     BYTE "Storage is full. Cannot register more items.", 0
msgSearchBy BYTE "Search by (1=Name, 2=Category, 3=Location): ", 0
msgKeyword  BYTE "Enter search keyword: ", 0
msgNoMatch  BYTE "No matching records found.", 0
msgEmpty    BYTE "No records available.", 0
msgHeader   BYTE "ID | NAME | CATEGORY | LOCATION | STATUS", 0
msgAskID    BYTE "Enter item ID: ", 0
msgNotFound BYTE "Item ID not found.", 0
msgNewStat  BYTE "New status (1=Lost, 2=Found, 3=Returned): ", 0
msgUpdated  BYTE "Status updated successfully.", 0
msgMatchHdr BYTE "Possible matches (Lost item then Found item):", 0
msgPair     BYTE "---- Match Found ----", 0
msgNoPair   BYTE "No lost item matches any found item.", 0
msgSumHdr   BYTE "-------- SUMMARY REPORT --------", 0
msgTotal    BYTE "Total records   : ", 0
msgLostCnt  BYTE "Lost items      : ", 0
msgFoundCnt BYTE "Found items     : ", 0
msgRetCnt   BYTE "Returned items  : ", 0
msgPercent  BYTE "Return rate (%) : ", 0
msgBye      BYTE "Thank you for using the system. Goodbye.", 0

.code

ToUpper PROC
    push eax
    push edx
upLoop:
    mov al, [edx]
    cmp al, 0
    je upDone
    cmp al, 'a'
    jb upNext
    cmp al, 'z'
    ja upNext
    sub al, 32
    mov [edx], al
upNext:
    inc edx
    jmp upLoop
upDone:
    pop edx
    pop eax
    ret
ToUpper ENDP

ReadField PROC
    push edx
    call ReadString
    pop edx
    call ToUpper
    ret
ReadField ENDP

PrintStatus PROC
    cmp al, 0
    je isLost
    cmp al, 1
    je isFound
    mov edx, OFFSET stReturned
    jmp printIt
isLost:
    mov edx, OFFSET stLost
    jmp printIt
isFound:
    mov edx, OFFSET stFound
printIt:
    call WriteString
    ret
PrintStatus ENDP

Contains PROC
    push ebx
    push ecx
    push edi
    push esi
    cmp BYTE PTR [esi], 0
    je noMatch
    mov ebx, edx
outerLoop:
    cmp BYTE PTR [ebx], 0
    je noMatch
    mov edi, ebx
    mov ecx, esi
innerLoop:
    mov al, [ecx]
    cmp al, 0
    je isMatch
    cmp al, [edi]
    jne nextPos
    inc ecx
    inc edi
    jmp innerLoop
nextPos:
    inc ebx
    jmp outerLoop
isMatch:
    mov eax, 1
    jmp finish
noMatch:
    xor eax, eax
finish:
    pop esi
    pop edi
    pop ecx
    pop ebx
    ret
Contains ENDP

MatchStr PROC
    call Contains
    cmp eax, 1
    je matchDone
    xchg edx, esi
    call Contains
    xchg edx, esi
matchDone:
    ret
MatchStr ENDP

FindByID PROC
    xor ebx, ebx
findLoop:
    cmp ebx, itemCount
    jae notFound
    cmp itemIDs[ebx*4], eax
    je foundIt
    inc ebx
    jmp findLoop
notFound:
    mov ebx, -1
foundIt:
    ret
FindByID ENDP

DisplayItem PROC
    pushad
    mov eax, itemIDs[ebx*4]
    call WriteDec
    mov edx, OFFSET sep
    call WriteString
    imul eax, ebx, NLEN
    lea edx, itemNames[eax]
    call WriteString
    mov edx, OFFSET sep
    call WriteString
    imul eax, ebx, CLEN
    lea edx, itemCats[eax]
    call WriteString
    mov edx, OFFSET sep
    call WriteString
    imul eax, ebx, LLEN
    lea edx, itemLocs[eax]
    call WriteString
    mov edx, OFFSET sep
    call WriteString
    movzx eax, itemStatus[ebx]
    call PrintStatus
    call Crlf
    popad
    ret
DisplayItem ENDP

RegisterItem PROC
    pushad
    cmp itemCount, MAX_ITEMS
    jae storageFull
    mov edi, itemCount
    mov eax, nextID
    mov itemIDs[edi*4], eax
    mov itemStatus[edi], bl
    inc nextID

    mov edx, OFFSET msgName
    call WriteString
    imul eax, edi, NLEN
    lea edx, itemNames[eax]
    mov ecx, NLEN - 1
    call ReadField

    mov edx, OFFSET msgCat
    call WriteString
    imul eax, edi, CLEN
    lea edx, itemCats[eax]
    mov ecx, CLEN - 1
    call ReadField

    mov edx, OFFSET msgLoc
    call WriteString
    imul eax, edi, LLEN
    lea edx, itemLocs[eax]
    mov ecx, LLEN - 1
    call ReadField

    mov edx, OFFSET msgDone
    call WriteString
    mov edi, itemCount
    mov eax, itemIDs[edi*4]
    call WriteDec
    call Crlf
    inc itemCount
    jmp regExit
storageFull:
    mov edx, OFFSET msgFull
    call WriteString
    call Crlf
regExit:
    popad
    ret
RegisterItem ENDP

SearchItems PROC
    pushad
    mov edx, OFFSET msgSearchBy
    call WriteString
    call ReadInt
    mov fieldChoice, eax
    cmp eax, 1
    jb badField
    cmp eax, 3
    ja badField

    mov edx, OFFSET msgKeyword
    call WriteString
    mov edx, OFFSET keyBuf
    mov ecx, 30
    call ReadString
    mov edx, OFFSET keyBuf
    call ToUpper

    mov matchCount, 0
    mov edx, OFFSET msgHeader
    call WriteString
    call Crlf
    xor ebx, ebx
searchLoop:
    cmp ebx, itemCount
    jae searchEnd
    mov eax, fieldChoice
    cmp eax, 1
    je byName
    cmp eax, 2
    je byCat
    imul eax, ebx, LLEN
    lea edx, itemLocs[eax]
    jmp doCompare
byName:
    imul eax, ebx, NLEN
    lea edx, itemNames[eax]
    jmp doCompare
byCat:
    imul eax, ebx, CLEN
    lea edx, itemCats[eax]
doCompare:
    mov esi, OFFSET keyBuf
    call Contains
    cmp eax, 1
    jne searchNext
    call DisplayItem
    inc matchCount
searchNext:
    inc ebx
    jmp searchLoop
searchEnd:
    cmp matchCount, 0
    jne searchExit
    mov edx, OFFSET msgNoMatch
    call WriteString
    call Crlf
    jmp searchExit
badField:
    mov edx, OFFSET msgInvalid
    call WriteString
    call Crlf
searchExit:
    popad
    ret
SearchItems ENDP

MatchItems PROC
    pushad
    mov matchCount, 0
    mov edx, OFFSET msgMatchHdr
    call WriteString
    call Crlf
    xor ebx, ebx
lostLoop:
    cmp ebx, itemCount
    jae matchEnd
    cmp itemStatus[ebx], 0
    jne lostNext
    xor edi, edi
foundLoop:
    cmp edi, itemCount
    jae lostNext
    cmp itemStatus[edi], 1
    jne foundNext

    imul eax, ebx, NLEN
    lea edx, itemNames[eax]
    imul eax, edi, NLEN
    lea esi, itemNames[eax]
    call MatchStr
    cmp eax, 1
    je pairFound

    imul eax, ebx, CLEN
    lea edx, itemCats[eax]
    imul eax, edi, CLEN
    lea esi, itemCats[eax]
    call MatchStr
    cmp eax, 1
    je pairFound
    jmp foundNext

pairFound:
    mov edx, OFFSET msgPair
    call WriteString
    call Crlf
    call DisplayItem
    push ebx
    mov ebx, edi
    call DisplayItem
    pop ebx
    inc matchCount
foundNext:
    inc edi
    jmp foundLoop
lostNext:
    inc ebx
    jmp lostLoop
matchEnd:
    cmp matchCount, 0
    jne matchExit
    mov edx, OFFSET msgNoPair
    call WriteString
    call Crlf
matchExit:
    popad
    ret
MatchItems ENDP

UpdateStatus PROC
    pushad
    mov edx, OFFSET msgAskID
    call WriteString
    call ReadInt
    call FindByID
    cmp ebx, -1
    je idMissing
    mov edx, OFFSET msgNewStat
    call WriteString
    call ReadInt
    cmp eax, 1
    jb badStatus
    cmp eax, 3
    ja badStatus
    dec eax
    mov itemStatus[ebx], al
    mov edx, OFFSET msgUpdated
    call WriteString
    call Crlf
    jmp updExit
badStatus:
    mov edx, OFFSET msgInvalid
    call WriteString
    call Crlf
    jmp updExit
idMissing:
    mov edx, OFFSET msgNotFound
    call WriteString
    call Crlf
updExit:
    popad
    ret
UpdateStatus ENDP

DisplayAll PROC
    pushad
    cmp itemCount, 0
    jne hasRecords
    mov edx, OFFSET msgEmpty
    call WriteString
    call Crlf
    jmp dispExit
hasRecords:
    mov edx, OFFSET msgHeader
    call WriteString
    call Crlf
    xor ebx, ebx
dispLoop:
    cmp ebx, itemCount
    jae dispExit
    call DisplayItem
    inc ebx
    jmp dispLoop
dispExit:
    popad
    ret
DisplayAll ENDP

SummaryReport PROC
    pushad
    mov cntLost, 0
    mov cntFound, 0
    mov cntReturned, 0
    xor ebx, ebx
sumLoop:
    cmp ebx, itemCount
    jae sumPrint
    cmp itemStatus[ebx], 0
    je addLost
    cmp itemStatus[ebx], 1
    je addFound
    inc cntReturned
    jmp sumNext
addLost:
    inc cntLost
    jmp sumNext
addFound:
    inc cntFound
sumNext:
    inc ebx
    jmp sumLoop
sumPrint:
    mov edx, OFFSET msgSumHdr
    call WriteString
    call Crlf
    mov edx, OFFSET msgTotal
    call WriteString
    mov eax, itemCount
    call WriteDec
    call Crlf
    mov edx, OFFSET msgLostCnt
    call WriteString
    mov eax, cntLost
    call WriteDec
    call Crlf
    mov edx, OFFSET msgFoundCnt
    call WriteString
    mov eax, cntFound
    call WriteDec
    call Crlf
    mov edx, OFFSET msgRetCnt
    call WriteString
    mov eax, cntReturned
    call WriteDec
    call Crlf
    cmp itemCount, 0
    je sumExit
    mov edx, OFFSET msgPercent
    call WriteString
    mov eax, cntReturned
    mov ebx, 100
    mul ebx
    xor edx, edx
    mov ebx, itemCount
    div ebx
    call WriteDec
    call Crlf
sumExit:
    popad
    ret
SummaryReport ENDP

main PROC
menuLoop:
    call Crlf
    mov edx, OFFSET title1
    call WriteString
    call Crlf
    mov edx, OFFSET menu1
    call WriteString
    call Crlf
    mov edx, OFFSET menu2
    call WriteString
    call Crlf
    mov edx, OFFSET menu3
    call WriteString
    call Crlf
    mov edx, OFFSET menu4
    call WriteString
    call Crlf
    mov edx, OFFSET menu5
    call WriteString
    call Crlf
    mov edx, OFFSET menu6
    call WriteString
    call Crlf
    mov edx, OFFSET menu7
    call WriteString
    call Crlf
    mov edx, OFFSET menu8
    call WriteString
    call Crlf
    mov edx, OFFSET msgChoice
    call WriteString
    call ReadInt

    cmp eax, 1
    je opt1
    cmp eax, 2
    je opt2
    cmp eax, 3
    je opt3
    cmp eax, 4
    je opt4
    cmp eax, 5
    je opt5
    cmp eax, 6
    je opt6
    cmp eax, 7
    je opt7
    cmp eax, 8
    je opt8
    mov edx, OFFSET msgInvalid
    call WriteString
    call Crlf
    jmp menuLoop

opt1:
    mov bl, 0
    call RegisterItem
    jmp menuLoop
opt2:
    mov bl, 1
    call RegisterItem
    jmp menuLoop
opt3:
    call SearchItems
    jmp menuLoop
opt4:
    call MatchItems
    jmp menuLoop
opt5:
    call UpdateStatus
    jmp menuLoop
opt6:
    call DisplayAll
    jmp menuLoop
opt7:
    call SummaryReport
    jmp menuLoop
opt8:
    mov edx, OFFSET msgBye
    call WriteString
    call Crlf
    exit
main ENDP

END main
