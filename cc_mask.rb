#!/usr/bin/env ruby

def credit_card_check(sequence)
  sequence_length = sequence.length
  return false if sequence_length < 14 || sequence_length > 16
  return false unless sequence.gsub(/[-\d\s]/, '').empty?
  return luhn_check(sequence)
end

def luhn_check(sequence)
  digit_array = sequence.gsub(/\D/, '').split('').collect{ |n| n.to_i }
  
  index = digit_array.length - 2
  while (index >= 0) do
    double = digit_array[index] * 2
    digit_array[index] = double < 10 ? double : [1, double - 10]
    index -= 2
  end
  
  remainder = digit_array.flatten.inject(0){ |sum, n| sum + n} % 10
  remainder.zero? ? true : false
end

def digit_count(sequence)
  sequence.gsub(/\D/, '').length
end
  
while log_line = gets
  log_line.chomp!
  output_line = ''


  # While we have characters left to test
  until log_line.empty?
    match_data = log_line.match /^([^-\d\s]*)([-\d\s]*)(.*)$/
    output_line += match_data[1]

    # if number of digits < 14 it couldn't be a CC number
    if digit_count(match_data[2]) < 14
      output_line += match_data[2]
    else
      # match_data[2] contains a string of digits, spaces, dashes.
      # Start at the first character.  Find 14, 15 and 16 digit strings
      # and if any of those match mark the appropriate spot in the mask
      # array (skipping non-digits!) for masking.
      all_characters = match_data[2]
#      puts "Checking mid-string: \"#{all_characters}\", length #{all_characters.length}"
      # Start at the first character
      current_index = 0
      # shortest possible match could start at this index
      last_index = all_characters.length - 14
#      puts "  last_index: #{last_index}"
      # Build array of mask indicators, one for each character in our
      # test string.  Initialize this mask_array with all "false" values.
      mask_array = [false] * all_characters.length

      (0..last_index).each do |current_index|
        # Get all digits from current_index
        digits = all_characters[current_index..-1].gsub(/\D/, '')
        # we're done if we have less than 14 digits.
        break if digits.length < 14
        # check for 14 digit CC
#        puts "  luhn_check-14: #{digits[0...14]}"
        if luhn_check(digits[0...14])
#          puts "    TRUE"
          to_mask = 14
          mask_index = current_index
          while to_mask > 0
            if all_characters[mask_index].match /\d/
              mask_array[mask_index] = true
              to_mask -= 1
            end
            mask_index += 1
          end
#          puts "    mask_array: #{mask_array.inspect}"
        end
        if digits.length >= 15 and luhn_check(digits[0...15])
#          puts "    TRUE"
          to_mask = 15
          mask_index = current_index
          while to_mask > 0
            if all_characters[mask_index].match /\d/
              mask_array[mask_index] = true
              to_mask -= 1
            end
            mask_index += 1
          end
#          puts "    mask_array: #{mask_array.inspect}"
        end
        if digits.length >= 16 and luhn_check(digits[0...16])
#          puts "    TRUE"
          to_mask = 16
          mask_index = current_index
          while to_mask > 0
            if all_characters[mask_index].match /\d/
              mask_array[mask_index] = true
              to_mask -= 1
            end
            mask_index += 1
          end
#          puts "    mask_array: #{mask_array.inspect}"
        end
      end
      
      (0...all_characters.length).each do |mask_index|
#        puts "    before: #{output_line}"
        if mask_array[mask_index]
          output_line += 'X'
        else
          output_line += all_characters[mask_index]
        end
#        puts "    after: #{output_line}"
      end
    end
    
    log_line = match_data[3]
  end

  puts output_line
end
