#!/usr/bin/env perl

use Modern::Perl;
use YAML::Tiny;

my $yaml = YAML::Tiny->read("opcodes.yaml");
my %opcodes = %{$yaml->[0]};

my @test;
my %all_opcodes;

my @CPUS = sort keys %{$opcodes{"nop"}};

# dump cpu_ok and cpu_ixiy_ok
for my $ixiy ("", "_ixiy") {
	for my $cpu (@CPUS) {
		for my $ez80_adl (0 .. ($cpu eq 'ez80' ? 1 : 0)) {
			@test = ();
			
			if ($cpu eq 'ez80') {
				push @test, " .assume adl=$ez80_adl";
			}
			
			for my $asm (sort keys %opcodes) {
				my $asm_ixiy = $asm;
				if ($ixiy) {
					$asm_ixiy =~ s/\b(ix|iy)/$1 eq 'ix' ? 'iy' : 'ix'/eg;
				}
				
				if (exists $opcodes{$asm_ixiy}{$cpu}) {
					my @ops = @{$opcodes{$asm_ixiy}{$cpu}};
					my $do_code = 1;
					
					# handle {ADL0}? xxx : xxx
					if ($ops[0][0] eq '{ADL0}?') {
						my(@adl0, @adl1);
						shift @ops;
						while (@ops && $ops[0][0] ne ':') {
							push @adl0, shift @ops;
						}
						shift @ops;
						@adl1 = @ops;
						
						@ops = $ez80_adl ? @adl1 : @adl0;
					}
					# handle {ADLn}
					elsif ($ops[0][0] =~ /\{ADL(\d)\}/) {
						my $this_adl = $1;
						shift @ops;
						if (!!$this_adl != !!$ez80_adl) {
							$do_code = 0;
						}
					}
					
					if ($do_code) {
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
						
						(my $bytes = join(' ', @bytes)) =~ s/\s+$//;
						add($cpu, $asm, $bytes);
					}
				}
			}
			
			open(my $fh, ">", "cpu_test_${cpu}_adl${ez80_adl}${ixiy}_ok.asm") or die $!;
			say $fh join("\n", compute_labels(sort @test));
		}
	}
}

# dump cpu_error
for my $cpu (@CPUS) {
	for my $ez80_adl (0 .. ($cpu eq 'ez80' ? 1 : 0)) {
		@test = ();
		
		if ($cpu eq 'ez80') {
			push @test, " .assume adl=$ez80_adl";
			for my $asm (sort keys %opcodes) {
				if (exists $opcodes{$asm}{$cpu}) {
					my @ops = @{$opcodes{$asm}{$cpu}};
					if ($ops[0][0] =~ /^\{ADL(\d)\}$/) {
						my $this_adl = $1;
						if ($this_adl != $ez80_adl) {
							push @test, sprintf(" %-31s; Error", $asm)
						}
					}
				}
			}
		}
		
		for my $asm (keys %{$all_opcodes{ALL}}) {
			if (!exists $all_opcodes{$cpu}{$asm}) {
				my $skip = 0;

				# special case: 'djnz ASMPC' is translated to 'djnz NN' in 8080/8085
				if ($asm =~ /^(jr|djnz)/) {
					if ($cpu =~ /^80/) {
						$skip = 1 if $asm =~ /ASMPC/;	# DIS
					}
					else {
						$skip = 1 if $asm =~ /\d+/;		# nn
					}
				}

				# special case: ld hl, sp+%u vs ld hl, sp+%s
				$skip = 1 if $asm =~ /ld hl, sp[+-]/;
				
				# special case: 24-bit addresses only in ez80
				if ($cpu ne 'ez80' && $asm !~ /^\w+\.(s|l|is|il)/) {
					$skip = 1 if $asm =~ /0x123456/; # not call.il
				}
				
				push @test, sprintf(" %-31s; Error", $asm) unless $skip;
			}
		}
		
		open(my $fh, ">", "cpu_test_${cpu}_adl${ez80_adl}_err.asm") or die $!;
		say $fh join("\n", sort @test);
	}
}


sub add {
	my($cpu, $asm, $bytes) = @_;
	my @bytes = split ' ', $bytes;
	
	#say "$cpu\t$asm\t$bytes";
	
	# special case for intel: jr and djnz %j is converted to %m
	if ($cpu =~ /^80/ && $asm =~ /^(jr|djnz)/) {
		$asm =~ s/%j/%m/;
	}
	
	if ($asm =~ /rst(\.(s|sil|l|lis))? %c/) {
		for my $c (0..8,0x10,0x18,0x20,0x28,0x30,0x38) {
			my $asm1 = $asm =~ s/%c/$c/r;
			$c *= 8 if $c < 8;
			my @bytes1;
			for (split(' ', $bytes)) {
				if (s/%c/$c/) {
					push @bytes1, sprintf("%02X", eval($_)); 
				}
				else {
					push @bytes1, $_;
				}
			}
			my $bytes1 = join(' ', @bytes1);
			
			# rabit lacks these restarts
			if ($cpu =~ /^r/ && ($c==0 || $c==8 || $c==0x30)) {	
				$bytes1 = sprintf("CD %02X 00", $c);
			}
			
			add($cpu, $asm1, $bytes1);
		}
		
		# create error cases
		for my $c (-1, 9..15, 17..23, 25..31, 33..39, 41..47, 49..55, 57..64) {
			(my $asm1 = $asm) =~ s/%c/$c/;
			$all_opcodes{ALL}{$asm1} = 1;
		}
	}
	elsif ($asm =~ /^ldh .*\(c\)/) {
		add($cpu, $asm =~ s/\(c\)/( c )/r, $bytes);	# ( c ) to break recursion
		add($cpu, $asm =~ s/ldh /ld /r =~ s/\(c\)/(0xff00+c)/r, $bytes);
	}
	elsif ($asm =~ /^ldh .*\(%h\)/) {
		add($cpu, $asm =~ s/\(%h\)/( %h )/r, $bytes);	# ( %h ) to break recursion
		add($cpu, $asm =~ s/ldh /ld /r =~ s/\(%h\)/(0xff00+%h)/r, $bytes);
	}
	elsif ($asm =~ /%d/) {
		my $asm1 = $asm =~ s/\+%d/+126/r;
		my $bytes1 = $bytes =~ s/%d/7E/r =~ s/%D/7F/r;
		add($cpu, $asm1, $bytes1);
		
		$asm1 = $asm =~ s/\+%d/-128/r;
		$bytes1 = $bytes =~ s/%d/80/r =~ s/%D/81/r;
		add($cpu, $asm1, $bytes1);
	}
	elsif ($asm =~ /%u/) {
		my $asm1 = $asm =~ s/\+%u/+0/r;
		my $bytes1 = $bytes =~ s/%u/00/r;
		add($cpu, $asm1, $bytes1);
		
		$asm1 = $asm =~ s/\+%u/+255/r;
		$bytes1 = $bytes =~ s/%u/FF/r;
		add($cpu, $asm1, $bytes1);
	}
	elsif ($asm =~ /%s/) {
		my $asm1 = $asm =~ s/%s/-128/r;
		$asm1 =~ s/\+-/-/g;
		my $bytes1 = $bytes =~ s/%s 00/80 FF/r;
		$bytes1 =~ s/%s/80/;
		add($cpu, $asm1, $bytes1);
		
		$asm1 = $asm =~ s/%s/127/r;
		$bytes1 = $bytes =~ s/%s 00/7F 00/r;
		$bytes1 =~ s/%s/7F/;
		add($cpu, $asm1, $bytes1);
	}
	elsif ($asm =~ /%n/) {
		my $asm1 = $asm =~ s/%n/-128/gr;
		my $bytes1 = $bytes =~ s/%n/80/gr;
		add($cpu, $asm1, $bytes1);
		
		$asm1 = $asm =~ s/%n/127/gr;
		$bytes1 = $bytes =~ s/%n/7F/gr;
		add($cpu, $asm1, $bytes1);
		
		$asm1 = $asm =~ s/%n/255/gr;
		$bytes1 = $bytes =~ s/%n/FF/gr;
		add($cpu, $asm1, $bytes1);
	}
	elsif ($asm =~ /%h/) {
		my $asm1 = $asm =~ s/%h/0/gr;
		my $bytes1 = $bytes =~ s/%h/00/gr;
		add($cpu, $asm1, $bytes1);
		
		$asm1 = $asm =~ s/%h/127/gr;
		$bytes1 = $bytes =~ s/%h/7F/gr;
		add($cpu, $asm1, $bytes1);
		
		$asm1 = $asm =~ s/%h/255/gr;
		$bytes1 = $bytes =~ s/%h/FF/gr;
		add($cpu, $asm1, $bytes1);
	}
	elsif ($bytes =~ /%m %m %m/) {
		my $asm1 = $asm =~ s/%m/0x123456/r;
		my $bytes1 = $bytes =~ s/%m/56/r;
		$bytes1 = $bytes1 =~ s/%m/34/r;
		$bytes1 = $bytes1 =~ s/%m/12/r;
		add($cpu, $asm1, $bytes1);
	}
	elsif ($asm =~ /%m/) {
		my $asm1 = $asm =~ s/%m/-32768/r;
		my $bytes1 = $bytes =~ s/%m/00/r;
		$bytes1 = $bytes1 =~ s/%m/80/r;
		add($cpu, $asm1, $bytes1);
		
		$asm1 = $asm =~ s/%m/32767/r;
		$bytes1 = $bytes =~ s/%m/FF/r;
		$bytes1 = $bytes1 =~ s/%m/7F/r;
		add($cpu, $asm1, $bytes1);
		
		$asm1 = $asm =~ s/%m/65535/r;
		$bytes1 = $bytes =~ s/%m/FF/r;
		$bytes1 = $bytes1 =~ s/%m/FF/r;
		add($cpu, $asm1, $bytes1);
	}
	elsif ($asm =~ /%M/) {
		my $asm1 = $asm =~ s/%M/-32768/r;
		my $bytes1 = $bytes =~ s/%M/80/r;
		$bytes1 = $bytes1 =~ s/%M/00/r;
		add($cpu, $asm1, $bytes1);
		
		$asm1 = $asm =~ s/%M/32767/r;
		$bytes1 = $bytes =~ s/%M/7F/r;
		$bytes1 = $bytes1 =~ s/%M/FF/r;
		add($cpu, $asm1, $bytes1);
		
		$asm1 = $asm =~ s/%M/65535/r;
		$bytes1 = $bytes =~ s/%M/FF/r;
		$bytes1 = $bytes1 =~ s/%M/FF/r;
		add($cpu, $asm1, $bytes1);
	}
	elsif ($asm =~ /%j/) {
		my $asm1 = $asm =~ s/%j/ASMPC/r;
		my $dist = @bytes==3 ? "FD" : "FE";
		my $bytes1 = $bytes =~ s/%j/$dist/r;
		add($cpu, $asm1, $bytes1);
	}
	elsif ($asm =~ /%c/) {
		my $bytes1 = $bytes =~ s/%c\((\d+.*?\d+)\)/%c/r;
		my @range = eval($1); $@ and die $@;
		for my $c (@range) {
			my $asm2 = $asm =~ s/%c/$c/r;
			my @bytes2 = split(' ', $bytes1);
			for (@bytes2) {
				if (s/%c/$c/g) {
					$_ = sprintf("%02X", eval($_)); $@ and die $@;
				}
			}
			add($cpu, $asm2, "@bytes2");
		}
		
		# create error cases
		for my $c ($range[0]-1, $range[-1]+1) {
			(my $asm1 = $asm) =~ s/%c/$c/;
			$all_opcodes{ALL}{$asm1} = 1;
		}
	}
	else {
		push @test, sprintf(" %-31s; %s", $asm, $bytes);
		$all_opcodes{$cpu}{$asm} = 1;
		$all_opcodes{ALL}{$asm} = 1;
	}
}

sub compute_labels {
	my(@test) = @_;
	my $asmpc = 0;
	for (@test) {
		next if /\.assume/i;
		my($asm, $bytes) = split(/;/, $_, 2);
		my $num_bytes = scalar(split(' ', $bytes));
		$num_bytes++ if $bytes =~ /\@/;
		
		if ($bytes =~ /%t/) {
			my $target = $asmpc+6;
			$bytes =~ s/%t/sprintf("%02X", $target & 0xFF)/e;
			$bytes =~ s/%t/sprintf("%02X", $target >> 8)/e;
			$_ = "$asm;$bytes";
		}
		
		$asmpc += $num_bytes;
	}
	return @test;
}
