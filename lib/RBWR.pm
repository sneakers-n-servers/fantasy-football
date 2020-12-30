package RBWR;
use Mouse;

extends 'Player'; 

has 'rushing_yds'   => (is => 'rw', isa => 'Stat');
has 'rushing_tds'   => (is => 'rw', isa => 'Stat');
has 'receptions'    => (is => 'rw', isa => 'Stat'); 
has 'receiving_yds' => (is => 'rw', isa => 'Stat');
has 'receiving_tds'  => (is => 'rw', isa => 'Stat');
has 'fumbles'       => (is => 'rw', isa => 'Stat');

sub calculate{
  my ($self, $scoring_ref) = @_;
  my %scoring = %{$scoring_ref}; 
  my @vals = @{$self->values};
  (scalar(@vals) == 8) || die "RB/WR does not have enough values"; 
  
  #Load em up and calculate
  if($self->position eq 'WR') {
    $self->receptions($vals[0]);
    $self->receiving_yds($vals[1]);
    $self->receiving_tds($vals[2]);
    $self->rushing_yds($vals[4]);
    $self->rushing_tds($vals[5]);
    $self->fumbles($vals[6]);
  }
  elsif($self->position eq 'RB'){
    $self->rushing_yds($vals[1]);
    $self->rushing_tds($vals[2]);
    $self->receptions($vals[3]);
    $self->receiving_yds($vals[4]);
    $self->receiving_tds($vals[5]);
    $self->fumbles($vals[6]);
  }
  else {
    die("Calculating the wrong player!");
  }

  my($high, $low); 
  foreach(Stat->meta->get_all_attributes){
    my $hi_lo = $_->name;
    my $calc = (
      ($self->rushing_yds->$hi_lo / $scoring{'rushing_yds'}) + 
      ($self->rushing_tds->$hi_lo * $scoring{'rushing_tds'}) + 
      ($self->receptions->$hi_lo  * $scoring{'receptions'})  + 
      ($self->receiving_yds->$hi_lo / $scoring{'receiving_yds'}) + 
      ($self->receiving_tds->$hi_lo * $scoring{'receiving_tds'}) + 
      ($self->fumbles->$hi_lo * $scoring{'fumbles'})
    );
    $self->fpts->$hi_lo($calc);
    ($high = $calc)if($hi_lo eq 'high');
    ($low = $calc)if($hi_lo eq 'low');
  }
  $self->variance(sprintf("%.2f", $high - $low));
}

__PACKAGE__->meta->make_immutable();

