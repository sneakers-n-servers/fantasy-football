#!/usr/bin/env perl
package Main;
use strict;
use warnings;
use Cwd 'abs_path';
use LWP::UserAgent;
use Getopt::Long;
use File::Basename; 
use lib './lib';
use QB;
use RBWR; 
use TE;
use Team;
use Stat;
use Data::UUID;
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
my $script_dir = dirname(abs_path($0));
my $input_dir = join('/', $script_dir, 'input');
my $output_dir = join('/', $script_dir, 'output');
my $ug = Data::UUID->new();

foreach($input_dir, $output_dir){
  (-d $_) || mkdir($_);
}

#Fantasy Settings
my $num_teams = 12;

my %scoring = (
  'passing_yds'   => 25,
  'passing_tds'   => 4, 
  'ints'          => -1,
  'rushing_yds'   => 10, 
  'rushing_tds'   => 6,
  'receptions'    => 0.5,
  'receiving_yds' => 10,
  'receiving_tds' => 6,
  'fumbles'       => -2
); 

my %positions = (
  'qb'    => 1,
  'wr'    => 3,
  'rb'    => 2,
  'te'    => 1,
  'flex'  => 1, 
  'bench' => 5
);

my %keeper_hash;
if($keepers){
  %keeper_hash = map{s/(^\s+|\s+$)//; $_ => 0} @{readf($keepers)};   
}

#Big hash contains everything, Calculated has is the finished product, inverse for flex
my(%big_hash, %calculated_hash, %inverse_hash); 
foreach(@pages){
  create_input($_, $reset);
  my @lines = @{readf(join('/', $input_dir, $_ . '.html'))}; 
  $big_hash{$_} = munge_data(\@lines, uc($_));

  $calculated_hash{$_} = grab_chunks($big_hash{$_}, $num_teams * $positions{$_}, 0);    
  $inverse_hash{$_} = grab_chunks($big_hash{$_}, $num_teams * $positions{$_}, 1);
}

#Grab the flex spots that won't be drafted, index them for the mock draft, add top spots to calculated
my @all_inverse = (@{$inverse_hash{'rb'}}, @{$inverse_hash{'wr'}},  @{$inverse_hash{'te'}});
my %all_remain = map{${$all_inverse[$_]}->uuid => $all_inverse[$_]}(0..$#all_inverse);
add_flex(\@all_inverse, $num_teams * $positions{'flex'});  

#Calculate our value, and remove the flex players from the remaining
foreach(keys %calculated_hash){
  $calculated_hash{$_} = calculate_value($calculated_hash{$_}); 
  foreach(@{$calculated_hash{$_}}){
    (exists($all_remain{${$_}->uuid})) && delete($all_remain{${$_}->uuid});
  }
}

#Copy the keeper hash, we modify it due to argument order pass by ref
#my %temp_hash = %keeper_hash; 
#my %temp_hash2 = %keeper_hash; 
(my %temp_hash, my %temp_hash2) = (%keeper_hash, %keeper_hash);
#($_ = %keeper_hash)foreach(my %temp_hash, my %temp_hash2);

#Dump the value list
my @all_together = (@{$calculated_hash{'qb'}}, @{$calculated_hash{'rb'}}, @{$calculated_hash{'wr'}},  @{$calculated_hash{'te'}});
@all_together = reverse sort{${$a}->value <=> ${$b}->value} @all_together;   
@all_together = @{filter(\@all_together, \%temp_hash, 1)};
dumpf('value', \@all_together, 1); 

#Dump the global rankings else
my @all_positions = (@{$big_hash{'rb'}}, @{$big_hash{'wr'}},  @{$big_hash{'te'}});
@all_positions = reverse sort{${$a}->fpts->avg <=> ${$b}->fpts->avg} @all_positions;   
@all_positions = @{filter(\@all_positions, \%temp_hash2, 0)};
dumpf('all', \@all_positions, 0); 

#Perform the mock draft
calc_draft(\@all_together, \%all_remain); 

exit(0);

#################################

sub calc_draft{ 
  my($draft_ref, $remain_ref) = @_; 
  my @list = @{$draft_ref};
  my %remain = %{$remain_ref};

  #Create list of teams, with new inventory
  my %team_hash = (); 
  for(1..$num_teams){ 
    my %new_pos = %positions;
    $team_hash{$_}  = 'Team'->new(inventory => \%new_pos, number => $_);
  }
  
  #Prepared draft order
  my %draft_players = map{$_ => $list[$_]}(0..$#list);

  #Remaining sorted by fpts
  my @remain_list = reverse sort{${$a}->fpts->avg <=> ${$b}->fpts->avg} values(%remain);
  my %remain_players = map{$_ => $remain_list[$_]} (0..$#remain_list);

  my $team_no = 1;
  my($ref1, $ref2); 
  for(my $i = 0; $i < scalar(@list); $i++){ 
    ($ref1, $ref2) = $team_hash{$team_no}->draft(\%draft_players, \%remain_players, $i+1);
    %draft_players = %{$ref1};
    %remain_players = %{$ref2};

    if(++$team_no == $num_teams+1){ 
      $team_no = 1;
    }
  } 

  my @keys = reverse sort{$team_hash{$a}->total <=> $team_hash{$b}->total} keys %team_hash;
  print("dumping draft.txt\n");
  my $file = join('/', $output_dir, 'draft.txt');
  open(my $fh, '>', $file) || die("ERROR: unable to open $file for writing");
  foreach(@keys){ 
    print($fh $team_hash{$_}->to_str, "\n"); 
  }
  close($fh);
}

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
  @arr = reverse sort{${$a}->fpts->avg <=> ${$b}->fpts->avg} @arr;   
  @arr = @arr[0..$count-1];
  foreach(@arr){
    my $key = lc(${$_}->position());
    push(@{$calculated_hash{$key}}, $_);
  }     
}


sub grab_chunks{
  my($ref, $num, $inv) = @_; 
  my @arr = @{$ref};   
  @arr = reverse sort{${$a}->fpts->avg <=> ${$b}->fpts->avg} @arr;   
  @arr = ($inv) ? @arr[$num..$#arr] : @arr[0..$num-1];
  return(\@arr);         
}

sub dumpf{ 
  my($position, $ref, $printv) = @_;   
  my @arr = @{$ref};
  my $outfile = join('/', $output_dir, $position . '.csv');
  print('dumping ' , $position . '.csv', "\n");  
  open(my $fh, '>', $outfile) || die("Unable to write $outfile"); 
  ($printv) ? print($fh 'NAME|POSITION|TEAM|FPTS (AVG)|FPTS (HIGH)|FPTS (LOW)|VALUE|VARIANCE', "\n") : print($fh 'NAME|POSITION|TEAM|FPTS (AVG)|FPTS (HIGH)|FPTS (LOW)', "\n"); 
  foreach(@arr){
    print($fh ${$_}->to_csv($printv), "\n"); 
  }  
  close($fh); 
}

sub calculate_value{ 
  my $ref = shift; 
  my @arr = @{$ref};
  @arr = reverse sort{${$a}->fpts->avg <=> ${$b}->fpts->avg} @arr;   
  for(my $i = 0; $i < scalar(@arr); $i++){
    my $value = sprintf("%.2f", (${$arr[$i]}->fpts->avg - ${$arr[-1]}->fpts->avg)); 
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
        'position' => $position,
        'uuid' => $ug->create()
      ); 
      $trigger = 1;
      next; 
    }

    #Reached the end of a player
    if($trigger && $_ eq '</tr>'){
      $player->calculate(\%scoring);
      ($debug) && print($player->to_str, "\n");
      my $x = $player;
      push(@return, \$x);
      $trigger = 0;
    } 
    
    #Grabbing values
    if($trigger){
      my $value = $current; 
      my @matches = $value =~ />([^<]+)</g;
      @matches = map{s/,//g; $_} @matches;
      (scalar(@matches) == 3) || die("Couldnt get whole line for player");
      my $stat = 'Stat'->new(
        'avg'  => $matches[0],
        'high' => $matches[1], 
        'low'  => $matches[2]
      );
      $player->push_stat($stat); 
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
  my $complete = join('', $site, $position, '.php', '?week=draft&max-yes=true&min-yes=true'); 
  my $ua = LWP::UserAgent->new(ssl_opts => { verify_hostname => 0 });
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
