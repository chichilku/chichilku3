require_relative '../lib/share/network'

describe "Network", :network do
    context "With valid input" do
        it "should pack valid small range without errors" do
            (0..NET_MAX_INT).each do |i|
                net_pack_int(i)
            end
        end

        it "should pack valid big range without errors" do
            # hooman logic to get max num of len:
            # == len 2 ==
            # 10*10-1 = 99
            # 9+1 = 10
            # (9+1)*(9+1) = 99
            # == len 3 ==
            # 10*10*10-1 = 999
            #
            # hooman 9 net equivalent is NET_MAX_INT
            # highest hooman digit is 9 lowest 0
            # highest net digit is ~ lowest !
            #
            # ~! * ~! - " = ~~
            # 94 * 94 - 1 = 8835
            # net_pack_bigint(8835, 2) = ~~
            (0..((NET_MAX_INT+1)*(NET_MAX_INT+1)-1)).each do |i|
                net_pack_bigint(i, 2)
            end
        end

        it "should pack and unpack same value (small)" do
            (0..NET_MAX_INT).each do |i|
                expect(net_unpack_int(net_pack_int(i))).to eq(i)
            end
        end

        it "should pack and unpack same value (big)" do
            (0..((NET_MAX_INT+1)*(NET_MAX_INT+1)-1)).each do |i|
                expect(net_unpack_bigint(net_pack_bigint(i, 2))).to eq(i)
            end
        end

        it "should pack and unpack same value in any buffer size" do
            (2..10).each do |buffersize|
                (0..((NET_MAX_INT+1)*(NET_MAX_INT+1)-1)).each do |i|
                    expect(net_unpack_bigint(net_pack_bigint(i, buffersize))).to eq(i)
                end
            end
        end

        it "should pack and unpack same value for big numbers" do
            (999000..999999).each do |i|
                expect(net_unpack_bigint(net_pack_bigint(i, 6))).to eq(i)
            end
        end
    end
end
