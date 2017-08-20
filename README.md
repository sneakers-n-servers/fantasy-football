# fantasy-football
*Perl scripts to run value based drafting algorithim.
*Compare all players QB, RB, WR, TE on an adjusted scale in order to produce an accurate draft list, based on settings in the main script
*I rip the numbers from [fantasypros](https://www.fantasypros.com/nfl/projections/qb.php?week=draft).
*Just added the mock draft feature. 

The cheat sheet produced looks like this:

NAME|POSITION|TEAM|FPTS (AVG)|FPTS (HIGH)|FPTS (LOW)|VALUE|VARIANCE
----|--------|----|----------|-----------|----------|-----|--------
David Johnson|RB|ARI|283.32|311.61|259.6|170.46|52.01
Le'Veon Bell|RB|PIT|262.44|289.55|225.5|149.58|64.05
LeSean McCoy|RB|BUF|219.92|243.84|191.2|107.06|52.64
Devonta Freeman|RB|ATL|211.3|234.2|186.98|98.44|47.22
Julio Jones|WR|ATL|203.05|230.89|179.44|89.73|51.45
Melvin Gordon|RB|LAC|201.94|222.26|182.13|89.08|40.13
Antonio Brown|WR|PIT|202.25|223.67|184.3|88.93|39.37
Jordan Howard|RB|CHI|201.74|217.56|190.34|88.88|27.22
Jay Ajayi|RB|MIA|198.94|225.86|181.38|86.08|44.48
DeMarco Murray|RB|TEN|193.5|228.9|170.14|80.64|58.76
Aaron Rodgers|QB|GB|343.744|378.56|314.046|79.48|64.51
Odell Beckham Jr.|WR|NYG|188.61|212.7|150|75.29|62.70
Todd Gurley|RB|LAR|184.69|202.66|163.95|71.83|38.71
Jordy Nelson|WR|GB|184.28|191.05|175.9|70.96|15.15
Mike Evans|WR|TB|183.86|200.4|164.01|70.54|36.39
Lamar Miller|RB|HOU|176.8|193.18|158.2|63.94|34.98
Leonard Fournette|RB|JAC|173.22|209.17|146.81|60.36|62.36
Tom Brady|QB|NE|323.626|349.34|304.76|59.36|44.58
A.J. Green|WR|CIN|172.44|195.4|151|59.12|44.40

Heres a sample of the mock draft:
|Team  1|
|--------|-------------|------------|
|01RB:   |David Johnson       |283.32|
|13RB:   |Todd Gurley         |184.69|
|25FLEX: |Isaiah Crowell      |158.82|
|37WR:   |Allen Robinson      |144.53|
|49TE:   |Jordan Reed         |120.55|
|61WR:   |Demaryius Thomas    |131.54|
|73WR:   |Emmanuel Sanders    |125.51|
|85QB:   | Kirk Cousins       |269.40|
|Total   | 1418.36|
|Variance|373.51|

Team  2
02RB:   Le'Veon Bell        262.44
14WR:   Jordy Nelson        184.28
26RB:   Marshawn Lynch      157.53
38FLEX: Mark Ingram         147.66
50QB:   Andrew Luck         284.64
62WR:   Davante Adams       131.32
74WR:   Willie Snead        125.28
86TE:   Eric Ebron          96.98
Total:  1390.13
Variance:  302.15

Doubt you can do any better with Perl
