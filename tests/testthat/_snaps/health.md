# health_summary prints

    Code
      health_summary(sim, truth = given)
    Message
      Label health
      * Overall score: 0.923
      * Estimated label issues: 23 of 300 examples
      
      Classes with the lowest label quality:
    Output
      # A tibble: 4 x 7
        class     n num_label_issues label_issue_rate label_noise inverse_label_noise
        <fct> <int>            <int>            <dbl>       <dbl>               <dbl>
      1 C        60                7           0.117       0.135               0.159 
      2 A       119                9           0.0756      0.0971              0.118 
      3 D        24                2           0.0833      0.229               0.118 
      4 B        97                5           0.0515      0.0938              0.0847
      # i 1 more variable: label_quality <dbl>
    Message
      
      Most confused class pairs:
    Output
      # A tibble: 5 x 4
        class_1 class_2 num_overlapping joint_probability
        <fct>   <fct>             <int>             <dbl>
      1 A       C                    13           0.0436 
      2 A       B                     9           0.0316 
      3 B       D                     5           0.0164 
      4 B       C                     3           0.0100 
      5 A       D                     3           0.00941

