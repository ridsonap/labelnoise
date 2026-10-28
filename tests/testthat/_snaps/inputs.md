# invalid inputs give informative errors

    Code
      label_inputs(toy_labels, toy_probs[1:3, ])
    Condition
      Error in `label_inputs()`:
      ! `pred_probs` has 3 rows, but 5 labels were supplied.

# labelnoise_inputs pass through and print

    Code
      print(inputs)
    Message
      <labelnoise_inputs>: 5 examples, 2 classes

