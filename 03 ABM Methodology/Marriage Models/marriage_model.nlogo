; Coded by Thomas Oléron Evans from the ODD description provided by Railsback & Grimm (2011)
; Available here: http://www.railsback-grimm-abm-book.com/downloads.html

; Based on a model originally created by Billari et al (2007)
; Billari, F. C., A. Prskawetz, B. Aparicio Diaz, and T. Fent. 2007. The “wedding-ring”: an agent-based marriage model based on social interactions. Demographic Research 17:59-82. Available on-line at: www.demographic-research.org/Volumes/Vol17/3/

globals
[
  initial-marriage-prob      ; Initial probability that an agent is married
  social-network-age-range   ; Maximum difference in age between partners
  social-network-angle-range ; Maximum difference in social angle between partners
  min-marriage-age           ; Minimum age of marriage (for a turtle choosing to marry - their partner may actually be younger)
  num-babies                 ; Number of children born each time step (if there are enough married women)
  tick-limit                 ; Number of years of simulation
  num-turtles                ; Initial number of turtles

  ; x01 ; Related to the 'social-pressure' calculation (set in the Interface)
  ; x09 ; Related to the 'social-pressure' calculation (set in the Interface)
  a     ; Related to the 'social-pressure' calculation
  b     ; Related to the 'social-pressure' calculation
]

turtles-own
[
  gender       ; string m/f
  age          ; int 0-60
  married?     ; boolean
  partner      ; turtle or nobody
  social-angle ; int 0-360
  mother       ; turtle or nobody (initial turtles have no parents)
  father       ; turtle or nobody (initial turtles have no parents)
  newlywed?    ; boolean (this variable was used for testing, to examine the rate of new marriages)

]

patches-own
[
]

to setup

  ca

  ; set patch color

  ask patches [set pcolor white]

  ; set all variables

  set initial-marriage-prob 0.1
  set social-network-age-range 3
  set social-network-angle-range 20
  set min-marriage-age 16
  set tick-limit 200
  set num-babies 16
  set num-turtles 1000

  ; set x01 0.3 ; set in Interface
  ; set x09 0.7 ; set in Interface
  set b (-4.394 / (x01 - x09)) ; see ODD description for justification of these formulae
  set a -2.197 - (b * x01) ; see ODD description for justification of these formulae

  crt num-turtles ; initialise the turtles
  [

    ; randomise their age, social-angle, gender

    set age random 60
    set social-angle random 360
    set gender one-of ["m" "f"]

    ; initial turtles are all orphans

    set mother nobody
    set father nobody

    ; this procedure places the turtles in age/social-angle space

    update-location

    ; some cosmetic variables

    set size 10
    set heading social-angle

    ; default is unmarried

    set married? false

  ]

  ; who is married to who initially?

  initialise-marriages

  ; colors distinguish between male/female and married/unmarried
  ; blue/pink (unmarried male/female), black/red (married male/female)

  ask turtles
  [
    set-your-color
  ]

  setup-plotting ; setup the plots

  reset-ticks

end

to go

  ; every year, newlyweds stop being newlyweds

  ask turtles [set newlywed? false]

  ; the three main model processes

  ageing
  childbirth
  marriage

  ; end condition

  if ticks > tick-limit [stop]

  plotting ; procedure that updates the plots

  tick

end

to ageing ; observer context

  ; each year you get older
  ; at 61 you die
  ; your location also has to be updated as you age

  ask turtles
  [
    set age (age + 1)
    if age > 60 [death]
    update-location
  ]
end

to childbirth ; observer context

  ; randomly select num-babies female married turtles under 40
  ; they each have a baby (which immediately runs the initialise-baby procedure)
  ; however, there might not be enough such women, hence the use of 'carefully' to avoid an error.
  ; the alternative code just makes all such women have babies

  carefully
  [
    ask n-of num-babies (turtles with [(gender = "f") and (age < 40) and (married? = true)])
    [hatch 1 [initialise-baby]]
  ]
  [ask (turtles with [(gender = "f") and (age < 40) and (married? = true)])
    [hatch 1 [initialise-baby]]
  ]
end

to marriage ; observer context

  ; all unmarried turtles over the minimum marriage age consider getting married
  ; they do so with probability equal to their social-pressure value (see the relevant reporter procedure) - if they are already unmarried
  ; a partner is selected from those in the social-network (see the relevant reporter procedure) who are unmarried and of the opposite gender
  ; The 'carefully' here may be redundant. It is designed to catch situations where there are no suitable partners.
  ; However, this should return 'nobody' anyway, so there is probably no problem.

  ask turtles with [age >= min-marriage-age]
  [
    if (married? = false) and (random-float 1) < social-pressure
    [
    carefully
      [
        set partner (one-of (social-network with [(married? = false) and (gender != ([gender] of myself))]))
        if partner != nobody
        [
          set married? true
          set newlywed? true
          partner-marriage-admin ; this procedure asks the partner to change their state variables to reflect their new relationship
          set-your-color
        ]
      ]
      []
    ]
  ]
end

to update-location ; turtle context

  ; places a turtle at the correct location in the world
  ; (note that the world has six cells horizontally to one year/tick, to make it square)

  setxy (6 * age) social-angle

end

to initialise-baby ; turtle context

  ; a new turtle sets all its relevant variables

  set mother myself
  set father ([partner] of myself)

  set partner nobody

  set age 0

  set-baby-social-angle ; procedure to set the social angle randomly between those of mother and father

  set gender one-of ["m" "f"]
  update-location
  set married? false

  set-your-color

  set size 10
  set heading social-angle

end

to set-baby-social-angle ; turtle context

  ; procedure that sets a baby's social angle
  ; all it does is randomly choose an angle between those of its parents
  ; however, the procedure is complicated by the fact that the world wraps vertically (what does between mean?)

  let mother-social-angle [social-angle] of mother
  let father-social-angle [social-angle] of father

  let max-sa (max (list mother-social-angle father-social-angle))
  let min-sa (min (list mother-social-angle father-social-angle))

  let base-sa 0
  let difference 0

  ifelse (max-sa - min-sa) <= 180
  [
    set base-sa min-sa
    set difference (max-sa - min-sa)
  ]
  [
    set base-sa max-sa
    set difference (min-sa - max-sa) + 360
  ]

  let new-sa (base-sa + random (difference + 1))

  if (new-sa > 360) [set new-sa (new-sa - 360)]

  set social-angle new-sa

end

to death ; turtle context

  ; procedure that kills turtles, called when they reach 60
  ; informs the partner of dead turtle (if any) that they are now unmarried and have no partner

  if married?
  [
    ask partner
    [
      set married? false
      set partner nobody
      set-your-color
    ]
  ]

  die

end

to set-your-color ; turtle context

  ; colors distinguish between male/female and married/unmarried
  ; blue/pink (unmarried male/female), black/red (married male/female)

  ifelse gender = "m"
  [ifelse married? [set color black] [set color blue]]
  [ifelse married? [set color red] [set color pink]]

end

to-report social-network ; turtle context

  ; returns all turtles in a rectangle near the turtle
  ; size of rectangle is specified by global variables

  let min-sa (social-angle - social-network-angle-range)
  let max-sa (social-angle + social-network-angle-range)
  let min-age (age - social-network-age-range)
  let max-age (age + social-network-age-range)

  report ((other turtles) with
    [ (social-angle >= min-sa) and (social-angle <= max-sa) and (age >= min-age) and (age <= max-age)])

end

to-report married-fraction-of-sn ; turtle context

  ; fraction of a turtle's social network who are married
  ; carefully, because you don't want to divide by zero

  let report-val 0
  carefully
  [set report-val (count (social-network with [married? = true])) / (count social-network)]
  []
  report report-val

end

to-report social-pressure

  ; The probability that a turtle married based on the fraction of its social network who are married
  ; see ODD description for an explanation of these calculations

  ; The below are possible default values for a and b (currently determined by slider values x01 and x09)
  ; They correspond to x01 = 0.3, x09 = 0.7 (as explained in the ODD description)

  ; let a -5.4925
  ; let b 10.985

  let Z (a + (b * married-fraction-of-sn))

  report (exp Z) / (1 + exp Z)

end

to partner-marriage-admin ; turtle context

  ; called by newly married turtle to ask new partner to change their relationship status

  ask partner
  [
    set married? true
    set newlywed? true
    set partner myself
    set-your-color
  ]
end

to initialise-marriages ; observer context

  ; This procedure initialises marriages in the setup
  ; All marriages are m-f, following the original published model
  ; Only women of marriageable age are considered and choose their partners from the whole male population.

  ask turtles with [gender = "f" and age >= min-marriage-age]
  [
    if (random-float 1) < initial-marriage-prob
    [
      set married? true
      set partner (one-of ((other turtles) with [(gender = "m" and married? = false and age >= min-marriage-age)]))
      partner-marriage-admin
    ]
  ]

end

to setup-plotting

  ; This procedure sets up the necessary plots
  ; The defaults for the line plot of social pressure are fine
  ; so we only need to setup the histogram:

  set-current-plot "Histogram of Married Individuals by Age"
  set-plot-x-range 0 60
  set-plot-y-range 0 80
  set-histogram-num-bars 12

end

to plotting

  ; This procedure updates the two plots
  ; The titles of the plots say what they show:

  set-current-plot "Mean Social Pressure of Unmarried Individuals of Marriageable Age"
  let plotvar mean [social-pressure] of (turtles with [age >= min-marriage-age and married? = false])
  plot plotvar

  set-current-plot "Histogram of Married Individuals by Age"
  histogram [age] of (turtles with [married? = true])

end
@#$#@#$#@
GRAPHICS-WINDOW
437
23
962
547
-1
-1
1.432133
1
10
1
1
1
0
0
1
1
0
360
0
359
0
0
1
ticks
30.0

BUTTON
19
100
85
133
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
87
100
150
133
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
87
135
150
168
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

PLOT
15
191
392
523
Mean Social Pressure of Unmarried Individuals of Marriageable Age
NIL
NIL
0.0
200.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" ""

SLIDER
20
23
428
56
x01
x01
0
1.0
0.3
0.01
1
NIL
HORIZONTAL

SLIDER
20
56
428
89
x09
x09
0
1
0.7
0.01
1
NIL
HORIZONTAL

PLOT
971
23
1390
364
Histogram of Married Individuals by Age
NIL
NIL
0.0
10.0
0.0
10.0
false
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" ""

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
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
NetLogo 6.0.1
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
