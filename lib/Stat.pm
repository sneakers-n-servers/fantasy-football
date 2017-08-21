package Stat;
use Mouse;

my $meta = __PACKAGE__->meta;

has 'avg'  => (is => 'rw', isa => 'Num', required => 1); 
has 'high' => (is => 'rw', isa => 'Num', required => 1); 
has 'low'  => (is => 'rw', isa => 'Num', required => 1); 

sub to_str{
  my $self = shift; 
  my $str = join(': ', 'HIGH', $self->high, 'LOW', $self->low, 'AVG', $self->avg); 
  return($str);
}

sub to_csv{ 
  my $self = shift;
  my $high = '+' . sprintf("%.2f", $self->high - $self->avg);
  my $low = '-' . sprintf("%.2f", $self->avg - $self->low); 
  join('|', $self->avg, $high, $low); 
}

__PACKAGE__->meta->make_immutable();
1;
