# frozen_string_literal: true

require_relative '../lib/share/math'

describe 'Math', :math do
  context 'Intervals left' do
    it 'Should get get left points for interval 64 correct' do
      expect(closest_interval_side(64, 65)).to eq(-1)
      expect(closest_interval_side(64, 66)).to eq(-1)
      expect(closest_interval_side(64, 67)).to eq(-1)
      expect(closest_interval_side(64, 68)).to eq(-1)
      expect(closest_interval_side(64, 69)).to eq(-1)
      expect(closest_interval_side(64, 70)).to eq(-1)
    end

    it 'Should get get left points for interval 128 correct' do
      expect(closest_interval_side(128, 129)).to eq(-1)
      expect(closest_interval_side(128, 130)).to eq(-1)
      expect(closest_interval_side(128, 131)).to eq(-1)
      expect(closest_interval_side(128, 132)).to eq(-1)
      expect(closest_interval_side(128, 133)).to eq(-1)
      expect(closest_interval_side(128, 134)).to eq(-1)
    end
  end

  context 'Intervals right' do
    it 'Should get get right points for interval 64 correct' do
      expect(closest_interval_side(64, 127)).to eq(1)
      expect(closest_interval_side(64, 126)).to eq(1)
      expect(closest_interval_side(64, 125)).to eq(1)
      expect(closest_interval_side(64, 124)).to eq(1)
      expect(closest_interval_side(64, 123)).to eq(1)
      expect(closest_interval_side(64, 122)).to eq(1)
    end

    it 'Should get get right points for interval 128 correct' do
      expect(closest_interval_side(128, 255)).to eq(1)
      expect(closest_interval_side(128, 254)).to eq(1)
      expect(closest_interval_side(128, 253)).to eq(1)
      expect(closest_interval_side(128, 252)).to eq(1)
      expect(closest_interval_side(128, 251)).to eq(1)
      expect(closest_interval_side(128, 250)).to eq(1)
    end
  end

  context 'Intervals left higher points' do
    it 'Should get get left high points for interval 64 correct' do
      expect(closest_interval_side(64, 513)).to eq(-1)
      expect(closest_interval_side(64, 514)).to eq(-1)
      expect(closest_interval_side(64, 515)).to eq(-1)
      expect(closest_interval_side(64, 516)).to eq(-1)
      expect(closest_interval_side(64, 517)).to eq(-1)
      expect(closest_interval_side(64, 518)).to eq(-1)
    end

    it 'Should get get left points for interval 128 correct' do
      expect(closest_interval_side(128, 1025)).to eq(-1)
      expect(closest_interval_side(128, 1026)).to eq(-1)
      expect(closest_interval_side(128, 1027)).to eq(-1)
      expect(closest_interval_side(128, 1028)).to eq(-1)
      expect(closest_interval_side(128, 1029)).to eq(-1)
      expect(closest_interval_side(128, 1030)).to eq(-1)
    end
  end

  context 'Intervals right higher points' do
    it 'Should get get right high points for interval 64 correct' do
      expect(closest_interval_side(64, 575)).to eq(1)
      expect(closest_interval_side(64, 574)).to eq(1)
      expect(closest_interval_side(64, 573)).to eq(1)
      expect(closest_interval_side(64, 572)).to eq(1)
      expect(closest_interval_side(64, 571)).to eq(1)
      expect(closest_interval_side(64, 570)).to eq(1)
    end

    it 'Should get get right points for interval 128 correct' do
      expect(closest_interval_side(128, 1151)).to eq(1)
      expect(closest_interval_side(128, 1150)).to eq(1)
      expect(closest_interval_side(128, 1149)).to eq(1)
      expect(closest_interval_side(128, 1148)).to eq(1)
      expect(closest_interval_side(128, 1147)).to eq(1)
      expect(closest_interval_side(128, 1146)).to eq(1)
    end
  end
end
