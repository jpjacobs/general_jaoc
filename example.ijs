NB. Example file for jAOC 
load 'general/jaoc'
NB. Set year (e.g. 2016)
2016 setup_aoc_ './'

1 day {{ NB. Test problem
  p2 =: 2*p1 =: len=:# NB. Nonsense example code
  0                    NB. required noun result 
}}
6 day {{ NB. Scrambled comms real solution
  p1 =: [: ([: {.&>@:({.@\: #&>) </.~)"1@|: ];._2
  p2 =: [: ([: {.&>@:({.@/: #&>) </.~)"1@|: ];._2
  0
}}
8 day {{
  coinsert 'd1' NB. reuse definitions from day 1.
  p1=: *:@len
0
}}
echo run 8 NB. run only day 8, only solutions and time
NB. Example submitting:
NB. run 6   NB. defines RES_d6_ as (p1;p2)io''
NB. sub 6 1 NB. for part 1
NB. sub 6 2 NB. for part 2
echo 1 run 1 6 8 NB. run all, show times.
NB. Line below for making vim fold direct definitions, and have sensible tab settings (2 spaces).
NB. vim: ts=2 sw=2 et fdm=marker foldmarker={{,}}
