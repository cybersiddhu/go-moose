=head1 NAME

OBO::InferenceEngine::GAFInferenceEngine

=head1 SYNOPSIS


=head1 DESCRIPTION

An OBO::InferenceEngine for making inferences over a GAF (Gene Association File).

=head2 Rules


=cut

package OBO::InferenceEngine::GAFInferenceEngine;
use Moose;
extends 'OBO::InferenceEngine';
use strict;
use OBO::Statement;
use OBO::Annotation;
use OBO::Graph;
use OBO::Node;
use OBO::TermNode;
use OBO::RelationNode;

has nodemap => (is=>'rw', isa=>'HashRef[OBO::Node]', default=>sub{{}});
has got_h => (is=>'rw', isa=>'HashRef[OBO::Node]', default=>sub{{}});

=head2 infer_annotations(ArrayRef[OBO::Annotation])

In the future this will be configurable.

For now there is only one kind of GAF inference:

=head3 Cross-ontology promotion

Given an annotation to an OBO::TermNode F, this will generate an IC
annotation to P, if it is possible to infer a F part_of P link AND the
inferred annotation is not redundant with either existing annotations
OR with another inference

=cut

sub infer_annotations {
    my $self = shift;
    my $anns = shift;
    my $ontg = $self->graph;
    my $nodemap = $self->nodemap;
    my $got_h = $self->got_h;
    my @ics = ();
    foreach my $ann (@$anns) {
        my $t = $ann->target;
        my $tid = $t->id;
        my $t_ns = $t->namespace;
        my $gene = $ann->node;
        if (!$nodemap->{$tid}) {
            #print STDERR "building nodemap for $tid\n";
            my $xlinks = $self->get_inferred_target_links($t);
            my %candidate_h = ();
            foreach my $xlink (@$xlinks) {
                next unless $xlink->relation->id eq 'part_of';
                next unless $xlink->target->namespace ne $t_ns;
                $candidate_h{$xlink->target->id} = 1;
                #print STDERR " xlink: $xlink\n";
            }
            #printf STDERR " candidates for $tid: %s\n", join('; ', keys %candidate_h);
            
            # TODO: throw in existing annotations for this gene..?
            $nodemap->{$tid} =
                $self->get_nonredundant_set([keys %candidate_h]);
        }
        if (@{$nodemap->{$tid}}) {
            if (!$got_h->{$gene}{$t}) {
                push(@ics, 
                     map {
                         printf STDERR "inferred $tid --> %s\n", $ontg->term_noderef($_);
                         new OBO::Annotation(node => $gene,
                                             target => $ontg->term_noderef($_),
                                             provenance => $ann->provenance,
                                             evidence => new OBO::Evidence(type=>$ontg->term_noderef('IC'),
                                                                           supporting_entities => [$t]),
                                             
                                             source=>'GOC',
                                             date=>DateTime->today)
                     } @{$nodemap->{$tid}});
                #printf STDERR "$gene $t\n";
            }
            $got_h->{$gene}{$t} = 1;
        }
        
    }
    return [@ics];
}

1;

=head1 SEE ALSO

  bin/go-gaf-inference.pl

=cut
