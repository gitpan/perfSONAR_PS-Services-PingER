package  perfSONAR_PS::Datatypes::v2_0::pingertopo::Topology::Domain;
use strict;
use warnings;
use English qw( -no_match_vars);
use version; our $VERSION = 0.09;
=head1 NAME

 perfSONAR_PS::Datatypes::v2_0::pingertopo::Topology::Domain  - A base class, implements  'domain'  element from the perfSONAR_PS RelaxNG schema
  
=head1 DESCRIPTION

   Object representation of the domain element.
   Object fields are:
    Scalar:     id, 
    Object reference:   comments => type HASH,
    Object reference:   node => type ARRAY,
   
   The constructor accepts only single parameter, it could be a hashref to parameters hash  or DOM with  'domain' element 
    
    
=head1 SYNOPSIS

              use perfSONAR_PS::Datatypes::v2_0::pingertopo::Topology::Domain;
          
          my $el =  perfSONAR_PS::Datatypes::v2_0::pingertopo::Topology::Domain->new($DOM_Obj);
 
=head1   METHODS

=cut
 

use XML::LibXML;
use Scalar::Util qw(blessed);
use Log::Log4perl qw(get_logger); 
use perfSONAR_PS::Datatypes::Element qw(getElement);
use perfSONAR_PS::Datatypes::Namespace;
use perfSONAR_PS::Datatypes::NSMap;
use Readonly;
use perfSONAR_PS::Datatypes::v2_0::nmtb::Topology::Domain::Comments;
use perfSONAR_PS::Datatypes::v2_0::pingertopo::Topology::Domain::Node;
use Class::Accessor::Fast;
use Class::Fields;
use base qw(Class::Accessor::Fast Class::Fields);
use fields qw(nsmap idmap refidmap id comments node  );

perfSONAR_PS::Datatypes::v2_0::pingertopo::Topology::Domain->mk_accessors(perfSONAR_PS::Datatypes::v2_0::pingertopo::Topology::Domain->show_fields('Public'));
  
=head2 new( )
   
      creates   object, accepts DOM with  element tree or hashref to the list of
      keyd parameters
         id   => undef, 
         comments => HASH,
         node => ARRAY,

=cut
Readonly::Scalar our $COLUMN_SEPARATOR => ':';
Readonly::Scalar our $CLASSPATH =>  'perfSONAR_PS::Datatypes::v2_0::pingertopo::Topology::Domain';
Readonly::Scalar our $LOCALNAME => 'domain';
            
sub new { 
    my $that = shift;
    my $param = shift;
 
    my $logger  = get_logger( $CLASSPATH ); 
    my $class = ref($that) || $that;
    my $self =  fields::new($class );
    $self->nsmap(perfSONAR_PS::Datatypes::NSMap->new()); 
    $self->nsmap->mapname( $LOCALNAME, 'pingertopo');
    
    if($param) {
        if(blessed $param && $param->can('getName')  && ($param->getName =~ m/$LOCALNAME$/xm) ) {
            return  $self->fromDOM($param);  
          
        } elsif(ref($param) ne 'HASH')   {
            $logger->error("ONLY hash ref accepted as param " . $param ); 
            return;
        }
    if($param->{xml}) {
         my $parser = XML::LibXML->new();
             my $dom;
             eval {
                  my $doc = $parser->parse_string( $param->{xml});
          $dom = $doc->getDocumentElement;
             };
             if($EVAL_ERROR) {
                 $logger->error(" Failed to parse XML :" . $param->{xml} . " \n ERROR: \n" . $EVAL_ERROR);
                return;
             }
             return  $self->fromDOM( $dom );  
    } 
        $logger->debug("Parsing parameters: " . (join " : ", keys %{$param}));
     
        no strict 'refs';
        foreach my $param_key (keys %{$param}) {
            $self->$param_key( $param->{$param_key} ) if $self->can($param_key);
        }  
        use strict;     
   
       $logger->debug("Done ");     
    }  
    return $self;
}

 
sub DESTROY {
    my $self = shift;
    $self->SUPER::DESTROY  if $self->can("SUPER::DESTROY");
    return;
}
 
=head2   getDOM ($) 
      
       accept parent DOM
       return domain object DOM, generated from object contents 
  
=cut 
 
sub getDOM {
    my $self = shift;
    my $parent = shift; 
    my $logger  = get_logger( $CLASSPATH ); 
    my $domain = getElement({name =>   $LOCALNAME, parent => $parent , ns => [$self->nsmap->mapname( $LOCALNAME )],
                             attributes => [

                                               ['id' =>  $self->id],
                                           ],
                         }); 
   if($self->comments  && blessed $self->comments  && $self->comments->can("getDOM")) {
        my  $commentsDOM = $self->comments->getDOM($domain);
       $commentsDOM?$domain->appendChild($commentsDOM):$logger->error("Failed to append  comments  with value: " .  $commentsDOM->toString ); 
   }
    if($self->node && ref($self->node) eq 'ARRAY' ) {
        foreach my $subel (@{$self->node}) { 
            if(blessed  $subel  &&  $subel->can("getDOM")) { 
                 my  $subDOM =  $subel->getDOM($domain);
                $subDOM?$domain->appendChild($subDOM):$logger->error("Failed to append  node elements  with value: " .  $subDOM->toString ); 
            }
         }
    }
    return $domain;
}
  
=head2  addnode()

    if any of subelements can be an arrray then this method will provide
    facility to add another element to the  array and will return ref to such array
    or just set the element to a new one
=cut

sub addNode {
    my $self = shift;
    my $new = shift;
    my $logger  = get_logger( $CLASSPATH ); 
   
    $self->node && ref($self->node) eq 'ARRAY'?push @{$self->node}, $new:$self->node([$new]); 
    $logger->debug("Added new to node"); 
    $self->buildIdMap; ## rebuild index map 
    $self->buildRefIdMap; ## rebuild ref index map  
    return $self->node;
}

=head2  removeNodeById()

     remove specific element from the array of node elements by id ( if id is supported by this element )
     accepts single param - id - which is id attribute of the element
     if there is no array then it will return undef and warninig
     if it removed some id then $id will be returned
     
=cut

sub removeNodeById {
    my $self = shift;
    my $id = shift;
    my $logger  = get_logger( $CLASSPATH ); 
    if(ref($self->node) eq 'ARRAY' && $self->idmap->{node} &&  exists $self->idmap->{node}{$id}) { 
        $self->node->[$self->idmap->{node}{$id}]->DESTROY; 
    my @tmp =  grep { defined $_ } @{$self->node};  
    $self->node([@tmp]);
    $self->buildRefIdMap; ## rebuild ref index map  
    $self->buildIdMap; ## rebuild index map 
    return $id;
    } elsif(!ref($self->node)  || ref($self->node) ne 'ARRAY')  {
        $logger->warn("Failed to remove  element because node not an array for non-existent id:$id");  
    } else {
        $logger->warn("Failed to remove element for non-existant id:$id");  
    } 
    return;
}   
=head2  getNodeByMetadataIdRef()

     get specific object from the array of node elements by  MetadataIdRef( if  MetadataIdRef is supported by this element )
     accepts single param -  MetadataIdRef
     if there is no array then it will return just an object
     
=cut

sub getNodeByMetadataIdRef {
    my $self = shift;
    my $id = shift;
    my $logger  = get_logger( $CLASSPATH ); 
    if(ref($self->node) eq 'ARRAY' && $self->refidmap->{node} && exists $self->refidmap->{node}{$id}) {
        my $node = $self->node->[$self->refidmap->{node}{$id}];
    return ($node->can("metadataIdRef") &&   $node->metadataIdRef eq  $id)?$node:undef; 
    } elsif($self->node && (!ref($self->node) || 
                                    (ref($self->node) ne 'ARRAY' &&
                                     blessed $self->node && $self->node->can("metadataIdRef") &&
                     $self->node->metadataIdRef eq  $id)))  {
        return $self->node;
    }  
    $logger->warn("Requested element for non-existent metadataIdRef:$id"); 
    return;
    
}

=head2  getNodeById()

     get specific element from the array of node elements by id ( if id is supported by this element )
     accepts single param - id
     if there is no array then it will return just an object
     
=cut

sub getNodeById {
    my $self = shift;
    my $id = shift;
    my $logger  = get_logger( $CLASSPATH ); 
    if(ref($self->node) eq 'ARRAY' && $self->idmap->{node} &&  exists $self->idmap->{node}{$id} ) {
        return $self->node->[$self->idmap->{node}{$id}];
    } elsif(!ref($self->node) || ref($self->node) ne 'ARRAY')  {
        return $self->node;
    }  
    $logger->warn("Requested element for non-existent id:$id"); 
    return;   
}

=head2  querySQL ()

      depending on config  it will return some hash ref  to the initialized fields
    for example querySQL ()
    accepts one optional prameter - query hashref
    will return:
    { ip_name_src =>  'hepnrc1.hep.net' },}
    
=cut

sub  querySQL {
    my $self = shift;
    my $query = shift; ### undef at first and then will be hash ref
    my $logger  = get_logger( $CLASSPATH );
     
    foreach my $subname (qw/comments node/) {
        if($self->{$subname} && (ref($self->{$subname}) eq 'ARRAY' ||  blessed $self->{$subname}))   {
            my @array = ref($self->{$subname}) eq 'ARRAY'?@{$self->{$subname}}:($self->{$subname});
        foreach my $el  (@array) {
            if(blessed  $el  &&  $el->can("querySQL"))  {
                    $el->querySQL($query);         
                    $logger->debug("Quering domain  for subclass $subname");
            } else {
                $logger->error(" Failed for domain Unblessed member or querySQL is not implemented by subclass $subname");
            }
        }  
        }
    }    
    return $query;
}

=head2 merge

      merge with another domain ( append + overwrite if exists )
      we can do it differently
      method #1:
         convert to dom both objects and then get resulted object from combined dom 
      method #2 default:
         through the introspection of the object

=cut


sub merge {
    my $self = shift;
    my $new_domain = shift;
    my $logger  = get_logger( $CLASSPATH );  
    unless($new_domain && blessed $new_domain && $new_domain->can("getDOM")) {
        $logger->error(" Please supply defined object of domain  ");
        return;
    } 
    ### for each field ( element or attribute )
    ### merge elements, add if its arrayref and overwrite attribtues for the same elements
    ### merge only if namespace is the same  
    foreach my $member_name ($new_domain->show_fields) {
        ### double check if   objects are the same
    if($self->can($member_name)) {
        my $current_member  = $self->{$member_name};
        my $new_member      =  $new_domain->{$member_name};
        ###  check if both objects are defined
        if($current_member && $new_member) {
            ### if  one of them array then just add another one
            if(blessed $current_member && blessed $new_member  && $current_member->can("merge") 
               && ( $current_member->nsmap->mapname($member_name) 
                eq  $new_member->nsmap->mapname($member_name) ) ) {
               $current_member->merge($new_member);
            $self->{$member_name} =  $current_member;
            $logger->debug("  Merged $member_name , got" . $current_member->asString);
            ### if its array then just push
            } elsif(ref($current_member) eq 'ARRAY'){
                 
           $self->{$member_name}=[$current_member, $new_member];
              
            $logger->debug("  Pushed extra to $member_name ");
            }  
        ## thats it, dont merge if new member is just a scalar
        } elsif( $new_member) {
           $self->{$member_name} = $new_member;
        }   
    } else {
        $logger->error(" This field $member_name,  found in supplied  domain  is not supported by domain class");
        return;
        }
    }
    return $self;
} 
 
=head2  buildIdMap()

    if any of subelements has id then get a map of it in form of
    hashref to { element}{id} = index in array and store in the idmap field

=cut

sub  buildIdMap {
    my $self = shift;
    my $map = (); 
    my $logger  = get_logger( $CLASSPATH );
    foreach my $field (qw/comments node/) {
        my @array = ref($self->{$field}) eq 'ARRAY'?@{$self->{$field}}:($self->{$field});
        my $i = 0;
        foreach my $el ( @array)  {
            if($el && blessed $el && $el->can("id") &&  $el->id)  { 
                $map->{$field}{$el->id} = $i;   
            }
            $i++;
        }
    }
    return $self->idmap($map);
}
=head2 buildrefIdMap ()

    if any of subelements has  metadataIdRef  then get a map of it in form of
    hashref to { element}{ metadataIdRef } = index in array and store in the idmap field

=cut

sub  buildRefIdMap {
    my $self = shift;
    my %map = (); 
    my $logger  = get_logger( $CLASSPATH );
    foreach my $field (qw/comments node/) {
        my @array = ref($self->{$field}) eq 'ARRAY'?@{$self->{$field}}:($self->{$field});
        my $i = 0;
        foreach my $el ( @array)  {
            if($el && blessed $el  && $el->can("metadataIdRef") &&  $el->metadataIdRef )  { 
                $map{$field}{$el->metadataIdRef} = $i;   
            }
            $i++;
        }
    }
    return $self->refidmap(\%map);
}
=head2  asString()

   shortcut to get DOM and convert into the XML string
   returns XML string  representation of the  domain object

=cut

sub asString {
    my $self = shift;
    my $dom = $self->getDOM();
    return $dom->toString('1');
}

=head2 registerNamespaces ()

   will parse all subelements and register all namepspaces within the domain namespace

=cut

sub registerNamespaces {
    my $self = shift;
    my $logger  = get_logger( $CLASSPATH );
    my $nsids = shift;
    my $local_nss = {reverse %{$self->nsmap->mapname}};
    unless($nsids) {
        $nsids =  $local_nss;
    }  else {
        %{$nsids} = ( %{$local_nss},  %{$nsids});
    }
    foreach my $field (qw/comments node/) {
        my @array = ref($self->{$field}) eq 'ARRAY'?@{$self->{$field}}:($self->{$field});
        foreach my $el ( @array)  {
            if(blessed $el &&   $el->can("registerNamespaces") )  { 
                my $fromNSmap =  $el->registerNamespaces($nsids); 
                my %ns_idmap =   %{$fromNSmap};  
                foreach my $ns ( keys %ns_idmap)  {
                      $nsids->{$ns}++
                }
            }
        }
    }
    return     $nsids;
}
=head2  fromDOM ($)
   
   accepts parent XML DOM   element   tree as parameter 
   returns domain  object

=cut

sub fromDOM {
    my $self = shift;
    my $logger  = get_logger( $CLASSPATH ); 
    my $dom = shift;
     
    $self->id($dom->getAttribute('id')) if($dom->getAttribute('id'));
    $logger->debug(" Attribute id= ". $self->id) if $self->id; 
    foreach my $childnode ($dom->childNodes) { 
        my  $getname  = $childnode->getName;
        my ($nsid, $tagname) = split $COLUMN_SEPARATOR,  $getname; 
        unless($nsid && $tagname) {   
            next;
        }
        if ($tagname eq  'comments' && $nsid eq 'nmtb' && $self->can($tagname)) { 
           my $element = undef;
           eval {
               $element = perfSONAR_PS::Datatypes::v2_0::nmtb::Topology::Domain::Comments->new($childnode) 
           };
           if($EVAL_ERROR || !($element  && blessed $element)) {
               $logger->error(" Failed to load and add  Comments : " . $dom->toString . " error: " . $EVAL_ERROR);
               return;
           }
           $self->comments($element); ### add another comments  
        }  elsif ($tagname eq  'node' && $nsid eq 'pingertopo' && $self->can($tagname)) { 
           my $element = undef;
           eval {
               $element = perfSONAR_PS::Datatypes::v2_0::pingertopo::Topology::Domain::Node->new($childnode) 
           };
           if($EVAL_ERROR || !($element  && blessed $element)) {
               $logger->error(" Failed to load and add  Node : " . $dom->toString . " error: " . $EVAL_ERROR);
               return;
           }
           ($self->node && ref($self->node) eq 'ARRAY')?push @{$self->node}, $element:$self->node([$element]);; ### add another node  
        }      ###  $dom->removeChild($childnode); ##remove processed element from the current DOM so subclass can deal with remaining elements
    }
  $self->buildIdMap;
 $self->buildRefIdMap;
 $self->registerNamespaces;
  
 return $self;
}

 
 
=head1 AUTHORS

   Maxim Grigoriev (FNAL)  2007-2008, maxim@fnal.gov

=cut 

1;
 
