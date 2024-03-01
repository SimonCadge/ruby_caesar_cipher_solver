require 'bundler/setup'
require 'dotenv/load'
require 'colorize'
require 'detect_language'

# Run DetectLanguage config script before anything else
# api_key loaded from environment, using dotenv for dev
DetectLanguage.configure do |config|
    config.api_key = ENV['DETECT_LANGUAGE_KEY']
    config.secure = true
end

class CipherSolver
    def self.inc_chars_with_wraparound(input_string)
        # If a character is alphabetical increment it with wraparound preserving case.
        # If a character isn't alphabetical ignore it.
        input_string.chars.map do |c| 
            if (c.ord >= 97 and c.ord < 122) or (c.ord >= 65 and c.ord < 90)
                (c.ord + 1).chr
            elsif c.ord == 122 #z
                'a'
            elsif c.ord == 90 #Z
                'A'
            else
                c
            end
        end.join
    end

    def self.generate_permutations(first_permutation)
        permutations = [{'text'=>first_permutation, 'offset'=>0}]

        # We already have offset 0, so this generates offset 1 -> 25
        for i in 1...26
            permutations.append({'text'=>inc_chars_with_wraparound(permutations.last['text']), 'offset'=>i})
        end

        permutations
    end

    def self.assign_weights_to_permutations(permutations)
        # Send all permutations to DetectLanguage in a single call
        language_guesses = DetectLanguage.detect(permutations.map {|permutation| permutation['text']})
        weighted_permutations = []
        
        # Enrich permutation hashes with DetectLanguage prediction data
        for i in 0...permutations.length
            if language_guesses[i].class == Array
                if language_guesses[i].length > 0
                    weighted_permutation = language_guesses[i][0].merge(permutations[i])
                    weighted_permutations.append(weighted_permutation)
                else
                    # Sometimes DetectLanguage doesn't detect anything, so the array is empty
                    weighted_permutation = permutations[i]
                    weighted_permutation['isReliable'] = false
                    weighted_permutation['confidence'] = 0.0
                    weighted_permutations.append(weighted_permutation)
                end
            else
                weighted_permutation = language_guesses[i].merge(permutations[i])
                weighted_permutations.append(weighted_permutation)
            end 
        end

        # Sort the permutations by confidence value in descending order
        weighted_permutations = weighted_permutations.sort_by {|obj| obj['confidence']}.reverse
        weighted_permutations
    end

    def self.print_human_readable(weighted_permutations)
        for permutation in weighted_permutations do
            if permutation['isReliable'] and permutation['confidence'] > 5.0
                puts permutation['text'].green
            else
                puts permutation['text'].red
            end
        end
    end

end

# Read cipher from the command line, process it and print out results
cmd_arguments = ARGV
if cmd_arguments.length == 1
    permutations = CipherSolver.generate_permutations(cmd_arguments[0])
    weighted_permutations = CipherSolver.assign_weights_to_permutations(permutations)
    CipherSolver.print_human_readable(weighted_permutations)
end