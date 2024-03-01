require 'cipher_solver'

describe CipherSolver do
    describe '.inc_chars_with_wraparound' do
        it 'increments a character by one' do
            expect(CipherSolver.inc_chars_with_wraparound('a')).to eq('b')
            expect(CipherSolver.inc_chars_with_wraparound('A')).to eq('B')
            expect(CipherSolver.inc_chars_with_wraparound('Aby')).to eq('Bcz')
        end

        it 'wraps around within lowercase letters' do
            expect(CipherSolver.inc_chars_with_wraparound('z')).to eq('a')
            expect(CipherSolver.inc_chars_with_wraparound('zas')).to eq('abt')
        end

        it 'wraps around within uppercase letters' do
            expect(CipherSolver.inc_chars_with_wraparound('Z')).to eq('A')
            expect(CipherSolver.inc_chars_with_wraparound('ZAS')).to eq('ABT')
        end

        it 'ignores punctuation' do
            expect(CipherSolver.inc_chars_with_wraparound('!')).to eq('!')
            expect(CipherSolver.inc_chars_with_wraparound(' ')).to eq(' ')
            expect(CipherSolver.inc_chars_with_wraparound('one !')).to eq('pof !')
        end

        it 'ignores empty strings' do
            expect(CipherSolver.inc_chars_with_wraparound('')).to eq('')
        end
    end

    describe '.generate_permutations' do
        it 'generates 25 permutations from one input string' do
            expect(CipherSolver.generate_permutations('ao!')).to include(
                {'text'=>'ao!', 'offset'=>0}, {'text'=>'th!', 'offset'=>19}, {'text'=>'ui!', 'offset'=>20})
        end
    end

    describe '.assign_weights_to_permutations' do
        it 'uses detectlanguage to detect which sentences are most likely to be real languages' do
            expect(CipherSolver.assign_weights_to_permutations([{'text'=>'asdk d asdd lkmd', 'offset'=>0}, {'text'=>'the cow jumped over the moon', 'offset'=>1}])).to eq([ 
                {'text'=>'the cow jumped over the moon', 'offset'=>1, 'language'=>'en', 'isReliable'=>true, 'confidence'=>15.88},
                {'text'=>'asdk d asdd lkmd', 'offset'=>0, 'language'=>'eu', 'isReliable'=>true, 'confidence'=>2.435}
            ])
        end
    end

    describe '.print_human_readable' do
        it 'prints weighted permutations in human readable format' do
            expect { CipherSolver.print_human_readable([ 
                {'text'=>'the cow jumped over the moon', 'language'=>'en', 'isReliable'=>true, 'confidence'=>15.88},
                {'text'=>'asdk d asdd lkmd', 'language'=>'eu', 'isReliable'=>false, 'confidence'=>2.435}
            ])}.to output(
                a_string_including('the cow jumped over the moon'.green).and a_string_including('asdk d asdd lkmd'.red)
                ).to_stdout
        end
    end
end