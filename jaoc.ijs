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
    HTTP requests are throttled, max 5 per 5 min by default;
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
URL   =: 'https://adventofcode.com'
AGENT =: 'github.com/jpjacobs/jAOC if complaints, please make a Github issue'
THROT =: 5 5 NB. A,B: max A req per B minutes

setup =: './'&$: : {{ NB. y=year, x=directory containing cached input & COOKIE.txt (defaults to './', i.e. current working directory)
  PATH=: '/',~^:(~:{:) jpath x
  'COOKIE.txt missing' assert 128=#COOKIE=:LF -.~ freads 'COOKIE.txt'
  if. IFJA do. HTTPCMD_wgethttp_ =. 'curl' end. NB. Seems to work, but is empty on Android.
  YEAR =: y
  NB. Throttle requests; list of connection timestamps
  NB. keep last N; refuse if now-first kept is < X min
  REQS =: ({.THROT)$0
}}
NB. Throttle requests based on THROT & REQS
NB. returns empty if fine; else error.
throttle =: {{
  t=. 1000 <.@%~ tsrep 6!:0'' NB. timestamp; seconds
  ('Throttled; please wait ',(":dd-d), ' seconds more') assert (dd=.60*{:THROT) <: d=. t-{.REQS NB. delay not ok?
  NB. keep max {.THROT el of Req timestamps, t
  0 0$REQS_aoc_ =: (}.REQS),t
}}
NB. TODO: Test, perhaps take article tag into account
NB. cleanhtml =: #~ 0=[:+/\&.|. 1 _1 +/ .* '<>' =/ ]

NB. req : Low level verb for implementing "io" and "sub"; does interaction with the website, buffering inputs.
NB.     req YYYY DD P gets input for year YYYY and date DD if not downloaded yet. Saves input as YYYYDD.txt (ignores P if present.)
NB. ANS req YYYY DD P POST's ANS as answer to day DD of year YYYY part P
req =: {{
  y=. 2 {. y
  if. -.fexist fn=.PATH,'.txt',~ ;('r<0>',"1'4.0',:'2.0')8!:0"1 0 y do.
    throttle_aoc_''
    if. 'curl' +/@:E. tolower HTTPCMD_wgethttp_ do.
      opts =. '-s -A # -H "cookie: session=_" ' rplc '_';COOKIE;'#';AGENT
    else.
      'wget not supported yet' assert 0
    end.
    inp =. opts gethttp URL,'/YY/day/DD/input' rplc ('YY';'DD') ,. <@":"0 y
    'COOKIE.txt wrong or expired' assert -. 'Puzzle inputs differ by user.  Please log in to get your puzzle input.' +./@:E. inp
    inp fwrites fn  NB. file will contain appropriate LF ending.
  end.
  freads fn
}} : {{
  if. _1 = s =. freads fn=.PATH,'sol','.txt',~ ;('r<0>',"1'4.0','2.0',:'2.0')8!:0"1 0 y do. 'i t'=. '' ,&< (0$a:) else. 'i t'=. ({.;._2 ,&< <@}.;._2) s end.
  NB. check previous tries
  if. (#t)>pl=. t i. <":x do. NB. Already tried
    echo 'solution already sent; was ' , '.',~(<;._1'_too low_too high_wrong_correct_unknown'){::~'LH-V'i.pl{i
  elseif. 'min max'=. (>./,0".&>t#~'L'=i);(<./,0".&>t#~'H'=i)
    (min&< *: <&max) x do. NB. Not tried yet; check range (if no range, fail graciously)
    echo (":x),' out of range ',(":min),' ',":max
  else.
    throttle_aoc_'' NB. Can we connect?
    if. 'curl' +/@:E. tolower HTTPCMD_wgethttp_ do.
      opts =.'-d "level=L&answer=A" ' rplc 'L';(":{:y);'A';":x
      opts =. opts,'-A ',AGENT,' '
      opts =. opts,'-s -H "cookie: session=_"' rplc '_';COOKIE
    else.
      'wget not supported yet' assert 0
    end.
    BAR_base_=:res =. opts gethttp URL,'/YY/day/DD/answer' rplc ('YY';'DD') ,. <@":"0 }: y
    NB. res =: '<article> That''s not the right answer, your answer is too ',('low' [^:(0.5>?0) 'high'),'. </article>'
    NB. TODO: check other pre-cooked examples.
    'COOKIE.txt wrong or expired' assert -. 'please identify yourself' +./@:E. res
    'Already solved or still locked' assert -. 'right level' +./@:E. res
    NB. post process to get proper answer: find first article, drop enough, and then take to '.' for first sentence.
    res =. '.' taketo (}.~ 8+'article'i.&1@:E.]) res
    NB. TODO Parse answer better; print result; check 'too high' 'too low' 'correct' 'incorrect'; perhaps add . where required.
    NB. store new try with previous tries
    ni =. 'LH-V?' {~ 1 i.~ (<;._1 '_too low_too high_not the right_right') +./@:E.&> <res
    l  =. (0 {.@".&> t) I. x NB. get where X should be (0 ". fails graciously)
    fn fwrites~ ; (<LF,~ni,":x) (l&{.@] , (, l&}.)) i (LF,~,)&.> t
    res
  end.
}}

tries =: {{ NB. try sol y for day m part x; returns lists of solutions and indicators, both as literal
if. _1 ~: s =. freads PATH,'sol','.txt',~ ;('r<0>',"1'4.0','2.0',:'2.0')8!:0"1 0 y do.
  sols=. ({.;._2 ,&< <@}.;._2) s
else.
  sols=. '';''
end.
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
  try =: m&try_jaoc_
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
