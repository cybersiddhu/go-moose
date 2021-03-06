#!/usr/bin/perl -w
# tests for the slimdown script

use strict;
use FileHandle;
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

use GOBO::Parsers::OBOParserDispatchHash;
use GOBO::Util::GraphFunctions;

use Storable;
use Test::More;
plan tests => 55;

my $verbose = $ENV{GO_VERBOSE} || 1;
$ENV{EXPERIMENTAL} = 1;
my $status;
my $parser;

# 1
$status = `perl bin/go-slimdown.pl -i t/data/obofile.obo -s test_goslim -o t/data/slimmer_test_results.obo 2>&1 1>/dev/null`;
like( $status, qr/Error: /, "Checking go-slimdown.pl with invalid input");

# 2
$status = `perl bin/go-slimdown.pl -i t/data/obo_file.obo -s test_goslim 2>&1 1>/dev/null`;
like( $status, qr/Error: /, "Checking go-slimdown.pl with no output");

# 3
$status = `perl bin/go-slimdown.pl -i t/data/obo_file.obo -o t/data/slimmer_test_results.obo 2>&1 1>/dev/null`;
like( $status, qr/Error: /, "Checking go-slimdown.pl with no slim");

# 4
$status = `perl bin/go-slimdown.pl -i t/data/obo_file.obo -s test_goslim -b t/data/myslimfile 2>&1 1>/dev/null`;
like( $status, qr/Error: /, "Checking go-slimdown.pl with incorrectly specified output");


# goslim not in file
# 5
$status = `perl bin/go-slimdown.pl -i t/data/obo_file.obo -s goslim_monster -o t/data/slimmer_test_results.obo 2>&1 1>/dev/null`;
like( $status, qr/Error: /, "Checking go-slimdown.pl with invalid subset");

# 6
# valid args
$status = system("perl", qw( bin/go-slimdown.pl -i t/data/obo_file.obo -s test_goslim -o t/data/slimmer_test_results.obo) );
die "go-slimdown.pl exited funny: $?" unless $status == 0;
# ok($status == 0, "Checking go-slimdown.pl with valid args");

## read in the graph, check it is ok
$parser = new GOBO::Parsers::OBOParserDispatchHash(file=>"t/data/slimmer_test_results.obo");
$parser->parse;

cmp_ok(testme($parser->graph, 'ontology_links', 1), "==", 1, "Checking slimmer_test_results.obo");
#die if testme($parser->graph) == 2;
system("rm", "t/data/slimmer_test_results.obo");
die ("Did not remove t/data/slimmer_test_results.obo properly!") if -e "t/data/slimmer_test_results.obo";

# 7
# OK, let's try a different slim now...
$status = system("perl", qw( bin/go-slimdown.pl -i t/data/obo_file.obo -s test_next_goslim -o t/data/slimmer_test_results.obo) );
die "go-slimdown.pl exited funny: $?" unless $status == 0;
# ok($status == 0, "Checking go-slimdown.pl with valid args -i t/data/obo_file.obo -s test_next_goslim -o t/data/slimmer_test_results.obo");

## read in the graph, check it is ok
undef $parser;
$parser = new GOBO::Parsers::OBOParserDispatchHash(file=>"t/data/slimmer_test_results.obo");
$parser->parse;

cmp_ok(testme($parser->graph, 'ontology_links', 2), "==", 1, "Checking slimmer_test_results.obo");
system("rm", "t/data/slimmer_test_results.obo");

die ("Did not remove t/data/slimmer_test_results.obo properly!") if -e "t/data/slimmer_test_results.obo";

# 8
# test a small subset
$status = `perl bin/go-slimdown.pl -i t/data/slimmer_test_2.obo -s gosubset_prok -o t/data/slimmer_test_results.obo 2>&1 1>/dev/null`;
like( $status, qr/Error: /, "Checking go-slimdown.pl with small subset");

# 9
# test again with the force mode on
$status = system("perl", qw( bin/go-slimdown.pl -f -i t/data/slimmer_test_2.obo -s gosubset_prok -o t/data/slimmer_test_results.obo ) );
die "go-slimdown.pl exited funny: $?" unless $status == 0;
#ok($status == 0, "Checking go-slimdown.pl with small subset and force mode on");

undef $parser;
$parser = new GOBO::Parsers::OBOParserDispatchHash(file=>"t/data/slimmer_test_results.obo");
$parser->parse;

cmp_ok(testme($parser->graph, 'ontology_links', 4), "==", 1, "Checking slimmer_test_results.obo");
system("rm", "t/data/slimmer_test_results.obo");

die ("Did not remove t/data/slimmer_test_results.obo properly!") if -e "t/data/slimmer_test_results.obo";

my $args = {
1 => [ qw(-s test_next_goslim -s test_goslim) ],
2 => [ qw(-s test_next_goslim test_goslim) ],
3 => [ '-a' ],
4 => [ qw(-r test) ],
5 => [ qw(-r test.+goslim) ],
};

# 10 - 44
# 7 tests per arg
foreach my $a (values %$args)
{	my $cmd;
	# invalid inputs
	# xxx, combined, no output
	$cmd = 'perl bin/go-slimdown.pl -i t/data/obo_file.obo ' . join(" ", @$a) . " --combined -b t/data/SLIMMER_TEST_SLIM_NAME.obo 2>&1 1>/dev/null";
	$status = `$cmd`;

	## 10
	like( $status, qr/Error: /, "Checking go-slimdown.pl with invalid params");

	# xxx, not combined, no basefile
	$cmd = 'perl bin/go-slimdown.pl -i t/data/obo_file.obo ' . join(" ", @$a) . " -o t/data/SLIMMER_TEST_results.obo 2>&1 1>/dev/null";
	$status = `$cmd`;

	## 11
	like( $status, qr/Error: /, "Checking go-slimdown.pl with invalid params");

#	$ENV{GO_VERBOSE} = 1;

	# valid inputs
	$status = system("perl", qw( bin/go-slimdown.pl -i t/data/obo_file.obo -b t/data/SLIMMER_TEST_SLIM_NAME.obo), @$a );

	## 12
	ok($status == 0, "Running go-slimdown.pl with args -i t/data/obo_file.obo -b t/data/SLIMMER_TEST_SLIM_NAME.obo " . join(" ", @$a) );

#undef $ENV{GO_VERBOSE};

	die "go-slimdown.pl exited funny: $?" unless $status == 0;

	# now test a combination of slims
	$status = system("perl", qw( bin/go-slimdown.pl -i t/data/obo_file.obo -o t/data/SLIMMER_TEST_results.obo --combined) , @$a );

	## 13
	ok($status == 0, "Running go-slimdown.pl with valid args -i t/data/obo_file.obo -o t/data/SLIMMER_TEST_results.obo --combined " . join(" ", @$a) );

	die "go-slimdown.pl exited funny: $?" unless $status == 0;

	## read in the graph, check it is ok
	undef $parser;
	$parser = new GOBO::Parsers::OBOParserDispatchHash(file=>"t/data/SLIMMER_TEST_test_goslim.obo");
	$parser->parse;

	## 14
	cmp_ok(testme($parser->graph, 'ontology_links', 1), "==", 1, "Checking SLIMMER_TEST_test_goslim.obo");

	if (testme($parser->graph, 'ontology_links', 1) != 1)
	{	die "Inference failed! Please check t/data/SLIMMER_TEST_test_goslim.obo";
	}

	## read in the graph, check it is ok
	undef $parser;
	$parser = new GOBO::Parsers::OBOParserDispatchHash(file=>"t/data/SLIMMER_TEST_test_next_goslim.obo");
	$parser->parse;

	## 15
	cmp_ok(testme($parser->graph, 'ontology_links', 2), "==", 1, "Checking SLIMMER_TEST_test_next_goslim.obo");

	if (testme($parser->graph, 'ontology_links', 2) != 1)
	{	die "Inference failed! Please check t/data/SLIMMER_TEST_test_next_goslim.obo";
	}

	## read in the graph, check it is ok
	undef $parser;
	$parser = new GOBO::Parsers::OBOParserDispatchHash(file=>"t/data/SLIMMER_TEST_results.obo");
	$parser->parse;

	## 16
	cmp_ok(testme($parser->graph, 'ontology_links', 3), "==", 1, "Checking SLIMMER_TEST_results.obo [combined]");

	if (testme($parser->graph, 'ontology_links', 3) != 1)
	{	die "Inference failed! Please check t/data/SLIMMER_TEST_results.obo";
	}

#	if (testme($parser->graph, 'ontology_links', 3) != 1)
#	{	system( "cp", "t/data/SLIMMER_TEST_results.obo", "t/data/wrong_SLIMMER_TEST_results.obo" );
#	}

	system("rm", "t/data/SLIMMER_TEST_results.obo");
	system("rm", "t/data/SLIMMER_TEST_test_goslim.obo");
	system("rm", "t/data/SLIMMER_TEST_test_next_goslim.obo");
	die ("Did not remove t/data/SLIMMER_TEST_*.obo properly!") if
		(-e "t/data/SLIMMER_TEST_results.obo" || -e "t/data/SLIMMER_TEST_test_goslim.obo" || -e "t/data/SLIMMER_TEST_test_next_goslim.obo");
}

## OK, let's do a slimming, create a mapping file, and then check
## load_mapping is ok
# make sure that there isn't already a mapping file in place...
if (-e "t/data/mapping_file.txt" || -e "t/data/mapping_file2.txt")
{	system("rm", "t/data/mapping_file.txt", "t/data/mapping_file2.txt");
	die "Mapping file still exists at t/data/mapping_file*" if -e "t/data/mapping_file.txt" || -e "t/data/mapping_file2.txt";
}

## test 45

# 45
$status = `perl bin/mapmaker.pl -i t/data/obofile.obo -s test_goslim -o t/data/mapping_file.txt 2>&1 1>/dev/null`;
like( $status, qr/Error: /, "Checking mapmaker.pl with invalid input");

# 46
$status = `perl bin/mapmaker.pl -i t/data/obo_file.obo -s test_goslim 2>&1 1>/dev/null`;
like( $status, qr/Error: /, "Checking mapmaker.pl with no output");

# 47
$status = `perl bin/mapmaker.pl -i t/data/obo_file.obo -o t/data/mapping_file.txt 2>&1 1>/dev/null`;
like( $status, qr/Error: /, "Checking mapmaker.pl with no slim");

# goslim not in file
# 48
$status = `perl bin/mapmaker.pl -i t/data/obo_file.obo -s goslim_monster -o t/data/mapping_file.txt 2>&1 1>/dev/null`;
like( $status, qr/Error: /, "Checking mapmaker.pl with invalid subset");

# 49
$status = `perl bin/mapmaker.pl -i t/data/obo_file.obo -s test_goslim -o t/data/mapping_file.txt -s test_next_goslim 2>&1 1>/dev/null`;
like( $status, qr/More than one subset was specified/, "Checking mapmaker.pl with too many subsets");

system("rm", "t/data/mapping_file.txt");
die "Mapping file still exists at t/data/mapping_file.txt" if -e "t/data/mapping_file.txt";

# 50
undef $status;
$status = system("perl", qw( bin/mapmaker.pl -i t/data/slimmer_test_3.obo -s test_goslim -o t/data/mapping_file.txt) );
ok($status == 0, "Checking mapmaker.pl with valid args");

## read in the mapping file
my $data = GOBO::Util::GraphFunctions::load_mapping( mapping_file => 't/data/mapping_file.txt' );

## the slim terms are in $data->{subset_term}
## closest terms are in data->{graph}
## other relations are in $data->{all}
## data->{termlist} contains all the terms in the graph

my $combos = {
	"1" => [ "is_a", ],
	"2" => [ "part_of", ],
	"3" => [ "regulates", ],
	"4" => [ "negatively_regulates", "regulates", ],
	"5" => [ "positively_regulates", "regulates", ],
	"6" => [ "has_part", ],

	"11" => [ "is_a", ],
	"12" => [ "part_of", ],
	"13" => [ "regulates", ],
	"14" => [ "negatively_regulates", "regulates", ],
	"15" => [ "positively_regulates", "regulates", ],
	"16" => [ "has_part", ],

	"21" => [ "part_of", ],
	"22" => [ "part_of", ],

	"31" => [ "regulates", ],
	"32" => [ "regulates", ],

	"41" => [ "negatively_regulates", "regulates", ],
	"42" => [ "regulates", ],

	"51" => [ "positively_regulates", "regulates", ],
	"52" => [ "regulates", ],

	"61" => [ "has_part", ],
	"66" => [ "has_part", ],
};

my @errs;
foreach my $t (sort keys %{$data->{termlist}})
{	my ($first, $last) = ((substr $t, -2, 1), (substr $t, -1));
	# PAD[12]_xx: closest is_a should be GO:00000xx
	# 00000xx: will have closest->{subset_term}{$t}
	# if $first == 0, term is connected only connected to 00
	# otherwise, we'll have a $combos->{$first} relationship to 0$last
	# and a $combos->{$first.$last} connection to 00
	my $expected;
	my $got;
	foreach my $r (keys %{$data->{graph}{$t}})
	{	map { $got->{$r . " " . $_} = 1 } keys %{$data->{graph}{$t}{$r}};
	}
	foreach my $r (keys %{$data->{all}{$t}})
	{	map { $got->{$r . " " . $_} += 10 } keys %{$data->{all}{$t}{$r}};
	}
	if ($data->{subset_term}{$t})
	{	$got->{is_subset_term}++;
	}

	if ($t =~ /PAD/)
	{	$expected->{"is_a" . " " . 'GO:00000' . $first . $last } = 11;
	}
	else
	{	$expected->{is_subset_term}++;
	}

	if ($first && $first != '0')
	{	# the link to 0.$last will be $combos->{$first}
		foreach (@{$combos->{$first}})
		{	$expected->{$_ . " GO:00000" . '0'.$last}++;
		}

		# the link to the root will be $combos->{$first.$last}
		if ($combos->{$first.$last})
		{	foreach (@{$combos->{$first.$last}})
			{	$expected->{$_ . " GO:0000000"}++;
			}
		}
	}
	else
	{	## IDs are xxxxx0n
		foreach (@{$combos->{$last}})
		{	$expected->{$_ . " GO:00000" . '00'} = 11 if $t =~ /PAD/;
			$expected->{$_ . " GO:00000" . '00'}++;
		}
	}

#	print STDERR "$t expected: " . Dumper($expected) . "got: " . Dumper($got) . "\n\n";

	# now compare the keys...
	foreach (keys %$expected)
	{	if ($got->{$_})
		{	delete $expected->{$_};
			delete $got->{$_};
		}
	}

	if ($expected && keys %$expected)
	{	foreach (keys %$expected)
		{	push @errs, "Error: found $t $_";
		}
	}
	if ($got && keys %$got)
	{	foreach (keys %$got)
		{	push @errs, "Error: lost  $t $_";
		}
	}
}

## 51
ok(! @errs, "Checking that mapmaking worked...");
if (@errs)
{	print STDERR "Found the following errors!\n" . join("\n", @errs) . "\n";
}

# 52: use a text file and term regexp
$status = system("perl", qw( bin/mapmaker.pl -i t/data/slimmer_test_3.obo -o t/data/mapping_file2.txt -t t/data/slimmer_test_3.obo -r GO:0000.+) );
die "go-slimdown.pl exited funny: $?" unless $status == 0;

ok( nodiff("t/data/mapping_file.txt","t/data/mapping_file2.txt"), "Checking results with a term regexp as input");


system("rm", "t/data/mapping_file.txt");
die "Mapping file still exists at t/data/mapping_file.txt" if -e "t/data/mapping_file.txt";

# 53, 54
# using the exciting obo_file.obo...
$status = system("perl", qw( bin/mapmaker.pl -i t/data/obo_file.obo -s test_goslim -o t/data/mapping_file.txt) );
die "go-slimdown.pl exited funny: $?" unless $status == 0;

## read in the mapping file
$data = GOBO::Util::GraphFunctions::load_mapping_as_graph( mapping_file => 't/data/mapping_file.txt' );
## run tests here!
#print STDERR "data: " . Dumper($data);

my $s = 5;
foreach my $ix qw(closest all)
{	cmp_ok(testme($data, $ix, $s), "==", 1, "Checking $ix links...");
	$s++;
}

# 55: use a term list as input
$status = system("perl", qw( bin/mapmaker.pl -i t/data/obo_file.obo -t t/data/test_goslim_termlist.txt -o t/data/mapping_file2.txt) );
die "go-slimdown.pl exited funny: $?" unless $status == 0;

ok( nodiff("t/data/mapping_file.txt","t/data/mapping_file2.txt"), "Checking results with a term list as input");

system("rm", "t/data/mapping_file.txt", "t/data/mapping_file2.txt");
die "Mapping file still exists at t/data/mapping_file.txt or t/data/mapping_file2.txt" if -e "t/data/mapping_file.txt" || -e "t/data/mapping_file2.txt";


exit(0);



=cut

GO:0000001 --[is_a]-->GO:0000008
GO:0000001 --[part_of]-->GO:0000008
GO:0000001 --[regulates]-->GO:0000008

GO:0000002 --[is_a]-->GO:0000006
GO:0000002 --[is_a]-->GO:0000007
GO:0000002 --[part_of]-->GO:0000011


GO:0000003 --[part_of]-->GO:0000007
GO:0000003 --[part_of]-->GO:0000011

GO:0000004 --[is_a]-->GO:0000012
GO:0000004 --[negatively_regulates]-->GO:0000016
GO:0000004 --[positively_regulates]-->GO:0000015

GO:0000005 --[regulates]-->GO:0000008

GO:0000006 --[is_a]-->GO:0000009

GO:0000007 --[part_of]-->GO:0000011

GO:0000008 --[negatively_regulates]-->GO:0000010

GO:0000009 --[is_a]-->GO:0000010

GO:0000010 --[is_a]-->GO:0000018

GO:0000011 --[is_a]-->GO:0000010

GO:0000012 --[is_a]-->GO:0000013

GO:0000013 --[is_a]-->GO:0000014

GO:0000014 --[is_a]-->GO:0000018

GO:0000015 --[part_of]-->GO:0000014

GO:0000016 --[is_a]-->GO:0000014

GO:0000017 --[is_a]-->GO:0000019

GO:0000018 --[is_a]-->GO:0000019

GO:0000021 --[is_a]-->GO:0000019

GO:0000022 --[is_a]-->GO:0000021

GO:0000023 --[is_a]-->GO:0000022

GO:0000024 --[is_a]-->GO:0000023
GO:0000024 --[part_of]-->GO:0000025

GO:0000025 --[part_of]-->GO:0000019

negatively_regulates --[is_a]-->regulates
positively_regulates --[is_a]-->regulates

GS terms:

test_goslim
GO:0000001
GO:0000002
GO:0000003
GO:0000004
GO:0000005
GO:0000006
GO:0000007
GO:0000010
GO:0000014
GO:0000015
GO:0000020
GO:0000024
GO:0000025

test_next_goslim
GO:0000001
GO:0000002
GO:0000003
GO:0000005
GO:0000008
GO:0000013
GO:0000021

gosubset_prok
GO:0000001
GO:0000002
GO:0000004

GO:0000019 is root

rlns we should therefore have:

GO:0000001 is_a GO:0000008 negatively_regulates GO:0000010       neg regs
GO:0000001 part_of GO:0000008 negatively_regulates GO:0000010    regs
GO:0000001 regulates GO:0000008 negatively_regulates GO:0000010  no rln
GO:0000002 is_a GO:0000006                                       is a
GO:0000002 is_a GO:0000007                                       is a
GO:0000002 is_a GO:0000007 part_of GO:0000011 is_a GO:0000010    part of (RED)
GO:0000003 part_of GO:0000007                                    part of
GO:0000004 is_a GO:0000012 is_a GO:0000013 is_a GO:0000014       is a
GO:0000004 pos_regs GO:0000015                                   pos regs
GO:0000004 neg_regulates GO:0000016 is_a GO:0000014              neg regs
GO:0000005 regulates GO:0000008 negatively_regulates GO:0000010  no rln
GO:0000006 is_a GO:0000010                                       is a
GO:0000007 part_of GO:0000011 is_a GO:0000010                    part of
GO:0000010 is_a GO:0000018 is_a GO:0000019                       is a
GO:0000014 is_a GO:0000018 is_a GO:0000019                       is a
GO:0000015 part_of GO:0000014                                    part of
GO:0000024 is_a ... is_a GO:0000021 is_a GO:0000019              is a
GO:0000024 part_of GO:0000025                                    part of
GO:0000025 part_of GO:0000019                                    part of


GO:0000001 is_a GO:0000008
GO:0000001 part_of GO:0000008
GO:0000001 regulates GO:0000008
	negatively_regulates GO:0000010
	is_a GO:0000018
	is_a GO:0000019
==> GO:0000001 neg_regs(, regs) GO:0000019 (RED)


GO:0000002 is_a GO:0000006
	is_a GO:0000009
	is_a GO:0000010
GO:0000002 is_a GO:0000007
	part_of GO:0000011
	is_a GO:0000010
==> GO:0000002 is_a, part_of GO:0000019

GO:0000004 is_a GO:0000012
	is_a GO:0000013
	is_a GO:0000014
	is_a GO:0000018
GO:0000004 positively_regulates GO:0000015
	part_of GO:0000014
GO:0000004 negatively_regulates GO:0000016
	is_a GO:0000014
GO:0000004 is_a, neg_regs(, regs) GO:0000019


=cut

sub testme {
	my $g = shift;
	my $ix = shift; # index name
	my $n = shift;  # test number

my $answers;

## test_goslim
$answers->{1}{"GO:0000001"}{negatively_regulates}{"GO:0000010"} = 1;
$answers->{1}{"GO:0000002"}{is_a}{"GO:0000006"} = 1;
$answers->{1}{"GO:0000002"}{is_a}{"GO:0000007"} = 1;
# $answers->{1}{"GO:0000002"}{part_of}{"GO:0000010"} = 1; REDUNDANT
$answers->{1}{"GO:0000003"}{part_of}{"GO:0000007"} = 1;
$answers->{1}{"GO:0000004"}{is_a}{"GO:0000014"} = 1;
$answers->{1}{"GO:0000004"}{negatively_regulates}{"GO:0000014"} = 1;
$answers->{1}{"GO:0000004"}{positively_regulates}{"GO:0000015"} = 1;
$answers->{1}{"GO:0000006"}{is_a}{"GO:0000010"} = 1;
$answers->{1}{"GO:0000007"}{part_of}{"GO:0000010"} = 1;
$answers->{1}{"GO:0000010"}{is_a}{"GO:0000019"} = 1;
$answers->{1}{"GO:0000014"}{is_a}{"GO:0000019"} = 1;
$answers->{1}{"GO:0000015"}{part_of}{"GO:0000014"} = 1;
$answers->{1}{"GO:0000024"}{is_a}{"GO:0000019"} = 1;
$answers->{1}{"GO:0000024"}{part_of}{"GO:0000025"} = 1;
$answers->{1}{"GO:0000025"}{part_of}{"GO:0000019"} = 1;
# $answers->{"GO:0000001"}{regulates}{"GO:0000010"} = 1;
# $answers->{"GO:0000004"}{regulates}{"GO:0000015"} = 1;
# $answers->{"GO:0000004"}{regulates}{"GO:0000014"} = 1;
#$answers->{negatively_regulates}{is_a}{regulates} = 1;
#$answers->{positively_regulates}{is_a}{regulates} = 1;


## test_next_goslim
$answers->{2}{"GO:0000001"}{regulates}{"GO:0000008"} = 1;
$answers->{2}{"GO:0000001"}{is_a}{"GO:0000008"} = 1;
$answers->{2}{"GO:0000001"}{part_of}{"GO:0000008"} = 1;
# $answers->{2}{"GO:0000001"}{negatively_regulates}{"GO:0000019"} = 1; REDUNDANT
$answers->{2}{"GO:0000002"}{is_a}{"GO:0000019"} = 1;
$answers->{2}{"GO:0000002"}{part_of}{"GO:0000019"} = 1;
$answers->{2}{"GO:0000003"}{part_of}{"GO:0000019"} = 1;
$answers->{2}{"GO:0000005"}{regulates}{"GO:0000008"} = 1;
$answers->{2}{"GO:0000008"}{negatively_regulates}{"GO:0000019"} = 1;
$answers->{2}{"GO:0000013"}{is_a}{"GO:0000019"} = 1;
$answers->{2}{"GO:0000021"}{is_a}{"GO:0000019"} = 1;

## combined
$answers->{3}{"GO:0000001"}{is_a}{"GO:0000008"} = 1;
$answers->{3}{"GO:0000001"}{part_of}{"GO:0000008"} = 1;
$answers->{3}{"GO:0000001"}{regulates}{"GO:0000008"} = 1;
# $answers->{3}{"GO:0000001"}{negatively_regulates}{"GO:0000010"} = 1; REDUNDANT
$answers->{3}{"GO:0000002"}{is_a}{"GO:0000006"} = 1;
$answers->{3}{"GO:0000002"}{is_a}{"GO:0000007"} = 1;
# $answers->{3}{"GO:0000002"}{part_of}{"GO:0000010"} = 1; REDUNDANT
$answers->{3}{"GO:0000003"}{part_of}{"GO:0000007"} = 1;
$answers->{3}{"GO:0000004"}{is_a}{"GO:0000013"} = 1;
$answers->{3}{"GO:0000004"}{negatively_regulates}{"GO:0000014"} = 1;
$answers->{3}{"GO:0000004"}{positively_regulates}{"GO:0000015"} = 1;
$answers->{3}{"GO:0000005"}{regulates}{"GO:0000008"} = 1;
$answers->{3}{"GO:0000006"}{is_a}{"GO:0000010"} = 1;
$answers->{3}{"GO:0000007"}{part_of}{"GO:0000010"} = 1;
$answers->{3}{"GO:0000008"}{negatively_regulates}{"GO:0000010"} = 1;
$answers->{3}{"GO:0000010"}{is_a}{"GO:0000019"} = 1;
$answers->{3}{"GO:0000013"}{is_a}{"GO:0000014"} = 1;
$answers->{3}{"GO:0000014"}{is_a}{"GO:0000019"} = 1;
$answers->{3}{"GO:0000015"}{part_of}{"GO:0000014"} = 1;
$answers->{3}{"GO:0000021"}{is_a}{"GO:0000019"} = 1;
$answers->{3}{"GO:0000024"}{is_a}{"GO:0000021"} = 1;
$answers->{3}{"GO:0000024"}{part_of}{"GO:0000025"} = 1;
$answers->{3}{"GO:0000025"}{part_of}{"GO:0000019"} = 1;


## gosubset_prok
$answers->{4}{"GO:0000001"}{negatively_regulates}{"GO:0000019"} = 1;
#$answers->{4}{"GO:0000001"}{regulates}{"GO:0000019"} = 1;
$answers->{4}{"GO:0000002"}{is_a}{"GO:0000019"} = 1;
$answers->{4}{"GO:0000002"}{part_of}{"GO:0000019"} = 1;
$answers->{4}{"GO:0000004"}{is_a}{"GO:0000019"} = 1;
$answers->{4}{"GO:0000004"}{negatively_regulates}{"GO:0000019"} = 1;
#$answers->{4}{"GO:0000004"}{regulates}{"GO:0000019"} = 1;

## mapping of all terms to test_goslim, closest links only

$answers->{5} = Storable::dclone $answers->{1};
$answers->{5}{"GO:0000008"}{negatively_regulates}{"GO:0000010"} = 1;
$answers->{5}{"GO:0000009"}{is_a}{"GO:0000010"} = 1;
$answers->{5}{"GO:0000011"}{is_a}{"GO:0000010"} = 1;
$answers->{5}{"GO:0000012"}{is_a}{"GO:0000014"} = 1;
$answers->{5}{"GO:0000013"}{is_a}{"GO:0000014"} = 1;
$answers->{5}{"GO:0000016"}{is_a}{"GO:0000014"} = 1;
$answers->{5}{"GO:0000017"}{is_a}{"GO:0000019"} = 1;
$answers->{5}{"GO:0000018"}{is_a}{"GO:0000019"} = 1;
$answers->{5}{"GO:0000021"}{is_a}{"GO:0000019"} = 1;
$answers->{5}{"GO:0000022"}{is_a}{"GO:0000019"} = 1;
$answers->{5}{"GO:0000023"}{is_a}{"GO:0000019"} = 1;

## mapping of all terms to test_goslim, all links
$answers->{6} = Storable::dclone $answers->{5};

$answers->{6}{"GO:0000001"}{regulates}{"GO:0000010"} = 1;
$answers->{6}{"GO:0000001"}{negatively_regulates}{"GO:0000019"} = 1;
$answers->{6}{"GO:0000001"}{regulates}{"GO:0000019"} = 1;
$answers->{6}{"GO:0000002"}{part_of}{"GO:0000010"} = 1;
$answers->{6}{"GO:0000002"}{is_a}{"GO:0000010"} = 1;
$answers->{6}{"GO:0000002"}{part_of}{"GO:0000019"} = 1;
$answers->{6}{"GO:0000002"}{is_a}{"GO:0000019"} = 1;
$answers->{6}{"GO:0000003"}{part_of}{"GO:0000007"} = 1;
$answers->{6}{"GO:0000003"}{part_of}{"GO:0000010"} = 1;
$answers->{6}{"GO:0000003"}{part_of}{"GO:0000019"} = 1;
$answers->{6}{"GO:0000004"}{is_a}{"GO:0000014"} = 1;
$answers->{6}{"GO:0000004"}{negatively_regulates}{"GO:0000014"} = 1;
$answers->{6}{"GO:0000004"}{regulates}{"GO:0000014"} = 1;
$answers->{6}{"GO:0000004"}{is_a}{"GO:0000019"} = 1;
$answers->{6}{"GO:0000004"}{negatively_regulates}{"GO:0000019"} = 1;
$answers->{6}{"GO:0000004"}{regulates}{"GO:0000019"} = 1;
$answers->{6}{"GO:0000004"}{positively_regulates}{"GO:0000015"} = 1;
$answers->{6}{"GO:0000004"}{regulates}{"GO:0000015"} = 1;
$answers->{6}{"GO:0000015"}{part_of}{"GO:0000019"} = 1;
$answers->{6}{"GO:0000016"}{is_a}{"GO:0000019"} = 1;
$answers->{6}{"GO:0000006"}{is_a}{"GO:0000019"} = 1;
$answers->{6}{"GO:0000007"}{part_of}{"GO:0000019"} = 1;
$answers->{6}{"GO:0000008"}{negatively_regulates}{"GO:0000019"} = 1;
$answers->{6}{"GO:0000008"}{regulates}{"GO:0000019"} = 1;
$answers->{6}{"GO:0000008"}{regulates}{"GO:0000010"} = 1;
$answers->{6}{"GO:0000009"}{is_a}{"GO:0000019"} = 1;
$answers->{6}{"GO:0000010"}{is_a}{"GO:0000019"} = 1;
$answers->{6}{"GO:0000011"}{is_a}{"GO:0000019"} = 1;
$answers->{6}{"GO:0000012"}{is_a}{"GO:0000019"} = 1;
$answers->{6}{"GO:0000013"}{is_a}{"GO:0000019"} = 1;
$answers->{6}{"GO:0000014"}{is_a}{"GO:0000019"} = 1;
$answers->{6}{"GO:0000015"}{part_of}{"GO:0000019"} = 1;
$answers->{6}{"GO:0000016"}{is_a}{"GO:0000019"} = 1;
$answers->{6}{"GO:0000024"}{is_a}{"GO:0000019"} = 1;
$answers->{6}{"GO:0000024"}{part_of}{"GO:0000019"} = 1;


	my $summary;
	my $ans;
	map {
		my $t = $_;
		map {
			my $r = $_;
			map {
				$ans->{$t}{$r}{$_} = 1
				} keys %{$answers->{$n}{$t}{$r}};
			} keys %{$answers->{$n}{$t}};
		} keys %{$answers->{$n}};

	foreach my $t (sort { $a->id cmp $b->id } @{$g->terms})
	{	#my @links = @{ $infeng->get_inferred_outgoing_links($t) };
		my @links = @{ $g->get_outgoing_statements_in_ix(ix=>$ix, node_id=>$t->id) };

#		print STDERR "links for " . $t->id . ": " . Dumper( \@links );

		foreach (sort { $a->target->id cmp $b->target->id } @links)
		{
#			print STDERR "\nnode: " . $_->node->id . ", target: " . $_->target->id . "\n" if $verbose;

			if ($ans->{$_->node->id}
				&& $ans->{$_->node->id}{$_->relation->id}
				&& $ans->{$_->node->id}{$_->relation->id}{$_->target->id} )
			{	# found the correct answer :D

#				print STDERR $_->node->id .": looking for ". join(" or ", keys %{$ans->{$_->node->id}} ) . ", found " . $_->relation->id . "\n" if $verbose;

				delete $ans->{$_->node->id}{$_->relation->id}{$_->target->id};

				if (! keys %{$ans->{$_->node->id}{$_->relation->id}})
				{	delete $ans->{$_->node->id}{$_->relation->id};
				}

				if (! keys %{$ans->{$_->node->id}})
				{	delete $ans->{$_->node->id};
				}
			}
			else
			{	# shouldn't have found a relation
#				print STDERR $_->node->id .": found " . $_->relation->id . " " . $_->target->id . ", incorrect!\n" if $verbose;
				$summary->{$_->node->id}{$_->relation->id}{$_->target->id}++;
			}
		}
	}

#	ok(! keys %{$ans->}, "Checking we have no results left");

#	if ($verbose)
	if (keys %$ans || keys %$summary)
	{	if (keys %$ans)
		{	print STDERR "Missing the following inferences:\n";
			foreach my $t1 (sort keys %$ans)
			{	foreach my $r (sort keys %{$ans->{$t1}})
				{	map { print STDERR "$t1 $r $_\n" } sort keys %{$ans->{$t1}{$r}};
				}
			}
		}
		if (keys %$summary)
		{	print STDERR "Made the following incorrect inferences:\n";
			foreach my $t1 (sort keys %$summary)
			{	foreach my $r (sort keys %{$summary->{$t1}})
				{	map { print STDERR "$t1 $r $_\n" } sort keys %{$summary->{$t1}{$r}};
				}
			}
		}
		return 2;
	}
	return 1;
}

sub nodiff {
	my ($f1,$f2) = @_;
	my $diff = `diff -I "Mapping file of terms to " -b $f1 $f2`;
	print $diff;
	return !$diff;
}

