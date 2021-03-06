package GOBO::Writers::Writer;
use Moose;
use GOBO::Graph;
use FileHandle;

has fh => (
    is        => 'rw',
    isa       => 'FileHandle',
    clearer   => 'clear_fh',
    predicate => 'has_fh'
);    #, coerce=>1);
has file => ( is => 'rw', isa => 'Str', trigger => \&init_fh );
has graph => ( is => 'rw', isa => 'GOBO::Graph',  clearer => 'clear_graph' );

## indexes to use for the different types of statement
has 'statement_ix'  => ( is => 'rw', isa => 'Str', default => 'statements' );
has 'annotation_ix' => ( is => 'rw', isa => 'Str', default => 'annotations' );
has 'edge_ix'       => ( is => 'rw', isa => 'Str', default => 'edges' );
has 'ontology_link_ix' =>
    ( is => 'rw', isa => 'Str', default => 'ontology_links' );

has 'header_data' => (
    is      => 'rw',
    isa     => 'ArrayRef',
    traits  => [qw/Array/],
    default => sub { [] },
    handles => {
        add_to_header     => 'push',
        has_header_data   => 'count',
        clear_header_data => 'clear',
        get_header_data   => 'elements'

    }
);

## set up output;
sub BUILD {
    my $self = shift;
    $self->init_fh;
}

sub create {
    my $proto = shift;
    my %argh  = @_;
    my $fmt   = $argh{format};
    if ($fmt) {
        my $pc;
        if ( $fmt eq 'obo' ) {
            $pc = 'GOBO::Writers::OBOWriter';
        }
        elsif ( $fmt eq 'oboxml' ) {
            $pc = 'GOBO::Writers::OBOXMLWriter';
        }
        my $mod = $pc;
        $mod =~ s/::/\//g;
        require "$mod.pm";

        # TODO
        return $pc->new(%argh);
    }
}

sub init_fh {
    my $self = shift;
    if ( !$self->fh ) {
        my $f = $self->file;
        my $fh;
        if ($f) {
            $fh = FileHandle->new(">$f");
        }
        if ( !$fh ) {
            $fh = FileHandle->new(">-");
        }
        $self->fh($fh);
    }
}

sub xxxfile {
    my $self = shift;
    if (@_) {
        my ($f) = @_;
        $self->{file} = $f;
        $self->fh( FileHandle->new(">$f") );
    }

    return $self->{file};
}

sub write {
    my $self = shift;

    my %ah = @_;
    if ( $ah{graph} ) {
        $self->graph( $ah{graph} );
    }

    #    $self->init_fh;
    $self->write_header;
    $self->write_body;
}

sub printrow {
    my $self = shift;
    my $row  = shift;
    my $fh   = $self->fh;
    print $fh join( "\t", @$row ), "\n";
    return;
}

sub print {
    my $self = shift;
    my $fh   = $self->fh;
    print $fh @_;
    return;
}

sub println {
    my $self = shift;
    my $fh   = $self->fh;
    print $fh @_, "\n";
    return;
}

sub printf {
    my $self = shift;
    my $fmt  = shift;
    my $fh   = $self->fh;

    #if (grep {!defined($_)} @_) {
    #    confess "undefined value in @_";
    #}
    printf $fh $fmt, @_;
    return;
}

sub nl {
    my $self = shift;
    my $fh   = $self->fh;
    print $fh "\n";
    return;
}

__PACKAGE__->meta->make_immutable;

1;
