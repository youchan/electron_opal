
def underscore(st)
  final = ''
  prev_was_uppercase = false
  first = true
  st.chars.each do |c|
    upper = c.upcase == c
    final += '_' if upper && !first && !prev_was_uppercase
    final += c.downcase
    prev_was_uppercase = upper
    first = false
  end
  final
end


def camelize(st)
  st.split('_')
  .collect(&:capitalize)
  .join
end
