#!/usr/bin/env perl

use Modern::Perl;
use YAML::Tiny;
use Text::Table;
use Clone 'clone';

my $yaml = YAML::Tiny->read("opcodes.yaml");
my %opcodes = %{$yaml->[0]};

my $sep = \"|";

%opcodes = expand_ez80(expand_consts(%opcodes));
my $opcode_table = make_opcode_table(%opcodes);
my $hex_table = make_hex_table(%opcodes);

open(my $fh, ">", "opcodes.txt") or die $!;
print $fh $opcode_table->rule('=');
print $fh $opcode_table->title;
print $fh $opcode_table->rule('=');
print $fh $opcode_table->body;
print $fh $opcode_table->rule('=');
print $fh "\n\n";
print $fh $hex_table->rule('=');
print $fh $hex_table->title;
print $fh $hex_table->rule('=');
print $fh $hex_table->body;
print $fh $hex_table->rule('=');


sub expand_consts {
	my(%opcodes_in) = @_;
	my %opcodes_out;

	for my $asm (sort keys %opcodes_in) {
		for my $cpu (sort keys %{$opcodes_in{$asm}}) {
			my @ops = @{clone($opcodes_in{$asm}{$cpu})};
			
			if ($asm =~ /%c/) {
				my @range = find_range($asm, $cpu, @ops);
				for my $c (@range) {
					my($asm1, @ops1) = replace_const($c, $asm, @ops);
					if ($asm =~ /^rst/ && $cpu =~ /^r/ && 
					    ($c == 0 || $c == 8 || $c == 0x30)) {
						$opcodes_out{$asm1}{$cpu} = [[0xCD, $c, 0]];
					}
					else {    
						$opcodes_out{$asm1}{$cpu} = \@ops1;
					}
				}
			}
			else {
				$opcodes_out{$asm}{$cpu} = \@ops;
			}
		}
	}
	
	return %opcodes_out;
}	

sub expand_ez80 {
	my(%opcodes_in) = @_;
	my %opcodes_out;

	for my $asm (sort keys %opcodes_in) {
		for my $cpu (sort keys %{$opcodes_in{$asm}}) {
			my @ops = @{clone($opcodes_in{$asm}{$cpu})};

			if ($cpu =~ /ez80/) {
				if ($ops[0][0] eq '{ADL0}') {
					shift @ops;
					$opcodes_out{$asm}{ez80_z80} = clone(\@ops);
				}
				elsif ($ops[0][0] eq '{ADL1}') {
					shift @ops;
					$opcodes_out{$asm}{ez80} = clone(\@ops);
				}
				elsif ($ops[0][0] eq '{ADL0}?') {
					shift @ops;
					my(@adl0, @adl1);
					while ($ops[0][0] ne ':') {
						push @adl0, shift @ops;
					}
					shift @ops;
					@adl1 = @ops;
					
					$opcodes_out{$asm}{ez80_z80} = clone(\@adl0);
					$opcodes_out{$asm}{ez80} = clone(\@adl1);
				}
				else {
					$opcodes_out{$asm}{ez80_z80} = clone(\@ops);
					$opcodes_out{$asm}{ez80} = clone(\@ops);
				}
			}
			else {
				$opcodes_out{$asm}{$cpu} = clone(\@ops);
			}
		}
	}
			
	return %opcodes_out;
}
				
sub find_range {
	my($asm, $cpu, @ops) = @_;
	
	if ($asm =~ / rst (\.(s|sil|l|lis))? \s+ %c /x) {
		return (0x00, 0x08, 0x10, 0x18, 0x20, 0x28, 0x30, 0x38);
	}
	else {
		for my $op (@ops) {
			for my $byte (@$op) {
				if ($byte =~ / %c \( (\d+) \.\. (\d+) \) /x) {
					return ($1 .. $2);
				}
			}
		}
	}
	
	die "no range found in $asm, $cpu";
}

sub replace_const {
	my($c, $asm, @ops) = @_;

	my $c_str = ($asm =~ /^rst/ || $c >= 10) ? sprintf("%02Xh", $c) : $c;
	$asm =~ s/%c/$c_str/;
	
	@ops = @{clone(\@ops)};
	for my $op (@ops) {
		for my $byte (@$op) {
			if ($byte =~ s/ %c ( \( \d+ \.\. \d+ \) )? /$c/xg) {
				$byte = eval($byte); die "$byte: $@" if $@;
			}
			if ($byte =~ /^\d+$/) {
				$byte = sprintf("%02X", $byte);
			}
		}
	}
	
	return ($asm, @ops);
}
	
sub make_opcode_table {
	my(%opcodes) = @_;
	my $tb = Text::Table->new($sep, "Assembly", $sep, "CPUs", $sep);

	for my $asm (sort keys %opcodes) {
		my @cpus;
		for my $cpu (sort keys %{$opcodes{'nop'}}) {	# always exists
			if (exists $opcodes{$asm}{$cpu}) {
				push @cpus, $cpu;
			}
			else {
				push @cpus, "-".(" " x (length($cpu)-1));
			}
		}
		$tb->add($asm, "@cpus");
	}
	return $tb;
}

sub make_hex_table {
	my(%opcodes) = @_;
	my $tb = Text::Table->new($sep, "Assembly", $sep, "CPU", $sep, "Opcodes", $sep);

	for my $asm (sort keys %opcodes) {
		for my $cpu (sort keys %{$opcodes{$asm}}) {
			my @ops = @{$opcodes{$asm}{$cpu}};
			my @bytes;
			for my $op (@ops) {
				for my $byte (@$op) {
					next unless defined $byte;
					if ($byte =~ /^\d+$/) {
						push @bytes, sprintf("%02X", $byte);
					}
					else {
						push @bytes, $byte;
					}
				}
			}
			$tb->add($asm, $cpu, "@bytes");
		}
	}
	return $tb;
}

