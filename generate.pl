#!/usr/bin/perl -w

use DBD::Pg;

use File::Slurp;
use Data::Dumper;
use Algorithm::MarkovChain;

my @in   = read_file( "processed/the-archers.dat" );
my @lovecraft   = read_file( "processed/lovecraft.dat" );
my @names= read_file( "name-substitutions.txt" );

$| = 1;

my      $dbh= DBI->connect("dbi:Pg:dbname=ambcraft;host=localhost", "ambcraft", "Brianftaghn" );
my $stmt = $dbh->prepare( "INSERT INTO ambridge_quotes ( text ) VALUES (?)" );

my $lovecraft_score = {};
my $archers_score   = {};

for my $i (@lovecraft) {
	my @s=split(/\s+/, $i );
	for my $s (@s) {
		$s=~ s/\s//g;
		$s=~ s/\n//g;
		${$lovecraft_score}{$s} = 1;
	}
}
for my $i (@in) {
	my @s=split(/\s+/, $i );
	for my $s (@s) {
		$s=~ s/\s//g;
		$s=~ s/\n//g;
		delete ${$lovecraft_score}{$s};
		${$archers_score}{$s} = 1;
	}
}
for my $i (@lovecraft) {
	my @s=split(/\s+/, $i );
	for my $s (@s) {
		$s=~ s/\s//g;
		$s=~ s/\n//g;
		delete ${$archers_score}{$s};
	}
}


#print Dumper( $lovecraft_score );
#print Dumper( $archers_score );
#exit 0;

my @badend = ( 'a', 'and', 'the' , 'to',  'she' );

push(@in, @lovecraft);
    my $chain = Algorithm::MarkovChain::->new();
    $chain->seed(symbols => \@in ); #, longest => 6);
    print "About to spew ...\n";
    print "---\n\n";
    foreach (1 .. 200) {
				my $PHRASE="";
        my @newness = $chain->spew(length   => 40
                                  , complete => [ ( "--\n" ) ]
				);
        my $let = join (" ", @newness);
				$let =~ s/^--//;
				$let =~ s/\n//g;
				$let =~ s/\.[^.]*$/./g;
				$let =~ s/\./\.\n/g;
				$let =~ s/--/.\n/g;

				my $hadsubst=0;

#				while( $let =~ /%C/ ) {
#					my $name = $names[rand @names];
#					chomp($name);
#					$let =~ s/%C/$name/;
#					$hadsubst=1;
#				}
		if( $let =~ /%C/ ) { $hadsubst=1; }

				my @rot= split(/\.\n/, $let );
				for my $p (@rot ) {
					$p =~ s/^\s+//;
					$p =~ s/\s+$//;
					$p = "$p.";
					foreach my $bad (@badend) {
						if( $p =~ / $bad\.$/ ) { $p="."; }
					}
					if( ! ($p eq ".") ) {
						$PHRASE = "$PHRASE $p";
						if( $hadsubst == 1 ) {
					
#if( length($PHRASE)>100 ) { # && length($PHRASE) <120 ) {			
							my @xx = split(/\s+/, $PHRASE );
							my $score_archers=0;
							my $score_lovecraft=0;
							foreach my $h (@xx) {
								$h =~ s/\s//g;
								if( exists ${$lovecraft_score}{$h} ) { $score_lovecraft += ${$lovecraft_score}{$h}; }#  print "LSCORE $h ${$lovecraft_score}{$h}\n"; }
								if( exists ${$archers_score}{$h} ) { $score_archers += ${$archers_score}{$h}; }#print "ASCORE $h ${$archers_score}{$h}\n"; }
							}
							if( $score_lovecraft>0 && $score_archers>0 ) {
								print "[$PHRASE] [ L=$score_lovecraft A=$score_archers ]\n\n";
$stmt->execute( $PHRASE );
							}
}
							$PHRASE="";

#						}
					}
				}
    }


#print "@out ";

#for my $l (@in) {
#	my @tok = split( /\s+/, $l );
#	for my $i ( @tok ) {
#		if( $i =~ /^[A-Z]/ ) {
#			my $red = $i;
#		$red =~ s/&quot//g;
#			$red =~ s/<.*>//g;
#			$red =~ s/\(//g;
#			$red =~ s/\)//g;
#			$red =~ s/\.$//g;
#			$red =~ s/\!$//g;
#			$red =~ s/\?//g;
#			$red =~ s/,$//g;
#			$red =~ s/:$//g;
#			$red =~ s/;$//g;
#			$red =~ s/'\w+$//g;
#			$red =~ s/'.*$//g;
#			${$names}{ $red } ++;
#		}
#	}
#
#}
#

#print Dumper($names);

