NB. Helper functions for https://adventofcode.com for organising code, getting
NB. input and uploading solutions.
Note 'Documentation'
Expects COOKIE.txt to contain the session cookie (see here:
https://github.com/wimglenn/advent-of-code-wim/issues/1) how to get it; copy
paste it in a new file named COOKIE.txt in the same directory as the year
scripts you're going to create or run.
**Don't add to your Git repo.**

Defines the following names in z:
  day: conjunction. m=day no; v is verb implementing p1, p2 (add 0 or y at
       end to return noun) see below for details.
  run: run and time day numbers in y
  sub: submit last run result for day {. y, part {: y eg. "sub 25 1" or
       "sub 5 2"; shorthand for "1 io_d25_ 0{::RES_d25_"

day runs its code in locale 'dm' with m being the day no. This locale has:
io: monad: get input for the day (for exploration, "run" automatically gets
           input). Caches input files in the current directory.
    dyad : post result y for part x (e.g. 2 io_d25_ 'foobar' submits foobar
    as result for day 25, part 1) Note that "sub" provides shorthand for
    this operation for the last run result (the most common case).
p1, p2   : default to 0:, should be monads defined in v for implementing
the day's parts 1 and 2. day does *not* run p1 and p2 by itself, so
definitions of previous days can be reused without having to wait for
execution results.

The aoc locale has:
  [path] setup year : set "path" as data directory (default to J's working directory) having cached input, then setup year, verify cookie, and
                   fix Android gethttp to use cURL (works on my phone...)
  [ans] req YYYY D P: monad: GET input for year YYYY, day D (P optional and ignored)
                    : dyad : POST ans as answer for YYYY,D, part P (1 or 2)
                             returns some rough text extracted.
)
load'web/gethttp'

cocurrent 'aoc'
NB. config and setting up
NB. ====================================================================
URL  =: 'https://adventofcode.com'

setup =: './'&$: : {{ NB. y=year, x=directory containing cached input & COOKIE.txt (defaults to './', i.e. current working directory)
  PATH=: '/',~^:(~:{:) jpath x
  'COOKIE.txt missing' assert 128=#COOKIE=:LF -.~ freads 'COOKIE.txt'
  if. IFJA do. HTTPCMD_wgethttp_ =. 'curl' end. NB. Seems to work, but is empty on Android.
  YEAR =: y
}}

NB. req : Low level verb for implementing "io" and "sub"; does interaction with the website, buffering inputs.
NB.     req YYYY DD P gets input for year YYYY and date DD if not downloaded yet. Saves input as YYYYDD.txt (ignores P if present.)
NB. ANS req YYYY DD P POST's ANS as answer to day DD of year YYYY part P
req =: {{
  y=. 2 {. y
  if. -.fexist fn=.PATH,'.txt',~ ;('r<0>4.0',:'r<0>2.0')8!:0"1 0 y do.
    if. 'curl' +/@:E. tolower HTTPCMD_wgethttp_ do.
      opts =. '-s -H "cookie: session=_" ' rplc '_';COOKIE
    else.
      'wget not supported yet' assert 0
    end.
    inp =. opts gethttp URL,'/YY/day/DD/input' rplc ('YY';'DD') ,. <@":"0 y
    'COOKIE.txt wrong or expired' assert -. 'Puzzle inputs differ by user.  Please log in to get your puzzle input.' +./@:E. inp
    inp fwrites fn  NB. file will contain appropriate LF ending.
  end.
  freads fn
}} : {{
  if. 'curl' +/@:E. tolower HTTPCMD_wgethttp_ do.
    opts =.'-d "level=L&answer=A" ' rplc 'L';(":{:y);'A';":x
    opts =. opts,'-s -H "cookie: session=_"' rplc '_';COOKIE
  else.
    'wget not supported yet' assert 0
  end.
  res =. opts gethttp URL,'/YY/day/DD/answer' rplc ('YY';'DD') ,. <@":"0 }: y
  'COOKIE.txt wrong or expired' assert -. 'Puzzle inputs differ by user.  Please log in to get your puzzle input.' +./@:E. res
  NB. post process to get proper answer: Find where article starts; take first, drop initial html, hard-wrap at 80 char.
  _80 ]\ (}.~ i.&'>')^:2 >{.(<;.1~ 'article>'&E.) res
}}

NB. day is a conjunction; taking day number and verb implementing day (p1,p2) which will execute in their own locale (named _dx_)
NB.   Before the verb is executed, the locale is set as "dx" with x being the day number.
NB.   Verb "io" is available for getting input (monad y=''), and submitting (dyad, y=solution, x=part(1 or 2); returns some text)
day_z_ =: {{ 
  cocurrent 'd',":m
  coinsert 'aoc'
  NB. Perhaps wrap in try/catch: (dberm dbsig dberr)'' (https://code.jsoftware.com/wiki/Vocabulary/Foreigns#m13)
  io =: ([: req_aoc_ (YEAR,m)&,) : ((req_aoc_ (YEAR,m)&,)~) NB. define input output
  p1 =: p2=: 0: NB. placeholder verbs
  v ''
  ('Day ',(":m),' should define monads p1,p2') assert 3*./@:= nc ;:'p1 p2'
  cocurrent'base'
}}
NB. run and time days in y (numeric list) x=1: show complete overview; x=0 or not provided: run solutions and show results only for last day in y
run_z_ =: {{
  res=. 0 4$a:
  header=.,:'Day';'Part 1';'Part 2';'Time'
  for_d. y do.
    cocurrent 'd',":d        NB. set day locale
    inp =. io''              NB. get input to exclude it from execution time
    tic =.(6!:1)''           NB. starting time 
    dr  =. RES =: (p1;p2)inp NB. get result, store in day locale and local var dr
    res =. res,(<":d),dr,<(6!:1'')-tic NB. add result and timing to res
  end.
  if. 2>#y do. }.{:res else. header,res,_4 {. 'Total';+/;{:"1 res end.
}}
NB. submit last run result for day {.y level {:y, numeric y
sub_z_ =: {{
  sl =. coname''
  cocurrent'd',":{.y
  res=. ({:y) io (<:{:y){:: RES
  cocurrent 'sl'
  res
}}
