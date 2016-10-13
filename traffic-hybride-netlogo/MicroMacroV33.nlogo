__includes ["Network.nls" "Initialization.nls" "LWR.nls" "Underwoods.nls" "NaSch.nls" "LWRHybrid.nls" "Discretization.nls"]

breed [cars car]

cars-own
[
  speed                                          ; speed of a car
  my-current-edge                                ; edge of a car
  current-node                                   ; origin node of the edge the car is on
  next-node                                      ; end node of the edge the car is on
  concentration-of-my-current-edge               ; concentration of the edge the car is on
  distance-next-node                             ; distance between the car and the next node
  dn                                             ; distance between a car and the car just ahead
]

globals
[
  time-first-car-reach-all-edges
  time-last-car-reach-all-edges
  Time-to-reach-all-edges
  nb-visited-edges
  last-node
  last-edge
  nb-subedges                                    ; number of subedges of a LWR edge (see Discretization.nls)

  ;; space, time & shifting parameters
  road-size-patch
  patch-size-km
  nb-edges
  car-size-km
  car-size-patch
  nb-cars-init
  speed-max-on-edge
]

to setup
  ca
  setup-nodes
  connect-nodes
  if Hybrid-Model? [define-LWR-Sections]
  initialize-globals
  initialize-length
  initialize-edges
  ask edges
  [
    update-edges-display
  ]
  discretise-LWR-edges
  setup-cars
  reset-ticks
end



to go
  reach-all-edges
  ifelse Hybrid-Model?
  [
    go-hybrid
  ]
  [
    go-nothybrid
  ]
    color-nodes
  tick
  if ticks = Time-to-reach-all-edges * nb-rd-stop
  [
    stop
  ]
end

to go-nothybrid
  ifelse traffic-function = "LWR"
  [
    ask edges
    [
      OfferFunction
      DemandFunction
    ]
    UpdateFlow
    UpdateConcentration
    Compute-LWR-speed
  ]
  [
    ifelse traffic-function = "NaSch"
    [
      update-car-position
      initialize-NasCh-speed
      NaSch-model
    ]
    [
      update-Underwood
      update-car-position
    ]
  ]
  ask edges
  [
    set cumulated-current-concentration cumulated-current-concentration + current-concentration
    tag-edges
    update-edges-display
  ]

end


to update-car-position
   ask cars
   [
     update-my-position
   ]
end


to color-nodes
  ask edges
  [
    ifelse current-concentration > 0
   [ ask end1
    [
      set color red
    ]
   ]
   [
     ask end1
     [
      set color white
     ]
   ]
    if speed-on-Edge * patch-size-km * 3600  > 90
    [
      set color yellow
    ]
  ]
end

to update-my-position
  let distance-to-next-node distance next-node
  let next-edge [one-of my-out-links] of next-node
  let next_edge_LWR? [LWR-Section] of next-edge = 1
  let epsilon speed / 1                                 ; By default / 1 since we do not take into account a finest approach of destination node
  ifelse distance-to-next-node <= epsilon
    [
      move-to next-node
      if next_edge_LWR?
      [
        UpdatePreviousEdgeFlowFromCars
      ]
      update-car-edge-current
      update-car-edge-next
      if [LWR-Section] of  my-current-edge = 1
        [
          die
        ]

    ]
    [
      ifelse distance-to-next-node > speed
      [
        fd speed
      ]
      [
        ; we first assume that speed is lower that the size of an edge

        fd distance-to-next-node
        if next_edge_LWR?
          [
            UpdatePreviousEdgeFlowFromCars
          ]
        update-car-edge-current
        update-car-edge-next
        update-Underwood
        fd (speed - distance-to-next-node)
        if [LWR-Section] of  my-current-edge = 1
          [
            die
          ]

     ]
  ]
end


to update-car-edge-current
  ask my-current-edge
  [
    set current-concentration current-concentration - 1
    set number-of-cars-passed number-of-cars-passed  + 1
  ]
  ask cars with [my-current-edge = [my-current-edge] of myself]
  [
   set concentration-of-my-current-edge concentration-of-my-current-edge - 1
  ]
end

to update-car-edge-next
  set my-current-edge one-of [my-out-edges] of next-node
  ask my-current-edge
  [
    set current-concentration current-concentration + 1
  ]
  set concentration-of-my-current-edge count cars with [my-current-edge = [my-current-edge] of myself]
  set current-node [end1] of my-current-edge
  set next-node [end2] of my-current-edge
  set heading towards next-node
end


to update-distance-next-node
  ask cars
  [
    set distance-next-node distance-nowrap next-node              ; for each car, this gives the distance to next node
  ]
end


to tag-edges
  if current-concentration > 0 and edge-already-visited? = 0
  [
    set  edge-already-visited? 1
  ]
end

to reach-all-edges
  let alledges count edges
  set Nb-visited-edges count edges with [edge-already-visited? = 1]

     if Nb-visited-edges = alledges and time-first-car-reach-all-edges = 0
     [
        set time-first-car-reach-all-edges ticks
     ]



    let  comparison-edge one-of edges with [end2 = Node 0 ]     ; identification of the last edge to determine the time needed for all crs to reach this last edge

   ifelse traffic-function = "LWR" or [LWR-section] of comparison-edge = 1
   [
     if time-last-car-reach-all-edges = 0 and [edge-already-visited?] of comparison-edge = 1 and [cumulated-current-concentration] of comparison-edge >= nb-cars-init
    [

       set time-last-car-reach-all-edges ticks
    ]

     ]

   [if time-last-car-reach-all-edges = 0 and [edge-already-visited?] of comparison-edge = 1 and [number-of-cars-passed] of comparison-edge >= nb-cars-init
    [

       set time-last-car-reach-all-edges ticks
    ]
   ]



end
@#$#@#$#@
GRAPHICS-WINDOW
701
14
1196
530
5
5
44.1
1
10
1
1
1
0
0
0
1
-5
5
-5
5
1
1
1
ticks
30.0

BUTTON
5
26
63
59
Setup
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

SLIDER
67
26
160
59
nb-nodes
nb-nodes
3
100
4
1
1
NIL
HORIZONTAL

PLOT
5
222
701
382
Concentrations
Time
Edges concentrations
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Min" 1.0 0 -14070903 true "" "plotxy ticks min [current-concentration] of edges"
"Max" 1.0 0 -14333415 true "" "plotxy ticks max [current-concentration] of edges"
"Mean" 1.0 0 -8053223 true "" "plotxy ticks mean [current-concentration] of edges"

INPUTBOX
3
107
243
167
maximum-speed-on-edges
90
1
0
Number

CHOOSER
308
10
494
55
traffic-function
traffic-function
"LWR" "Homogeneous" "Underwood" "Underwood-Random" "Underwood-Cars-Forward" "NaSch"
5

INPUTBOX
252
105
350
165
car-size
1
1
0
Number

TEXTBOX
259
89
350
115
Car Size (m)
10
0.0
1

TEXTBOX
8
89
214
115
Maximum Speed on Eddges (km/h)
10
0.0
1

PLOT
7
535
617
686
Speed of cars
Time
Speed
0.0
10.0
0.0
100.0
true
true
"" ""
PENS
"Min" 1.0 0 -13345367 true "" "if any? cars\n[ \n   plotxy ticks min [speed] of cars * patch-size-km * 3600 \n]"
"Max" 1.0 0 -15637942 true "" "if any? cars\n[\nplotxy ticks max [speed] of cars * patch-size-km * 3600 \n]"
"Mean" 1.0 0 -5298144 true "" "if any? cars \n[\nplotxy ticks mean [speed] of cars * patch-size-km * 3600 \n]"

PLOT
621
535
1194
685
Speed of one car (km/h)
Time
Speed
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -5298144 true "" "if any? cars \n[\nask one-of cars\n[\n  plotxy ticks Speed * patch-size-km * 3600 \n]\n]"

TEXTBOX
496
627
646
672
***************\nExcept for LWR\n***************
12
0.0
1

TEXTBOX
1096
629
1211
674
***************\nExcept for LWR\n***************
12
0.0
1

TEXTBOX
570
323
655
368
***********\nAll models\n***********
12
0.0
1

MONITOR
36
451
245
496
time-first-car-reach-all-edges
time-first-car-reach-all-edges
17
1
11

MONITOR
36
404
245
449
time-last-car-reach-all-edges
time-last-car-reach-all-edges
17
1
11

PLOT
7
687
617
837
Speed on edges
NIL
NIL
0.0
10.0
0.0
100.0
true
true
"" ""
PENS
"Min" 1.0 0 -14070903 true "" "if any? edges with [lwr-section = 1]\n[\nplotxy ticks ( min [speed-on-Edge] of edges with [lwr-section = 1] )  * patch-size-Km * 3600 \n]"
"Max" 1.0 0 -13210332 true "" "if any? edges with [lwr-section = 1]\n[ \nplotxy ticks ( max [speed-on-Edge] of edges with [lwr-section = 1] )  * patch-size-km * 3600\n]"
"Mean" 1.0 0 -2674135 true "" "if any? edges with [lwr-section = 1]\n[\nplotxy ticks ( mean [speed-on-Edge] of edges with [lwr-section = 1] )  * patch-size-km * 3600\n]"

TEXTBOX
447
782
597
827
**********************\nLWR Speed on edges\n**********************
12
0.0
1

SLIDER
499
10
693
43
NaSch-Noise
NaSch-Noise
0
1
0
0.01
1
NIL
HORIZONTAL

SLIDER
500
43
693
76
NaSch-Factor
NaSch-Factor
0
1
0.33
0.01
1
NIL
HORIZONTAL

PLOT
279
388
540
529
Error Plot
NIL
NIL
0.0
10.0
-1.0E-11
1.0E-11
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot nb-cars-init - sum  [current-concentration + car-remainder] of edges"

INPUTBOX
359
106
436
166
road-size-km
1
1
0
Number

SLIDER
500
77
694
110
Underwood-Factor
Underwood-Factor
0
1
0.4
0.01
1
NIL
HORIZONTAL

SLIDER
167
44
302
77
nb-LWR-edges
nb-LWR-edges
0
nb-nodes - 1
1
1
1
NIL
HORIZONTAL

SWITCH
167
10
302
43
hybrid-model?
hybrid-model?
0
1
-1000

BUTTON
601
170
656
203
Go
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

SLIDER
7
174
301
207
critical-concentration-reduction-factor
critical-concentration-reduction-factor
0.1
1
0.5
0.1
1
NIL
HORIZONTAL

PLOT
622
686
1194
836
Speed of one of LWR edge
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "if any? edges with [lwr-section = 1]\n[\n plotxy ticks [speed-on-Edge] of one-of edges with [lwr-section = 1] * patch-size-km * 3600\n]"

TEXTBOX
1107
782
1257
827
*************\nOnly for LWR\n*************
12
0.0
1

TEXTBOX
360
90
459
116
Road Size (km)
10
0.0
1

INPUTBOX
517
144
592
204
nb-rd-stop
6
1
0
Number

TEXTBOX
405
469
536
514
********************\nTrafic conservation\n********************
12
0.0
1

SLIDER
308
56
480
89
Initial-trafic-factor
Initial-trafic-factor
0
1
0.1
0.05
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

The LWR model was proposed by Lighthill and Whitham (1955) and by Richards (1956).

Author: A. Banos, N. Corson, P. Taillandier

This model describes the trafic at a global level considering the speed, concentration and flows without taking into account the individual behavior af vehicles.
Speed, concentration and flow are the three components of the LWR model.
This models reproduces flow of traffic and congestion in specific conditions (homogeneous traffic), 	going from one equilibrium state to another (see the fundamental diagramm of traffic, which gives flow according to concentration).
In this model, a road is divided into sections and we arbitrarily give to the middle section a lower speed and critical concentration.

## CREDITS AND REFERENCES

 * LIGHTHILL, M.J., WHITHAM, G.B., On kinematic waves II. A theory of traffic flow on long crowded roads, Proceedings of the Royal Society A, 1955, vol. 229 , pp. 317-345.

 * RICHARDS, P.I., Shockwaves on the highway, Operations research, 1956, vol. 4, pp. 42-51.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arn-car-yellow
true
0
Rectangle -256 true false 76 29 225 270
Rectangle -256 true false 59 44 75 90
Rectangle -256 true false 224 210 240 256
Rectangle -256 true false 60 209 75 255
Rectangle -256 true false 224 44 241 90
Rectangle -16776961 true false 99 64 204 118
Rectangle -16776961 true false 120 210 186 237

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

dot-arn
false
0
Circle -16777216 true false 60 60 180
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
NetLogo 5.2.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment-FlowDensity" repetitions="30" runMetricsEveryStep="false">
    <setup>setup-FlowDensity-Diagram-BehaviorSpace</setup>
    <go>compute-FlowDensity-Diagram-BehaviorSpace</go>
    <final>set NumberCarsDuring-Measuring-Time-Tick  (NbCarsInit - count cars)</final>
    <exitCondition>ticks &gt;= Measuring-Time-Tick</exitCondition>
    <metric>NumberCarsDuring-Measuring-Time-Tick</metric>
    <enumeratedValueSet variable="TrafficFunction">
      <value value="&quot;Underwood&quot;"/>
      <value value="&quot;Underwood Cars Forward&quot;"/>
      <value value="&quot;NaSch&quot;"/>
    </enumeratedValueSet>
    <steppedValueSet variable="NB-Cars" first="10" step="10" last="200"/>
    <steppedValueSet variable="CriticalConcentration-ReductionFactor" first="0.1" step="0.1" last="1"/>
  </experiment>
  <experiment name="experiment-duration" repetitions="30" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>ticks = Time-to-reach-all-edges * NbTrStop</exitCondition>
    <metric>time-last-car-reach-all-edges</metric>
    <metric>time-first-car-reach-all-edges</metric>
    <enumeratedValueSet variable="TrafficFunction">
      <value value="&quot;LWR&quot;"/>
      <value value="&quot;Underwood&quot;"/>
      <value value="&quot;Underwood Cars Forward&quot;"/>
      <value value="&quot;NaSch&quot;"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
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

link-arn
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Polygon -7500403 true true 150 105 135 180 165 180

link-arn2
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0

@#$#@#$#@
0
@#$#@#$#@
