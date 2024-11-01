#!/bin/bash

nasm -f elf64 src/x86_64.asm -o bin/x86_64.o && ld bin/*.o -o yamm