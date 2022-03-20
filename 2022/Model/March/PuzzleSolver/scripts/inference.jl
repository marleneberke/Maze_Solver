using PuzzleSolver

# trace, _ = generate(gm, (10,))
# display(get_choices(trace))

function mh_inference()
    observation = Gen.choicemap((:total_time, 300.))

    (trace, _) = generate(gm, (10,), observation)
    display(get_choices(trace))

    selection = select(:chain, :time_per_unit_think)

    for iter = 1:5
        trace, accepted = mh(trace, selection)
        println("accepted ", accepted)
        display(get_choices(trace))
    end
end

mh_inference()
