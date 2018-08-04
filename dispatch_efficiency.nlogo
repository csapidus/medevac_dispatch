globals [

  nimroz-helmand ;; Afghani province border
  helmand-kandahar ;; Afghani province border
  kandahar-zabul ;; Afghani province border
  casualty_count_stabilizer
  casualty_generator
  total_utility
  missions_complete
  time_of_day
  color-min
  color-max
  testvariable
  casevac_count
]

patches-own [
  elevation
]

breed [casualties casualty]
casualties-own[casualty_count dispatch_enroute dispatch_time evacuee_distance evacuated escort_required classification province];

breed [staging_locations staging_location] ;four

breed [medevacs medevac] ;four
medevacs-own[evacuee_distance dispatch_time dispatched evacuee evacuating evacuation_time mtf_selection unloading unloading_time designated_landing_zone mission_complete casualty_count province classification response_time];

breed [mtfs mtf]; two

breed [casevacs casevac]
casevacs-own[time_delay]

breed [escorts escort]

to setup
  clear-all
  ;; read the elevations from an external file
  ;; note that the file is formatted as a list
  ;; so we only have to read once into a local variable.
  file-open "Grand Canyon data.txt"
  let patch-elevations file-read
  file-close
  ;; put a little padding on the upper bound so we don't get too much
  ;; white, and higher elevations have a little more variation.
  set color-max max patch-elevations + 200
  let min-elevation min patch-elevations
  ;; adjust the color-min a little so patches don't end up black
  set color-min min-elevation - ((color-max - min-elevation) / 10)
  ;; transfer the data from the file into the sorted patches
  (foreach sort patches patch-elevations [ [the-patch the-elevation] ->
    ask the-patch [ set elevation the-elevation ]
  ])
  setup-world
  ; display-labels
  reset-ticks
end

to setup-world

  set testvariable FALSE

  ask patches[ set pcolor scale-color brown elevation color-min color-max ]
  ; resize-world 0 100 0 60
  set nimroz-helmand 50
  set helmand-kandahar 150
  set kandahar-zabul 250
  set casualty_count_stabilizer 1
  set casualty_generator round random-normal 322 54

  ;ask patches [  ;; change colors for different provinces to make distinction
  ;  if pxcor >= 0 and pxcor < nimroz-helmand [ ;; nimroz
  ;    set pcolor brown
  ;  ]
  ;
  ;  if pxcor >= nimroz-helmand and pxcor < helmand-kandahar [ ;; helmand
  ;    set pcolor blue
  ;  ]
  ;
  ;  if pxcor >= helmand-kandahar and pxcor < kandahar-zabul [ ;; kandahar
  ;    set pcolor red
  ;  ]
  ;
  ;  if pxcor >= kandahar-zabul [ ;; zabul
  ;    set pcolor green
  ;  ]

  ;]

  ;; staging locations for MEDEVAC assets now set
  set-default-shape staging_locations "landing_zone"
  set-default-shape medevacs "blackhawk" ; to be changed
  set-default-shape casualties "person soldier"
  set-default-shape mtfs "hospital"
  set-default-shape casevacs "casevac" ;;

  ;; --------------------------------- NIMROZ --------------------------------------------- ;;
  create-staging_locations 1 [
    setxy random-normal (nimroz-helmand * .5) 5 random-normal 150 25
    set size 15
  ]
  create-medevacs 1 [

    set designated_landing_zone one-of staging_locations with [ pxcor < nimroz-helmand]
    move-to designated_landing_zone
    set size 20
    set dispatched FALSE
    set evacuating FALSE
    set unloading FALSE
    set mission_complete FALSE
    set dispatch_time 0
    set evacuation_time 0
    set unloading_time 0
    set casualty_count 0
    set province "nimroz"
  ]

   ;; --------------------------------- HELMAND --------------------------------------------- ;;

  let xsavedh random-normal ((helmand-kandahar + nimroz-helmand) * .5) 10
  let ysavedh random-normal 150 25

  create-mtfs 1 [
    setxy xsavedh ysavedh
    set size 30
    set color white
  ]

  create-staging_locations 1 [
    setxy xsavedh ysavedh + 15
    set size 15
  ]

  create-medevacs 1 [
    set designated_landing_zone one-of staging_locations with [(pxcor < helmand-kandahar) and (pxcor > nimroz-helmand)]
    move-to designated_landing_zone
    set size 20
    set dispatched FALSE
    set evacuating FALSE
    set unloading FALSE
    set mission_complete FALSE
    set dispatch_time 0
    set evacuation_time 0
    set unloading_time 0
    set casualty_count 0
    set province "helmand"
  ]

  ;; --------------------------------- KANDAHAR --------------------------------------------- ;;

  let xsavedk random-normal ((helmand-kandahar + kandahar-zabul) * .5) 10
  let ysavedk random-normal 150 25

  create-mtfs 1 [
    setxy xsavedk ysavedk
    set size 30
    set color white
  ]

  create-staging_locations 1 [
    setxy xsavedk ysavedk + 15
    set size 15
  ]

  create-medevacs 1 [
    set designated_landing_zone one-of staging_locations with [(pxcor < kandahar-zabul) and (pxcor > helmand-kandahar)]
    move-to designated_landing_zone
    set size 20
    set dispatched FALSE
    set evacuating FALSE
    set unloading FALSE
    set mission_complete FALSE
    set dispatch_time 0
    set evacuation_time 0
    set unloading_time 0
    set casualty_count 0
    set province "kandahar"
  ]

   ;; --------------------------------- ZABUL --------------------------------------------- ;;
  create-staging_locations 1 [
    setxy random-normal (0.5 * (300 + kandahar-zabul)) 5 random-normal 150 25
    set size 15
  ]
  create-medevacs 1 [
    set designated_landing_zone one-of staging_locations with [pxcor > kandahar-zabul]
    move-to designated_landing_zone
    set size 20
    set dispatched FALSE
    set evacuating FALSE
    set unloading FALSE
    set mission_complete FALSE
    set dispatch_time 0
    set evacuation_time 0
    set unloading_time 0
    set casualty_count 0
    set province "zabul"
  ]

  end

to go
  ;; add day and night features later

  if (casualty_generator <= ticks) and (ticks mod casualty_generator = 0) [
    set casualty_generator round random-normal 322 54
    create-casualties 1 [
      set dispatch_enroute FALSE
      set evacuated FALSE
      set dispatch_time 0

      let temp1 random 1000
      ; if temp1 < 4 [move-to one-of patches with [pxcor < nimroz-helmand] set province "nimroz"]
      if temp1 < 4 [
        let temp1y random-normal 150 75
        let temp1x random-normal (nimroz-helmand * 0.5) (8)
        if temp1y > 299 [set temp1y 299]
        if temp1y < 1 [set temp1y 1]
        if temp1x < 1 [set temp1x 1]
        setxy temp1x temp1y set province "nimroz"
      ]
      ; if (temp1 >= 4) and (temp1 < 589) [move-to one-of patches with [(pxcor < helmand-kandahar) and (pxcor > nimroz-helmand)] set province "helmand"]
      if (temp1 >= 4) and (temp1 < 589) [
        let temp2y random-normal 150 75
        let temp2x random-normal ((helmand-kandahar + nimroz-helmand) * 0.5) (25)
        if temp2y > 299 [set temp2y 299]
        if temp2y < 1 [set temp2y 1]
        if temp2x < 1 [set temp2x 1]
        setxy temp2x temp2y set province "helmand"
      ]
      ; if (temp1 >= 589) and (temp1 < 927) [move-to one-of patches with [(pxcor < kandahar-zabul) and (pxcor > helmand-kandahar)] set province "kandahar"]
      if (temp1 >= 589) and (temp1 < 927) [
        let temp3y random-normal 150 75
        let temp3x random-normal ((helmand-kandahar + kandahar-zabul) * 0.5) (25)
        if temp3y > 299 [set temp3y 299]
        if temp3y < 1 [set temp3y 1]
        if temp3x > 299 [set temp3x 299]
        setxy temp3x temp3y set province "kandahar"
      ]
      ; if temp1 >= 927 [move-to one-of patches with [pxcor > kandahar-zabul] set province "zabul"]
      if temp1 >= 927 [
        let temp4y random-normal 150 75
        if temp4y > 299 [set temp4y 299]
        if temp4y < 1 [set temp4y 1]
        setxy random-normal ((kandahar-zabul + 300 ) * 0.5) (8) temp4y set province "zabul"
      ]

      let temp2 random 1000
      if temp2 < 574 [set casualty_count 1]
      if (temp2 >= 574) and (temp2 < 934) [set casualty_count 2]
      if (temp2 >= 934) and (temp2 < 984) [set casualty_count 3]
      if temp2 >= 984 [set casualty_count 4]

      let temp3 random 100
      if temp3 < 32 [set escort_required TRUE]
      if temp3 >= 32 [set escort_required FALSE]

      let temp4 random 1000
      if temp4 < 159 [set classification "urgent"]
      if temp4 >= 159 and temp4 < 316 [set classification "priority"]
      if temp4 >= 316 [set classification "routine"]

      set size 10
    ]
  ]

  ;; --------------------------------- MYOPIC DISPATCHING --------------------------------------------- ;;
  if dispatching_strategy = "Myopic" [
     if count casualties = casualty_count_stabilizer [
      set casualty_count_stabilizer casualty_count_stabilizer + 1

      if count medevacs with [dispatched = FALSE] != 0 [
        ask medevacs with [dispatched = FALSE] [set evacuee_distance distance min-one-of casualties with [dispatch_enroute = FALSE] with [hidden? = FALSE] [distance myself]]
        ask casualties with [dispatch_enroute = FALSE] with [hidden? = FALSE] [set evacuee_distance distance min-one-of medevacs with [dispatched = FALSE] [distance myself]]

        ask min-one-of (medevacs with [dispatched = FALSE]) [evacuee_distance] [
          set dispatched TRUE
          set evacuee min-one-of casualties with [dispatch_enroute = FALSE] with [hidden? = FALSE] [distance myself]
          set casualty_count [casualty_count] of evacuee
          set classification [classification] of evacuee
        ]
      ]
    ]

    if count medevacs with [dispatched = FALSE] = 0 and count casualties with [dispatch_enroute = FALSE] with [hidden? = FALSE]!= 0 [
      create-casevacs 1 [
        move-to one-of casualties with [dispatch_enroute = FALSE] with [hidden? = FALSE]
        set size 20
      ]
      ask casualties with [dispatch_enroute = FALSE] [set hidden? TRUE]
      set casevac_count casevac_count + 1
    ]

    if count casevacs != 0 [
      ask casevacs [set time_delay time_delay + 1]
    ]

    ask casevacs with [time_delay > 100] [die]


    if count casualties with [dispatch_enroute = FALSE] with [hidden? = FALSE] != 0 [
      ask min-one-of (casualties with [dispatch_enroute = FALSE] with [hidden? = FALSE]) [evacuee_distance] [set dispatch_enroute TRUE]
    ]


    ask medevacs with [dispatched = TRUE] [
      set dispatch_time dispatch_time + 1
    ]

    ask casualties with [dispatch_enroute = TRUE] [
      set dispatch_time dispatch_time + 1
    ]

    ask medevacs with [dispatched = TRUE] with [[escort_required] of evacuee = FALSE] with [dispatch_time >= 15] with [evacuating = FALSE] [
      set heading towards evacuee if [distance myself] of evacuee > 3 [
        fd MEDEVAC_Speed
      ]
    ]

    ask medevacs with [dispatched = TRUE] with [[escort_required] of evacuee = TRUE] with [dispatch_time >= 25] with [evacuating = FALSE] [
      set heading towards evacuee if [distance myself] of evacuee > 3 [
        fd MEDEVAC_Speed
      ]
    ]

    ask medevacs with [dispatched = TRUE] with [evacuating = FALSE] [
      if [distance myself] of evacuee <= 3 [
        set evacuating TRUE
        ask evacuee [
          set evacuated TRUE
        ]
      ]
    ]
  ]


    ;; --------------------------------- INTRA-ZONE DISPATCHING --------------------------------------------- ;;
  if dispatching_strategy = "Intra-Zone" [
    if count casualties = casualty_count_stabilizer [
      set casualty_count_stabilizer casualty_count_stabilizer + 1

      foreach ["nimroz" "helmand" "kandahar" "zabul"] [ x ->
        if count casualties with [province = x] with [dispatch_enroute = FALSE] with [hidden? = FALSE] != 0 [
          ; ask casualties with [province = x] with [dispatch_enroute = FALSE] with [hidden? = FALSE][
          ;   set evacuee_distance distance min-one-of medevacs with [province = x] [distance myself]
          ; ]
          ask medevacs with [province = x] with [dispatched = FALSE][
            set evacuee_distance distance min-one-of casualties with [province = x] with [hidden? = FALSE] [distance myself]
            set evacuee min-one-of casualties with [province = x] with [hidden? = FALSE] [distance myself]
            set dispatched TRUE
            set casualty_count [casualty_count] of evacuee
            set classification [classification] of evacuee
          ]
        ]
      ]
    ]

    ask medevacs with [dispatched = TRUE] [
      set dispatch_time dispatch_time + 1
    ]

    ask medevacs with [dispatched = TRUE] with [[escort_required] of evacuee = FALSE] with [dispatch_time >= 15] with [evacuating = FALSE] [
      set heading towards evacuee if [distance myself] of evacuee > 3 [
        ; set heading towards evacuee if distance evacuee [distance myself] > 3 [
        fd MEDEVAC_Speed
      ]
    ]

    ask medevacs with [dispatched = TRUE] with [[escort_required] of evacuee = TRUE] with [dispatch_time >= 25] with [evacuating = FALSE] [
      set heading towards evacuee if [distance myself] of evacuee > 3 [
        fd MEDEVAC_Speed
      ]
    ]

    ask medevacs with [dispatched = TRUE] with [evacuating = FALSE] [
      if [distance myself] of evacuee <= 3 [
        set evacuating TRUE
        ask evacuee [
          set evacuated TRUE
        ]
      ]
    ]
  ]


  ;; --------------------------------- OPTIMAL DISPATCHING --------------------------------------------- ;;
  if dispatching_strategy = "Optimal" [
    if count casualties = casualty_count_stabilizer [
      set casualty_count_stabilizer casualty_count_stabilizer + 1
      ; to do once

      if count medevacs with [dispatched = FALSE] != 0 [
        if count casualties with [dispatch_enroute = FALSE] with [hidden? = FALSE] with [province = "kandahar"] with [classification != "urgent"] != 0 [
          ask medevacs with [province = "zabul"] with [dispatched = FALSE] [
            set evacuee_distance distance min-one-of casualties with [dispatch_enroute = FALSE] with [hidden? = FALSE] with [province = "kandahar"] with [classification != "urgent"] [distance myself]
            ask casualties with [dispatch_enroute = FALSE] with [hidden? = FALSE] with [province = "kandahar"] with [classification != "urgent"] [
              set evacuee_distance distance min-one-of medevacs with [dispatched = FALSE] with [province = "zabul"] [distance myself]
              set dispatch_enroute TRUE
            ]
          ]
          ask medevacs with [province = "zabul"] with [dispatched = FALSE] [
            set dispatched TRUE
            set evacuee min-one-of casualties with [hidden? = FALSE] with [province = "kandahar"] with [classification != "urgent"] [distance myself]
            set casualty_count [casualty_count] of evacuee
            set classification [classification] of evacuee
          ]
        ]
        if count casualties with [dispatch_enroute = FALSE] with [hidden? = FALSE] with [province = "helmand"] with [classification != "urgent"] != 0 [
          ask medevacs with [province = "nimroz"] with [dispatched = FALSE] [
            set evacuee_distance distance min-one-of casualties with [dispatch_enroute = FALSE] with [hidden? = FALSE] with [province = "helmand"] with [classification != "urgent"] [distance myself]
            ask casualties with [dispatch_enroute = FALSE] with [hidden? = FALSE] with [province = "helmand"] with [classification != "urgent"] [
              set evacuee_distance distance min-one-of medevacs with [dispatched = FALSE] with [province = "nimroz"] [distance myself]
              set dispatch_enroute TRUE
            ]
          ]
          ask medevacs with [province = "nimroz"] with [dispatched = FALSE] [
            set dispatched TRUE
            set evacuee min-one-of casualties with [hidden? = FALSE] with [province = "helmand"] with [classification != "urgent"] [distance myself]
            set casualty_count [casualty_count] of evacuee
            set classification [classification] of evacuee
          ]
        ]
        if count casualties with [dispatch_enroute = FALSE] with [hidden? = FALSE] != 0 [
          ask medevacs with [dispatched = FALSE] [set evacuee_distance distance min-one-of casualties with [dispatch_enroute = FALSE] with [hidden? = FALSE] [distance myself]]
          ask casualties with [dispatch_enroute = FALSE] with [hidden? = FALSE] [set evacuee_distance distance min-one-of medevacs with [dispatched = FALSE] [distance myself]]

          ask min-one-of (medevacs with [dispatched = FALSE]) [evacuee_distance] [
            set dispatched TRUE
            set evacuee min-one-of casualties with [dispatch_enroute = FALSE] with [hidden? = FALSE] [distance myself]
            set casualty_count [casualty_count] of evacuee
            set classification [classification] of evacuee
          ]
        ]
      ]
    ] ;; check?

      if count medevacs with [dispatched = FALSE] = 0 and count casualties with [dispatch_enroute = FALSE] with [hidden? = FALSE]!= 0 [
        create-casevacs 1 [
          move-to one-of casualties with [dispatch_enroute = FALSE] with [hidden? = FALSE]
          set size 20
        ]
        ask casualties with [dispatch_enroute = FALSE] [set hidden? TRUE]
        set casevac_count casevac_count + 1
      ]

      if count casevacs != 0 [
        ask casevacs [set time_delay time_delay + 1]
      ]

      ask casevacs with [time_delay > 100] [die]


      ;if count casualties with [dispatch_enroute = FALSE] with [hidden? = FALSE] != 0 [
      ;  ask min-one-of (casualties with [dispatch_enroute = FALSE] with [hidden? = FALSE]) [evacuee_distance] [set dispatch_enroute TRUE]
      ;]


      ask medevacs with [dispatched = TRUE] [
        set dispatch_time dispatch_time + 1
      ]

      ask casualties with [dispatch_enroute = TRUE] [
        set dispatch_time dispatch_time + 1
      ]

      ask medevacs with [dispatched = TRUE] with [[escort_required] of evacuee = FALSE] with [dispatch_time >= 15] with [evacuating = FALSE] [
        set heading towards evacuee if [distance myself] of evacuee > 3 [
          fd MEDEVAC_Speed
        ]
      ]

      ask medevacs with [dispatched = TRUE] with [[escort_required] of evacuee = TRUE] with [dispatch_time >= 25] with [evacuating = FALSE] [
        set heading towards evacuee if [distance myself] of evacuee > 3 [
          fd MEDEVAC_Speed
        ]
      ]

      ask medevacs with [dispatched = TRUE] with [evacuating = FALSE] [
        if [distance myself] of evacuee <= 3 [
          set evacuating TRUE
          ask evacuee [
            set evacuated TRUE
          ]
        ]
      ]
    ]

  ;; --------------------------------- EVACUATING --------------------------------------------- ;;
  if count casualties + 1 = casualty_count_stabilizer [
    ask medevacs with [evacuating = TRUE] [set mtf_selection min-one-of mtfs [distance myself]]
  ]

  ask medevacs with [evacuating = TRUE] [
    set evacuation_time evacuation_time + 1
  ]

  ask medevacs with [evacuating = TRUE] with [evacuation_time >= 10] with [unloading = FALSE] [
    ask casualties with [evacuated = TRUE] with [hidden? = FALSE] [
      set hidden? TRUE
      set dispatch_enroute FALSE
      set dispatch_time 0
    ]
    set heading towards mtf_selection if [distance myself] of mtf_selection > 3 [
      ; set heading towards mtf_selection if (not any? mtfs-on neighbors) and (not any? mtfs-on patch-ahead 2) and (not any? mtfs-on patch-ahead 0) [
      fd MEDEVAC_Speed
    ]
  ]

  ask medevacs with [evacuating = TRUE] with [unloading = FALSE] [
    if [distance myself] of mtf_selection <= 3 [
      set unloading TRUE
    ]
  ]

  ;; --------------------------------- UNLOADING --------------------------------------------- ;;
  ask medevacs with [unloading = TRUE] [
    set unloading_time unloading_time + 1
  ]
  ask medevacs with [unloading = TRUE] with [unloading_time >= 5] [
    set heading towards designated_landing_zone if [distance myself] of designated_landing_zone > 3 [
      ; set heading towards designated_landing_zone if (not any? staging_locations-on neighbors) and (not any? staging_locations-on patch-ahead 2)and (not any? staging_locations-on patch-ahead 0) [
      fd MEDEVAC_Speed
    ]
  ]
  ask medevacs with [unloading = TRUE] with [mission_complete = FALSE] [
    if [distance myself] of designated_landing_zone <= 3 [
      set mission_complete TRUE
    ]
  ]
  ; ask medevacs with [unloading = TRUE] with [mission_complete = FALSE] with [unloading_time >= 5] with [province = "helmand" or province = "kandahar"] [set mission_complete TRUE]

  ;; --------------------------------- MISSION-RESET --------------------------------------------- ;;
  ask medevacs with [mission_complete = TRUE] [
    set response_time (dispatch_time - unloading_time + 5)
    ifelse RTT = "NATO" [
      if response_time <= 90 and classification = "urgent" [set total_utility total_utility + casualty_count * 10]
      if response_time <= 360 and classification = "priority" [set total_utility total_utility + casualty_count]
      ;; if response_time <= 2400 and classification = "routine" [set total_utility total_utility + casualty_count]
    ][
      if response_time <= 60 and classification = "urgent" [set total_utility total_utility + casualty_count * 10]
      if response_time <= 240 and classification = "priority" [set total_utility total_utility + casualty_count]
      ;; if response_time <= 2400 and classification = "routine" [set total_utility total_utility + casualty_count]
    ]
    set missions_complete missions_complete + 1
    set dispatched FALSE
    set unloading FALSE
    set evacuating FALSE
    set mission_complete FALSE
    set dispatch_time 0
    set evacuation_time 0
    set unloading_time 0
    set casualty_count 0
  ] ; reset

  tick
end
@#$#@#$#@
GRAPHICS-WINDOW
535
15
1295
776
-1
-1
2.5
1
10
1
1
1
0
0
0
1
0
300
0
300
1
1
1
ticks
30.0

BUTTON
23
163
86
196
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
24
202
87
235
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
0

MONITOR
34
378
193
423
Z distance to evacuee
[evacuee_distance] of medevacs with [province = \"zabul\"]
5
1
11

MONITOR
34
477
178
522
K distance to evacuee
[evacuee_distance] of medevacs with [province = \"kandahar\"]
17
1
11

MONITOR
34
577
184
622
H distance to evacuee
[evacuee_distance] of medevacs with [province = \"helmand\"]
17
1
11

MONITOR
34
681
178
726
N distance to evacuee
[evacuee_distance] of medevacs with [province = \"nimroz\"]
17
1
11

MONITOR
199
378
399
423
Zabul MEDEVAC dispatched?
[dispatched] of medevacs with [province = \"zabul\"]
17
1
11

MONITOR
182
477
406
522
Kandahar MEDEVAC dispatched?
[dispatched] of medevacs with [province = \"kandahar\"]
17
1
11

MONITOR
187
577
406
622
Helmand MEDEVAC dispatched?
[dispatched] of medevacs with [province = \"helmand\"]
17
1
11

MONITOR
181
680
387
725
Nimroz MEDEVAC dispatched?
[dispatched] of medevacs with [province = \"nimroz\"]
17
1
11

MONITOR
251
239
391
284
MEDEVAC Requests
missions_complete
17
1
11

MONITOR
167
239
248
284
total utility
total_utility
17
1
11

MONITOR
404
379
509
424
Z evacuating?
[evacuating] of medevacs with [province = \"zabul\"]
17
1
11

MONITOR
392
681
496
726
N evacuating?
[evacuating] of medevacs with [province = \"nimroz\"]
17
1
11

MONITOR
411
576
515
621
H evacuating?
[evacuating] of medevacs with [province = \"helmand\"]
17
1
11

MONITOR
409
478
512
523
K evacuating?
[evacuating] of medevacs with [province = \"kandahar\"]
17
1
11

MONITOR
35
428
133
473
Z unloading?
[unloading] of medevacs with [province = \"zabul\"]
17
1
11

MONITOR
34
527
126
572
K unloading?
[unloading] of medevacs with [province = \"kandahar\"]
17
1
11

MONITOR
34
626
131
671
H unloading?
[unloading] of medevacs with [province = \"helmand\"]
17
1
11

MONITOR
34
730
131
775
N unloading?
[unloading] of medevacs with [province = \"nimroz\"]
17
1
11

CHOOSER
189
164
340
209
Dispatching_Strategy
Dispatching_Strategy
"Myopic" "Intra-Zone" "Optimal"
0

TEXTBOX
982
24
1132
48
KANDAHAR
20
0.0
1

TEXTBOX
551
26
701
50
NIMROZ
20
0.0
1

TEXTBOX
746
26
896
50
HELMAND
20
0.0
1

TEXTBOX
1217
26
1367
50
ZABUL
20
0.0
1

MONITOR
137
429
293
474
Z Event Classification
[classification] of medevacs with [province = \"zabul\"]
17
1
11

MONITOR
130
528
284
573
K Event Classification
[classification] of medevacs with [province = \"kandahar\"]
17
1
11

MONITOR
135
626
290
671
H Event Classification
[classification] of medevacs with [province = \"helmand\"]
17
1
11

MONITOR
137
730
292
775
N Event Classification
[classification] of medevacs with [province = \"nimroz\"]
17
1
11

MONITOR
287
528
416
573
K Response Time
[response_time] of medevacs with [province = \"kandahar\"]
17
1
11

MONITOR
296
627
424
672
H Response Time
[response_time] of medevacs with [province = \"helmand\"]
17
1
11

MONITOR
297
430
426
475
Z Response Time
[response_time] of medevacs with [province = \"zabul\"]
17
1
11

MONITOR
298
731
426
776
N Response Time
[response_time] of medevacs with [province = \"nimroz\"]
17
1
11

CHOOSER
93
164
185
209
RTT
RTT
"NATO" "US"
0

MONITOR
1221
690
1290
771
TIME
ticks mod 2400
17
1
20

MONITOR
1158
690
1218
771
DAY
floor (ticks / 2400)
17
1
20

TEXTBOX
20
57
526
85
For Technical Report, Code, visit mahdialhusseini.com
18
0.0
1

MONITOR
24
239
163
284
CASEVAC Requests
casevac_count
17
1
11

INPUTBOX
345
163
493
223
MEDEVAC_Speed
2.54
1
0
Number

MONITOR
396
238
522
283
Casualty Counter
casualty_generator
17
1
11

TEXTBOX
61
345
489
393
TROUBLESHOOTING MONITORS (ADMIN)
20
0.0
1

TEXTBOX
218
131
368
155
PRIMARY GUI
20
0.0
1

TEXTBOX
52
15
538
47
MEDEVAC DISPATCH SIMULATIONS
25
0.0
1

TEXTBOX
1042
754
1192
772
Mahdi Al-Husseini
12
0.0
1

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

ambulance
false
0
Rectangle -7500403 true true 30 90 210 195
Polygon -7500403 true true 296 190 296 150 259 134 244 104 210 105 210 190
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Circle -16777216 true false 69 174 42
Rectangle -1 true false 288 158 297 173
Rectangle -1184463 true false 289 180 298 172
Rectangle -2674135 true false 29 151 298 158
Line -16777216 false 210 90 210 195
Rectangle -16777216 true false 83 116 128 133
Rectangle -16777216 true false 153 111 176 134
Line -7500403 true 165 105 165 135
Rectangle -7500403 true true 14 186 33 195
Line -13345367 false 45 135 75 120
Line -13345367 false 75 135 45 120
Line -13345367 false 60 112 60 142

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

azaps
false
0
Rectangle -2674135 true false 150 135 270 150
Rectangle -2674135 true false 30 135 150 150
Rectangle -7500403 true true 120 60 135 90
Rectangle -16777216 true false 135 60 150 75
Rectangle -16777216 true false 150 60 165 75
Rectangle -7500403 true true 150 90 165 105
Rectangle -7500403 true true 135 45 150 60
Rectangle -2674135 true false 120 90 135 105
Rectangle -7500403 true true 150 90 165 105
Rectangle -7500403 true true 90 120 135 120
Rectangle -7500403 true true 90 120 180 120
Rectangle -13345367 true false 90 105 210 120
Rectangle -13345367 true false 180 105 195 120
Circle -13345367 true false 105 120 90
Rectangle -16777216 true false 195 105 210 120
Rectangle -16777216 true false 150 90 165 105
Rectangle -16777216 true false 135 75 165 90
Rectangle -2674135 true false 165 60 180 105
Rectangle -7500403 true true 150 45 165 60
Rectangle -13345367 true false 195 105 210 120
Rectangle -13345367 true false 90 210 210 225
Rectangle -6459832 true false 120 285 120 300
Rectangle -2674135 true false 120 225 135 300
Rectangle -2674135 true false 165 225 180 300
Circle -2674135 true false 135 135 0
Rectangle -2674135 true false 135 60 135 105
Rectangle -2674135 true false 120 60 135 90
Rectangle -2674135 true false 120 45 180 60
Rectangle -13345367 true false 150 180 165 195
Rectangle -13345367 true false 135 165 150 180
Rectangle -2674135 true false 150 165 165 165
Rectangle -13345367 true false 150 150 165 165
Rectangle -2674135 true false 120 150 165 165
Rectangle -2674135 true false 135 150 150 165
Rectangle -2674135 true false 120 165 135 180
Rectangle -2674135 true false 135 180 150 195
Rectangle -2674135 true false 150 180 165 195
Rectangle -2674135 true false 120 150 135 165
Rectangle -2674135 true false 120 180 135 195
Rectangle -13345367 true false 120 150 165 195
Rectangle -16777216 true false 135 75 135 75
Rectangle -16777216 true false 135 60 135 75
Rectangle -16777216 true false 150 90 150 90
Rectangle -16777216 true false 135 75 150 105
Rectangle -2674135 true false 150 135 165 150
Rectangle -2674135 true false 150 180 165 195
Rectangle -2674135 true false 135 150 150 165
Rectangle -2674135 true false 135 165 150 180

blackhawk
false
3
Rectangle -7500403 true false 165 135 210 195
Polygon -7500403 true false 270 180 285 165 255 150 240 135 180 135 210 195
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 240 150 252 171 225 180 225 150
Rectangle -1184463 true false 289 180 298 172
Polygon -7500403 true false 165 195 60 195 15 120 30 120 60 165 165 135 165 195
Rectangle -7500403 true false 180 120 195 135
Polygon -7500403 true false 180 105 285 105 240 120
Polygon -7500403 true false 195 105 75 105 135 120
Polygon -7500403 true false 195 105 60 90 165 90
Polygon -7500403 true false 180 120 255 75 210 90
Polygon -16777216 true false 210 150 210 180 180 180 180 150
Polygon -16777216 true false 180 150 180 180 150 180 150 150
Line -7500403 false 180 150 180 180
Line -2674135 false 120 150 120 180
Line -2674135 false 105 165 135 165
Polygon -7500403 true false 180 120 195 105 195 120
Polygon -7500403 true false 30 120 0 120 15 135 30 135
Polygon -7500403 true false 15 135 0 165 30 135 15 120
Polygon -7500403 true false 15 120 75 120 30 135

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

byzantine
false
15
Rectangle -6459832 true false 120 60 135 90
Rectangle -6459832 true false 135 60 150 75
Rectangle -6459832 true false 150 60 165 75
Rectangle -7500403 true false 150 90 165 105
Rectangle -6459832 true false 135 45 150 60
Rectangle -6459832 true false 120 90 135 105
Rectangle -7500403 true false 150 90 165 105
Rectangle -7500403 true false 90 120 135 120
Rectangle -7500403 true false 90 120 180 120
Rectangle -6459832 true false 90 105 210 120
Rectangle -6459832 true false 180 105 195 120
Circle -6459832 true false 105 120 90
Rectangle -16777216 true false 195 105 210 120
Rectangle -16777216 true false 150 90 165 105
Rectangle -16777216 true false 135 75 165 90
Rectangle -6459832 true false 165 60 180 105
Rectangle -6459832 true false 150 45 165 60
Rectangle -6459832 true false 195 105 210 120
Rectangle -6459832 true false 90 210 210 225
Rectangle -6459832 true false 120 285 120 300
Rectangle -6459832 true false 120 225 135 300
Rectangle -6459832 true false 165 225 180 300
Circle -2674135 true false 135 150 30
Circle -2674135 true false 135 135 0
Rectangle -6459832 true false 150 135 270 150
Rectangle -6459832 true false 30 135 150 150

byzantineflags
false
12
Rectangle -7500403 true false 135 75 135 255
Rectangle -7500403 true false 90 75 105 285
Rectangle -2674135 true false 105 75 225 150
Rectangle -1 true false 180 90 180 105
Rectangle -1 true false 180 90 165 105
Circle -1 true false 135 90 60
Rectangle -2674135 true false 105 150 225 165
Circle -2674135 true false 159 99 42
Rectangle -2674135 true false 105 75 225 165
Rectangle -955883 true false 150 75 165 165
Rectangle -955883 true false 105 120 225 135
Rectangle -955883 true false 195 90 210 105
Rectangle -955883 true false 195 150 210 165
Rectangle -955883 true false 120 90 135 105
Rectangle -955883 true false 120 150 135 165

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

casevac
false
3
Rectangle -16777216 true false 165 135 210 195
Polygon -16777216 true false 270 180 285 165 255 150 240 135 180 135 210 195
Rectangle -1 true false 195 60 195 105
Polygon -7500403 true false 240 150 252 171 225 180 225 150
Rectangle -1184463 true false 289 180 298 172
Polygon -16777216 true false 165 195 60 195 15 120 30 120 60 165 165 135 165 195
Rectangle -16777216 true false 180 120 195 135
Polygon -7500403 true false 180 105 285 105 240 120
Polygon -7500403 true false 195 105 75 105 135 120
Polygon -7500403 true false 195 105 60 90 165 90
Polygon -7500403 true false 180 120 255 75 210 90
Polygon -7500403 true false 210 150 210 180 180 180 180 150
Polygon -7500403 true false 180 150 180 180 150 180 150 150
Line -16777216 false 180 150 180 180
Polygon -7500403 true false 180 120 195 105 195 120
Polygon -16777216 true false 30 120 0 120 15 135 30 135
Polygon -16777216 true false 15 135 0 165 30 135 15 120
Polygon -16777216 true false 15 120 75 120 30 135

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

hospital
false
0
Polygon -16777216 true false 15 180 227 180 152 150 32 150
Rectangle -1 true false 75 135 270 255
Rectangle -16777216 true false 124 195 187 256
Rectangle -16777216 true false 210 195 255 240
Rectangle -16777216 true false 90 150 120 180
Rectangle -16777216 true false 225 150 255 180
Line -16777216 false 270 135 270 255
Rectangle -1 true false 15 180 75 255
Polygon -16777216 true false 75 135 270 135 240 90 105 90
Line -16777216 false 75 135 75 180
Rectangle -16777216 true false 30 195 93 240
Line -16777216 false 75 135 270 135
Line -16777216 false 240 90 270 135
Line -16777216 false 15 180 75 180
Line -7500403 true 60 195 60 240
Line -7500403 true 154 195 154 255
Rectangle -2674135 true false 165 105 180 180
Rectangle -2674135 true false 135 135 210 150

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

house two story
false
0
Polygon -7500403 true true 2 180 227 180 152 150 32 150
Rectangle -7500403 true true 270 75 285 255
Rectangle -7500403 true true 75 135 270 255
Rectangle -16777216 true false 124 195 187 256
Rectangle -16777216 true false 210 195 255 240
Rectangle -16777216 true false 90 150 135 180
Rectangle -16777216 true false 210 150 255 180
Line -16777216 false 270 135 270 255
Rectangle -7500403 true true 15 180 75 255
Polygon -7500403 true true 60 135 285 135 240 90 105 90
Line -16777216 false 75 135 75 180
Rectangle -16777216 true false 30 195 93 240
Line -16777216 false 60 135 285 135
Line -16777216 false 255 105 285 135
Line -16777216 false 0 180 75 180
Line -7500403 true 60 195 60 240
Line -7500403 true 154 195 154 255

janissaries
false
0
Rectangle -2674135 true false 150 135 270 150
Rectangle -2674135 true false 30 135 150 150
Rectangle -7500403 true true 120 60 135 90
Rectangle -16777216 true false 135 60 150 75
Rectangle -16777216 true false 150 60 165 75
Rectangle -7500403 true true 150 90 165 105
Rectangle -7500403 true true 135 45 150 60
Rectangle -2674135 true false 120 90 135 105
Rectangle -7500403 true true 150 90 165 105
Rectangle -7500403 true true 90 120 135 120
Rectangle -7500403 true true 90 120 180 120
Rectangle -10899396 true false 90 105 210 120
Rectangle -10899396 true false 180 105 195 120
Circle -1 true false 105 120 90
Rectangle -16777216 true false 195 105 210 120
Rectangle -16777216 true false 150 90 165 105
Rectangle -16777216 true false 135 75 165 90
Rectangle -2674135 true false 165 60 180 105
Rectangle -7500403 true true 150 45 165 60
Rectangle -10899396 true false 195 105 210 120
Rectangle -10899396 true false 90 210 210 225
Rectangle -6459832 true false 120 285 120 300
Rectangle -2674135 true false 120 225 135 300
Rectangle -2674135 true false 165 225 180 300
Circle -2674135 true false 135 135 0
Rectangle -2674135 true false 135 60 135 105
Rectangle -2674135 true false 120 60 135 90
Rectangle -2674135 true false 120 45 180 60
Rectangle -2674135 true false 150 165 165 165
Rectangle -16777216 true false 135 75 135 75
Rectangle -16777216 true false 135 60 135 75
Rectangle -16777216 true false 150 90 150 90
Rectangle -16777216 true false 135 75 150 105
Rectangle -7500403 true true 120 45 165 45
Rectangle -1 true false 120 30 180 45
Circle -2674135 true false 116 131 67
Circle -2674135 true false 150 165 0
Rectangle -2674135 true false 120 150 135 180
Rectangle -10899396 true false 135 135 165 195

landing_zone
false
0
Circle -1 true false 0 0 300
Circle -16777216 true false 30 30 240
Circle -16777216 true false 45 60 180
Rectangle -1 true false 75 60 105 240
Rectangle -1 true false 195 60 225 240
Rectangle -1 true false 105 135 195 165

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

oships
false
2
Rectangle -6459832 true false 60 165 240 255
Circle -6459832 true false 28 178 62
Circle -6459832 true false 208 178 62
Rectangle -2674135 true false 135 45 240 105
Circle -16777216 true false 60 180 60
Circle -16777216 true false 180 180 60
Circle -1 true false 165 45 60
Circle -1 true false 75 225 0
Circle -2674135 true false 195 75 0
Circle -2674135 true false 189 54 42
Rectangle -7500403 true false 135 45 150 210

ottomanflags
false
12
Rectangle -7500403 true false 135 75 135 255
Rectangle -7500403 true false 90 75 105 285
Rectangle -2674135 true false 105 75 225 150
Rectangle -1 true false 180 90 180 105
Rectangle -1 true false 180 90 165 105
Circle -1 true false 135 90 60
Rectangle -2674135 true false 105 150 225 165
Circle -2674135 true false 159 99 42

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

person soldier
false
0
Rectangle -7500403 true true 127 79 172 94
Polygon -10899396 true false 105 90 60 195 90 210 135 105
Polygon -10899396 true false 195 90 240 195 210 210 165 105
Circle -7500403 true true 110 5 80
Polygon -10899396 true false 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -6459832 true false 120 90 105 90 180 195 180 165
Line -6459832 false 109 105 139 105
Line -6459832 false 122 125 151 117
Line -6459832 false 137 143 159 134
Line -6459832 false 158 179 181 158
Line -6459832 false 146 160 169 146
Rectangle -6459832 true false 120 193 180 201
Polygon -6459832 true false 122 4 107 16 102 39 105 53 148 34 192 27 189 17 172 2 145 0
Polygon -16777216 true false 183 90 240 15 247 22 193 90
Rectangle -6459832 true false 114 187 128 208
Rectangle -6459832 true false 177 187 191 208

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

role_two
false
0
Rectangle -1 true false 75 135 270 210
Rectangle -16777216 true false 90 150 120 180
Rectangle -16777216 true false 225 150 255 180
Polygon -16777216 true false 75 135 270 135 240 90 105 90
Line -16777216 false 75 135 270 135
Line -16777216 false 240 90 270 135
Rectangle -2674135 true false 165 105 180 180
Rectangle -2674135 true false 135 135 210 150
Line -16777216 false 270 135 270 255

serbs
false
0
Rectangle -2674135 true false 150 135 270 150
Rectangle -2674135 true false 30 135 150 150
Rectangle -7500403 true true 120 60 135 90
Rectangle -16777216 true false 135 60 150 75
Rectangle -16777216 true false 150 60 165 75
Rectangle -7500403 true true 150 90 165 105
Rectangle -7500403 true true 135 45 150 60
Rectangle -2674135 true false 120 90 135 105
Rectangle -7500403 true true 150 90 165 105
Rectangle -7500403 true true 90 120 135 120
Rectangle -7500403 true true 90 120 180 120
Rectangle -13345367 true false 90 105 210 120
Rectangle -13345367 true false 180 105 195 120
Circle -13345367 true false 105 120 90
Rectangle -16777216 true false 195 105 210 120
Rectangle -16777216 true false 150 90 165 105
Rectangle -16777216 true false 135 75 165 90
Rectangle -2674135 true false 165 60 180 105
Rectangle -7500403 true true 150 45 165 60
Rectangle -13345367 true false 195 105 210 120
Rectangle -13345367 true false 90 210 210 225
Rectangle -6459832 true false 120 285 120 300
Rectangle -2674135 true false 120 225 135 300
Rectangle -2674135 true false 165 225 180 300
Circle -2674135 true false 135 135 0
Rectangle -2674135 true false 135 60 135 105
Rectangle -2674135 true false 120 60 135 90
Rectangle -2674135 true false 120 45 180 60
Rectangle -13345367 true false 150 180 165 195
Rectangle -13345367 true false 135 165 150 180
Rectangle -2674135 true false 150 165 165 165
Rectangle -13345367 true false 150 150 165 165
Rectangle -2674135 true false 120 150 165 165
Rectangle -2674135 true false 135 150 150 165
Rectangle -2674135 true false 120 165 135 180
Rectangle -2674135 true false 135 180 150 195
Rectangle -2674135 true false 150 180 165 195
Rectangle -2674135 true false 120 150 135 165
Rectangle -2674135 true false 120 180 135 195
Rectangle -13345367 true false 120 150 165 195
Rectangle -2674135 true false 135 120 165 210
Rectangle -2674135 true false 105 150 195 165
Rectangle -16777216 true false 135 75 135 75
Rectangle -16777216 true false 135 60 135 75
Rectangle -16777216 true false 150 90 150 90
Rectangle -16777216 true false 135 75 150 105

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

tank
true
0
Rectangle -7500403 true true 144 0 159 105
Rectangle -6459832 true false 195 45 255 255
Rectangle -16777216 false false 195 45 255 255
Rectangle -6459832 true false 45 45 105 255
Rectangle -16777216 false false 45 45 105 255
Line -16777216 false 45 75 255 75
Line -16777216 false 45 105 255 105
Line -16777216 false 45 60 255 60
Line -16777216 false 45 240 255 240
Line -16777216 false 45 225 255 225
Line -16777216 false 45 195 255 195
Line -16777216 false 45 150 255 150
Polygon -7500403 true true 90 60 60 90 60 240 120 255 180 255 240 240 240 90 210 60
Rectangle -16777216 false false 135 105 165 120
Polygon -16777216 false false 135 120 105 135 101 181 120 225 149 234 180 225 199 182 195 135 165 120
Polygon -16777216 false false 240 90 210 60 211 246 240 240
Polygon -16777216 false false 60 90 90 60 89 246 60 240
Polygon -16777216 false false 89 247 116 254 183 255 211 246 211 237 89 236
Rectangle -16777216 false false 90 60 210 90
Rectangle -16777216 false false 143 0 158 105

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

vicflags
false
12
Rectangle -7500403 true false 135 75 135 255
Rectangle -7500403 true false 90 75 105 285
Rectangle -2674135 true false 105 75 225 150
Rectangle -1 true false 180 90 180 105
Rectangle -1 true false 180 90 165 105
Circle -1 true false 135 90 60
Rectangle -2674135 true false 105 150 225 165
Circle -2674135 true false 159 99 42

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
  <experiment name="dispatching_strategies" repetitions="75" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="144000"/>
    <metric>total_utility</metric>
    <enumeratedValueSet variable="Dispatching_Strategy">
      <value value="&quot;Myopic&quot;"/>
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
