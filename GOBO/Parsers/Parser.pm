package GOBO::Parsers::Parser;
use Moose;
use Moose::Util::TypeConstraints;
use GOBO::Types;

use FileHandle;
use Carp;

#coerce 'GOBO::Parsers::Parser::ProtoFileHandle'
#	=> from 'Str'
#		=> via { FileHandle->new( $_ ) }
#	=> from 'FileHandle'
#		=> via { $_ };

has verbose => (is=>'rw', isa=>'Bool');
has input_record_separator => (is=>'rw', isa=>'Str', default => "\n");

has fh => (is=>'rw', isa=>'GOBO::Parsers::Parser::ProtoFileHandle', clearer=>'clear_fh', predicate=>'has_fh', writer=>'_set_fh', coerce => 1, init_arg => 'file', trigger => \&reset_temporary_variables );
has lines => (is=>'rw', isa=>'ArrayRef',default=>sub{[]});
has parsed_header => (is=>'rw', isa=>'Bool');

#has line_no => (is=>'rw', isa=>'Int', default=>sub{0});
#has stalled => (is=>'rw', isa=>'Bool');
#has max_chunk => (is=>'rw', isa=>'Int', init_arg => 'size', clearer=>'clear_max_chunk');

has data => (is=>'rw', isa => 'HashRef', clearer => 'clear_data');

has options => (is => 'rw', isa => 'HashRef|Undef', clearer => 'clear_all_options', trigger => \&check_options );
has checked_options => (is => 'rw', isa => 'Bool');

has liberal_mode => (is=>'rw', isa=>'Bool',default=>sub{1});
has verbose => (is=>'rw', isa=>'Bool',default=>sub{0});

sub BUILDARGS {
	my $class = shift;
	return $class->SUPER::BUILDARGS(@_) unless ( @_ );
	my %arg_h = ( @_ );

	if ( $arg_h{fh} ) {
		$arg_h{file} = $arg_h{fh};
		delete $arg_h{fh};
	}
	if ( $arg_h{file} )
	{	die "The file $arg_h{file} could not be found! " if ! -e $arg_h{file};
	}

	return \%arg_h;
}


=head1 NAME

GOBO::Parsers::Parser

=head1 SYNOPSIS

  my $p = GOBO::Parser->new;
  $p->parse_file(file => $file, options => $option_h);
  $g = $p->graph;

=head1 DESCRIPTION

Base class for all parsers. Parsers take formats (e.g. GOBO::Parsers::OBOParser) and generate objects, typically some combination of GOBO::Node and GOBO::Statement objects

=cut


=head2 parse_file

$parser->parse_file(file => '/path/to/file', options => $option_h)

input:  self
        file => $f_name    # either as /path/to/filename or a FileHandle object
        options => $opt_h  # a hash of options [optional]

The file will be parsed according to the options
This method does not return anything; instead, the parser object can be queried
for the results.

=cut

sub parse_file {
	my $self = shift;
	my %args;
	# allow parse_file('/path/to/file')
	if (scalar @_ == 1)
	{	$args{file} = shift;
	}
	else
	{	%args = (@_);
	}

	# initialize the fh
	$self->set_fh($args{file});
	$self->set_options($args{options}) if $args{options};

	# parse the file
	$self->_parse;

	return 1;
}


=head2 parse

$parser->parse(options => $option_h)

input:  self
        options => $opt_h  # a hash of options [optional]

Parse according to the options. Note that the file to be parsed should already
have been specified.

This method does not return anything; instead, the parser object can be queried
for the results.

=cut

sub parse {
	my $self = shift;
	confess "No file handle present!" unless $self->has_fh;

	my %args = (@_);
	$self->set_options($args{options}) if $args{options};

	return $self->_parse;
}

sub _parse {
	my $self = shift;
	return 0 unless $self->has_fh;

	# make sure we've checked our parser options
	$self->check_options;
	if ($self->parsed_header)
	{	#print STDERR "Header has been parsed!\n";
		#print STDERR "parser: " . $self->dump(2) . "\n";
	}
	else
	{	$self->parse_header;
	}
	$self->parse_body;

	# close the file handle
#	$self->fh->close if ! $self->stalled;
	return 1;
}



sub create {
	my $proto = shift;
	my %argh = @_;
	my $fmt = $argh{format};
	if ($fmt) {
		my $pc;
		if ($fmt eq 'obo') {
			$pc = 'GOBO::Parsers::OBOParser';
		}
		#require $pc;
		return $pc->new(%argh);
	}
}


=head2 set_file

$parser->set_file($f_name)

input:  self
        $f_name    # either as /path/to/filename or a FileHandle object

Set the parser to parse a certain file

=cut

sub set_file {
	my $self = shift;
	my $f = shift || die "No file specified! Dying";

	# clear the existing fh
	$self->clear_fh;

	# if there is an argument passed
	# is it a filehandle?
	if (ref $f && ref $f eq 'FileHandle')
	{	$self->_set_fh($f);
		return;
	}
	elsif (! ref $f)
	{	die "The file $f could not be found! " if ! -e $f;

		my $fh;
		if ($f =~ /\.gz$/) {
			$fh = FileHandle->new("gzip -dc $f |") or confess "Could not create a filehandle for $f: $! ";
		}
		else {
			$fh = FileHandle->new($f) or confess "Could not create a filehandle for $f: $! ";
		}
		$self->_set_fh($fh);
		return;
	}
	# uh-oh, no FH in sight! :o
	confess "Could not find create a filehandle!";
}
*set_fh = \&set_file;

sub next_line {
	my $self = shift;
	my $lines = $self->lines;
	if (@$lines) {
		return shift @$lines;
	}
	if ($self->fh)
	{	my $fh = $self->fh;
		my $string = do { local $/ = $self->input_record_separator; <$fh> } ;
		return $string;
	}
	return undef;
}

sub unshift_line {
	my $self = shift;
	unshift(@{$self->lines},@_);
	return;
}


=head2 set_options

input:	self, hash ref of options

Sets a hash of options, accessed by $self->options.

Existing options will remain intact.

=cut

sub set_options {
	my $self = shift;
	my $o = shift;
	my $options = $self->options;

	while ( my ( $k, $v ) = each %$o )
	{	$options->{$k} = $v;
	}

	if (! $options || ! keys %$options )
	{	$self->clear_all_options;
		return;
	}
	$self->options($options);
}

*set_option = \&set_options;


=head2 set_all_options

input:	self, hash ref of options

Sets a hash of options, accessed by $self->options.

Existing options are deleted.

=cut

sub set_all_options {
	my $self = shift;
	my $o = shift;

	$self->clear_all_options;

	if (! $o || ! keys %$o )
	{	return;
	}

	$self->set_options($o);

}



=head2 clear_options

input: self, arrayref of strings corresponding to keys in the 'options' hash

Removes key(s) from the options hash

=head2 clear_all_options

Delete everything from the options hash

=cut

sub clear_options {
	my $self = shift;
	my $o = shift;
	my $options = $self->options || {};

	# convert scalar to an array ref
	$o = [ $o ] if ! ref $o;

	foreach (@$o)
	{	delete $options->{$_};
	}

	if (! $options || ! keys %$options )
	{	$self->clear_all_options;
		return;
	}

	$self->options($options);

}

*clear_option = \&clear_options;


sub check_options {
	my $self = shift;
	$self->checked_options(1);
}

sub reset_checked_options {
	shift->checked_options(0);
}

=head2 reset_parser

$self->reset_parser

Removes the file handle, data, and options from the parser

=cut

sub reset_parser {
	my $self = shift;
	$self->clear_fh;
	$self->clear_all_options;
	$self->clear_data;
#	$self->clear_max_chunk;
	$self->reset_temporary_variables;
}


=head2 reset_temporary_variables

$self->reset_temporary_variables

These variables should be reset every time the parser is used on a new file

=cut

sub reset_temporary_variables {
	my $self = shift;
	$self->parsed_header(0);
#	$self->stalled(0);
#	$self->line_no(0);
	$self->checked_options(0);
}


__PACKAGE__->meta->make_immutable;

1;

