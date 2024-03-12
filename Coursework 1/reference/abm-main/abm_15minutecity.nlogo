;===================================================================================
; CASA0011 Agent Based Modelling
; Assessment 2, T2 2023
;
; Author: Guk Yu
; Date last updated: --
;
; WOMEN SAFETY IN 15-MIN CITY
;
;===================================================================================


;===================================================================================
; VARIABLES
;===================================================================================

;; Define the two types of agent: men and women
breed [men man]
breed [women woman]

globals
[
  gridsize              ;size of city grids
  agent-size            ;size of agents
  num-homes             ;number of homes in simulation
  num-men               ;number of men in simulation
  num-women             ;number of women in simulation, including mothers
  num-mother            ;number of women with child-care responsibilities

;  lights?              ;boolean for streetlights, on dashboard

  count-women           ;number of women who reached destination
  count-men             ;number of men who reached destination
  count-mother          ;number of mothers who reached destination

  fem-alive-time        ;average number of ticks for women to reach destination
  men-alive-time        ;average number of ticks for men to reach destination
  mother-alive-time     ;average number of ticks for mothers to reach destination

;  traffic              ;float number from 0 to 1, on dashboard

]

patches-own
[
  dist-exit1            ;distance to destination using all roads [see define-routes-all]
  selected1?            ;whether a patch has been used to calculate distance [see define-routes-all]

  dist-exit-main-roads  ;distance to destination using main roads only [see define-routes-main-roads]
  selected2?            ;whether a patch has been used to calculate distance [see define-routes-main-roads]
  closest?              ;whether this patch is the closest patch to a turtle with main-road-dependency > 0.67
]

turtles-own
[
 next-patch            ;next patch
 on-road?              ;whether turtle has moved to it's closest road from home
 wait-time             ;number of ticks turtles has waited on the same patch
]



men-own
[
  main-road-dependency ;likelihood of men to stay on roads
]

women-own
[
  main-road-dependency ;likelihood of women to stay on roads
  with-minor?          ;whether a women has child-care responsibilities
]


;===================================================================================
; SETUP PROCEDURES
;===================================================================================

to setup

  ca
  reset-ticks

  setup-globals
  setup-patches
  setup-geography
       ;; subprocedures: create-dest, create-homes
  populate
  define-routes-all
  define-routes-main-roads

end

;----------------------------------------------------------------------------------
to setup-globals      ;; set  initialisation values for global variables

  set gridsize 3
  set num-homes 20
  set agent-size 2
  set num-men 400
  set num-women 400
  set count-mother 0
  set fem-alive-time 0
  set men-alive-time 0
  set traffic 0.9
  set-default-shape men "person"
  set-default-shape women "person"

end

;----------------------------------------------------------------------------------
to setup-geography

  create-dest
  create-homes

end
;----------------------------------------------------------------------------------
to create-dest     ;;set the destination of simulation
   ask (patches with [pxcor <= 2 and pxcor >= -2 and pycor <= 2 and pycor >= -2])
  [set pcolor black]
end

;----------------------------------------------------------------------------------
to create-homes    ;; randomly sprout homes across the environemnt

  ask n-of num-homes (patches with [pcolor = 39])
  [
   set pcolor green
  ]

end
;----------------------------------------------------------------------------------

to populate ;; spawn men and women on a sprouting patch
ask one-of patches with [pcolor = 2]
  [
   sprout-men num-men [setup-turtles setup-men]
   sprout-women num-women [setup-turtles setup-women]
  ]
end

;----------------------------------------------------------------------------------
to setup-turtles      ;; set initialisation values for turtles variables

  set size agent-size
  move-to one-of (patches with [pcolor = green])
  set count-women 0
  set count-men 0

  set on-road? false
  set wait-time 0
  set closest? false
  identify-closest

end
;----------------------------------------------------------------------------------
to setup-women      ;; set initialisation values for women breed turtles variables
  set color pink
  set main-road-dependency (0.4 + random-float 0.3)
  ifelse random-float 1 < 0.2
  [
    set with-minor? true
    set main-road-dependency (main-road-dependency * 1.3)
    if main-road-dependency > 1 [set main-road-dependency 1]
    set num-mother (count women with [with-minor? = true])
  ]
  [ set with-minor? false ]

end
;----------------------------------------------------------------------------------
to setup-men           ;; set initialisation values for men breed turtles variables
  set color blue
  set main-road-dependency 0.1 + random-float 0.4
end

;----------------------------------------------------------------------------------
to define-routes-all      ;; to calculate distance to destination taking account into all roads

  ask patches with [pcolor = black]
  [
    set dist-exit1 0
    set selected1? false
  ]

  ask patches with [(pcolor = green)]
  [
    set dist-exit1 1000000
    set selected1? false
  ]

  ask patches with [(pcolor = white or pcolor = 7 or pcolor = 4 or pcolor = 49.2)]
  [
    set dist-exit1 100000
    set selected1? false
  ]

  while [any? (patches with [dist-exit1 = 100000])]
  [
    let possible-patches (patches with [selected1? = false])
    let chosen-patch (one-of possible-patches with-min [dist-exit1])

    ask chosen-patch
    [
      set selected1? true
      ask (neighbors4 with [dist-exit1 = 100000])
      [set dist-exit1 (1 + [dist-exit1] of myself)]
    ]
  ]

end
;----------------------------------------------------------------------------------
to define-routes-main-roads  ;; to calculate distance to destination taking account into primary roads only

  ask patches with [pcolor = black]                                      ; the exit
  [
    set dist-exit-main-roads 0                                           ; set the distance to the exit as 0.
    set selected2? false
  ]
  ask patches with [(pcolor = green)]                                    ; the homes to make sure theyre not included in paths
  [
    set dist-exit-main-roads 1000000
    set selected2? false
  ]
  ask patches with [(pcolor = white or pcolor = 4)]                      ; the generic road and primary road
  [
    set dist-exit-main-roads 100000 ; set them as v far away
    set selected2? false
  ]

  while [any? (patches with [dist-exit-main-roads = 100000])]
  [
    let possible-patches (patches with [selected2? = false])
    let chosen-patch (one-of possible-patches with-min [dist-exit-main-roads])
    ask chosen-patch
    [
      set selected2? true ; tell itself that it is now the chosen patch
      ask (neighbors4 with [dist-exit-main-roads = 100000])
      [set dist-exit-main-roads (1 + [dist-exit-main-roads] of myself)]   ;set all its neigbhouring patches to be 1 + the distance from the chosen patch.
    ]
  ]

end
;----------------------------------------------------------------------------------
to setup-patches       ;; setup the simulation environment

  ask patches [set pcolor 39]


  ;; set all patches divisible by gridsize to a road to create a gridded network
  ask patches with [(pycor mod gridsize) = 0]
  [set pcolor white]
  ask patches with [(pxcor mod gridsize) = 0]
  [set pcolor white]
  ask patches with [(pxcor mod gridsize = 0) and (pycor mod gridsize = 0)]
  [set pcolor white]


  if lights? = true       ;; set up luminated streets
  [
  ask (patches with [(pxcor = -3 or pxcor = -9 or pxcor = -18) and (pycor <= 5 and pycor >= -20 )])
  [set pcolor 49.2]
  ask (patches with [(pxcor = 3 or pxcor = 9 or pxcor = 18) and (pycor <= 5 and pycor >= -23 )])
  [set pcolor 49.2]
  ask (patches with [(pycor = 3 or pycor = 0 or pycor = -9 or pycor = -18) and (pxcor <= 20 and pxcor >= -20 )])
    [set pcolor 49.2]
  ]

  ;; secondary roads
  ask (patches with [pxcor = -15 and pycor <= 5 and pycor >= -20])
  [set pcolor 7]

  ask (patches with [pxcor = -6 and pycor <= 5 and pycor >= 0])
  [set pcolor 7]

  ask (patches with [pxcor <= -3 and pxcor >= -15 and pycor = 0])
  [set pcolor 7]

  ask (patches with [pxcor <= -1 and pxcor >= -20 and pycor = 12])
  [set pcolor 7]

  ask (patches with [pxcor <= 21 and pxcor >= 1 and pycor = -12])
 [set pcolor 7]

  ask (patches with [pxcor <= 21 and pxcor >= 16 and pycor = -6])
 [set pcolor 7]

  ask (patches with [pxcor <= 28 and pxcor >= 1 and pycor = -24])
 [set pcolor 7]

  ask (patches with [pxcor = 21 and pycor <= 24 and pycor >= -24])
  [set pcolor 7]

  ask (patches with [pxcor = 15 and pycor <= 34 and pycor >= 7])
  [set pcolor 7]

  ask (patches with [pxcor <= -16 and pxcor >= -20 and pycor = -9])
  [set pcolor 7]

  ask (patches with [pxcor <= 20 and pxcor >= -20 and pycor = 0])
 [set pcolor 4]

  ask (patches with [pxcor <= 28 and pxcor >= 1 and pycor = 21])
 [set pcolor 7]

  ask (patches with [pxcor <= 6 and pxcor >= 1 and pycor = 9])
 [set pcolor 7]

 ask (patches with [pxcor <= 20 and pxcor >= 16 and pycor = 12])
 [set pcolor 7]

 ask (patches with [pxcor <= -1 and pxcor >= -35 and pycor = -6])
 [set pcolor 7]

  ask (patches with [pxcor <= -1 and pxcor >= -30 and pycor = -27])
  [set pcolor 7]

  ask (patches with [pxcor = -30 and pycor <= -22 and pycor >= -38])
  [set pcolor 7]

  ask (patches with [pxcor = 6 and pycor <= 8 and pycor >= 7])
  [set pcolor 7]


    ;; primary roads
   ask (patches with [pxcor <= 30 and pxcor >= -20 and pycor = 6])
  [set pcolor 4]

  ask (patches with [pxcor = 0 and pycor <= 34 and pycor >= -38])
  [set pcolor 4]

  ask (patches with [pxcor <= 0 and pxcor >= -39 and pycor = -21])
  [set pcolor 4]

  ask (patches with [pxcor = -21 and pycor <= 15 and pycor >= 6])
  [set pcolor 4]

  ask (patches with [pxcor <= -21 and pxcor >= -39 and pycor = 15])
  [set pcolor 4]

  ask (patches with [pxcor = 15 and pycor <= 5 and pycor >= -37])
  [set pcolor 4]

   ask (patches with [pxcor = -21 and pycor <= 5 and pycor >= -20])
  [set pcolor 4]

  ask (patches with [pxcor = 6 and pycor <= 5 and pycor >= -27])
  [set pcolor 4]

  ask (patches with [pxcor = 27 and pycor <= 15 and pycor >= 7])
  [set pcolor 4]

  ask (patches with [pxcor <= 26 and pxcor >= 1 and pycor = 15])
 [set pcolor 4]

  ask (patches with [pxcor <= 16 and pxcor >= 1 and pycor = -27])
 [set pcolor 4]

    ;; sprouting ground
  ask (patches with [pxcor = -60 and pycor = -60])
  [set pcolor 2]

end


;===================================================================================
; GO PROCEDURES
;===================================================================================
to go
  if (not any? turtles) [stop]
  turtle-movement
  tick

end

;----------------------------------------------------------------------------------
to turtle-movement
  ask turtles
  [
    move-to-destination
         ;; subprocedures:
    reach-destination
  ]
end
;----------------------------------------------------------------------------------
to reach-destination     ;;to report turtles count and total number of ticks to reach destination

    ifelse pcolor = black
    [
      ifelse breed = women
      [if with-minor? = false
        [
          set count-women (count-women + 1)
        ]
        if with-minor? = true
        [set count-mother (count-mother + 1)]
      ]
      [
        set count-men (count-men + 1)
      ]
      die
    ]
    [
      ifelse breed = women
      [
        if with-minor? = true
        [set mother-alive-time (mother-alive-time + 1)]
        if with-minor? = false
        [set fem-alive-time (fem-alive-time + 1)]
      ]
      [set men-alive-time (men-alive-time + 1)]
    ]

end
;----------------------------------------------------------------------------------
to move-to-destination

     ;;High road dependency population
           ;;Prioritise to get to the closest primary/secondary road, then look to move to a primary road with minimum distance to destination
    ifelse main-road-dependency >= 0.7
    [
      ifelse on-road? = false
      [move-to-closest]
    [
        ifelse any? neighbors4 with [(pcolor = 4 or pcolor = black) and any? neighbors4 with-min [dist-exit-main-roads]]
      [move-to-mainroad-min-dist]
      [
          if any? neighbors4 with [(pcolor = 7 or pcolor = black or pcolor = 49.2) and any? neighbors4 with-min [dist-exit1]]
        [move-to-secondary-road-min-dist]
      ]
    ]
  ]
    ;; Medium road dependency population
          ;; Both minimum travel time and general road safety are prioritise, but not to a strict degree.
  [
    ifelse main-road-dependency >= 0.34 and main-road-dependency < 0.7
    [
      ifelse any? neighbors4 with [(pcolor = 4 or pcolor = 7 or pcolor = black or pcolor = 49.2) and any? neighbors4 with-min [dist-exit1]]
      [
        move-to-anyroad-min-dist
        escape-loop
      ]
      [
        ifelse any? neighbors4 with [(pcolor = 4 or pcolor = 7 or pcolor = black or pcolor = 49.2)]
        [move-to-mainroad]
        [move-to-shortest-path]
      ]
    ]
       ;; Low road dependency population
    [           ;; Prioritise minimum travel time and little regard for road safety.
      if main-road-dependency < 0.34
      [move-to-shortest-path]
    ]
  ]

end

;----------------------------------------------------------------------------------
to identify-closest      ;; identify the closest primary/secondary road patch from home
  ask min-one-of patches with [(pcolor = 4 or pcolor = 7 or pcolor = black or pcolor = 49.2)] in-radius 70 [distance myself]
  [set closest? true]
end
;----------------------------------------------------------------------------------
to move-to-closest       ;; move towards identified closest primary/secondar road patch
  let target-patch min-one-of (patches in-radius 70 with [closest? = true and any? turtles-here = false] ) [distance myself]
  ifelse any? neighbors with  [closest? = true]
  [
    carefully
    [
      move-to target-patch
      set on-road? True
    ]
    []
  ]
  [
    carefully
    [
      face target-patch
      ifelse not any? turtles-on patch-ahead 1
      [fd 0.7]
      [
        set heading heading + random 270
        fd 0.7
      ]
    ]
    []
  ]
end
;----------------------------------------------------------------------------------
to move-to-anyroad-min-dist   ;;move to any neighbouring primary, secondary, or luminated roads that has minimum distance to destination

  ifelse count turtles-on neighbors4 >= 3
  [
    if random-float 1 > traffic
    [
       carefully
    [
      move-to one-of neighbors4 with [pcolor = 4 or pcolor = 7 or pcolor = black or pcolor = 49.2] with-min [dist-exit1]
    ]
    []
  ]
  ]
  [carefully
    [
      move-to one-of neighbors4 with [pcolor = 4 or pcolor = 7 or pcolor = black or pcolor = 49.2 and any? turtles-here = false] with-min [dist-exit1]
    ]
    []
  ]

end
;----------------------------------------------------------------------------------
to move-to-mainroad-min-dist          ;; move to neighbouring primary roads with minimum distance

  ifelse count turtles-on neighbors4 >= 3
  [
    if random-float 1 > traffic
    [
       carefully
    [
      move-to one-of neighbors4 with [pcolor = 4 or pcolor = black] with-min [dist-exit-main-roads]
    ]
    []
    ]
  ]
  [carefully
    [
      move-to one-of neighbors4 with [pcolor = 4 or pcolor = black and any? turtles-here = false] with-min [dist-exit-main-roads]
    ]
    []
  ]

end
;----------------------------------------------------------------------------------
to move-to-secondary-road-min-dist       ;; move to neighbouring secondary roads with minimum distance
   ifelse count turtles-on neighbors4 >= 3
  [
    if random-float 1 > traffic
    [
       carefully
    [
      move-to one-of neighbors4 with [pcolor = 7 or pcolor = 49.2] with-min [dist-exit1]
    ]
    []
    ]
  ]
  [
    carefully
    [
      move-to one-of neighbors4 with [pcolor = 7 or pcolor = 49.2 and any? turtles-here = false] with-min [dist-exit1]
    ]
    []
  ]

end
;----------------------------------------------------------------------------------
to move-to-mainroad               ;; move to any neighbouring primary and secondary roads, regardless distance to destination
ifelse count turtles-on neighbors4 >= 3
  [
    if random-float 1 > traffic
    [
       carefully
    [
      move-to one-of neighbors4 with [pcolor = 7 or pcolor = 4 or pcolor = 49.2]
    ]
    []
    ]
  ]
 [
  carefully
  [
  move-to one-of neighbors4 with [pcolor = 4 or pcolor = 7 or pcolor = 49.2 and any? turtles-here = false]
  ]
  []
  ]
end
;----------------------------------------------------------------------------------
to move-to-shortest-path        ;; move towards destination via the shortest path following any available roads

  set next-patch one-of ((neighbors4 with [(pcolor != 39)]) with-min [dist-exit1])

    face next-patch
    move-to next-patch

end
;----------------------------------------------------------------------------------
to escape-loop                  ;; if turtles get trapped in a loop
  if count neighbors4 with [pcolor = 4 or pcolor = 7 or pcolor = black ] with-min [dist-exit1] >= 2
  [
    move-to-mainroad-min-dist
  ]
end
;===================================================================================
; REPORTERS
;===================================================================================
 ;; report average time to reach destination in minutes.
to-report women-steps-to-dest-avg

  report fem-alive-time * 0.16 / num-women

end
;----------------------------------------------------------------------------------

to-report men-steps-to-dest-avg

  report men-alive-time * 0.16 / num-men

end
;----------------------------------------------------------------------------------

to-report mother-steps-to-dest-avg

  report mother-alive-time * 0.16 / num-mother

end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
823
624
-1
-1
5.0
1
10
1
1
1
0
0
0
1
-60
60
-60
60
1
1
1
ticks
200.0

BUTTON
69
133
135
166
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
70
177
133
210
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
69
224
132
257
step
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
842
114
962
159
count-women
count-women
17
1
11

MONITOR
843
175
925
220
count-men
count-men
17
1
11

MONITOR
988
114
1170
159
women-steps-to-dest-avg 
women-steps-to-dest-avg
1
1
11

MONITOR
989
175
1151
220
men-steps-to-dest-avg
men-steps-to-dest-avg
1
1
11

MONITOR
842
53
943
98
NIL
count-mother
17
1
11

MONITOR
987
52
1167
97
NIL
mother-steps-to-dest-avg
1
1
11

SWITCH
863
619
966
652
lights?
lights?
1
1
-1000

PLOT
853
264
1307
541
Average time to reach destination
ticks
minutes to reach destination
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -2064490 true "" "plot women-steps-to-dest-avg"
"pen-1" 1.0 0 -14070903 true "" "plot men-steps-to-dest-avg"

SLIDER
863
578
1036
611
traffic
traffic
0
1
0.9
0.1
1
NIL
HORIZONTAL

@#$#@#$#@
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.3.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
