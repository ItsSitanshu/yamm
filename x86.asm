section .bss
    memory_pool resb 65536    ; 64 KB
    pool_ptr    resq 1        
    pool_end    resq 1       

section .text
global malloc, free, _start

HEADER_SIZE equ 16   ; [..] = size, [.. + 8] = is_free

malloc:
    ; Input: rdi - number of bytes to allocate
    ; Output: rax - pointer to the allocated memory (not including the header)

    mov rdx, rdi

    add rdx, HEADER_SIZE
    and rdx, -8

    cmp qword [pool_ptr], 0
    jne .alloc                

    mov rax, memory_pool     
    mov [pool_ptr], rax      
    add rax, 65536           
    mov [pool_end], rax

.alloc:
    mov rsi, memory_pool     
.find_free_block:
    cmp rsi, [pool_ptr]
    jge .allocate_new_block

    ; [rsi] = size, [rsi + 8] = is_free
    mov rax, [rsi]          
    cmp qword [rsi + 8], 1 
    jne .next_block       

    cmp rax, rdx          
    jae .use_free_block  
.next_block:
    add rsi, rax         
    jmp .find_free_block

.use_free_block:
    mov qword [rsi + 8], 0   
    add rsi, HEADER_SIZE     
    mov rax, rsi            
    ret

.allocate_new_block:
    mov rsi, [pool_ptr]     
    add rsi, rdx            

    cmp rsi, [pool_end]     
    jg .expand_heap

    jmp .allocate_memory
.allocate_memory:
    mov rax, [pool_ptr]      
    mov [rax], rdx           
    mov qword [rax + 8], 0   

    add qword [pool_ptr], rdx 
    add rax, HEADER_SIZE     
    ret

.expand_heap:
    mov rax, 12              ; sys_brk 
    mov rdi, [pool_end]      
    add rdi, 65536           ; 64 KB
    syscall

    test rax, rax          
    js .error
    
    mov [pool_end], rdi
    
    cmp rdi, rdx
    jle .expand_heap 
    
    jmp .allocate_new_block  
.error:
    xor rax, rax 
    ret

free:
    ; Input: rdi - pointer to the memory to free (allocated block)
    ; Output: None

    test rdi, rdi           
    je .end_free            

    sub rdi, HEADER_SIZE     
    mov qword [rdi + 8], 1   ; is_free = 1

.end_free:
    ret

_start:
    mov rdi, 60000   
    call malloc

    mov rdi, rax
    call free

    mov rdi, 5536   
    call malloc

    mov rdi, rax
    mov rax, 60          
    syscall
