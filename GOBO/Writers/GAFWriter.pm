package GOBO::Writers::GAFWriter;
use Moose;
use strict;
extends 'GOBO::Writers::Writer';
use GOBO::Graph;

#use GOBO::Node;
#use GOBO::Gene;
#use GOBO::Evidence;
#use GOBO::Annotation;

sub write_header {
    my $self = shift;
    if ( $self->has_header_data ) {
        $self->fh->print( '! ' . $_ . "\n" ) for $self->get_header_data;
    }
    return;
}

sub write_annotation {
    my $self = shift;
    my $ann  = shift;

    my $gene         = $ann->node;
    my $gene_product = $ann->specific_node;
    my @vals         = (
        $gene->id_db,
        $gene->local_id,
        $gene->label,
        $ann->target->id,
        '',    # qualifiers
        join( '|',
            map {$_}
                ( @{ $ann->provenance->xrefs || [] }, $ann->provenance->id )
        ),
        $ann->evidence->ev_type->id,
        $ann->evidence->with_str,        # with,
        _aspect( $ann->target ),         # aspect
        '',                              # gene name
        $self->fetch_synonyms($gene),    # syn
        $gene->gp_type->id,              #
        $gene->taxon->id,                #
        $ann->date_compact,
        $ann->source->id,
        '',
        $gene_product ? $gene_product->id : ''
    );
    $self->printrow( \@vals );
    return;
}

sub fetch_synonyms {
    my ( $self, $gene ) = @_;
    if ( defined $gene->synonyms ) {
        return join( '|', map { $_->label } @{ $gene->synonyms } );
    }
}

sub write_body {
    my $self = shift;
    my $g    = $self->graph;

    foreach
        my $ann ( @{ $g->get_all_statements_in_ix( $self->annotation_ix ) } )
    {

        #    foreach my $ann (@{$g->annotations}) {
        $self->write_annotation($ann);
    }
    return;
}

sub _aspect {
    my $ns = shift->namespace || '';
    if    ( $ns eq 'molecular_function' ) {'F'}
    elsif ( $ns eq 'biological_process' ) {'P'}
    elsif ( $ns eq 'cellular_component' ) {'C'}
    else                                  {'-'}

}

__PACKAGE__->meta->make_immutable;

1;
