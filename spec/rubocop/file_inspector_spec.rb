# encoding: utf-8

require 'spec_helper'

module Rubocop
  class FileInspector
    attr_writer :errors # Needed only for testing.
  end
end

describe Rubocop::FileInspector do
  subject(:inspector) { described_class.new(options) }
  let(:options) { {} }
  let(:offenses) { [] }
  let(:errors) { [] }

  before(:each) do
    $stdout = StringIO.new
    $stderr = StringIO.new

    allow(inspector).to receive(:process_source) do
      [double('ProcessedSource').as_null_object, []]
    end

    allow(inspector).to receive(:inspect_file) do
      inspector.errors = errors
      [offenses, !:updated_source_file]
    end
  end

  after(:each) do
    $stdout = STDOUT
    $stderr = STDERR
  end

  describe '#display_error_summary' do
    let(:errors) do
      ['An error occurred while Encoding cop was inspecting file.rb.']
    end

    it 'displays an error message to stderr when errors are present' do
      inspector.process_files(['file.rb'], nil) {}
      inspector.display_error_summary
      expect($stderr.string.lines.to_a[-6..-5])
        .to eq(["1 error occurred:\n", "#{errors.first}\n"])
    end
  end

  describe '#process_files' do
    context 'if there are no offenses in inspected files' do
      it 'returns false' do
        result = inspector.process_files(['file.rb'], nil) {}
        expect(result).to eq(false)
      end
    end

    context 'if there is an offense in an inspected file' do
      let(:offenses) do
        [Rubocop::Cop::Offense.new(:convention,
                                   Struct.new(:line, :column,
                                              :source_line).new(1, 0, ''),
                                   'Use alias_method instead of alias.',
                                   'Alias')]
      end

      it 'returns true' do
        expect(inspector.process_files(['file.rb'], nil) {}).to eq(true)
      end

      it 'sends the offense to a formatter' do
        inspector.process_files(['file.rb'], nil) {}
        expect($stdout.string.split("\n"))
          .to eq(['Inspecting 1 file',
                  'C',
                  '',
                  'Offenses:',
                  '',
                  "file.rb:1:1: C: #{offenses.first.message}",
                  '',
                  '1 file inspected, 1 offense detected'])
      end
    end
  end
end
