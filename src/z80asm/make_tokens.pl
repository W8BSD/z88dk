#!/usr/bin/perl

#------------------------------------------------------------------------------
# Z88DK Z80 Macro Assembler
#
# Copyright (C) Paulo Custodio, 2011-2023
# License: The Artistic License 2.0, http://www.perlfoundation.org/artistic_license_2_0
#------------------------------------------------------------------------------

use 5.020;
use warnings;
use autodie;

my @tokens = (
	'END',						# = 0; end of file reached
	'NIL',						# Returned for rubbish
	
	# Semantic tokens
	'NAME', 'LABEL', 'NUMBER', 'STRING', 'TERN_COND',	# cond ? true : false

	# Tokens
	'NEWLINE', 'LOG_NOT', 'CONST_EXPR', 'MOD', 'BIN_AND', 'LOG_AND',
	'LPAREN', 'RPAREN', 'MULTIPLY', 'PLUS', 'COMMA', 'MINUS', 'DOT',
	'DIVIDE', 'COLON', 'LESS', 'LEFT_SHIFT', 'LESS_EQ', 'NOT_EQ', 'EQUAL',
	'GREATER', 'RIGHT_SHIFT', 'GREATER_EQ', 'QUESTION', 'LSQUARE', 'RSQUARE',
	'BIN_XOR', 'POWER', 'LCURLY', 'BIN_OR', 'LOG_OR', 'RCURLY', 'BIN_NOT',
	
	# Indirect 8-bit register
	'IND_C',
	
	# Indirect 16-bit register
	'IND_BC', 'IND_DE', 'IND_HL', 'IND_SP', 'IND_IX', 'IND_IY', 'IND_HLI', 'IND_HLD',
	
	# Assembly keywords
	'ASMPC', 
	
	# Flags, C register
	'NZ', 'Z', 'NC', 'C', 'PO', 'PE', 'P', 'M', 
	'LZ', 'LO', 'NV', 'V', 'NK', 'K', 'NX5', 'X5',

	# 8-bit registers
	'B', 'D', 'E', 'H', 'L', 'A', 'F', 'I', 'R', 
	'IIR', 'EIR', 'XPC', 'IXH', 'IYH', 'IXL', 'IYL', 'X',

	# 16-bit registers
	'BC', 'DE', 'HL', 'IX', 'IY', 'AF', 'SP', 'PSW',

	# alternate registers
	'B1', 'C1', 'D1', 'E1', 'H1', 'L1', 'A1', 'F1', 'BC1', 'DE1', 'HL1', 'AF1',
	
	# EZ80 specific keywords
	'ADL', 'S', 'IS', 'IL', 'SIS', 'LIL', 'LIS', 'SIL', 'MB',
	'LEA', 'PEA', 'RSMIX', 'STMIX',
	'INI2', 'INI2R', 'IND2', 'IND2R', 'INIM', 'INIMR', 'INDM', 'INDMR', 'INIRX', 'INDRX',
	'OTD2R', 'OTDRX', 'OTI2R', 'OTIRX', 'OUTD2', 'OUTI2',

	# Assembly directives
	'ALIGN', 'ASSERT', 'ASSUME', 
	'BYTE', 'C_LINE', 'DB', 'DC', 'DDB', 'DEFB', 'DEFC', 
	'DEFDB', 'DEFGROUP', 'DEFINE', 'DEFM', 'DEFP', 'DEFQ', 'DEFS', 'DEFVARS', 
	'DEFW', 'DEPHASE', 'DM', 'DP', 'DQ', 'DS', 'DW', 'DWORD', 'EQU', 'EXTERN', 
	'GLOBAL', 'LIB', 'LINE', 'LSTOFF', 'LSTON', 'MODULE', 'ORG', 'PHASE', 'PTR', 
	'PUBLIC', 'SECTION', 'UNDEFINE', 'WORD', 'XDEF', 'XLIB', 'XREF',

	# DEFGROUP storage specifiers
	'DS_B', 'DS_W', 'DS_P', 'DS_Q',

	# Z80 opcode specifiers
	'ADC', 'ADD', 'AND', 'BIT', 'CALL', 'CCF', 'CCF1', 'CP', 'CPD', 'CPDR', 
	'CPI', 'CPIR', 'CPL', 'DAA', 'DEC', 'DI', 'DJNZ', 'EI', 'EX', 'EXX', 'HALT', 
	'IM', 'IN', 'INC', 'IND', 'INDR', 'INI', 'INIR', 'JP', 'JR', 'LD', 'LDH', 
	'LDHL', 'LDD', 'LDDR', 'LDI', 'LDIR', 'NEG', 'NOP', 'OR', 'OTDR', 'OTIR', 
	'OUT', 'OUTD', 'OUTI', 'POP', 'PUSH', 'RES', 'RET', 'RETI', 'RETN', 'RL', 
	'RLA', 'RLA1', 'RLC', 'RLCA', 'RLCA1', 'RLD', 'RR', 'RRA', 'RRA1', 'RRC', 
	'RRCA', 'RRCA1', 'RRD', 'RST', 'SBC', 'SCF', 'SCF1', 'SET', 'SLA', 'SLL', 
	'SLS', 'SLI', 'SRA', 'SRL', 'STOP', 'SUB', 'XOR',

	# Z80-ZXN specific opcodes
	'SWAPNIB', 'SWAP', 'OUTINB', 'LDIX', 'LDIRX', 'LDDX', 'LDDRX', 'LDIRSCALE',
	'LDPIRX', 'LDWS', 'FILL', 'FILLDE', 'MIRROR', 'NEXTREG', 'PIXELDN', 'PIXELAD',
	'SETAE', 'TEST', 'MMU', 'MMU0', 'MMU1', 'MMU2', 'MMU3', 'MMU4', 'MMU5', 
	'MMU6', 'MMU7', 'CU_WAIT', 'CU_MOVE', 'CU_STOP', 'CU_NOP', 'DMA_WR0', 
	'DMA_WR1', 'DMA_WR2', 'DMA_WR3', 'DMA_WR4', 'DMA_WR5', 'DMA_WR6', 'DMA_CMD',
	'BSLA', 'BSRA', 'BSRL', 'BSRF', 'BRLC', 'LDRX', 'LIRX', 'LPRX', 'MIRR', 
	'NREG', 'OTIB', 'PXAD', 'PXDN', 'STAE', 

	# Z180 specific opcodes
	'SLP', 'MLT', 'IN0', 'OUT0', 'OTIM', 'OTIMR', 'OTDM', 'OTDMR', 'TST', 'TSTIO',

	# EZ80 specific opcodes
	
	# Rabbit 2000/3000 specific opcodes
	'ALTD', 'BOOL', 'IOE', 'IOI', 'IPRES', 'IPSET', 'IDET', 'LDDSR', 'LDISR', 
	'LDP', 'LSDR', 'LSIR', 'LSDDR', 'LSIDR', 'MUL', 'IP', 'SU', 'RDMODE', 
	'SETUSR', 'SURES', 'SYSCALL', 'UMA', 'UMS',

	# Z88DK specific opcodes
	'CALL_OZ', 'CALL_PKG', 'FPP', 'INVOKE',

	# Intel 8080/8085 specific opcodes
	'MOV', 'MVI', 'LXI', 'LDA', 'STA', 'LHLD', 'SHLD', 'LDAX', 'STAX', 'XCHG', 
	'ADI', 'ACI', 'SUI', 'SBB', 'SBI', 'INR', 'DCR', 'INX', 'DCX', 'DAD', 'ANA',
	'ANI', 'ORA', 'ORI', 'XRA', 'XRI', 'CMP', 'RAL', 'RAR', 'CMA', 'CMC', 'STC',
	'JMP', 'JNC', 'JC', 'JNZ', 'JZ', 'JPO', 'JPE', 'JNV', 'JV', 'JLO', 'JLZ', 
	'JM', 'JK', 'JX5', 'JNK', 'JNX5', 'J_NC', 'J_C', 'J_NZ', 'J_Z', 'J_PO', 'J_PE',
	'J_NV', 'J_V', 'J_LO', 'J_LZ', 'J_P', 'J_M', 'J_K', 'J_X5', 'J_NK', 'J_NX5',
	'CNC', 'CC', 'CNZ', 'CZ', 'CPO', 'CPE', 'CNV', 'CV', 'CLO', 'CLZ', 'CM', 
	'C_NC', 'C_C', 'C_NZ', 'C_Z', 'C_PO', 'C_PE', 'C_NV', 'C_V', 'C_LO', 'C_LZ',
	'C_P', 'C_M', 'RNC', 'RC', 'RNZ', 'RZ', 'RPO', 'RPE', 'RNV', 'RV', 'RLO', 
	'RLZ', 'RP', 'RM', 'R_NC', 'R_C', 'R_NZ', 'R_Z', 'R_PO', 'R_PE', 'R_NV', 'R_V',
	'R_LO', 'R_LZ', 'R_P', 'R_M', 'PCHL', 'XTHL', 'SPHL', 'HLT', 'RIM', 'SIM', 
	'DSUB', 'ARHL', 'RRHL', 'RDEL', 'RLDE', 'LDHI', 'LDSI', 'RSTV', 'OVRST8', 
	'SHLX', 'SHLDE', 'LHLX', 'LHLDE',
);

# output tokens.h
print <<END;
/* generated by $0 - do not edit */
#pragma once
END

for my $i (0..$#tokens) {
	say sprintf("%-23s %d", "#define _TK_$tokens[$i]", $i);
}

print <<END;

#ifndef NO_TOKEN_ENUM
typedef enum tokid_t {
END

for my $i (0..$#tokens) {
	say sprintf("    %-19s = %d,", "TK_$tokens[$i]", $i);
}

print <<END;
} tokid_t;
#endif
END
