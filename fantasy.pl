#!/usr/bin/env perl
package Player;
use Mouse; 

has 'name'     => (is => 'ro', isa => 'Str');
has 'team'     => (is => 'ro', isa => 'Str');
has 'position' => (is => 'ro', isa => 'Str');
has 'values'   => (is => 'ro', isa => 'ArrayRef[Num]', default => sub {[]}); 
has 'fpts'     => (is => 'rw', isa => 'Num', default => 0); 
has 'value'  => (is => 'rw', isa => 'Num', default => 0); 

sub push_val{ 
  my($self, $val) = @_;
  push(@{$self->values}, $val);  
}

sub to_csv{ 
  my($self, $printv) = @_;
  my $string = ($printv) ? 
    join('|', $self->name, $self->position, $self->team, $self->fpts, $self->value) :
    join('|', $self->name, $self->position, $self->team, $self->fpts); 
  return($string);  
} 

sub debug{
  my $self = shift; 
  my $string = join('|', $self->name, $self->position, $self->team, @{$self->values});
  return($string); 
}

__PACKAGE__->meta->make_immutable();

package QB; 
use Mouse; 

extends 'Player';

has 'passing_yds' => (is => 'rw', isa => 'Num');
has 'passing_tds' => (is => 'rw', isa => 'Num');
has 'ints'        => (is => 'rw', isa => 'Num');
has 'rushing_yds' => (is => 'rw', isa => 'Num');
has 'rushing_tds'  => (is => 'rw', isa => 'Num');
has 'fumbles'      => (is => 'rw', isa => 'Num');

sub calculate{
  my ($self, $scoring_ref) = @_;
  my %scoring = %{$scoring_ref}; 
  my @vals = @{$self->values};
  (scalar(@vals) == 10) || die "Quarterback does not have enough values"; 
  
  #Load em up and calculate
  $self->passing_yds($vals[2]);
  $self->passing_tds($vals[3]); 
  $self->ints($vals[4]); 
  $self->rushing_yds($vals[6]);
  $self->rushing_tds($vals[7]); 
  $self->fumbles($vals[8]);
  my $calc = (
    ($self->passing_yds / $scoring{'passing_yds'}) +
    ($self->passing_tds * $scoring{'passing_tds'}) + 
    ($self->ints *  $scoring{'ints'})              + 
    ($self->rushing_yds / $scoring{'rushing_yds'}) + 
    ($self->rushing_tds * $scoring{'rushing_tds'}) + 
    ($self->fumbles * $scoring{'fumbles'})
  );
  $self->fpts($calc); 
}

__PACKAGE__->meta->make_immutable();

package RBWR;
use Mouse;

extends 'Player'; 

has 'rushing_yds'   => (is => 'rw', isa => 'Num');
has 'rushing_tds'   => (is => 'rw', isa => 'Num');
has 'receptions'    => (is => 'rw', isa => 'Num'); 
has 'receiving_yds' => (is => 'rw', isa => 'Num');
has 'receiving_tds'  => (is => 'rw', isa => 'Num');
has 'fumbles'       => (is => 'rw', isa => 'Num');

sub calculate{
  my ($self, $scoring_ref) = @_;
  my %scoring = %{$scoring_ref}; 
  my @vals = @{$self->values};
  (scalar(@vals) == 8) || die "RB/WR does not have enough values"; 
  
  #Load em up and calculate
  $self->rushing_yds($vals[1]);
  $self->rushing_tds($vals[2]);  
  $self->receptions($vals[3]);  
  $self->receiving_yds($vals[4]);
  $self->receiving_tds($vals[5]); 
  $self->fumbles($vals[6]);
  my $calc = (
    ($self->rushing_yds / $scoring{'rushing_yds'}) + 
    ($self->rushing_tds * $scoring{'rushing_tds'}) + 
    ($self->receptions  * $scoring{'receptions'})  + 
    ($self->receiving_yds / $scoring{'receiving_yds'}) + 
    ($self->receiving_tds * $scoring{'receiving_tds'}) + 
    ($self->fumbles * $scoring{'fumbles'})
  );
  $self->fpts($calc); 
}

__PACKAGE__->meta->make_immutable();

package TE;
use Mouse;  

extends 'Player';

has 'receptions'    => (is => 'rw', isa => 'Num'); 
has 'receiving_yds' => (is => 'rw', isa => 'Num');
has 'receiving_tds'  => (is => 'rw', isa => 'Num');
has 'fumbles'       => (is => 'rw', isa => 'Num');

sub calculate{
  my ($self, $scoring_ref) = @_;
  my %scoring = %{$scoring_ref}; 
  my @vals = @{$self->values};
  (scalar(@vals) == 5) || die "TE does not have enough values"; 
  
  #Load em up and calculate
  $self->receptions($vals[0]);  
  $self->receiving_yds($vals[1]);
  $self->receiving_tds($vals[2]); 
  $self->fumbles($vals[3]);
  my $calc = (
    ($self->receptions  * $scoring{'receptions'})  + 
    ($self->receiving_yds / $scoring{'receiving_yds'}) + 
    ($self->receiving_tds * $scoring{'receiving_tds'}) + 
    ($self->fumbles * $scoring{'fumbles'})
  );
  $self->fpts($calc); 
}

__PACKAGE__->meta->make_immutable();

package Main;
use strict;
use warnings;
use LWP::UserAgent;
use Getopt::Long;
use File::Basename; 
use open qw(:std :utf8);

$_ = '' for(my $reset, my $keepers, my $debug); 
{
  my $mess ='';
  local $SIG{__WARN__} = sub { $mess .= $_[0]; };
  GetOptions('r|reset'     => \$reset,
             'k|keepers=s' => \$keepers,
	     'd|debug'     => \$debug,
             'u|usage'     => sub{usage(0)},
             'h|help'      => sub{usage(0)}) || usage(1, $mess); 
  validate_input();
}

#Some constants
my @pages =('qb', 'rb', 'wr', 'te'); 
my $input_dir = './input';
my $output_dir = './output'; 

#Fantasy Settings
my $num_teams = 12;

my %scoring = (
  'passing_yds'   => 25,
  'passing_tds'   => 4, 
  'ints'          => -1,
  'rushing_yds'   => 10, 
  'rushing_tds'   => 6,
  'receptions'    => .5,
  'receiving_yds' => 10,
  'receiving_tds' => 6,
  'fumbles'       => -2
); 

my %positions = (
  'qb' => 1,
  'wr' => 3,
  'rb' => 2,
  'te' => 1,
  'flex' => 2
);

my %keeper_hash;
if($keepers){
  %keeper_hash = map{s/(^\s+|\s+$)//; $_ => 0} @{readf($keepers)};   
}

my(%big_hash, %calculated_hash, %inverse_hash); 
foreach(@pages){
  create_input($_, $reset);
  my @lines = @{readf(join('/', $input_dir, $_ . '.html'))}; 
  $big_hash{$_} = munge_data(\@lines, uc($_));
  $calculated_hash{$_} = grab_chunks($big_hash{$_}, $num_teams * $positions{$_}, 0);    
  $inverse_hash{$_} = grab_chunks($big_hash{$_}, $num_teams * $positions{$_}, 1);
}


my @all_inverse = (@{$inverse_hash{'rb'}}, @{$inverse_hash{'wr'}},  @{$inverse_hash{'te'}});
add_flex(\@all_inverse, $num_teams * $positions{'flex'});  

foreach(keys %calculated_hash){
  $calculated_hash{$_} = calculate_value($calculated_hash{$_}); 
}

#Store these
my %temp_hash = %keeper_hash; 
my %temp_hash2 = %keeper_hash; 

#Dump the value
my @all_together = (@{$calculated_hash{'qb'}}, @{$calculated_hash{'rb'}}, @{$calculated_hash{'wr'}},  @{$calculated_hash{'te'}});
@all_together = reverse sort{${$a}->value <=> ${$b}->value} @all_together;   
@all_together = @{filter(\@all_together, \%temp_hash, 1)};
dumpf('value', \@all_together, 1); 

#Dump everything else
my @all_positions = (@{$big_hash{'rb'}}, @{$big_hash{'wr'}},  @{$big_hash{'te'}});
@all_positions = reverse sort{${$a}->fpts <=> ${$b}->fpts} @all_positions;   
@all_positions = @{filter(\@all_positions, \%temp_hash2, 0)};
dumpf('all', \@all_positions, 0); 

exit(0);

#################################

sub filter{
  my($player_ref, $keeper_ref, $validate) = @_; 
  my @players = @{$player_ref};
  my %keepers = %{$keeper_ref}; 
  my @return;
  foreach(@players){
    if(!exists($keepers{${$_}->name()})){ 
      push(@return, $_); 
    }
    else{
      $keepers{${$_}->name()} = 1;  
    }
  }
  
  #Verify that all keepers have been removed
  if($validate){
    foreach(keys %keepers){
      ($keepers{$_} == 1) || die("Unable to remove $_ from evaluation\n");
    }
  }
  return(\@return); 
}

sub add_flex{ 
  my($ref, $count) = @_; 
  my @arr = @{$ref};     
  @arr = reverse sort{${$a}->fpts <=> ${$b}->fpts} @arr;   
  @arr = @arr[0..$count-1];
  foreach(@arr){
    my $key = lc(${$_}->position());
    push(@{$calculated_hash{$key}}, $_);
  }     
} 

sub grab_chunks{
  my($ref, $num, $inv) = @_; 
  my @arr = @{$ref};   
  @arr = reverse sort{${$a}->fpts <=> ${$b}->fpts} @arr;   
  @arr = ($inv) ? @arr[$num..$#arr] : @arr[0..$num-1];
  return(\@arr);         
}

sub dumpf{ 
  my($position, $ref, $printv) = @_;   
  my @arr = @{$ref};
  my $outfile = join('/', $output_dir, $position . '.csv');
  print('dumping ' , $position . '.csv', "\n");  
  open(my $fh, '>', $outfile) || die("Unable to write $outfile"); 
  ($printv) ? print($fh 'NAME|POSITION|TEAM|FPTS|VALUE', "\n") : print($fh 'NAME|POSITION|TEAM|FPTS', "\n"); 
  foreach(@arr){
    print($fh ${$_}->to_csv($printv), "\n"); 
  }  
  close($fh); 
}

sub calculate_value{ 
  my $ref = shift; 
  my @arr = @{$ref};
  @arr = reverse sort{${$a}->fpts <=> ${$b}->fpts} @arr;   
  for(my $i = 0; $i < scalar(@arr); $i++){
    my $value = sprintf("%.2f", (${$arr[$i]}->fpts - ${$arr[-1]}->fpts)); 
    ${$arr[$i]}->value($value);  
  } 
  return(\@arr); 
}

sub munge_data{ 
  my($ref, $position) = @_; 
  my @lines = @{$ref}; 
 
  #RB/WR have the same stats, use the same object
  my $objname = ($position =~ /^(RB|WR)$/) ? 'RBWR' : $position;

  my($trigger, $player, @return);  
  foreach(@lines){
    my $current = $_;
    if(/fp-player-name/){
      #Grab name and team
      $_ = $current foreach(my $name, my $team); 
      $name =~ s/^.+fp-player-name=\"([^\"]+)\".+$/$1/;      
      $team =~ s/^.+\/a> ([A-Z]+) .+$/$1/;  
      $team = ($team eq $_) ? 'null' : $team; 
      
      #Create a new player, and set trigger to collect values
      $player = $objname->new(
	'name' => $name, 
	'team' => $team,
        'position' => $position
      ); 
      $trigger = 1;
      next; 
    }
    #Reached the end of a player
    if($trigger && $_ eq '</tr>'){
      $player->calculate(\%scoring);
      (print($player->debug, "\n"))if($debug);
      my $x = $player;
      push(@return, \$x);
      $trigger = 0;
    } 
    
    #Grabbing values
    if($trigger){
      my $value = $current; 
      $value =~ s/^.+>([^<]+)<.+$/$1/;
      $value =~ s/,//g;
      $player->push_val($value); 
    }
  } 
  return(\@return); 
}

sub readf{ 
  my $infile = shift; 
  open(my $fh, '<', $infile) || die("Unable to read $infile"); 
  my @lines = <$fh>; 
  close($fh);
  chomp(@lines);  
  return(\@lines);  
}

sub create_input{
  my($position, $reset) = @_; 
  my $outfile = join('/', $input_dir, $position . '.html'); 
  (-e $outfile && !$reset) && return; 
  print('getting ', $position . '.html', "\n"); 
  my $data = get_data($position); 
  open(my $fh, '>', $outfile) || die("Unable to write $outfile"); 
  print($fh $data); 
  close($fh);  
}

sub get_data{ 
  my $position = shift; 
  my $site = 'https://www.fantasypros.com/nfl/projections/';
  my $complete = join('', $site, $position, '.php', '?week=draft'); 
  my $ua = LWP::UserAgent->new( ssl_opts => { verify_hostname => 0 });
  my $response = $ua->get($complete);
  ($response->is_success) ? return($response->decoded_content) : die $response->status_line; 
}

sub validate_input{
  if($keepers){
    (-f $keepers) || die("ERROR: $keepers does not exist");
  }
} 

sub usage{ 
  my($exit_val, $mess) = @_;
  
  #Print error messages
  if($mess){ 
    my @lines = split("\n", $mess); 
    foreach(@lines){ print('ERROR: ', $_, "\n");};
    print("\n"); 
  }   
  my $script = basename($0);
  my $usage = <<"EOF";
Usage: $script [OPTIONS]

Options:
  -r|--reset         force download of latest stats from fantasypros.com
  -k|--keepers=FILE  remove a list of players from analysis  
  -u|--usage         print this message
  -h|--help          print this message 

EOF
  print($usage); 
  exit($exit_val);    
}

__PACKAGE__->meta->make_immutable();
