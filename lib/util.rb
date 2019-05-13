def subs(hash)
  subarrays(hash.keys).map do |sub|
    sub.map {|key| [key, hash[key]] }.to_h
  end
end

def subarrays(arr)
  return [[]] if arr.length == 0
  prev = subarrays(arr[0...-1])
  prev + prev.map {|sub| sub + [arr.last]}
end
