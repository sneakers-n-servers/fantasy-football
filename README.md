# fantasy-football
*Perl scripts to run value based drafting algorithim.
*Compare all players QB, RB, WR, TE on an adjusted scale in order to produce an accurate draft list, based on settings in the main script
*I rip the numbers from [fantasypros](https://www.fantasypros.com/nfl/projections/qb.php?week=draft).
*Just added the mock draft feature, it works

The cheat sheet produced looks like this:

PICK|NAME|POSITION|TEAM|FPTS (AVG)|FPTS (HIGH)|FPTS (LOW)|VALUE|VARIANCE
---|----|--------|----|----------|-----------|----------|-----|--------
1  |Todd Gurley|RB|LAR|311.32|+35.67|-31.28|66.95|188.47
2  |Le'Veon Bell|RB|PIT|308.3|+35.98|-32.74|68.72|185.45
3  |David Johnson|RB|ARI|286.22|+66.18|-49.32|115.50|163.37
4  |Ezekiel Elliott|RB|DAL|267.87|+41.67|-34.45|76.12|145.02
5  |Alvin Kamara|RB|NO|253.55|+30.58|-27.05|57.63|130.70
6  |Melvin Gordon|RB|LAC|246.46|+30.99|-33.45|64.44|123.61
7  |Kareem Hunt|RB|KC|238.32|+25.57|-32.00|57.57|115.47
8  |Saquon Barkley|RB|NYG|235.97|+34.44|-32.61|67.05|113.12
9  |Leonard Fournette|RB|JAC|232.06|+27.56|-24.66|52.22|109.21
10  |Dalvin Cook|RB|MIN|226.14|+37.75|-23.17|60.92|103.29
11  |Antonio Brown|WR|PIT|208.34|+22.82|-22.54|45.36|98.01
12  |Rob Gronkowski|TE|NE|199.51|+29.99|-18.54|48.53|95.37
13  |Christian McCaffrey|RB|CAR|214.84|+40.24|-48.92|89.16|91.99
14  |Devonta Freeman|RB|ATL|212.16|+18.22|-20.24|38.46|89.31
15  |Aaron Rodgers|QB|GB|383.658|+55.28|-40.08|95.36|77.86
16  |DeAndre Hopkins|WR|HOU|188.09|+27.81|-18.33|46.14|77.76
17  |Julio Jones|WR|ATL|187.21|+22.04|-22.01|44.05|76.88
18  |Travis Kelce|TE|KC|180.37|+13.43|-18.19|31.62|76.23
19  |Jerick McKinnon|RB|SF|195.97|+33.76|-32.26|66.02|73.12
20  |LeSean McCoy|RB|BUF|191.73|+47.93|-55.73|103.66|68.88
21  |Odell Beckham Jr.|WR|NYG|177.14|+17.58|-19.14|36.72|66.81
22  |Jordan Howard|RB|CHI|188.04|+36.03|-31.94|67.97|65.19
23  |Keenan Allen|WR|LAC|172.78|+22.48|-19.38|41.86|62.45
24  |Michael Thomas|WR|NO|170.05|+23.58|-20.55|44.13|59.72
25  |Joe Mixon|RB|CIN|181.08|+37.02|-37.72|74.74|58.23
26  |Zach Ertz|TE|PHI|161.55|+12.20|-11.65|23.85|57.41
27  |Tom Brady|QB|NE|362.174|+70.57|-55.26|125.84|56.37
28  |Alex Collins|RB|BAL|176.55|+34.27|-25.86|60.13|53.70
29  |A.J. Green|WR|CIN|160.49|+21.81|-18.89|40.70|50.16
30  |Davante Adams|WR|GB|160.4|+13.13|-13.30|26.43|50.07
31  |Kenyan Drake|RB|MIA|170.99|+28.66|-27.89|56.55|48.14
32  |Tyreek Hill|WR|KC|158.1|+16.48|-17.50|33.98|47.77
33  |Derrick Henry|RB|TEN|168.8|+30.23|-27.27|57.50|45.95
34  |Mike Evans|WR|TB|155.89|+26.89|-20.84|47.73|45.56
35  |Lamar Miller|RB|HOU|162.59|+26.01|-24.34|50.35|39.74
36  |Evan Engram|TE|NYG|143.19|+17.34|-12.59|29.93|39.05
37  |Jay Ajayi|RB|PHI|161.9|+22.90|-23.50|46.40|39.05
38  |Russell Wilson|QB|SEA|344.166|+36.73|-50.99|87.71|38.37
39  |Royce Freeman|RB|DEN|160.62|+52.36|-48.87|101.23|37.77
40  |Doug Baldwin|WR|SEA|147.73|+25.10|-14.23|39.33|37.40
41  |Greg Olsen|TE|CAR|138.65|+24.80|-21.85|46.65|34.51
42  |Delanie Walker|TE|TEN|138.51|+22.24|-22.91|45.15|34.37
43  |T.Y. Hilton|WR|IND|144.13|+26.37|-35.10|61.47|33.80
44  |Stefon Diggs|WR|MIN|142.59|+15.58|-18.89|34.47|32.26
45  |Amari Cooper|WR|OAK|141.68|+15.47|-14.42|29.89|31.35
46  |Jimmy Graham|TE|GB|135.39|+31.70|-30.39|62.09|31.25
47  |Drew Brees|QB|NO|336.084|+61.02|-56.02|117.04|30.28
48  |Adam Thielen|WR|MIN|140.37|+15.83|-25.54|41.37|30.04
49  |Rex Burkhead|RB|NE|149.5|+29.35|-24.20|53.55|26.65
50  |Deshaun Watson|QB|HOU|332.286|+75.27|-72.97|148.24|26.49


Heres a sample of the mock draft:

|Team  1|                    |      |
|-------|--------------------|------|
|01RB   |Todd Gurley         |311.32|
|24WR   |Michael Thomas      |170.05|
|25RB   |Joe Mixon           |181.08|
|48WR   |Adam Thielen        |140.37|
|49FLEX |Rex Burkhead        |149.50|
|72QB   |Cam Newton          |319.19|
|73WR   |Jarvis Landry       |122.55|
|96TE   |Jared Cook          |100.92|
|Total  |                    |1494.98|
|Variance|                    |464.17|

|Team  2 |                    |      | 
|--------|--------------------|------|
|02RB    |Le'Veon Bell        |308.30|
|23WR    |Keenan Allen        |172.78|
|26TE    |Zach Ertz           |161.55|
|47QB    |Drew Brees          |336.08|
|50WR    |JuJu Smith-Schuster |135.32|
|71RB    |Duke Johnson        |135.28|
|74FLEX  |Chris Thompson      |135.24|
|95WR    |Jamison Crowder     |110.33|
|Total   |                    |1494.88|
|Variance|                    |438.61|

Doubt you can do any better with Perl
