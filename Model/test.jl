function increment()
    global i = i + 1
end

i = 0;
for j = 1:10
  increment()
end
println(i)
