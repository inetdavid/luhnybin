#!/usr/bin/env ruby

# CcMasker class 
class CcMasker
  attr_reader :digits, :sequence

  def initialize(sequence)
    @sequence = sequence
    # Remove non-digits (dashes/spaces) from sequence
    @digits = sequence.gsub(/\D/, '')
    # Initialize mask of digits to mask out to all false.
    @digit_mask = [false] * sequence.length
  end

  # Here we detect valid CC sequences, set the appropriate
  # masks to indicate which digits need to be obscured, and
  # finally obscure all CC digits.
  def mask_cc
    # We have to check each starting point in the initial
    # sequence for all three valid CC lengths (14, 15 and 16
    # digits) to ensure that we cover all overlaping CC numbers.
    # We *can* stop once we have less than 14 digits though
    # since no valid CC sequences can be found after that point.

    # Work our way through the sequence starting at the beginning
    max_offset = @sequence.length - 14
    (0..max_offset).each do |current_offset|
      # Get up to 16 digits located after our current offset.
      digits = @sequence[current_offset..-1].gsub(/\D/, '')[0...16]

      # We're done if there are fewer than 14 digits left
      break if digits.length < 14

      # Mark digit locations to mask
      mark_mask(14, current_offset) if luhn_check(digits[0...14])

      # Check longer lengths if we have enough digits left
      mark_mask(15, current_offset) if luhn_check(digits[0...15]) if digits.length >= 15
      mark_mask(16, current_offset) if luhn_check(digits[0...16]) if digits.length >= 16
    end

    # Now use our generated mask to convert matching digits to 'X's
    (0...@sequence.length).each do |mask_index|
      @sequence[mask_index] = 'X' if @digit_mask[mask_index]
    end
  end

  private

  def mark_mask(length, offset)
    while length > 0
      # If next character is a digit then mark it for masking
      # and decrement the length remaining.
      if @sequence[offset].match /\d/
        @digit_mask[offset] = true
        length -= 1
      end
      offset += 1
    end
  end

  # Return true if sequence passes the Luhn check, else false
  #
  # The Luhn filter looks for sequeences of digits hat pass the Luhn check,
  # a simple checksum algorithm invented by Hans Peter Luhn in 1954.  All
  # valid credit card numbers pass the Luhn check, thereby enabling computer
  # programs, like our log filter, to distinguish credit card numbers from
  # random digit sequences.
  #
  # The Luhn check works like this:
  # 1) Starting from the rightmost digit and working left, double every
  #    second digit.
  # 2) If a product has two digits, treat the digits independently.
  # 3) Sum each individual digit, including the non-doubled digits.
  # 4) Divide the result by 10.
  # 5) If the remainder is 0, the number passed the Luhn check.
  ############################################################
  def luhn_check(sequence)
    # remove non-digits and convert to array of Fixnum digits
    # ("12-34" => [1, 2, 3, 4])
    digit_array = sequence.gsub(/\D/, '').split('').collect{ |n| n.to_i }

    # 1) Index every other digit, starting from the rightmost.
    index = digit_array.length - 2
    while (index >= 0) do
      double = digit_array[index] * 2
      # 2) Split digits if doubled value > 10
      digit_array[index] = double < 10 ? double : [1, double - 10]
      index -= 2
    end

    # 3, 4, 5) Sum and get remainder, modulo 10
    remainder = digit_array.flatten.inject(0){ |sum, n| sum + n} % 10

    # Luhn check passes if no remainder.
    remainder.zero? ? true : false
  end
end

while log_line = gets
  log_line.chomp!
  output_line = ''


  # While we have characters left to test
  until log_line.empty?
    # First split the current log line into three portions:
    # 1) Beginning of the log_line with *no* digits/dashes/spaces
    # 2) Longest string containing all digits/dashes/spaces.
    # 3) Remainder of log_line, starting with a *non* digit/dash/space.
    match_data = log_line.match /^([^-\d\s]*)([-\d\s]*)(.*)$/

    # First, match 1 just gets passed straight to the output line.
    output_line += match_data[1]

    # Match 2 could need CC numbers masked out so most work is done here.
    masker = CcMasker.new(match_data[2])

    # But if number of digits < 14 it couldn't be a CC number
    if masker.digits.length < 14
      # So jsut append to the output line as is.
      output_line += masker.sequence
    else
      # Detect and mask out any CC sequences found.
      masker.mask_cc

      # Add masked sequence to output line
      output_line += masker.sequence
    end

    # Continue processing remainder of log_line
    log_line = match_data[3]
  end

  puts output_line
end
