;The purpose of our ABM is to help the seasonal climate forecast community better understand to what degree the integration of forecast information into
;local-level decision-making may provide value for smallholder farming communities and related patterns of adoption based on communication through local
;agricultural extension experts and peer farmer agents.
;Developed by Sarah Alexander, University of Wisconsin-Madison, 2021

extensions [rnd matrix csv]

;variables for the total years of simulation and number households as well as variables all entities need access to for climate/crop info
globals [year years-simulated num-households total-fields num-experts AN-cutoff BN-cutoff forecast-prob forecast-rain forecast-skill
  actual-rain FcstResp-matrix PrecipPredSeries PrecipObsSeries PrecipSkillSeries MaizePayoff TeffPayoff dry-years wet-years expert-share peer-share]

breed [fields field]
breed [households household]
breed [experts expert]

; patches represent fields for households and have the following variables/information
fields-own [household-turtle maize-grown teff-grown ]

; turtle agents represent one household and have the following variables
households-own [num-fields field1 trust trust-expert trust-peer trust-rate food-store Mdecision Tdecision hear-peer hear-expert use-forecast
  adopt-group trust-thres heuristic peertalk ready-change peer-ben num-changes Tconstant Tweight peer-ftu]

; agricultural expert agents in the community do not have any state variables
experts-own []


to setup

  clear-all

  random-seed param-rand-seed
  ;world is set to 37 x 37, representing ~53 sq ha or approximately 2,830 sq km for ~700 households
  set year -1
  set years-simulated 39 ;simulate 39 years (1981-2019)
  set num-households 1260 ;Ziervogel uses 700 but I shifted to 15x15 world and 70 households so each has 3 fields and it works out evenly
  set total-fields 1260 ;set this to the number of patches (fields) available
  set num-experts 3

  ;if not pre-specifying values then should input historical rainfall, rainfall-crop yield matrix, and fit gaussian distribution
  set BN-cutoff 1031
  set AN-cutoff 1118.3
  set dry-years []
  set wet-years []

  set PrecipPredSeries csv:from-file "KogaPrecipPredSeries3.csv"
  set PrecipObsSeries csv:from-file "KogaObsPrecipSeries3.csv"
  set PrecipSkillSeries csv:from-file "PredSkillSeries3.csv"

  ;percent of farmer agents who trust peers, experts respectively
  set expert-share 68
  set peer-share 45

  ;input forecast response option matrices for crop ratio and density (cols: maize, teff)
  set FcstResp-matrix matrix:from-row-list [[30 70][50 50][90 10]]

  ;input yield matrices for sorghum and maize
  set MaizePayoff csv:from-file "CropPayoff_Maize3Series.csv"
  set TeffPayoff csv:from-file "CropPayoff_Teff3Series.csv"

  ;create the field turtles
  create-fields total-fields
  [
    set color 57
    set shape "plant"
    move-to one-of patches with [not any? turtles-here]
  ]

   ; Create the household turtles and set their state variables
  create-households num-households
  [
    set color 1
    set shape "person"
    move-to one-of patches with [not any? households-here]
    set num-fields 1
    set trust 0
    set trust-rate 1
    ifelse random 100 < 69 [set trust-expert 1] [set trust-expert 0]
    ifelse random 100 < 44 [set trust-peer 1] [set trust-peer 0]
    set food-store 0
    set hear-peer 0
    set hear-expert 0
    set use-forecast 0
    set ready-change 0
    set peer-ben 0
    set num-changes 0
    set Tconstant 0.1
    set Tweight 0
    set peer-ftu 0

    ; categorize farmers into early adopter (34%), middle (40%) and late adopter (26%) categories
    let num random 100
    ifelse num < 74 [ifelse num < 34 [set adopt-group 0][set adopt-group 1]][set adopt-group 2] ; 0 = early, 1 = middle, 2 = late

    ; define characteristics of the adopter categories
    if adopt-group = 0 [ifelse random 100 < 40 [set trust-thres 1][set trust-thres 2]set heuristic 4]
    if adopt-group = 1 [ifelse random 100 < 50 [set trust-thres 3][set trust-thres 4]set heuristic 1]
    if adopt-group = 2 [ifelse random 100 < 60 [set trust-thres 5][set trust-thres 6]set heuristic 2]

    ; link each household to a field
    create-link-with one-of fields with [not any? link-neighbors] ;creates link to just one field
    set field1 [who] of link-neighbors
  ]

  ;create the agricultural extension expert turtles
  create-experts num-experts
  [
    set color 15
    set shape "person"
    move-to one-of patches with [not any? experts-here]
  ]

  ;ask fields [set household-turtle households with [field1 = myself]]
  ask fields [set household-turtle [who] of link-neighbors]

  ask patches
  [
    ifelse not any? fields-here [set pcolor 35][set pcolor (53 + random 3)]
  ]

;  setup-plots
  ;open a file to record output for fields
  if (file-exists? "AlexanderBlock_ABM_FieldOutput.csv")
  [
    carefully
      [file-delete "AlexanderBlock_ABM_FieldOutput.csv"]
      [print error-message]
  ]
  file-open "AlexanderBlock_ABM_FieldOutput.csv"
  file-type "id,"
  file-type "tick,"
  file-type "year,"
  file-type "maize-grown,"
  file-type "teff-grown,"
  file-print "household-turtle"
  file-close

   ;open a file to record output for farmer agents
  if (file-exists? "AlexanderBlock_ABM_FarmerOutput.csv")
  [
    carefully
      [file-delete "AlexanderBlock_ABM_FarmerOutput.csv"]
      [print error-message]
  ]
  file-open "AlexanderBlock_ABM_FarmerOutput.csv"
  file-type "id,"
  file-type "tick,"
  file-type "year,"
  file-type "num-fields,"
  file-type "field1,"
  file-type "trust,"
  file-type "trust-rate,"
  file-type "trust-expert,"
  file-type "trust-peer,"
  file-type "food-store,"
  file-type "Mdecision,"
  file-type "Tdecision,"
  file-type "hear-peer,"
  file-type "hear-expert,"
  file-type "use-forecast,"
  file-type "adopt-group,"
  file-type "heuristic,"
  file-type "peertalk,"
  file-type "trust-thres,"
  file-type "ready-change,"
  file-type "peer-ben,"
  file-type "num-changes,"
  file-type "Tconstant,"
  file-type "Tweight,"
  file-print "peer-ftu"

  file-close

  update-output
  reset-ticks
end

;call procedures in order to run the model; for scenarios 1-3, omit "assess-change" procedure
to go

  tick
  if ticks > years-simulated [stop]
  set year year + 1

  ask households
  [
    forecast ;determine seasonal rainfall forecast
    get-forecast-skill ;get the skill of forecast compared to observed
    households-act ; farmers make farming decisions (crop ratio) based on forecast and crop expectation and ask patches to change their variables
    update-fields ;update field information based on crop ratio chosen by farmer-agents
    assess-change ;farmers assess whether they should continue with same heuristic strategy or change, if they want to change, it calls update-strategy procedure
    update-trust ;farmers update their trust variable based on forecast skill
  ]

  ask fields
  [
    set maize-grown [Mdecision] of link-neighbors
    set teff-grown [Tdecision] of link-neighbors

  ]

  update-output

end

to forecast
;  procedure -- to forecast rainfall

;  TO FORECAST BASED ON STAT MODEL PRED
;  increment the year (done above) and then retrieve the precip prediction for that year from the input file
  set forecast-rain (item series_number item year PrecipPredSeries)

;  Scenario 1 (no forecast use) comment above statistical prediction and use line below
;  set forecast-rain 1065
end

to get-forecast-skill
  ; procedure -- serves as the met office entity, determining the forecast skill for each timestep

  ;TO GET REAL SKILL OF PRECIP PRED COMPARED TO OBSERVED
  let obs (item series_number item year PrecipObsSeries)
  set actual-rain obs
  let skill (item series_number item year PrecipSkillSeries)
  set forecast-skill skill
end

to households-act
  ; procedure -- households move around world and may interact with farmers in the kebele or extension experts. Based on their interactions and trust, household agents
  ; make decisions on crop ratio of maize and teff to plant. Trust is a function of past forecast skill, frequency of hearing from a source, and trust in source.

;     Scenarios 1: uncomment 'Scenario 2,3,4 code' below and use two lines below, set percentage maize and teff to plant in expectation of normal year
;     set Mdecision 0.50
;     set Tdecision 0.50
;
;     Scenarios 2: uncomment 'Scnarios 1,3,4 code' and use two lines below, set percentage maize and teff to plant in expectation of normal year
;     set use-forecast 1
;     let MatrixPosition 5
;
;     if forecast-rain <= BN-cutoff [set MatrixPosition 0]
;     if forecast-rain >= BN-cutoff [if forecast-rain <= AN-cutoff [set MatrixPosition 1]]
;     if forecast-rain >= AN-cutoff [set MatrixPosition 2]

;     ;assume that farmers plant ratio and density according to response options matrix based on the forecast
;     set Mdecision (matrix:get FcstResp-matrix MatrixPosition 0) / 100
;     set Tdecision (matrix:get FcstResp-matrix MatrixPosition 1) / 100

  ;Scenarios 3 and 4: Farmers move to a new random location - if neighboring farmers or experts have used the forecast, then there is a chance that they will share this information.
  setxy random-xcor random-ycor
  ask experts [setxy random-xcor random-ycor]
  let household-neighbors other households in-radius influence
  let expert-neighbors other experts in-radius influence
  set peertalk count household-neighbors

  if (any? household-neighbors with [use-forecast = 1] and (trust-peer = 1)) [set hear-peer 1]
  if (any? expert-neighbors) and (trust-expert = 1) [set hear-expert 1]

  ;if trust has built up (>3) and the farmer has heard of the forecast, then they will use it. Otherwise, plant business as usual ratios (expect normal year).
  ifelse (trust > trust-thres) and ((hear-peer = 1) or (hear-expert = 1))
  [
     ;farmers use the forecast to act based on the expected payoff given the rainfall condition
     set use-forecast 1
     let MatrixPosition 5

     if forecast-rain <= BN-cutoff [set MatrixPosition 0]
     if forecast-rain >= BN-cutoff [if forecast-rain <= AN-cutoff [set MatrixPosition 1]]
     if forecast-rain >= AN-cutoff [set MatrixPosition 2]

     ; assume that farmers plant ratio and density according to response options matrix based on the forecast
     set Mdecision (matrix:get FcstResp-matrix MatrixPosition 0) / 100
     set Tdecision (matrix:get FcstResp-matrix MatrixPosition 1) / 100
  ]
  [
    set use-forecast 0
    set Mdecision 0.50
    set Tdecision 0.50
  ]
end

to update-fields
  ; procedure -- update field information based on crop ratio and density chosen by each household agent

  ;ACT BASED ON STAT MODEL PREDICTION
  let actualCategory 5

  ; update fields with actual yield for maize and teff
  let maize-actual (item series_number item year MaizePayoff) * Mdecision
  let teff-actual (item series_number item year TeffPayoff) * Tdecision

  set food-store (maize-actual + teff-actual) * num-fields
  if food-store < 0 [set food-store 0]

  ;create lists of average dry and wet years food stores of households
  if actual-rain < 1023 [set dry-years lput (mean [food-store] of households) dry-years] ;record mean food-store if one of 25% driest years (25th prctle, ~bottom 10)
  if actual-rain > 1170 [set wet-years lput (mean [food-store] of households) wet-years] ;record mean food-store if one of 25% wettest years (75th prctle, ~top 10)
end


to assess-change
  ;procedure for households to determine whether they should change their trust heuristic strategy based on peers within influence radius (Scenario 4 only)
  let peer-store peer-benefit
  let peer-strat peer-strategy

  ifelse length peer-strat != 1 [set peer-strat 0][set peer-strat item 0 peer-strat]

  if peer-store > food-store
  [
    if peer-strat != heuristic [set ready-change ready-change + 1]
  ]

  if ready-change > change-thres [update-strategy]
end

to update-strategy
  ;procedure for farmer-agents to update their strategy based on the dominant strategy of peer-agents in their influence radius (Scenario 4 only)
  if length peer-strategy = 1
  [
    set heuristic item 0 peer-strategy
    set ready-change 0
    set num-changes num-changes + 1
  ]
end

to update-trust
;procedure to update the trust variable of households based on the skill of the forecast
  if heuristic = 1 [
   ;Neutral strategy: gain 1 FTU when correct - lose 1 FTU when incorrect
   ifelse forecast-skill >= 1 [set trust (trust + trust-rate)] [set trust (trust - trust-rate)]
  ]

  if heuristic = 3 [
   ;Averse strategy: gain 1 FTU when dry/wet correct - lose 1 FTU when off by 1 categor, lose 2 FTU when off by 2 categories
   if forecast-skill >= 2 [set trust (trust + trust-rate)]
   if forecast-skill = -1 [set trust (trust - trust-rate)]
  ]

  if heuristic = 4 [
   ;Tolerant strategy: gain 1 FTU when normal correct, 2 FTU when dry correct, 3 FTU when wet correct - lose 1 FTU when off by 1 category, lose 2 FTU when off by 2 categories
   if forecast-skill = 3 [set trust (trust + 3 * trust-rate)]
   if forecast-skill = 2 [set trust (trust + 2 * trust-rate)]
   if forecast-skill = 1 [set trust (trust + trust-rate)]
   if forecast-skill = -1 [set trust (trust - trust-rate)]
   if forecast-skill = -2 [set trust (trust - 2 * trust-rate)]
  ]

  ;Scenario 4 only (other scenarios, comment out below): adjust trust based on the trust of neighboring peers (if agent trusts their peers)
  set peer-ftu peer-trust

  if peer-trust > trust and trust-peer = 1 [set Tweight Tweight + Tconstant]
  if peer-trust < trust and trust-peer = 1 [set Tweight Tweight - Tconstant]

  set trust trust + ((abs peer-trust) * Tweight)
end

to update-output
;procedure to update the output files
  if year >= 0 [
   file-open "AlexanderBlock_ABM_FieldOutput.csv"
    ask fields
     [
      file-type (word who ",")
      file-type (word ticks ",")
      file-type (word year ",")
      file-type (word maize-grown ",")
      file-type (word teff-grown ",")
      file-print household-turtle
     ]
   file-close

   file-open "AlexanderBlock_ABM_FarmerOutput.csv"
    ask households
     [
      file-type (word who ",")
      file-type (word ticks  ",")
      file-type (word year ",")
      file-type (word num-fields ",")
      file-type (word field1 ",")
      file-type (word trust ",")
      file-type (word trust-rate ",")
      file-type (word trust-expert ",")
      file-type (word trust-peer ",")
      file-type (word food-store ",")
      file-type (word Mdecision ",")
      file-type (word Tdecision ",")
      file-type (word hear-peer ",")
      file-type (word hear-expert ",")
      file-type (word use-forecast ",")
      file-type (word adopt-group ",")
      file-type (word heuristic ",")
      file-type (word peertalk ",")
      file-type (word trust-thres ",")
      file-type (word ready-change ",")
      file-type (word peer-ben ",")
      file-type (word num-changes ",")
      file-type (word Tconstant ",")
      file-type (word Tweight ",")
      file-print peer-ftu
     ]
   file-close

    if year = years-simulated - 1
    [
      output-write "avg benefit:"
      output-print avg-benefit
      output-write "dry benefit:"
      output-print dry-benefit
      output-write "wet benefit:"
      output-print wet-benefit
    ]
  ]
end

;codes below report several metrics to display in the interface with output from model runs
to-report avg-benefit
  let ben mean [food-store] of households
  report ben
end

to-report dry-benefit
  let dry-ben mean dry-years
  report dry-ben
end

to-report wet-benefit
  let wet-ben mean wet-years
  report wet-ben
end

to-report perc-early-adopted
  let num-adopt sum [use-forecast] of households with [adopt-group = 0]
  let early-cat households with [adopt-group = 0]
  let total count early-cat
  let perc-adopt (num-adopt / total) * 100
  report perc-adopt

end

to-report perc-mid-adopted
  let num-adopt sum [use-forecast] of households with [adopt-group = 1]
  let mid-cat households with [adopt-group = 1]
  let total count mid-cat
  let perc-adopt (num-adopt / total) * 100
  report perc-adopt

end

to-report perc-late-adopted
  let num-adopt sum [use-forecast] of households with [adopt-group = 2]
  let late-cat households with [adopt-group = 2]
  let total count late-cat
  let perc-adopt (num-adopt / total) * 100
  report perc-adopt

end

to-report peer-trust
  let nearby-peers other households in-radius influence
  let PT mean [trust] of nearby-peers
  report PT
end

to-report peer-benefit
  let nearby-peers other households in-radius influence
  let fcst-peers nearby-peers with [use-forecast = 1]
  ifelse any? fcst-peers [set peer-ben mean [food-store] of fcst-peers][set peer-ben 0]
  report peer-ben
end

to-report peer-strategy
  let nearby-peers other households in-radius influence
  let fcst-peers nearby-peers with [use-forecast = 1]
  let strategy modes [heuristic] of fcst-peers
  report strategy
end
@#$#@#$#@
GRAPHICS-WINDOW
290
10
768
489
-1
-1
10.0
1
10
1
1
1
0
1
1
1
-23
23
-23
23
1
1
1
ticks
10.0

BUTTON
14
12
80
45
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

BUTTON
111
12
174
45
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

PLOT
8
178
285
368
Household food store
Years
Food store (tons)
0.0
40.0
0.0
100000.0
false
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot mean [food-store] of households"

PLOT
1326
86
1563
285
Maize planted
Years
Percent of plot maize
0.0
40.0
0.0
100.0
false
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" "plot mean [Mdecision] of households * 100"

PLOT
1327
296
1566
494
Teff planted
Years
Percent of plot teff
0.0
40.0
0.0
100.0
false
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" "plot mean [Tdecision] of households * 100"

BUTTON
206
12
269
45
NIL
Go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

OUTPUT
8
376
284
496
13

SLIDER
15
56
187
89
influence
influence
0
15
3.0
1
1
NIL
HORIZONTAL

SLIDER
16
97
188
130
series_number
series_number
0
101
96.0
1
1
NIL
HORIZONTAL

PLOT
794
11
1282
188
Total forecast adoption
Year
Number adopted
0.0
40.0
0.0
1270.0
false
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot sum [use-forecast] of households"

PLOT
795
193
1039
343
Early adopters
Year
% Adopted
0.0
40.0
0.0
100.0
false
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot perc-early-adopted"

PLOT
794
347
994
497
Middle adopters
Year
% Adopted
0.0
40.0
0.0
100.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot perc-mid-adopted"

PLOT
1045
191
1284
341
Late adopters
Year
% Adopted
0.0
40.0
0.0
100.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot perc-late-adopted"

PLOT
1000
346
1287
496
Average trust
Year
Mean trust
0.0
40.0
-10.0
30.0
false
true
"" ""
PENS
"Early" 1.0 0 -16777216 true "" "plot mean [trust] of households with [adopt-group = 0]"
"Middle" 1.0 0 -13791810 true "" "plot mean [trust] of households with [adopt-group = 1]"
"Late" 1.0 0 -2674135 true "" "plot mean [trust] of households with [adopt-group = 2]"

SLIDER
16
136
188
169
change-thres
change-thres
0
5
3.0
1
1
NIL
HORIZONTAL

SLIDER
43
502
215
535
param-rand-seed
param-rand-seed
0
1000
1.900000001E9
1
1
NIL
HORIZONTAL

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
NetLogo 6.0.4
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="all clim series v2" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>sum [use-forecast] of households</metric>
    <metric>sum [hear-peer] of households</metric>
    <metric>sum [hear-expert] of households</metric>
    <metric>perc-early-adopted</metric>
    <metric>perc-mid-adopted</metric>
    <metric>perc-late-adopted</metric>
    <metric>mean [trust] of households with [adopt-group = 0]</metric>
    <metric>mean [trust] of households with [adopt-group = 1]</metric>
    <metric>mean [trust] of households with [adopt-group = 2]</metric>
    <metric>mean [food-store] of households with [adopt-group = 0]</metric>
    <metric>mean [food-store] of households with [adopt-group = 1]</metric>
    <metric>mean [food-store] of households with [adopt-group = 2]</metric>
    <metric>mean [num-changes] of households with [adopt-group = 0]</metric>
    <metric>mean [num-changes] of households with [adopt-group = 1]</metric>
    <metric>mean [num-changes] of households with [adopt-group = 2]</metric>
    <metric>modes [heuristic] of households with [adopt-group = 0]</metric>
    <metric>modes [heuristic] of households with [adopt-group = 1]</metric>
    <metric>modes [heuristic] of households with [adopt-group = 2]</metric>
    <steppedValueSet variable="param-rand-seed" first="1" step="100000000" last="2000000000"/>
    <steppedValueSet variable="series_number" first="1" step="1" last="100"/>
  </experiment>
  <experiment name="experiment infl sensitivity" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>sum [use-forecast] of households</metric>
    <metric>perc-early-adopted</metric>
    <metric>perc-mid-adopted</metric>
    <metric>perc-late-adopted</metric>
    <metric>min [peertalk] of households</metric>
    <metric>mean [peertalk] of households</metric>
    <metric>max [peertalk] of households</metric>
    <steppedValueSet variable="influence" first="1" step="1" last="15"/>
  </experiment>
  <experiment name="peertalk" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>sum [use-forecast] of households</metric>
    <metric>min [peertalk] of households</metric>
    <metric>mean [peertalk] of households</metric>
    <metric>max [peertalk] of households</metric>
    <steppedValueSet variable="series_number" first="1" step="1" last="100"/>
  </experiment>
  <experiment name="benefit" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>avg-benefit</metric>
    <metric>dry-benefit</metric>
    <metric>wet-benefit</metric>
    <steppedValueSet variable="series_number" first="1" step="1" last="100"/>
  </experiment>
  <experiment name="Obs Clim Run" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>sum [use-forecast] of households</metric>
    <metric>perc-early-adopted</metric>
    <metric>perc-mid-adopted</metric>
    <metric>perc-late-adopted</metric>
    <metric>mean [trust] of households with [adopt-group = 0]</metric>
    <metric>mean [trust] of households with [adopt-group = 1]</metric>
    <metric>mean [trust] of households with [adopt-group = 2]</metric>
    <metric>mean [food-store] of households with [adopt-group = 0]</metric>
    <metric>mean [food-store] of households with [adopt-group = 1]</metric>
    <metric>mean [food-store] of households with [adopt-group = 2]</metric>
    <metric>mean [num-changes] of households with [adopt-group = 0]</metric>
    <metric>mean [num-changes] of households with [adopt-group = 1]</metric>
    <metric>mean [num-changes] of households with [adopt-group = 2]</metric>
    <metric>modes [heuristic] of households with [adopt-group = 0]</metric>
    <metric>modes [heuristic] of households with [adopt-group = 1]</metric>
    <metric>modes [heuristic] of households with [adopt-group = 2]</metric>
    <enumeratedValueSet variable="change-thres">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="influence">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="series_number">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="all degraded clim series" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>sum [use-forecast] of households</metric>
    <metric>perc-early-adopted</metric>
    <metric>perc-mid-adopted</metric>
    <metric>perc-late-adopted</metric>
    <metric>mean [trust] of households with [adopt-group = 0]</metric>
    <metric>mean [trust] of households with [adopt-group = 1]</metric>
    <metric>mean [trust] of households with [adopt-group = 2]</metric>
    <metric>mean [food-store] of households with [adopt-group = 0]</metric>
    <metric>mean [food-store] of households with [adopt-group = 1]</metric>
    <metric>mean [food-store] of households with [adopt-group = 2]</metric>
    <metric>mean [num-changes] of households with [adopt-group = 0]</metric>
    <metric>mean [num-changes] of households with [adopt-group = 1]</metric>
    <metric>mean [num-changes] of households with [adopt-group = 2]</metric>
    <metric>modes [heuristic] of households with [adopt-group = 0]</metric>
    <metric>modes [heuristic] of households with [adopt-group = 1]</metric>
    <metric>modes [heuristic] of households with [adopt-group = 2]</metric>
    <steppedValueSet variable="series_number" first="1" step="1" last="10"/>
  </experiment>
  <experiment name="varyRandSeed" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>sum [use-forecast] of households</metric>
    <metric>sum [hear-peer] of households</metric>
    <metric>sum [hear-expert] of households</metric>
    <metric>perc-early-adopted</metric>
    <metric>perc-mid-adopted</metric>
    <metric>perc-late-adopted</metric>
    <metric>mean [trust] of households with [adopt-group = 0]</metric>
    <metric>mean [trust] of households with [adopt-group = 1]</metric>
    <metric>mean [trust] of households with [adopt-group = 2]</metric>
    <metric>mean [food-store] of households with [adopt-group = 0]</metric>
    <metric>mean [food-store] of households with [adopt-group = 1]</metric>
    <metric>mean [food-store] of households with [adopt-group = 2]</metric>
    <metric>mean [num-changes] of households with [adopt-group = 0]</metric>
    <metric>mean [num-changes] of households with [adopt-group = 1]</metric>
    <metric>mean [num-changes] of households with [adopt-group = 2]</metric>
    <metric>modes [heuristic] of households with [adopt-group = 0]</metric>
    <metric>modes [heuristic] of households with [adopt-group = 1]</metric>
    <metric>modes [heuristic] of households with [adopt-group = 2]</metric>
    <enumeratedValueSet variable="change-thres">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="influence">
      <value value="3"/>
    </enumeratedValueSet>
    <steppedValueSet variable="param-rand-seed" first="1" step="100000000" last="2000000000"/>
    <enumeratedValueSet variable="series_number">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="all clim series" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>sum [use-forecast] of households</metric>
    <metric>sum [hear-peer] of households</metric>
    <metric>sum [hear-expert] of households</metric>
    <metric>perc-early-adopted</metric>
    <metric>perc-mid-adopted</metric>
    <metric>perc-late-adopted</metric>
    <metric>mean [trust] of households with [adopt-group = 0]</metric>
    <metric>mean [trust] of households with [adopt-group = 1]</metric>
    <metric>mean [trust] of households with [adopt-group = 2]</metric>
    <metric>mean [food-store] of households with [adopt-group = 0]</metric>
    <metric>mean [food-store] of households with [adopt-group = 1]</metric>
    <metric>mean [food-store] of households with [adopt-group = 2]</metric>
    <metric>mean [num-changes] of households with [adopt-group = 0]</metric>
    <metric>mean [num-changes] of households with [adopt-group = 1]</metric>
    <metric>mean [num-changes] of households with [adopt-group = 2]</metric>
    <metric>modes [heuristic] of households with [adopt-group = 0]</metric>
    <metric>modes [heuristic] of households with [adopt-group = 1]</metric>
    <metric>modes [heuristic] of households with [adopt-group = 2]</metric>
    <steppedValueSet variable="series_number" first="1" step="1" last="100"/>
  </experiment>
  <experiment name="test" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>sum [use-forecast] of households</metric>
    <metric>sum [hear-peer] of households</metric>
    <metric>sum [hear-expert] of households</metric>
    <metric>perc-early-adopted</metric>
    <metric>perc-mid-adopted</metric>
    <metric>perc-late-adopted</metric>
    <metric>mean [trust] of households with [adopt-group = 0]</metric>
    <metric>mean [trust] of households with [adopt-group = 1]</metric>
    <metric>mean [trust] of households with [adopt-group = 2]</metric>
    <metric>mean [food-store] of households with [adopt-group = 0]</metric>
    <metric>mean [food-store] of households with [adopt-group = 1]</metric>
    <metric>mean [food-store] of households with [adopt-group = 2]</metric>
    <metric>mean [num-changes] of households with [adopt-group = 0]</metric>
    <metric>mean [num-changes] of households with [adopt-group = 1]</metric>
    <metric>mean [num-changes] of households with [adopt-group = 2]</metric>
    <metric>modes [heuristic] of households with [adopt-group = 0]</metric>
    <metric>modes [heuristic] of households with [adopt-group = 1]</metric>
    <metric>modes [heuristic] of households with [adopt-group = 2]</metric>
    <steppedValueSet variable="param-rand-seed" first="1" step="100000000" last="2000000000"/>
    <steppedValueSet variable="series_number" first="1" step="1" last="2"/>
  </experiment>
  <experiment name="testWetDryBen" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>sum [use-forecast] of households</metric>
    <metric>sum [hear-peer] of households</metric>
    <metric>sum [hear-expert] of households</metric>
    <metric>perc-early-adopted</metric>
    <metric>perc-mid-adopted</metric>
    <metric>perc-late-adopted</metric>
    <metric>mean [trust] of households with [adopt-group = 0]</metric>
    <metric>mean [trust] of households with [adopt-group = 1]</metric>
    <metric>mean [trust] of households with [adopt-group = 2]</metric>
    <metric>mean [food-store] of households with [adopt-group = 0]</metric>
    <metric>mean [food-store] of households with [adopt-group = 1]</metric>
    <metric>mean [food-store] of households with [adopt-group = 2]</metric>
    <metric>mean [num-changes] of households with [adopt-group = 0]</metric>
    <metric>mean [num-changes] of households with [adopt-group = 1]</metric>
    <metric>mean [num-changes] of households with [adopt-group = 2]</metric>
    <metric>modes [heuristic] of households with [adopt-group = 0]</metric>
    <metric>modes [heuristic] of households with [adopt-group = 1]</metric>
    <metric>modes [heuristic] of households with [adopt-group = 2]</metric>
    <metric>avg-benefit</metric>
    <metric>dry-benefit</metric>
    <metric>wet-benefit</metric>
    <enumeratedValueSet variable="change-thres">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="influence">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="param-rand-seed">
      <value value="1800000001"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="series_number">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="all clim series add v2" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>sum [use-forecast] of households</metric>
    <metric>sum [hear-peer] of households</metric>
    <metric>sum [hear-expert] of households</metric>
    <metric>perc-early-adopted</metric>
    <metric>perc-mid-adopted</metric>
    <metric>perc-late-adopted</metric>
    <metric>mean [trust] of households with [adopt-group = 0]</metric>
    <metric>mean [trust] of households with [adopt-group = 1]</metric>
    <metric>mean [trust] of households with [adopt-group = 2]</metric>
    <metric>mean [food-store] of households with [adopt-group = 0]</metric>
    <metric>mean [food-store] of households with [adopt-group = 1]</metric>
    <metric>mean [food-store] of households with [adopt-group = 2]</metric>
    <metric>mean [num-changes] of households with [adopt-group = 0]</metric>
    <metric>mean [num-changes] of households with [adopt-group = 1]</metric>
    <metric>mean [num-changes] of households with [adopt-group = 2]</metric>
    <metric>modes [heuristic] of households with [adopt-group = 0]</metric>
    <metric>modes [heuristic] of households with [adopt-group = 1]</metric>
    <metric>modes [heuristic] of households with [adopt-group = 2]</metric>
    <steppedValueSet variable="param-rand-seed" first="1" step="100000000" last="2000000000"/>
    <steppedValueSet variable="series_number" first="1" step="1" last="94"/>
  </experiment>
  <experiment name="Obs Clim Run w seeds" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>sum [use-forecast] of households</metric>
    <metric>perc-early-adopted</metric>
    <metric>perc-mid-adopted</metric>
    <metric>perc-late-adopted</metric>
    <metric>mean [trust] of households with [adopt-group = 0]</metric>
    <metric>mean [trust] of households with [adopt-group = 1]</metric>
    <metric>mean [trust] of households with [adopt-group = 2]</metric>
    <metric>mean [food-store] of households with [adopt-group = 0]</metric>
    <metric>mean [food-store] of households with [adopt-group = 1]</metric>
    <metric>mean [food-store] of households with [adopt-group = 2]</metric>
    <metric>mean [num-changes] of households with [adopt-group = 0]</metric>
    <metric>mean [num-changes] of households with [adopt-group = 1]</metric>
    <metric>mean [num-changes] of households with [adopt-group = 2]</metric>
    <metric>modes [heuristic] of households with [adopt-group = 0]</metric>
    <metric>modes [heuristic] of households with [adopt-group = 1]</metric>
    <metric>modes [heuristic] of households with [adopt-group = 2]</metric>
    <enumeratedValueSet variable="change-thres">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="influence">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="series_number">
      <value value="1"/>
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
@#$#@#$#@
0
@#$#@#$#@
